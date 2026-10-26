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
  final published = File('../extensions/catalog.json').readAsBytesSync();
  final signature = File('../extensions/catalog.json.minisig').readAsBytesSync();
  Map<String, dynamic> document() => jsonDecode(utf8.decode(published)) as Map<String, dynamic>;
  Map<String, dynamic> entry(Map<String, dynamic> doc) => (doc['extensions'] as List).single as Map<String, dynamic>;
  CatalogEntry model(Map<String, dynamic> doc) => ExtensionCatalog.parse(utf8.encode(jsonEncode(doc))).entries.single;

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
  test('fresh signed catalog adds a listing without replacing the application', () async {
    final dir = await Directory.systemTemp.createTemp('sora-catalog-live-refresh-');
    addTearDown(() => dir.delete(recursive: true));
    final cache = CatalogCache(dir.path);
    // Only the old local cache is synthetic; fetched bytes and signature are
    // the actual team-signed published document, verified by production code.
    final old = document()..['extensions'] = <Object>[];
    await cache.store(utf8.encode(jsonEncode(old)));
    expect((await cache.load())!.catalog.entries, isEmpty);
    final requests = <String>[];
    final client = MockClient((request) async {
      requests.add(request.url.toString());
      return http.Response.bytes(request.url.path.endsWith('.minisig') ? signature : published, 200);
    });
    addTearDown(client.close);
    final refreshed = await cache.refresh(client: client);
    expect(refreshed.fromCache, false);
    expect(refreshed.catalog.entries.single.id, model(document()).id);
    expect(requests, [defaultCatalogUrl, '$defaultCatalogUrl.minisig']);
    expect((await cache.load())!.catalog.entries.single.id, refreshed.catalog.entries.single.id);
    final tampered = MockClient(
      (request) async =>
          http.Response.bytes(request.url.path.endsWith('.minisig') ? signature : utf8.encode('{}'), 200),
    );
    addTearDown(tampered.close);
    final fallback = await cache.refresh(client: tampered);
    expect(fallback.fromCache, true);
    expect(fallback.catalog.entries.single.id, refreshed.catalog.entries.single.id);
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
        final os = Platform.isWindows ? 'linux' : 'windows';
        if (checkVersion) {
          entry(doc)['min_app_version'] = '999.0.0';
        } else {
          entry(doc)['platforms'] = [os];
        }
        final expected = entry(doc)['name'] as String;
        if (installed) entry(doc)['version'] = '1.0.1';
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
          if (installed) expect(store.installed.single.version, '1.0.0');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }, () => client);
      });
    }
  }
}
