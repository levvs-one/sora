import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show Server, ServiceCall;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/ext/bypass.dart';
import 'package:sora/src/ext/catalog.dart';
import 'package:sora/src/ext/conflicts.dart';
import 'package:sora/src/ext/package.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/ext/verifier.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/ui/extensions/detail_screen.dart';
import 'package:sora/src/ui/modes.dart';
import 'package:sora/src/generated/sora/custom/v1/custom.pbgrpc.dart' as custom;
import 'package:sora/src/sora.dart';

class _Custom extends custom.CustomServersServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('$invocation');
  @override
  Future<custom.ListCustomServersResponse> listCustomServers(
    ServiceCall call,
    custom.ListCustomServersRequest request,
  ) async => custom.ListCustomServersResponse();
}

class _Core extends CoreControlServiceBase {
  final events = StreamController<CoreEvent>.broadcast();
  final subscriptions = StreamController<SubscriptionState>.broadcast();
  Future<void> close() async {
    await subscriptions.close();
    await events.close();
  }

  ConnectionState state = ConnectionState(value: ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED);
  final plans = <SessionPlan>[];
  int disconnects = 0;
  bool reject = false;
  Completer<void>? gate;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('$invocation');
  @override
  Future<HandshakeResponse> handshake(ServiceCall call, HandshakeRequest request) async =>
      HandshakeResponse(negotiatedVersion: apiVersion, controlAuthenticator: List.filled(32, 7));
  @override
  Future<GetAboutResponse> getAbout(ServiceCall call, GetAboutRequest request) async =>
      GetAboutResponse(about: About(contract: apiVersion.deepCopy()..capabilities.add('serverless')));
  @override
  Future<GetStatusResponse> getStatus(ServiceCall call, GetStatusRequest request) async =>
      GetStatusResponse(status: SessionStatus(connection: state));
  @override
  Future<ListProfilesResponse> listProfiles(ServiceCall call, ListProfilesRequest request) async =>
      ListProfilesResponse();
  @override
  Future<GetStatsResponse> getStats(ServiceCall call, GetStatsRequest request) async =>
      GetStatsResponse(stats: StatsTick());
  @override
  Stream<SubscriptionState> watchSubscriptions(ServiceCall call, WatchSubscriptionsRequest request) =>
      subscriptions.stream;
  @override
  Stream<CoreEvent> watchEvents(ServiceCall call, WatchEventsRequest request) => events.stream;
  @override
  Future<ConnectResponse> connect(ServiceCall call, ConnectRequest request) async {
    expect(request.controlAuthenticator, List.filled(32, 7));
    plans.add(request.sessionPlan.deepCopy());
    await gate?.future;
    if (reject) return ConnectResponse(error: SoraError(userMessageKey: 'core.engine.binary_missing'));
    state = ConnectionState(value: ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTED, sessionId: 'fixture');
    return ConnectResponse(status: SessionStatus(connection: state));
  }

  @override
  Future<DisconnectResponse> disconnect(ServiceCall call, DisconnectRequest request) async {
    expect(request.controlAuthenticator, List.filled(32, 7));
    disconnects++;
    state = ConnectionState(value: ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED);
    return DisconnectResponse(status: SessionStatus(connection: state));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = Directory('../extensions/sources/${Platform.isWindows ? 'byedpi' : 'zapret'}');
  final socket = Platform.environment['SORA_CORE_SOCKET'];
  final isolated = Platform.isLinux && socket != null && socket.startsWith('/tmp/sora-ext-bypass-');
  late Directory fixture;
  late String tool, publicKey;
  late Directory dir;
  late ExtensionStore store;
  late ExtPackage pkg;
  var ownedBySora = false;
  Future<void> command(String executable, List<String> args, {String? workingDirectory}) async {
    final result = await Process.run(executable, args, workingDirectory: workingDirectory);
    expect(result.exitCode, 0, reason: '${args.first}: ${result.stderr}');
  }

  Future<ExtPackage> signed({
    String? id,
    String? version,
    Map<String, dynamic>? descriptor,
    Directory? sourceOverride,
    String? outputFile,
  }) async {
    final root = await Directory('${fixture.path}/src-${DateTime.now().microsecondsSinceEpoch}').create();
    final input = sourceOverride ?? source;
    for (final entity in input.listSync(recursive: true, followLinks: false).whereType<File>()) {
      final relative = entity.path.substring(input.path.length + 1);
      final target = File('${root.path}/$relative');
      await target.parent.create(recursive: true);
      await entity.copy(target.path);
    }
    final file = File('${root.path}/sora-extension.json');
    final manifest = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    (manifest['author'] as Map<String, dynamic>)['public_key'] = publicKey;
    if (id != null) manifest['id'] = id;
    if (version != null) manifest['version'] = version;
    await file.writeAsString(jsonEncode(manifest));
    if (descriptor != null) await File('${root.path}/hook.json').writeAsString(jsonEncode(descriptor));
    final output = outputFile ?? '${root.path}.soraext';
    await command(tool, ['pack', root.path, '-o', output]);
    await command(tool, ['sign', '--key', '${fixture.path}/temporary-author.key', output]);
    return ExtPackage.open(await File(output).readAsBytes());
  }

  Future<void> install(ExtPackage value) async {
    await store.install(value, source: 'catalog', granted: value.manifest.permissions, authorKeyPin: publicKey);
  }

  setUpAll(() async {
    await (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'packages/material_symbols_icons/MaterialSymbolsRounded',
    )..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'))).load();
    fixture = await Directory.systemTemp.createTemp('sora-bypass-signed-');
    tool = '${fixture.path}/sora-ext${Platform.isWindows ? '.exe' : ''}';
    await command('go', ['build', '-o', tool, './cmd/sora-ext'], workingDirectory: '../tools/sora-ext');
    await command(tool, ['keygen', '-o', '${fixture.path}/temporary-author']);
    publicKey = (await File('${fixture.path}/temporary-author.pub').readAsLines()).last.trim();
    pkg = await signed();
  });
  tearDownAll(() => fixture.delete(recursive: true));
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    ownedBySora = false;
    dir = await Directory.systemTemp.createTemp('sora-bypass-store-');
    store = ExtensionStore(dir: dir.path);
    await store.load();
  });
  tearDown(() async {
    if (!ownedBySora) store.dispose();
    await dir.delete(recursive: true);
  });

  test('release candidate packages and signed catalog keep version and platform boundaries', () async {
    final team = '${fixture.path}/temporary-team';
    await command(tool, ['keygen', '-o', team]);
    final teamKey = (await File('$team.pub').readAsLines()).last.trim();
    final rows = <Map<String, dynamic>>[];
    final sources = [
      ('../extensions/sources/zapret', ['linux', 'windows']),
      ('../extensions/sources/byedpi', ['windows']),
      ('../examples/hello-panel', ['linux', 'windows']),
    ];
    for (var i = 0; i < sources.length; i++) {
      final (path, platforms) = sources[i];
      final output = '${fixture.path}/candidate-$i.soraext';
      final candidate = await signed(sourceOverride: Directory(path), outputFile: output);
      await candidate.verify(authorKeyLine: publicKey);
      await expectLater(candidate.verify(authorKeyLine: teamKey), throwsA(isA<PackageError>()));
      await command(tool, ['publish', '--ack-dangerous', output]);
      final bytes = await File(output).readAsBytes();
      final manifest = candidate.manifest;
      rows.add({
        'id': manifest.id,
        'name': manifest.name,
        'version': manifest.version,
        'description': manifest.description,
        'author': manifest.author.name,
        'author_identity': manifest.author.identity,
        'author_key': publicKey,
        'permissions': manifest.permissions,
        'capabilities': manifest.capabilities,
        'min_app_version': manifest.minAppVersion,
        'platforms': platforms,
        'download_url': 'https://example.invalid/${manifest.id}.soraext',
        'sha256': crypto.sha256.convert(bytes).toString(),
        'size': bytes.length,
      });
      if (platforms.contains(Platform.operatingSystem)) {
        await install(candidate);
        expect(store.get(manifest.id), isNotNull);
        if (manifest.networkHookEntry != null) {
          expect(store.bypassProfiles.single.extensionId, manifest.id);
        }
        await store.uninstall(manifest.id);
      } else {
        await expectLater(install(candidate), throwsA(isA<ExtAssetError>()));
        expect(store.installed, isEmpty);
      }
    }
    final catalogFile = File('${fixture.path}/candidate-catalog.json');
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'catalog_version': 1,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'max_age': 3600,
          'extensions': rows,
        }),
      ),
    );
    await catalogFile.writeAsBytes(bytes);
    await command(tool, ['sign-file', '--key', '$team.key', '--role', 'catalog.json', catalogFile.path]);
    final sig = await File('${catalogFile.path}.minisig').readAsString();
    await verifyPayload(teamKey, sig, 'catalog.json', bytes);
    await expectLater(verifyPayload(teamKey, sig, 'revocations.json', bytes), throwsA(isA<SignatureError>()));
    final changed = Uint8List.fromList(bytes)..[0] ^= 1;
    await expectLater(verifyPayload(teamKey, sig, 'catalog.json', changed), throwsA(isA<SignatureError>()));
    await expectLater(verifyCatalogSignature(sig, bytes), throwsA(isA<SignatureError>()));

    final catalog = ExtensionCatalog.parse(bytes);
    expect(catalog.entries.map((e) => e.id).toSet(), {'org.sora.zapret', 'org.sora.byedpi', 'org.sora.hello-panel'});
    for (final entry in catalog.entries) {
      expect(entry.requiresNewerApp('1.1.2'), isTrue, reason: entry.id);
      expect(entry.requiresNewerApp('1.1.3'), isFalse, reason: entry.id);
      expect(entry.supportsPlatform('windows'), isTrue, reason: entry.id);
      expect(entry.supportsPlatform('linux'), entry.id != 'org.sora.byedpi', reason: entry.id);
      expect(entry.supportsPlatform('android'), isFalse, reason: entry.id);
    }
    await store.catalogCache.store(bytes);
    expect(
      (await store.catalogCache.load())!.catalog.entries.map((e) => e.id).toSet(),
      catalog.entries.map((e) => e.id).toSet(),
    );
  });

  test('declared installed backend only; immutable descriptors and copied strategies', () {
    for (final backend in ['tpws', 'byedpi']) {
      final descriptor = ExtensionBypass.parse(
        jsonEncode({
          'hook_version': 2,
          'backend': backend,
          'profiles': {
            'plain': {
              'splitPos': ['1'],
            },
          },
        }),
      );
      expect(descriptor.supports('linux'), backend == 'tpws');
      expect(descriptor.supports('windows'), backend == 'byedpi');
      expect(descriptor.supports('android'), false);
      expect(descriptor.supports('macos'), false);
      descriptor.select({'profile': 'plain'}).splitPos.clear();
      expect(descriptor.select({'profile': 'plain'}).splitPos, ['1']);
      expect(() => descriptor.profiles.clear(), throwsUnsupportedError);
      expect(() => descriptor.profiles['plain']!.splitPos.clear(), throwsUnsupportedError);
      expect(() => descriptor.select({'profile': 'missing'}), throwsFormatException);
    }
  });
  test('paths, flags, old contracts, unknown protobuf fields and excessive profiles reject', () {
    final valid = <String, dynamic>{
      'hook_version': 2,
      'backend': 'tpws',
      'profiles': {
        'plain': {
          'splitPos': ['1'],
        },
      },
    };
    for (final doc in [
      {...valid, 'hook_version': 1},
      {...valid, 'backend': 'winws'},
      {...valid, 'path': '/bin/sh'},
      {
        ...valid,
        'args': ['--anything'],
      },
      {...valid, 'profiles': <String, dynamic>{}},
      {
        ...valid,
        'profiles': {for (var i = 0; i < 17; i++) '$i': <String, dynamic>{}},
      },
      {
        ...valid,
        'profiles': {' ': <String, dynamic>{}},
      },
      {
        ...valid,
        'profiles': {'x': 'not a strategy'},
      },
      {
        ...valid,
        'profiles': {
          'x': {'nativePath': '/bin/sh'},
        },
      },
      {
        ...valid,
        'profiles': {
          'x': {'splitPos': 1},
        },
      },
    ]) {
      expect(() => ExtensionBypass.parse(jsonEncode(doc)), throwsA(isA<FormatException>()), reason: '$doc');
    }
  });
  test('CLI signed source, author pin, settings update and invalid write preserve state', () async {
    await install(pkg);
    expect(store.bypassProfiles.single.extensionId, pkg.manifest.id);
    expect(store.bypassProfiles.single.strategy.splitPos, ['1', if (Platform.isLinux) 'midsld']);
    final selected = store.bypassProfiles.single.choiceId;
    await store.setSettings(pkg.manifest.id, {'profile': 'HTTP'});
    expect(store.bypassProfile(selected)!.strategy.hostCase, true);
    final file = File('${dir.path}/${pkg.manifest.id}.settings.json');
    final before = await file.readAsBytes();
    await expectLater(store.setSettings(pkg.manifest.id, {'profile': 'missing'}), throwsA(isA<ExtStoreError>()));
    expect(await file.readAsBytes(), before);
    expect(store.bypassProfile(selected)!.strategy.hostCase, true);
    await store.setEnabled(pkg.manifest.id, false);
    expect(store.bypassProfiles, isEmpty);
    await store.setEnabled(pkg.manifest.id, true);
    expect(store.bypassProfile(selected)!.strategy.hostCase, true);
    await store.uninstall(pkg.manifest.id);
    expect(store.bypassProfiles, isEmpty);
  });
  test('signature, platform and permission gates reject before extraction', () async {
    await expectLater(
      store.install(pkg, source: 'catalog', granted: [], authorKeyPin: publicKey),
      throwsA(isA<ExtStoreError>()),
    );
    final damaged = Map<String, Uint8List>.from(pkg.files);
    damaged['hook.json'] = utf8.encode('{}');
    await expectLater(install(ExtPackage.fromFiles(damaged, pkg.manifest)), throwsA(isA<PackageError>()));
    final descriptor = {
      'hook_version': 2,
      'backend': Platform.isWindows ? 'tpws' : 'byedpi',
      'profiles': {
        'TCP+TLS': {
          'splitPos': ['1'],
        },
      },
    };
    await expectLater(install(await signed(descriptor: descriptor)), throwsA(isA<ExtAssetError>()));
    expect(store.installed, isEmpty);
    expect(dir.listSync().whereType<Directory>(), isEmpty);
  });
  test('conflicts need a winner; missing grants never apply', () async {
    await install(pkg);
    final other = await signed(id: 'org.sora.profile-other');
    await install(other);
    expect(store.bypassProfiles, isEmpty);
    final conflict = findConflicts(store.installed).single;
    await store.setConflictWinner(conflict.key, other.manifest.id);
    expect(store.bypassProfiles.single.extensionId, other.manifest.id);
    await store.setEnabled(other.manifest.id, false);
    expect(store.bypassProfiles.single.extensionId, pkg.manifest.id);
    final registry = File('${dir.path}/installed.json');
    final data = jsonDecode(await registry.readAsString()) as Map<String, dynamic>;
    (data[pkg.manifest.id] as Map<String, dynamic>)['granted'] = <String>[];
    await registry.writeAsString(jsonEncode(data));
    final reloaded = ExtensionStore(dir: dir.path);
    addTearDown(reloaded.dispose);
    await reloaded.load();
    expect(reloaded.bypassProfiles, isEmpty);
  });
  test('invalid asset contender still requires the permission-based conflict decision', () async {
    await install(pkg);
    final other = await signed(id: 'org.sora.profile-other');
    await install(other);
    await File('${dir.path}/${other.manifest.id}@${other.manifest.version}/hook.json').writeAsString('{}');
    final reloaded = ExtensionStore(dir: dir.path);
    addTearDown(reloaded.dispose);
    await reloaded.load();
    expect(reloaded.runtimeErrors, contains(other.manifest.id));
    expect(reloaded.bypassProfiles, isEmpty);
  });

  test('source profile in plan; manual settings stay intact; disabled choice cannot fall back', () async {
    await install(pkg);
    final settings = await Settings.load();
    settings.splitPos = ['3'];
    final sora = Sora(settings, extensions: store);
    ownedBySora = true;
    addTearDown(sora.dispose);
    expect(sora.selected, isNot(store.bypassProfiles.single.choiceId));
    await sora.select(store.bypassProfiles.single.choiceId);
    final strategy = sora.currentPlan.outbounds.single.bypass;
    expect(strategy.splitPos, ['1', if (Platform.isLinux) 'midsld']);
    expect(settings.splitPos, ['3']);
    strategy.splitPos.clear();
    expect(sora.currentPlan.outbounds.single.bypass.splitPos, isNotEmpty);
    await store.setEnabled(pkg.manifest.id, false);
    expect(sora.selected, startsWith(extensionBypassPrefix));
    expect(sora.currentPlan.outbounds, isEmpty);
    expect(settings.splitPos, ['3']);
  });

  test('an explicit proxy chain takes precedence over a previously selected extension mode', () async {
    await install(pkg);
    final settings = await Settings.load();
    settings.tunnel = 'tun';
    final servers = [
      for (final id in ['a', 'b']) OutboundSpec(id: id, protocol: 'socks5'),
    ];
    final selected = store.bypassProfiles.single;
    final ordinary = buildPlan(servers: servers, choice: 'auto', settings: settings, chain: ['a', 'b']);
    final extension = buildPlan(
      servers: servers,
      choice: selected.choiceId,
      settings: settings,
      chain: ['a', 'b'],
      bypassProfile: selected,
    );
    expect(extension, ordinary);
    expect(extension.chain, ['a', 'b']);
    expect(extension.outbounds.every((entry) => entry.protocol != 'bypass'), true);
  });

  for (final brightness in Brightness.values) {
    testWidgets('profile detail and mode picker at 320px/1.6 ${brightness.name}', (tester) async {
      late Sora sora;
      await tester.runAsync(() async {
        await install(pkg);
        final settings = await Settings.load();
        settings.animations = false;
        sora = Sora(settings, extensions: store)..serverlessAvailable = true;
        ownedBySora = true;
      });
      addTearDown(sora.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      addTearDown(tester.view.reset);
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: SoraScope(
            sora: sora,
            child: ExtScope(
              store: store,
              child: MotionScope(
                enabled: false,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: buildTheme(brightness),
                  locale: const Locale('en'),
                  localizationsDelegates: S.localizationsDelegates,
                  supportedLocales: S.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.6)),
                    child: child!,
                  ),
                  home: ExtensionDetailScreen(installed: store.get(pkg.manifest.id)),
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('DPI'), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('DPI'), findsOneWidget);
      expect(find.text('TCP+TLS'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(sora.strings.trayConnect),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text(sora.strings.trayConnect), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (Platform.environment['SORA_SHOTS'] != null) {
        final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final target = Directory('../artifacts/ui-feedback/bypass');
          await target.create(recursive: true);
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('${target.path}/detail-${brightness.name}.png').writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      sora.settings.server = '$extensionBypassPrefix${List.filled(32, 'long').join('.')}';
      await tester.pumpWidget(
        SoraScope(
          sora: sora,
          child: MaterialApp(
            theme: buildTheme(brightness),
            locale: const Locale('en'),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: const Scaffold(body: ModeButton()),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('mode-button')));
      await tester.pumpAndSettle();
      expect(find.text(pkg.manifest.name), findsOneWidget);
      await tester.tap(find.text(pkg.manifest.name));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
      }
      expect(sora.selected, store.bypassProfiles.single.choiceId);
      expect(sora.settings.tunnel, 'tun');
      expect(sora.phase, Phase.offline);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('Windows signed Winws needs native capability and fresh host consent per author/version', () async {
    final descriptor =
        jsonDecode(File('../extensions/sources/zapret/hook.json').readAsStringSync()) as Map<String, dynamic>;
    final winws = await signed(id: 'org.sora.winws-fixture', descriptor: descriptor);
    await install(winws);
    final settings = await Settings.load();
    final sora = Sora(settings, extensions: store);
    ownedBySora = true;
    addTearDown(sora.dispose);
    final choice = store.bypassProfiles.single.choiceId;
    expect(store.bypassProfiles.single.systemWide, true);
    final before = sora.selected;
    await sora.select(choice);
    expect(sora.selected, before);
    final key = sora.systemFilterConsentKey(choice)!;
    expect(sora.approveSystemFilter(choice, key), false);
    sora.coreCapabilities.add('serverless-winws');
    expect(sora.approveSystemFilter(choice, 'wrong author/version'), false);
    expect(sora.approveSystemFilter(choice, key), true);
    await sora.select(choice);
    expect(sora.currentPlan.outbounds.single.protocol, 'winws');
    final updated = await signed(id: winws.manifest.id, version: '1.0.1', descriptor: descriptor);
    await install(updated);
    expect(sora.needsSystemFilterConsent(choice), true);
    expect(sora.approveSystemFilter(choice, key), false);
    final reloaded = ExtensionStore(dir: dir.path);
    await reloaded.load();
    final restarted = Sora(settings, extensions: reloaded)..coreCapabilities.add('serverless-winws');
    addTearDown(restarted.dispose);
    expect(restarted.needsSystemFilterConsent(choice), true);
  }, skip: !Platform.isWindows ? 'requires native Windows app platform; no driver is loaded' : false);

  testWidgets('Windows scope info and Escape do not consent; explicit selection does', (tester) async {
    late Sora sora;
    late String choice;
    await tester.runAsync(() async {
      final descriptor =
          jsonDecode(File('../extensions/sources/zapret/hook.json').readAsStringSync()) as Map<String, dynamic>;
      await install(await signed(id: 'org.sora.winws-fixture', descriptor: descriptor));
      final settings = await Settings.load();
      settings.animations = false;
      settings.language = 'en';
      sora = Sora(settings, extensions: store)..coreCapabilities.add('serverless-winws');
      ownedBySora = true;
      choice = store.bypassProfiles.single.choiceId;
    });
    addTearDown(sora.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      SoraScope(
        sora: sora,
        child: MotionScope(
          enabled: false,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            locale: const Locale('en'),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: const Scaffold(body: ModeButton()),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('mode-button')));
    await tester.pumpAndSettle();
    final name = store.get('org.sora.winws-fixture')!.manifest.name;
    await tester.tap(find.byKey(ValueKey('info-$name')));
    await tester.pumpAndSettle();
    expect(find.text(sora.strings.winwsScopeWarning), findsOneWidget);
    expect(sora.needsSystemFilterConsent(choice), true);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('system-filter-consent')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(sora.selected, isNot(choice));
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(sora.strings.chooseEngine(name)));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(sora.selected, choice);
    expect(sora.needsSystemFilterConsent(choice), false);
    expect(sora.currentPlan.outbounds.single.protocol, 'winws');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }, skip: !Platform.isWindows);

  group('actual private gRPC transport', () {
    late _Core core;
    late Server server;
    late Sora sora;
    late Future<void> running;
    Future<void> until(bool Function() ready, String stage) async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!ready()) {
        if (DateTime.now().isAfter(deadline)) {
          fail('RPC state timed out: $stage phase=${sora.phase} calls=${core.plans.length} failure=${sora.failure}');
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    setUp(() async {
      if (!isolated) return;
      core = _Core();
      server = Server.create(services: [core, _Custom()]);
      await server.serve(address: InternetAddress(socket, type: InternetAddressType.unix), port: 0);
      await install(pkg);
      final settings = await Settings.load();
      settings.splitPos = ['3'];
      sora = Sora(settings, extensions: store);
      ownedBySora = true;
      running = sora.run();
      await until(() => sora.serverlessAvailable, 'startup');
    });
    tearDown(() async {
      if (!isolated) return;
      if (core.gate case final gate? when !gate.isCompleted) gate.complete();
      sora.dispose();
      await running.timeout(const Duration(seconds: 10));
      await server.shutdown();
      await core.close();
      if (await File(socket).exists()) await File(socket).delete();
    });
    test('disabling an in-flight profile waits for connection and disconnects without fallback', () async {
      core.gate = Completer<void>();
      await sora.select(store.bypassProfiles.single.choiceId);
      final connecting = sora.connect();
      await until(() => core.plans.length == 1, 'pending connect');
      await store.setEnabled(pkg.manifest.id, false);
      expect(core.disconnects, 0);
      core.gate!.complete();
      await connecting;
      await until(() => core.disconnects == 1 && sora.phase == Phase.off, 'pending disable');
      expect(core.plans.length, 1);
      expect(sora.selected, startsWith(extensionBypassPrefix));
      expect(sora.currentPlan.outbounds, isEmpty);
    });

    test('explicit connect, profile update, failed replacement and disable use actual authenticated RPC', () async {
      expect(core.plans, isEmpty);
      await sora.select(store.bypassProfiles.single.choiceId);
      await sora.connect();
      expect(sora.phase, Phase.connected);
      expect(core.plans.single.outbounds.single.bypass.splitPos, ['1', 'midsld']);
      await until(() => core.events.hasListener, 'initial watch');
      expect(sora.settings.splitPos, ['3']);
      await store.setSettings(pkg.manifest.id, {'profile': 'HTTP'});
      await until(() => core.plans.length == 2 && sora.phase == Phase.connected, 'profile update');
      expect(core.plans.last.outbounds.single.bypass.hostCase, true);
      await until(() => core.events.hasListener, 'replacement watch');
      core.reject = true;
      await store.setSettings(pkg.manifest.id, {'profile': 'TLS'});
      await until(() => core.plans.length == 3 && sora.failure != null && sora.phase == Phase.connected, 'rejection');
      expect(sora.phase, Phase.connected);
      expect(core.disconnects, 0);
      await store.setEnabled(pkg.manifest.id, false);
      await until(() => core.disconnects == 1 && sora.phase == Phase.off, 'disable');
      final count = core.plans.length;
      await sora.connect();
      expect(core.plans.length, count);
      expect(sora.selected, startsWith(extensionBypassPrefix));
      expect(sora.settings.splitPos, ['3']);
    });
  }, skip: isolated ? false : 'use SORA_CORE_SOCKET=/tmp/sora-ext-bypass-unique.sock; no owner core');
}
