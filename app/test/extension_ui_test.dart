import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/main.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/ext/catalog.dart';
import 'package:sora/src/ext/conflicts.dart';
import 'package:sora/src/ext/package.dart';
import 'package:sora/src/ext/manifest.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/extensions/detail_screen.dart';
import 'package:sora/src/ui/extensions/conflicts_sheet.dart';
import 'package:sora/src/ui/extensions/permissions_sheet.dart';
import 'package:sora/src/ui/extensions/progress_window.dart';
import 'package:sora/src/ui/extensions/store_screen.dart';
import 'package:sora/src/ui/extensions/widgets.dart';
import 'package:sora/src/ui/kit.dart';
import 'package:sora/src/ui/shell.dart';

import 'ext_runtimes_test.dart' show seed;

final _catalogBytes = File('../extensions/catalog.json').readAsBytesSync();
final _entry = ExtensionCatalog.parse(_catalogBytes).entries.single;
final _packageBytes = File('../extensions/packages/${_entry.downloadUrl.split('/').last}').readAsBytesSync();

class _Routes extends NavigatorObserver {
  final dialogs = <Route<dynamic>>{};
  int maximum = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is DialogRoute) dialogs.add(route);
    if (dialogs.length > maximum) maximum = dialogs.length;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is DialogRoute<dynamic>) {
      unawaited(
        route.completed.then<void>((_) {
          dialogs.remove(route);
        }),
      );
    }
  }
}

class _DownloadClient extends http.BaseClient {
  _DownloadClient({this.url, this.knownTotal = true});
  final String? url;
  final bool knownTotal;
  final chunks = StreamController<List<int>>();
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    expect(request.url.toString(), url ?? _entry.downloadUrl);
    return http.StreamedResponse(chunks.stream, 200, contentLength: knownTotal ? _entry.size : null);
  }

  @override
  void close() {
    if (closed) return;
    closed = true;
    if (!chunks.isClosed) {
      chunks.addError(http.ClientException('cancelled'));
      unawaited(chunks.close());
    }
  }
}

Widget _app(Widget home, {ExtensionStore? store, NavigatorObserver? observer, bool motion = false}) {
  final app = MaterialApp(
    theme: buildTheme(Brightness.light),
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    navigatorObservers: [?observer],
    home: MotionScope(enabled: motion, child: home),
  );
  return store == null ? app : ExtScope(store: store, child: app);
}

Future<ExtensionStore> _store(WidgetTester tester, {bool installed = false}) async {
  final store = (await tester.runAsync(() async {
    final dir = await Directory.systemTemp.createTemp('sora-extui-');
    addTearDown(() => dir.delete(recursive: true));
    final store = ExtensionStore(dir: dir.path);
    await store.catalogCache.store(_catalogBytes);
    await store.load();
    if (installed) {
      await store.install(
        ExtPackage.open(_packageBytes),
        source: 'catalog',
        granted: _entry.permissions,
        authorKeyPin: _entry.authorKey,
      );
    }
    return store;
  }))!;
  return store;
}

Future<void> _io(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _ready(WidgetTester tester) async {
  for (var i = 0; i < 80 && find.byType(ExtensionCard).evaluate().isEmpty; i++) {
    await _io(tester);
  }
  expect(find.byType(ExtensionCard), findsWidgets);
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  testWidgets('progress updates percentage and stages on exactly one route', (tester) async {
    final observer = _Routes();
    await tester.pumpWidget(_app(const Scaffold(), observer: observer, motion: true));
    final window = ExtensionInstallDialog(
      tester.element(find.byType(Scaffold)),
      const InstallProgressWindow(stage: InstallStage.download, received: 364, total: 3640),
    );
    await tester.pumpAndSettle();
    expect(find.text('10%'), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('extension-progress-surface'))).width, 320);
    window.show(const InstallProgressWindow(stage: InstallStage.download, received: 1456, total: 3640));
    await tester.pump();
    await tester.pump(Motion.fast);
    expect(find.text('40%'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, closeTo(0.4, 0.001));
    window.show(const InstallProgressWindow(stage: InstallStage.verify));
    await tester.pump();
    await tester.pump(Motion.fast);
    expect(find.text('Verifying…'), findsOneWidget);
    expect(find.text('40%'), findsNothing);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, isNull);
    window.show(InstallPermissionPrompt(manifest: ExtPackage.open(_packageBytes).manifest, sideload: false));
    await tester.pump();
    expect(find.byType(Dialog), findsOneWidget);
    window.show(const InstallProgressWindow(stage: InstallStage.install));
    await tester.pump();
    expect(find.text('Installing…'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(observer.maximum, 1);
    final closed = window.close();
    await tester.pumpAndSettle();
    await closed;
    expect(observer.dialogs, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown total shows real bytes and no percentage', (tester) async {
    await tester.pumpWidget(
      _app(const Scaffold(body: InstallProgressWindow(stage: InstallStage.download, received: 1456))),
    );
    expect(find.text('1,456 B'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, isNull);
    expect(find.textContaining('%'), findsNothing);
    expect(tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration, Duration.zero);
  });

  testWidgets('verified badge follows the name with only a tooltip', (tester) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: ExtensionCard(title: 'Hello Panel', author: 'Sora', verified: true),
        ),
      ),
    );
    final badge = tester.widget<VerifiedBadge>(find.byType(VerifiedBadge));
    expect(badge.size, 14);
    final icon = tester.widget<Icon>(find.descendant(of: find.byType(VerifiedBadge), matching: find.byType(Icon)));
    expect(icon.fill, 1);
    expect(icon.color, Palette.light.verified);
    expect(find.byTooltip('Verified by Sora'), findsOneWidget);
    expect(find.text('Sora team'), findsNothing);
    expect(find.ancestor(of: find.byType(VerifiedBadge), matching: find.byType(ExtensionName)), findsOneWidget);
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: ExtensionCard(title: 'Other', author: 'Other'),
        ),
      ),
    );
    expect(find.byType(VerifiedBadge), findsNothing);
  });

  testWidgets('sideload warning wraps and dangerous permissions still require consent', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(420, 800);
    addTearDown(tester.view.reset);
    final manifest = ExtManifest.parse(File('../examples/routing-split/sora-extension.json').readAsStringSync());
    await tester.pumpWidget(_app(Scaffold(body: InstallPermissionPrompt(manifest: manifest, sideload: true))));
    expect(find.text('Install only if you trust the author’s self-signed key.'), findsOneWidget);
    expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onTap, isNull);
    await tester.tap(find.text('I understand these permissions are powerful'));
    await tester.pump();
    expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onTap, isNotNull);
    expect(tester.takeException(), isNull);
  });

  for (final installed in [false, true]) {
    testWidgets('detail has one header and actions before description, installed=$installed', (tester) async {
      final store = await _store(tester, installed: installed);
      addTearDown(store.dispose);
      await tester.pumpWidget(_app(ExtensionDetailScreen(entry: _entry), store: store));
      await _io(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ExtensionName), findsOneWidget);
      expect(find.text('Sora, 1.0.0'), findsOneWidget);
      expect(find.text('Author'), findsNothing);
      expect(find.text('Version'), findsNothing);
      expect(find.text('Changelog'), findsNothing);
      expect(find.byType(Group), findsOneWidget);
      expect(tester.widget<VerifiedBadge>(find.byType(VerifiedBadge)).size, 16);
      final action = find.text(installed ? 'Open' : 'Install');
      expect(tester.getTopLeft(action).dy, lessThan(tester.getTopLeft(find.text(_entry.description)).dy));
      expect(find.byType(PermissionRow), findsNWidgets(_entry.permissions.length));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('an available update keeps the installed panel accessible', (tester) async {
    final store = await _store(tester, installed: true);
    addTearDown(store.dispose);
    final json =
        ((jsonDecode(utf8.decode(_catalogBytes)) as Map<String, dynamic>)['extensions'] as List).single
            as Map<String, dynamic>;
    final update = CatalogEntry.fromJson({...json, 'version': '1.0.1'});
    await tester.pumpWidget(_app(ExtensionDetailScreen(entry: update), store: store));
    await _io(tester);
    await tester.pumpAndSettle();
    expect(find.text('Update to 1.0.1'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.byType(VerifiedBadge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling an actual catalog download is silent and keeps the page', (tester) async {
    final store = await _store(tester);
    final sora = Sora(await Settings.load(), extensions: store);
    addTearDown(sora.dispose);
    final observer = _Routes();
    await tester.pumpWidget(
      SoraScope(
        sora: sora,
        child: _app(const ExtensionsScreen(), store: store, observer: observer),
      ),
    );
    await _ready(tester);
    final client = _DownloadClient();
    await http.runWithClient(() async {
      await tester.tap(find.text('Install'));
      await tester.pump();
      client.chunks.add(_packageBytes.sublist(0, (_packageBytes.length * 0.4).round()));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('40%'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }, () => client);
    expect(client.closed, isTrue);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(ExtensionsScreen), findsOneWidget);
    expect(find.text('Install failed'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(observer.maximum, 1);
    expect(store.installed, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('URL download without Content-Length shows bytes and cancels silently', (tester) async {
    final store = await _store(tester);
    final sora = Sora(await Settings.load(), extensions: store);
    addTearDown(sora.dispose);
    final observer = _Routes();
    await tester.pumpWidget(
      SoraScope(
        sora: sora,
        child: _app(const ExtensionsScreen(), store: store, observer: observer),
      ),
    );
    await _ready(tester);
    const url = 'https://example.org/extension.soraext';
    final client = _DownloadClient(url: url, knownTotal: false);
    await http.runWithClient(() async {
      await tester.tap(find.byWidgetPredicate((w) => w is RoundButton && w.label == 'Install from URL'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), url);
      await tester.tap(find.text('Download'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      client.chunks.add(_packageBytes.sublist(0, 1456));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('1,456 B'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }, () => client);
    expect(client.closed, isTrue);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(observer.maximum, 1);
    expect(tester.takeException(), isNull);
  });

  for (final corrupt in [false, true]) {
    testWidgets('catalog flow keeps one route through approval or error, corrupt=$corrupt', (tester) async {
      final store = await _store(tester);
      final sora = Sora(await Settings.load(), extensions: store);
      addTearDown(sora.dispose);
      final observer = _Routes();
      await tester.pumpWidget(
        SoraScope(
          sora: sora,
          child: _app(const ExtensionsScreen(), store: store, observer: observer),
        ),
      );
      await _ready(tester);
      final client = _DownloadClient();
      await http.runWithClient(() async {
        await tester.tap(find.text('Install'));
        await tester.pump();
        final data = _packageBytes.toList();
        if (corrupt) data[data.length - 1] ^= 1;
        client.chunks.add(data);
        unawaited(client.chunks.close());
        for (
          var i = 0;
          i < 100 &&
              find.byType(InstallPermissionPrompt).evaluate().isEmpty &&
              find.text('Install failed').evaluate().isEmpty;
          i++
        ) {
          await _io(tester);
        }
        if (corrupt) {
          expect(find.text('Install failed'), findsOneWidget);
          expect(store.installed, isEmpty);
          await tester.tap(find.text('OK'));
        } else {
          expect(find.byType(InstallPermissionPrompt), findsOneWidget);
          expect(find.byType(Dialog), findsOneWidget);
          await tester.tap(find.descendant(of: find.byType(InstallPermissionPrompt), matching: find.text('Install')));
          for (var i = 0; i < 100 && find.byType(Dialog).evaluate().isNotEmpty; i++) {
            await _io(tester);
          }
          expect(store.get(_entry.id)?.version, _entry.version);
        }
        await tester.pumpAndSettle();
      }, () => client);
      expect(find.byType(Dialog), findsNothing);
      expect(observer.maximum, 1);
      expect(tester.takeException(), isNull);
    });
  }
}

void extensionScreenshots() {
  testWidgets('extension screen screenshots', (tester) async {
    final lang = Platform.environment['SORA_SHOTS_LANG'] ?? 'ru';
    final output = '${Platform.environment['HOME']!}/.local/share/sora-dev/shots';
    final capture = GlobalKey();
    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 720);
      await tester.runAsync(() async {
        await (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'))).load();
        await (FontLoader(
          'packages/material_symbols_icons/MaterialSymbolsRounded',
        )..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'))).load();
        await (FontLoader(
          'packages/cupertino_icons/CupertinoIcons',
        )..addFont(rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'))).load();
        await Directory(output).create(recursive: true);
      });
      Future<void> save(String screen, String theme) async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '$screen $theme $lang');
        final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          final path = '$output/extui-$screen-$theme-$lang.png';
          await File(path).writeAsBytes(png.buffer.asUint8List());
          image.dispose();
          debugPrint(path);
        });
      }

      for (final theme in ['light', 'dark']) {
        SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
        final settings = await Settings.load();
        await settings.completeTour();
        settings
          ..language = lang
          ..theme = theme
          ..animations = false;
        final store = await _store(tester);
        final sora = Sora(settings, extensions: store);
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: SoraApp(sora: sora),
          ),
        );
        await tester.pumpAndSettle();
        tester.widget<ShellScope>(find.byType(ShellScope)).select(8);
        await tester.pump();
        await _ready(tester);
        await save('catalog', theme);
        await tester.tap(find.byType(ExtensionName).first);
        await tester.pumpAndSettle();
        await save('detail', theme);
        final context = tester.element(find.byType(ExtensionDetailScreen));
        late final ExtensionInstallDialog window;
        window = ExtensionInstallDialog(
          context,
          InstallProgressWindow(
            stage: InstallStage.download,
            received: (_entry.size * 0.4).round(),
            total: _entry.size,
            onCancel: () => unawaited(window.close()),
          ),
        );
        await save('download-40', theme);
        window.show(const InstallProgressWindow(stage: InstallStage.verify));
        await save('verify', theme);
        window.show(
          InstallPermissionPrompt(
            manifest: ExtPackage.open(_packageBytes).manifest,
            sideload: false,
            verified: _entry.badges.contains('staff'),
            onDecision: (_) => unawaited(window.close()),
          ),
        );
        await save('permissions', theme);
        final close = window.close();
        await tester.pumpAndSettle();
        await close;
        await tester.runAsync(
          () => store.install(
            ExtPackage.open(_packageBytes),
            source: 'catalog',
            granted: _entry.permissions,
            authorKeyPin: _entry.authorKey,
          ),
        );
        await tester.pumpAndSettle();
        await save('detail-installed', theme);
        Navigator.of(context).pop();
        await tester.pumpAndSettle();
        final s = S.of(tester.element(find.byType(ExtensionsScreen)));
        await tester.tap(find.text(s.extInstalled));
        await tester.pumpAndSettle();
        await save('installed', theme);
        final sheetContext = tester.element(find.byType(ExtensionsScreen));
        final conflictStore = (await tester.runAsync(() async {
          final dir = await Directory.systemTemp.createTemp('sora-extui-conflicts-');
          addTearDown(() => dir.delete(recursive: true));
          await seed(dir, 'theme-midnight', id: 'org.sora.midnight.one');
          await seed(dir, 'theme-midnight', id: 'org.sora.midnight.two');
          final store = ExtensionStore(dir: dir.path);
          await store.load();
          return store;
        }))!;
        final conflicts = showConflictsSheet(
          sheetContext,
          conflicts: findConflicts(conflictStore.installed),
          store: conflictStore,
        );
        await tester.pumpAndSettle();
        await save('conflicts', theme);
        Navigator.of(sheetContext, rootNavigator: true).pop();
        await tester.pumpAndSettle();
        await conflicts;
        conflictStore.dispose();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        sora.dispose();
      }
    } finally {
      debugDisableShadows = previousShadows;
    }
  }, skip: Platform.environment['SORA_SHOTS'] == null);
}
