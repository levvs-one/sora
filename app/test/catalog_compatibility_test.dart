import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/ext/catalog.dart';
import 'package:sora/src/ext/package.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/updates.dart' show appVersion;
import 'package:sora/src/ui/extensions/detail_screen.dart';
import 'package:sora/src/ui/extensions/store_screen.dart';
import 'package:sora/src/ui/extensions/widgets.dart';
import 'package:sora/src/ui/kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'))).load();
    await (FontLoader(
      'packages/cupertino_icons/CupertinoIcons',
    )..addFont(rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'packages/material_symbols_icons/MaterialSymbolsRounded',
    )..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'))).load();
  });
  final catalogBytes = File('../extensions/catalog-1.1.6.json').readAsBytesSync();
  final signature = File('../extensions/catalog-1.1.6.json.minisig').readAsBytesSync();
  Map<String, dynamic> document() => jsonDecode(utf8.decode(catalogBytes)) as Map<String, dynamic>;
  Map<String, dynamic> entry(Map<String, dynamic> doc) => (doc['extensions'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((item) => item['id'] == 'org.sora.hello-panel');
  CatalogEntry model(Map<String, dynamic> doc) =>
      ExtensionCatalog.parse(utf8.encode(jsonEncode(doc))).find('org.sora.hello-panel')!;

  test('Hello remains addressable when the catalog has multiple entries', () {
    final doc = document();
    final hello = entry(doc);
    doc['extensions'] = [
      {...hello, 'id': 'org.fixture.before'},
      ...doc['extensions'] as List,
      {...hello, 'id': 'org.fixture.after'},
    ];
    expect(model(doc).id, 'org.sora.hello-panel');
    entry(doc)['platforms'] = ['linux'];
    expect(model(doc).supportsPlatform('windows'), false);
  });

  testWidgets('catalog displays and filters multiple entries independently', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 900);
    addTearDown(tester.view.reset);
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final doc = document();
    final hello = entry(doc);
    // This local cache is a UI fixture, not a signed publication.
    doc['extensions'] = [
      {...hello, 'id': 'org.fixture.before', 'name': 'Fixture before'},
      hello,
      {...hello, 'id': 'org.fixture.after', 'name': 'Fixture after'},
    ];
    late Directory dir;
    late Sora sora;
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('sora-catalog-multiple-ui-');
      final store = ExtensionStore(dir: dir.path);
      await store.load();
      await store.catalogCache.store(utf8.encode(jsonEncode(doc)));
      sora = Sora(await Settings.load(), extensions: store);
    });
    addTearDown(() async {
      sora.dispose();
      await dir.delete(recursive: true);
    });
    final client = MockClient((request) async => http.Response('', 503));
    addTearDown(client.close);
    await http.runWithClient(() async {
      await tester.pumpWidget(
        SoraScope(
          sora: sora,
          child: ExtScope(
            store: sora.extensions,
            child: MaterialApp(
              theme: buildTheme(Brightness.light),
              locale: const Locale('en'),
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              home: const ExtensionsScreen(),
            ),
          ),
        ),
      );
      for (var i = 0; i < 80 && find.byType(ExtensionCard).evaluate().length < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byType(ExtensionCard), findsNWidgets(3));
      await tester.enterText(find.byType(EditableText), 'fixture after');
      await tester.pump();
      expect(find.byKey(const ValueKey('org.fixture.after')), findsOneWidget);
      expect(find.byKey(const ValueKey('org.fixture.before')), findsNothing);
      expect(find.byKey(const ValueKey('org.sora.hello-panel')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }, () => client);
  });

  test('platform metadata is optional, typed and immutable; future OS entries stay visible', () {
    expect(model(document()).supportsPlatform('windows'), true);
    final doc = document();
    entry(doc)['platforms'] = ['linux'];
    final e = model(doc);
    expect(e.supportsPlatform('linux'), true);
    expect(e.supportsPlatform('windows'), false);
    expect(() => e.platforms.add('windows'), throwsUnsupportedError);
    entry(doc)['platforms'] = ['future-os'];
    expect(model(doc).supportsPlatform(Platform.operatingSystem), false);
    for (final value in [
      'linux',
      [1],
      ['Windows'],
      ['linux', 'linux'],
      ['../windows'],
      ['x' * 33],
      List.generate(17, (i) => 'os$i'),
    ]) {
      entry(doc)['platforms'] = value;
      expect(() => model(doc), throwsA(isA<CatalogError>()));
    }
  });
  test('version requirement handles known release versions and preserves dev behavior', () {
    final doc = document();
    entry(doc)['min_app_version'] = '1.2.0';
    final e = model(doc);
    expect(e.requiresNewerApp('1.1.2'), true);
    expect(e.requiresNewerApp('1.2.0'), false);
    expect(e.requiresNewerApp('2.0.0'), false);
    expect(e.requiresNewerApp('dev'), false);
    expect(e.requiresNewerApp('0.0.0.42'), false);
  });
  const candidateSources = [
    '../extensions/sources/zapret/sora-extension.json',
    '../extensions/sources/byedpi/sora-extension.json',
    '../examples/hello-panel/sora-extension.json',
  ];
  for (final path in candidateSources) {
    test('release candidate requirement excludes the published client: $path', () {
      final manifest = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final doc = document();
      entry(doc)['min_app_version'] = manifest['min_app_version'];
      final listing = model(doc);
      // A source never installs on the last host before its requirement and
      // always installs on the version it names.
      final required = manifest['min_app_version'] as String;
      final parts = required.split('.').map(int.parse).toList();
      final before = '${parts[0]}.${parts[1]}.${parts[2] - 1}';
      expect(listing.requiresNewerApp('1.1.2'), isTrue);
      expect(listing.requiresNewerApp(before), isTrue);
      expect(listing.requiresNewerApp(required), isFalse);
    });
  }
  test('release host version enables candidate sources and rejects a future requirement', () {
    expect(appVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    for (final path in candidateSources) {
      final manifest = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final doc = document();
      entry(doc)['min_app_version'] = manifest['min_app_version'];
      expect(model(doc).requiresNewerApp(appVersion), isFalse, reason: path);
    }
    final next = document();
    final major = int.parse(appVersion.split('.').first);
    entry(next)['min_app_version'] = '${major + 1}.0.0';
    expect(model(next).requiresNewerApp(appVersion), isTrue);
  }, skip: const bool.fromEnvironment('SORA_RELEASE_CHECK') ? false : 'requires a release version define');
  test('fresh signed catalog adds a listing without replacing the application', () async {
    final dir = await Directory.systemTemp.createTemp('sora-catalog-live-refresh-');
    addTearDown(() => dir.delete(recursive: true));
    final cache = CatalogCache(dir.path);
    // Only the old local cache is synthetic; fetched bytes and signature are
    // the repository team-signed catalog, verified by production code.
    final old = document()..['extensions'] = <Object>[];
    await cache.store(utf8.encode(jsonEncode(old)));
    expect((await cache.load())!.catalog.entries, isEmpty);
    final requests = <String>[];
    final client = MockClient((request) async {
      requests.add(request.url.toString());
      return http.Response.bytes(request.url.path.endsWith('.minisig') ? signature : catalogBytes, 200);
    });
    addTearDown(client.close);
    final refreshed = await cache.refresh(client: client);
    expect(refreshed.fromCache, false);
    final ids = ExtensionCatalog.parse(catalogBytes).entries.map((entry) => entry.id).toList();
    expect(refreshed.catalog.entries.map((entry) => entry.id).toList(), ids);
    expect(requests, [defaultCatalogUrl, '$defaultCatalogUrl.minisig']);
    expect((await cache.load())!.catalog.entries.map((entry) => entry.id).toList(), ids);
    final tampered = MockClient(
      (request) async =>
          http.Response.bytes(request.url.path.endsWith('.minisig') ? signature : utf8.encode('{}'), 200),
    );
    addTearDown(tampered.close);
    final fallback = await cache.refresh(client: tampered);
    expect(fallback.fromCache, true);
    expect(fallback.catalog.entries.map((entry) => entry.id).toList(), ids);
  });
  for (final checkVersion in [false, true]) {
    for (final installed in [false, true]) {
      testWidgets('incompatible listing stays visible; no download, version=$checkVersion installed=$installed', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 900);
        addTearDown(tester.view.reset);
        final capture = GlobalKey();
        SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
        late Directory dir;
        late ExtensionStore store;
        late Sora sora;
        final doc = document();
        doc['extensions'] = [entry(doc)];
        final currentVersion = (entry(doc)['version'] as String).split('.');
        final nextVersion = '${currentVersion[0]}.${currentVersion[1]}.${int.parse(currentVersion[2]) + 1}';
        final os = Platform.isWindows ? 'linux' : 'windows';
        if (checkVersion) {
          entry(doc)['min_app_version'] = '999.0.0';
        } else {
          entry(doc)['platforms'] = [os];
        }
        final expected = entry(doc)['name'] as String;
        if (installed) entry(doc)['version'] = nextVersion;
        final action = installed ? 'Update' : 'Install';
        await tester.runAsync(() async {
          dir = await Directory.systemTemp.createTemp('sora-catalog-compat-ui-');
          store = ExtensionStore(dir: dir.path);
          await store.load();
          if (installed) {
            final known = model(document());
            final bytes = await File('../extensions/packages/${known.downloadUrl.split('/').last}').readAsBytes();
            await store.install(
              ExtPackage.open(bytes),
              source: 'catalog',
              granted: known.permissions,
              authorKeyPin: known.authorKey,
            );
          }
          // As in the catalog UI tests, seed the trusted local cache. No changed
          // document is accepted by the team-signature network fetch.
          await store.catalogCache.store(utf8.encode(jsonEncode(doc)));
          sora = Sora(await Settings.load(), extensions: store);
        });
        addTearDown(() async {
          sora.dispose();
          await dir.delete(recursive: true);
        });
        final downloads = <String>[];
        final client = MockClient((request) async {
          downloads.add(request.url.toString());
          return http.Response('', 503);
        });
        addTearDown(client.close);
        await http.runWithClient(() async {
          await tester.pumpWidget(
            RepaintBoundary(
              key: capture,
              child: SoraScope(
                sora: sora,
                child: ExtScope(
                  store: store,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.6)),
                      child: child!,
                    ),
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
          for (var i = 0; i < 80 && find.byType(ExtensionCard).evaluate().isEmpty; i++) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
            await tester.pump(const Duration(milliseconds: 20));
          }
          expect(tester.widget<ExtensionCard>(find.byType(ExtensionCard)).title, expected);
          if (checkVersion && !model(doc).requiresNewerApp(appVersion)) {
            expect(find.byWidgetPredicate((w) => w is PillButton && w.label == action), findsOneWidget);
            await tester.pumpWidget(const SizedBox());
            return;
          }
          expect(find.byWidgetPredicate((w) => w is PillButton && w.label == action), findsNothing);
          expect(find.byType(InfoButton), findsOneWidget);
          await tester.tap(find.byType(InfoButton));
          await tester.pumpAndSettle();
          expect(find.text(action), findsOneWidget);
          expect(find.textContaining(checkVersion ? '999.0.0' : (os == 'linux' ? 'Linux' : 'Windows')), findsOneWidget);
          if (Platform.environment['SORA_SHOTS'] != null) {
            final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final target = Directory('../artifacts/ui-feedback/catalog-compatibility');
              await target.create(recursive: true);
              final image = await boundary.toImage(pixelRatio: 1);
              final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
              await File('${target.path}/info-$checkVersion-$installed.png').writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.tap(find.text('Close'));
          await tester.pumpAndSettle();
          if (installed) {
            await tester.tap(find.text('Installed'));
            await tester.pumpAndSettle();
            expect(find.byWidgetPredicate((w) => w is PrimaryButton && w.label == 'Update all'), findsNothing);
          }
          await tester.tap(find.byType(ExtensionCard));
          await tester.pumpAndSettle();
          final detail = tester.widget<ExtensionDetailScreen>(find.byType(ExtensionDetailScreen));
          expect(find.byWidgetPredicate((w) => w is PrimaryButton && w.label == action), findsNothing);
          await tester.runAsync(() async {
            await detail.onInstall!(detail.entry!);
          });
          await tester.pump();
          expect(find.byType(SnackBar), findsOneWidget);
          expect(downloads.any((url) => url.endsWith('.soraext')), false);
          expect(store.installed.length, installed ? 1 : 0);
          if (installed) expect(store.installed.single.version, currentVersion.join('.'));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }, () => client);
      });
    }
  }
}
