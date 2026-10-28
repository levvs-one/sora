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
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
import 'package:sora/src/updates.dart' show appVersion;
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/ui/extensions/detail_screen.dart';
import 'package:sora/src/ui/extensions/permissions_sheet.dart';
import 'package:sora/src/ui/extensions/store_screen.dart';
import 'package:sora/src/ui/extensions/widgets.dart';
import 'package:sora/src/ui/kit.dart';
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
  Future<GetAboutResponse> getAbout(ServiceCall call, GetAboutRequest request) async => GetAboutResponse(
    about: About(contract: apiVersion.deepCopy()..capabilities.addAll(['serverless', 'serverless-bydpi'])),
  );
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
    final packages = <String, Uint8List>{};
    final sources = [
      ('../extensions/sources/zapret', ['linux', 'windows']),
      ('../extensions/sources/byedpi', ['linux', 'windows']),
      ('../examples/hello-panel', ['linux', 'windows']),
    ];
    for (var i = 0; i < sources.length; i++) {
      final (path, platforms) = sources[i];
      final output = '${fixture.path}/candidate-$i.soraext';
      final candidate = await signed(sourceOverride: Directory(path), outputFile: output);
      await candidate.verify(authorKeyLine: publicKey);
      await expectLater(candidate.verify(authorKeyLine: teamKey), throwsA(isA<PackageError>()));
      final published = await Process.run(tool, ['publish', '--ack-dangerous', output]);
      expect(published.exitCode, 0, reason: '${published.stderr}');
      final text = published.stdout as String;
      final start = text.lastIndexOf('\n  {');
      expect(start, greaterThanOrEqualTo(0), reason: 'publish must output a catalog entry');
      final entry = jsonDecode(text.substring(start)) as Map<String, dynamic>;
      final bytes = await File(output).readAsBytes();
      final manifest = candidate.manifest;
      expect(entry['capabilities'], manifest.capabilities, reason: manifest.id);
      expect(entry['permissions'], manifest.permissions, reason: manifest.id);
      expect(entry['sha256'], crypto.sha256.convert(bytes).toString(), reason: manifest.id);
      expect(entry['size'], bytes.length, reason: manifest.id);
      expect(text, contains('platforms'), reason: 'the publisher must review supported platforms');
      rows.add({...entry, 'platforms': platforms, 'download_url': 'https://example.invalid/${manifest.id}.soraext'});
      packages[manifest.id] = bytes;
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
      expect(entry.supportsPlatform('linux'), isTrue, reason: entry.id);
      expect(entry.supportsPlatform('android'), isFalse, reason: entry.id);
      final data = packages[entry.id]!;
      final manifest = ExtPackage.open(data).manifest;
      expect(manifest.id, entry.id);
      expect(manifest.version, entry.version, reason: entry.id);
      expect(manifest.minAppVersion, entry.minAppVersion, reason: entry.id);
      expect(manifest.permissions, unorderedEquals(entry.permissions), reason: entry.id);
      expect(manifest.capabilities, unorderedEquals(entry.capabilities), reason: entry.id);
      final damaged = Uint8List.fromList(data)..[0] ^= 1;
      await expectLater(
        store.installBytes(
          damaged,
          source: 'catalog',
          granted: entry.permissions,
          expectedSha256: entry.sha256,
          authorKeyPin: entry.authorKey,
        ),
        throwsA(isA<ExtStoreError>()),
      );
      await expectLater(
        store.installBytes(
          data,
          source: 'catalog',
          granted: entry.permissions,
          expectedSha256: entry.sha256,
          authorKeyPin: teamKey,
        ),
        throwsA(isA<ExtStoreError>()),
      );
      await store.installBytes(
        data,
        source: 'catalog',
        granted: entry.permissions,
        expectedSha256: entry.sha256,
        authorKeyPin: entry.authorKey,
      );
      expect(store.isEnabled(entry.id), isTrue, reason: entry.id);
    }
    expect(store.installed.map((entry) => entry.id).toSet(), packages.keys.toSet());
    final conflict = findConflicts(store.installed).single;
    expect(conflict.kind, ExtConflictKind.netHooks);
    expect(conflict.extensionIds, ['org.sora.byedpi', 'org.sora.zapret']);
    expect(store.bypassProfiles, isEmpty);
    await store.setConflictWinner(conflict.key, 'org.sora.byedpi');
    expect(store.bypassProfiles.single.extensionId, 'org.sora.byedpi');
    final reloaded = ExtensionStore(dir: dir.path);
    addTearDown(reloaded.dispose);
    await reloaded.load();
    expect(reloaded.installed.map((entry) => entry.id).toSet(), packages.keys.toSet());
    expect(reloaded.bypassProfiles.single.extensionId, 'org.sora.byedpi');
    await reloaded.setEnabled('org.sora.byedpi', false);
    expect(reloaded.bypassProfiles.single.extensionId, 'org.sora.zapret');
    await store.catalogCache.store(bytes);
    expect(
      (await store.catalogCache.load())!.catalog.entries.map((e) => e.id).toSet(),
      catalog.entries.map((e) => e.id).toSet(),
    );
  });

  testWidgets('catalog UI enforces candidate host compatibility and explicit grants', (tester) async {
    late Sora sora;
    late bool incompatibleHost;
    late String requiredVersion;
    final downloads = <String, Uint8List>{};
    final ids = <String>[];
    await tester.runAsync(() async {
      final team = '${fixture.path}/ui-team';
      await command(tool, ['keygen', '-o', team]);
      final teamKey = (await File('$team.pub').readAsLines()).last.trim();
      final rows = <Map<String, dynamic>>[];
      final paths = ['../extensions/sources/zapret', '../extensions/sources/byedpi', '../examples/hello-panel'];
      for (var i = 0; i < paths.length; i++) {
        final output = '${fixture.path}/ui-candidate-$i.soraext';
        final candidate = await signed(sourceOverride: Directory(paths[i]), outputFile: output);
        final result = await Process.run(tool, ['publish', '--ack-dangerous', output]);
        expect(result.exitCode, 0, reason: '${result.stderr}');
        final published = result.stdout as String;
        final start = published.lastIndexOf('\n  {');
        expect(start, greaterThanOrEqualTo(0));
        final row = jsonDecode(published.substring(start)) as Map<String, dynamic>;
        final id = candidate.manifest.id;
        final url = 'https://example.invalid/$id.soraext';
        ids.add(id);
        downloads[url] = await File(output).readAsBytes();
        rows.add({
          ...row,
          'platforms': ['linux', 'windows'],
          'download_url': url,
        });
      }
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
      final file = File('${fixture.path}/ui-catalog.json');
      await file.writeAsBytes(bytes);
      await command(tool, ['sign-file', '--key', '$team.key', '--role', 'catalog.json', file.path]);
      final signature = await File('${file.path}.minisig').readAsString();
      await verifyPayload(teamKey, signature, 'catalog.json', bytes);
      final catalog = ExtensionCatalog.parse(bytes);
      incompatibleHost = catalog.entries.every((entry) => entry.requiresNewerApp(appVersion));
      requiredVersion = catalog.entries.first.minAppVersion;
      // The test key is not the production root. Seed the already-verified
      // local cache and make the simulated network refresh fail closed.
      await store.catalogCache.store(bytes);
      sora = Sora(await Settings.load(), extensions: store);
      ownedBySora = true;
    });
    addTearDown(sora.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1100);
    addTearDown(tester.view.reset);
    final requested = <String>[];
    final client = MockClient((request) async {
      final bytes = downloads[request.url.toString()];
      if (bytes == null) return http.Response('', 503);
      requested.add(request.url.toString());
      return http.Response.bytes(bytes, 200);
    });
    addTearDown(client.close);
    await http.runWithClient(() async {
      await tester.pumpWidget(
        SoraScope(
          sora: sora,
          child: ExtScope(
            store: store,
            child: MotionScope(
              enabled: false,
              child: MaterialApp(
                theme: buildTheme(Brightness.light),
                locale: const Locale('en'),
                localizationsDelegates: S.localizationsDelegates,
                supportedLocales: S.supportedLocales,
                home: const ExtensionsScreen(),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 1000 && find.byType(ExtensionCard).evaluate().length < ids.length; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byType(ExtensionCard), findsNWidgets(3));
      if (incompatibleHost) {
        expect(find.text('Install'), findsNothing);
        expect(find.byType(InfoButton), findsNWidgets(3));
        await tester.tap(find.byType(InfoButton).first);
        await tester.pumpAndSettle();
        expect(find.textContaining(requiredVersion), findsWidgets);
        expect(requested, isEmpty);
        expect(store.installed, isEmpty);
        await tester.pumpWidget(const SizedBox());
        return;
      }
      for (final id in ids) {
        final card = find.byKey(ValueKey(id));
        expect(card, findsOneWidget);
        await tester.ensureVisible(card);
        if (id == 'org.sora.zapret') {
          await tester.tap(find.descendant(of: card, matching: find.text('Zapret')));
          await tester.pumpAndSettle();
          expect(find.byType(ExtensionDetailScreen), findsOneWidget);
          expect(find.text('This permission does nothing in this version of Sora yet.'), findsNothing);
          Navigator.of(tester.element(find.byType(ExtensionDetailScreen))).pop();
          await tester.pumpAndSettle();
        }
        await tester.tap(find.descendant(of: card, matching: find.text('Install')));
        await tester.pump();
        for (var i = 0; i < 1000 && find.byType(InstallPermissionPrompt).evaluate().isEmpty; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump(const Duration(milliseconds: 20));
        }
        final prompt = find.byType(InstallPermissionPrompt);
        expect(prompt, findsOneWidget, reason: id);
        expect(tester.widget<InstallPermissionPrompt>(prompt).manifest.id, id);
        if (id != 'org.sora.hello-panel') {
          expect(
            find.descendant(
              of: prompt,
              matching: find.text('This permission does nothing in this version of Sora yet.'),
            ),
            findsNothing,
          );
          final confirm = find.descendant(of: prompt, matching: find.byType(PrimaryButton));
          expect(tester.widget<PrimaryButton>(confirm).onTap, isNull);
          await tester.tap(find.text('I understand these permissions are powerful'));
          await tester.pump();
          expect(tester.widget<PrimaryButton>(confirm).onTap, isNotNull);
        }
        await tester.tap(find.descendant(of: prompt, matching: find.text('Install')));
        for (var i = 0; i < 1000 && (store.get(id) == null || find.byType(Dialog).evaluate().isNotEmpty); i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(store.get(id), isNotNull, reason: id);
        expect(find.byType(Dialog), findsNothing, reason: id);
        await tester.pumpAndSettle();
      }
      expect(requested.length, 3);
      expect(store.installed.map((entry) => entry.id).toSet(), ids.toSet());
      final conflict = findConflicts(store.installed).single;
      expect(conflict.kind, ExtConflictKind.netHooks);
      expect(conflict.extensionIds, ['org.sora.byedpi', 'org.sora.zapret']);
      expect(store.bypassProfiles, isEmpty);
      await tester.tap(find.text('Installed'));
      await tester.pumpAndSettle();
      final conflictBanner = find.text('1 conflicts need your decision');
      for (var i = 0; i < 1000 && conflictBanner.evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(conflictBanner, findsOneWidget);
      await tester.tap(conflictBanner);
      await tester.pumpAndSettle();
      final conflictDialog = find.byType(Dialog);
      expect(conflictDialog, findsOneWidget);
      expect(find.text('This permission does nothing in this version of Sora yet.'), findsNothing);
      final confirm = find.descendant(of: conflictDialog, matching: find.byType(PrimaryButton));
      expect(tester.widget<PrimaryButton>(confirm).onTap, isNull);
      await tester.tap(find.descendant(of: conflictDialog, matching: find.text('ByeDPI')));
      await tester.pump();
      expect(tester.widget<PrimaryButton>(confirm).onTap, isNotNull);
      await tester.tap(find.descendant(of: conflictDialog, matching: find.text('Confirm')));
      for (
        var i = 0;
        i < 1000 &&
            (store.bypassProfiles.isEmpty ||
                conflictDialog.evaluate().isNotEmpty ||
                conflictBanner.evaluate().isNotEmpty);
        i++
      ) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(store.bypassProfiles.single.extensionId, 'org.sora.byedpi');
      expect(conflictDialog, findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('1 conflicts need your decision'), findsNothing);

      late ExtPackage generic;
      await tester.runAsync(() async {
        final genericSource = await Directory('${fixture.path}/generic-hook').create();
        final manifest = jsonDecode(
          await File('../extensions/sources/zapret/sora-extension.json').readAsString(),
        ) as Map<String, dynamic>;
        manifest['id'] = 'org.sora.dormant';
        manifest['name'] = 'Dormant network';
        manifest['capabilities'] = <String>[];
        manifest.remove('network_hook');
        manifest.remove('settings_schema');
        await File('${genericSource.path}/sora-extension.json').writeAsString(jsonEncode(manifest));
        generic = await signed(sourceOverride: genericSource);
      });
      final screenContext = tester.element(find.byType(ExtensionsScreen));
      unawaited(
        showDialog<void>(
          context: screenContext,
          builder: (_) => InstallPermissionPrompt(manifest: generic.manifest, sideload: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('This permission does nothing in this version of Sora yet.'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Cancel')));
      await tester.pumpAndSettle();
      await tester.runAsync(() => install(generic));
      for (var i = 0; i < 1000 && conflictBanner.evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(conflictBanner, findsOneWidget);
      await tester.tap(conflictBanner);
      await tester.pumpAndSettle();
      final dormant = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Dormant network wins. This permission does nothing in this version of Sora yet.',
      );
      final active = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Zapret wins',
      );
      final inactiveNotice = find.text('This permission does nothing in this version of Sora yet.');
      expect(find.descendant(of: dormant, matching: inactiveNotice), findsOneWidget);
      expect(find.descendant(of: active, matching: inactiveNotice), findsNothing);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Cancel')));
      await tester.pumpAndSettle();
      final dormantCard = find.byKey(const ValueKey('org.sora.dormant'));
      await tester.ensureVisible(dormantCard);
      await tester.tap(dormantCard);
      await tester.pumpAndSettle();
      expect(find.text('This permission does nothing in this version of Sora yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }, () => client);
  }, timeout: const Timeout(Duration(minutes: 3)));

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

  Future<void> liveNetworkProfile(String backend) async {
    final env = Platform.environment;
    expect(Platform.isLinux, isTrue);
    final root = env['SORA_LIVE_BYPASS_ROOT'];
    final parentNet = env['SORA_PARENT_NETNS'];
    final parentUser = env['SORA_PARENT_USERNS'];
    expect(root, isNotNull);
    expect(parentNet, matches(RegExp(r'^net:\[\d+\]$')));
    expect(parentUser, matches(RegExp(r'^user:\[\d+\]$')));
    expect(await Link('/proc/self/ns/net').target(), isNot(parentNet));
    expect(await Link('/proc/self/ns/user').target(), isNot(parentUser));
    final status = await File('/proc/self/status').readAsLines();
    for (final key in ['CapInh:', 'CapPrm:', 'CapEff:', 'CapBnd:', 'CapAmb:']) {
      final line = status.singleWhere((line) => line.startsWith(key));
      expect(line.split(RegExp(r'\s+')).last, matches(RegExp(r'^0+$')), reason: key);
    }
    expect(await Directory(root!).resolveSymbolicLinks(), root);
    expect(root.split(Platform.pathSeparator).last, startsWith('sora-live-app-'));
    expect((await Directory(root).stat()).mode & 0x3f, 0);
    expect(env['TMPDIR'], root);
    Uri? peerHttpTarget;
    Uri? peerTlsTarget;
    List<int>? peerCertificate;
    if (backend == 'tpws') {
      final targetsFile = File('$root/targets.json');
      expect(FileSystemEntity.typeSync(targetsFile.path, followLinks: false), FileSystemEntityType.file);
      final targets = jsonDecode(await targetsFile.readAsString()) as Map<String, dynamic>;
      peerHttpTarget = Uri.parse(targets['HTTP'] as String);
      peerTlsTarget = Uri.parse(targets['HTTPS'] as String);
      for (final (target, scheme) in [(peerHttpTarget, 'http'), (peerTlsTarget, 'https')]) {
        expect(target.scheme, scheme);
        expect(target.host, '198.18.0.2');
        expect(target.port, inInclusiveRange(1, 65535));
      }
      final encodedCertificate = targets['Certificate'] as String;
      final certificateLines = RegExp(r'.{1,64}').allMatches(encodedCertificate).map((m) => m.group(0)).join('\n');
      peerCertificate = utf8.encode('-----BEGIN CERTIFICATE-----\n$certificateLines\n-----END CERTIFICATE-----\n');
    }
    for (final entry in {
      'HOME': 'home',
      'XDG_CONFIG_HOME': 'config',
      'XDG_CACHE_HOME': 'cache',
      'XDG_DATA_HOME': 'data',
      'XDG_RUNTIME_DIR': 'runtime',
    }.entries) {
      final path = '$root/${entry.value}';
      expect(env[entry.key], path, reason: entry.key);
      expect(await Directory(path).resolveSymbolicLinks(), path, reason: entry.key);
    }
    for (final key in [
      'DBUS_SESSION_BUS_ADDRESS',
      'DISPLAY',
      'WAYLAND_DISPLAY',
      'NOTIFY_SOCKET',
      'SSH_AUTH_SOCK',
      'SORA_DATA_DIR',
    ]) {
      expect(env.containsKey(key), isFalse, reason: key);
    }
    expect(socket, '$root/core.sock');
    expect(FileSystemEntity.typeSync(socket!, followLinks: false), FileSystemEntityType.notFound);
    final binary = '$root/sora-core';
    final engines = '$root/engines';
    expect(await File(binary).exists(), isTrue);
    expect(await File('$engines/$backend').exists(), isTrue);
    expect(await File('$engines/mihomo').exists(), isTrue);

    final log = StringBuffer();
    void capture(String chunk) {
      if (log.length < 8192) log.write(chunk);
    }

    final core = await Process.start(binary, [
      '-socket',
      socket,
      '-data-dir',
      '$root/coredata',
      '-engines-dir',
      engines,
      '-allow-file-keys',
    ]);
    core.stdout.transform(utf8.decoder).listen(capture);
    core.stderr.transform(utf8.decoder).listen(capture);
    addTearDown(() async {
      core.kill(ProcessSignal.sigterm);
      await core.exitCode.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          core.kill(ProcessSignal.sigkill);
          return core.exitCode;
        },
      );
    });

    Future<void> until(bool Function() condition, String stage) async {
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (!condition()) {
        if (DateTime.now().isAfter(deadline)) fail('$stage timed out; core log: $log');
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    }

    await until(() => FileSystemEntity.typeSync(socket, followLinks: false) != FileSystemEntityType.notFound, 'socket');
    final sourceName = backend == 'tpws' ? 'zapret' : 'byedpi';
    final package = await signed(sourceOverride: Directory('../extensions/sources/$sourceName'));
    await install(package);
    final settings = await Settings.load();
    settings.tunnel = 'proxy';
    settings.engine = 'mihomo';
    settings.blockAds = false;
    final destination = backend == 'tpws' ? '198.18.0.2' : '127.0.0.1';
    settings.rules = ['proxy $destination/32'];
    final sora = Sora(settings, extensions: store);
    ownedBySora = true;
    final running = sora.run();
    addTearDown(() async {
      try {
        if (sora.phase == Phase.connected || sora.phase == Phase.connecting || sora.phase == Phase.reconnecting) {
          await sora.disconnect().timeout(const Duration(seconds: 15));
        }
      } finally {
        sora.dispose();
        await running.timeout(const Duration(seconds: 10));
      }
    });
    await until(
      () => backend == 'byedpi' ? sora.coreCapabilities.contains('serverless-bydpi') : sora.serverlessAvailable,
      'core capability',
    );
    final choice = store.bypassProfiles.single.choiceId;
    await sora.select(choice);
    expect(sora.currentPlan.outbounds.single.protocol, backend == 'byedpi' ? 'byedpi' : 'bypass');
    expect(sora.currentPlan.networkControlAllowed, isFalse);
    expect(sora.currentPlan.outbounds.single.bypass.splitPos, backend == 'byedpi' ? ['1'] : ['1', 'midsld']);
    expect(sora.currentPlan.routes.single.destination, '$destination/32');
    expect(sora.currentPlan.routes.single.outboundId, Sora.bypassId);
    await sora.connect();
    expect(sora.phase, Phase.connected, reason: 'failure=${sora.failure}; core log: $log');
    final proxy = sora.localProxy;
    expect(proxy, isNotNull);
    expect(InternetAddress.tryParse(proxy!.host)?.isLoopback, isTrue);
    expect(proxy.port, greaterThan(0));

    late final Uri httpTarget, tlsTarget;
    late final String tlsName;
    late final List<int> trustedCertificate;
    if (backend == 'tpws') {
      httpTarget = peerHttpTarget!;
      tlsTarget = peerTlsTarget!;
      tlsName = 'example.com';
      trustedCertificate = peerCertificate!;
    } else {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        final body = await utf8.decoder.bind(request).join();
        request.response.write(body);
        await request.response.close();
      });
      final certificate = '$root/tls-cert.pem';
      final privateKey = '$root/tls-test-key.pem';
      final generated = await Process.run('openssl', [
        'req',
        '-x509',
        '-newkey',
        'rsa:2048',
        '-nodes',
        '-days',
        '1',
        '-subj',
        '/CN=localhost',
        '-addext',
        'subjectAltName=DNS:localhost',
        '-keyout',
        privateKey,
        '-out',
        certificate,
      ]);
      expect(generated.exitCode, 0, reason: 'temporary TLS certificate generation failed');
      final serverContext = SecurityContext()
        ..useCertificateChain(certificate)
        ..usePrivateKey(privateKey);
      final secureServer = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, serverContext);
      addTearDown(() => secureServer.close(force: true));
      secureServer.listen((request) async {
        final body = await utf8.decoder.bind(request).join();
        request.response.write(body);
        await request.response.close();
      });
      httpTarget = Uri(scheme: 'http', host: '127.0.0.1', port: server.port, path: '/');
      tlsTarget = Uri(scheme: 'https', host: '127.0.0.1', port: secureServer.port);
      tlsName = 'localhost';
      trustedCertificate = await File(certificate).readAsBytes();
    }

    final connection = await Socket.connect(proxy.host, proxy.port, timeout: const Duration(seconds: 10));
    addTearDown(connection.destroy);
    const payload = 'signed candidate through isolated core';
    connection.write(
      'POST ${httpTarget.replace(path: '/')} HTTP/1.1\r\n'
      'Host: ${httpTarget.authority}\r\n'
      'Content-Length: ${utf8.encode(payload).length}\r\n'
      'Connection: close\r\n\r\n$payload',
    );
    final response = await utf8.decoder.bind(connection).join().timeout(const Duration(seconds: 10));
    expect(response, startsWith('HTTP/1.1 200'), reason: 'backend=$backend; core log: $log');
    expect(response, contains(payload));

    Future<Socket> connectTunnel() async {
      final tunnel = await Socket.connect(proxy.host, proxy.port, timeout: const Duration(seconds: 10));
      addTearDown(tunnel.destroy);
      final bytes = <int>[];
      final ready = Completer<String>();
      late StreamSubscription<List<int>> subscription;
      subscription = tunnel.listen(
        (chunk) {
          bytes.addAll(chunk);
          final header = latin1.decode(bytes);
          if (header.contains('\r\n\r\n') && !ready.isCompleted) {
            subscription.pause();
            ready.complete(header);
          }
        },
        onError: (Object error, StackTrace stack) {
          if (!ready.isCompleted) ready.completeError(error, stack);
        },
      );
      addTearDown(subscription.cancel);
      tunnel.write(
        'CONNECT ${tlsTarget.authority} HTTP/1.1\r\n'
        'Host: ${tlsTarget.authority}\r\n\r\n',
      );
      final header = await ready.future.timeout(const Duration(seconds: 10));
      expect(header, startsWith('HTTP/1.1 200'));
      return tunnel;
    }

    final untrusted = await connectTunnel();
    await expectLater(
      SecureSocket.secure(
        untrusted,
        host: tlsName,
        context: SecurityContext(withTrustedRoots: false),
      ).timeout(const Duration(seconds: 10)),
      throwsA(isA<HandshakeException>()),
    );
    final trustedContext = SecurityContext(withTrustedRoots: false)..setTrustedCertificatesBytes(trustedCertificate);
    final secure = await SecureSocket.secure(
      await connectTunnel(),
      host: tlsName,
      context: trustedContext,
    ).timeout(const Duration(seconds: 10));
    addTearDown(secure.destroy);
    secure.write(
      'POST / HTTP/1.1\r\n'
      'Host: $tlsName\r\n'
      'Content-Length: ${utf8.encode(payload).length}\r\n'
      'Connection: close\r\n\r\n$payload',
    );
    final tlsResponse = await utf8.decoder.bind(secure).join().timeout(const Duration(seconds: 10));
    expect(tlsResponse, startsWith('HTTP/1.1 200'));
    expect(tlsResponse, contains(payload));

    await store.setEnabled(package.manifest.id, false);
    await until(() => sora.phase == Phase.off, 'disable disconnect');
    expect(sora.currentPlan.outbounds, isEmpty);
  }

  test(
    'signed ByeDPI profile connects the app to a real isolated core',
    () => liveNetworkProfile('byedpi'),
    skip: Platform.environment['SORA_LIVE_BYPASS'] == '1'
        ? false
        : 'requires a guarded private user and network namespace with real core and engines',
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'signed Zapret profile connects the app to a real isolated core',
    () => liveNetworkProfile('tpws'),
    skip: Platform.environment['SORA_LIVE_BYPASS'] == '1'
        ? false
        : 'requires guarded private user and peer network namespaces with real core and engines',
    timeout: const Timeout(Duration(minutes: 3)),
  );

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
    test('signed Linux ByeDPI requires capability before authenticated connect', () async {
      await store.uninstall(pkg.manifest.id);
      final byedpi = await signed(sourceOverride: Directory('../extensions/sources/byedpi'));
      await install(byedpi);
      expect(sora.coreCapabilities, contains('serverless-bydpi'));
      final choice = store.bypassProfiles.single.choiceId;
      await sora.select(choice);
      sora.coreCapabilities.remove('serverless-bydpi');
      await sora.connect();
      expect(core.plans, isEmpty);
      expect(sora.failure?.key, 'app.extension_asset');
      sora.coreCapabilities.add('serverless-bydpi');
      await sora.connect();
      expect(sora.phase, Phase.connected);
      expect(core.plans.single.outbounds.single.protocol, 'byedpi');
      expect(core.plans.single.outbounds.single.bypass.splitPos, ['1']);
      await store.setEnabled(byedpi.manifest.id, false);
      await until(() => core.disconnects == 1 && sora.phase == Phase.off, 'ByeDPI disable');
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
