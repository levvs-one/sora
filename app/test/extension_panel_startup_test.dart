import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:webview_all/webview_all.dart';
import 'package:webview_platform_interface/webview_platform_interface.dart' as platform;
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/ext/package.dart';
import 'package:sora/src/ext/bridge.dart';
import 'package:sora/src/ext/catalog.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/extensions/panel_screen.dart';

class _Platform extends WebViewPlatform {
  final initialization = Completer<void>();
  late _Controller controller;
  bool created = false;
  late _Navigation navigation;
  @override
  platform.PlatformWebViewController createPlatformWebViewController(PlatformWebViewControllerCreationParams params) {
    controller = _Controller(params, initialization.future);
    created = true;
    return controller;
  }

  @override
  platform.PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => navigation = _Navigation(params);
  @override
  platform.PlatformWebViewWidget createPlatformWebViewWidget(PlatformWebViewWidgetCreationParams params) =>
      _View(params);
}

class _Controller extends platform.PlatformWebViewController {
  _Controller(super.params, this.initialized) : super.implementation();
  final Future<void> initialized;
  bool fail = false;
  JavaScriptMode? mode;
  platform.PlatformNavigationDelegate? delegate;
  final channels = <platform.JavaScriptChannelParams>[];
  final loaded = <Uri>[];
  final scripts = <String>[];
  int cacheClears = 0;
  @override
  Future<void> setJavaScriptMode(JavaScriptMode value) async {
    await initialized;
    if (fail) throw StateError('fixture initialization failure');
    mode = value;
  }

  @override
  Future<void> setPlatformNavigationDelegate(platform.PlatformNavigationDelegate value) async {
    delegate = value;
  }

  @override
  Future<void> addJavaScriptChannel(platform.JavaScriptChannelParams value) async {
    channels.add(value);
  }

  @override
  Future<void> loadRequest(platform.LoadRequestParams params) async {
    loaded.add(params.uri);
  }

  @override
  Future<void> runJavaScript(String script) async {
    scripts.add(script);
  }

  @override
  Future<void> clearCache() async {
    cacheClears++;
  }
}

class _Navigation extends platform.PlatformNavigationDelegate {
  _Navigation(super.params) : super.implementation();
  NavigationRequestCallback? request;
  PageEventCallback? finished;
  @override
  Future<void> setOnNavigationRequest(NavigationRequestCallback value) async {
    request = value;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback value) async {
    finished = value;
  }
}

class _View extends platform.PlatformWebViewWidget {
  _View(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const SizedBox(key: ValueKey('native-panel-surface'));
}

void main() {
  late Directory work;
  late ExtensionStore store;
  late Sora sora;
  late _Platform platformView;
  WebViewPlatform? previous;
  const id = 'org.sora.hello-panel';
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    work = await Directory.systemTemp.createTemp('sora-panel-startup-');
    store = ExtensionStore(dir: work.path);
    await store.load();
    final package = ExtPackage.open(File('../extensions/packages/hello-panel-1.0.0.soraext').readAsBytesSync());
    await store.install(
      package,
      source: 'catalog',
      granted: package.manifest.permissions,
      authorKeyPin: ExtensionCatalog.parse(File('../extensions/catalog.json').readAsBytesSync()).entries
          .singleWhere((e) => e.id == id)
          .authorKey,
    );
    sora = Sora(await Settings.load(), extensions: store);
    previous = WebViewPlatform.instance;
    WebViewPlatform.instance = platformView = _Platform();
  });
  tearDown(() async {
    if (!platformView.initialization.isCompleted) platformView.initialization.complete();
    sora.dispose();
    if (previous != null) WebViewPlatform.instance = previous;
    await work.delete(recursive: true);
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      SoraScope(
        sora: sora,
        child: ExtScope(
          store: store,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            locale: const Locale('en'),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: const ExtensionPanelScreen(extensionId: id),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 40 && !platformView.created; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(platformView.created, isTrue);
  }

  Future<void> ready(WidgetTester tester) async {
    for (var i = 0; i < 40 && platformView.controller.loaded.isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(platformView.controller.loaded, hasLength(1));
  }

  testWidgets('asynchronous WebView initialization replaces the spinner without another Sora event', (tester) async {
    await mount(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    platformView.initialization.complete();
    await ready(tester);
    expect(find.byType(WebViewWidget), findsOneWidget);
    expect(find.byKey(const ValueKey('native-panel-surface')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(platformView.controller.mode, JavaScriptMode.unrestricted);
    expect(platformView.controller.channels.single.name, PanelBridge.channelName);
    final uri = platformView.controller.loaded.single;
    expect(uri.scheme, 'http');
    expect(uri.host, '127.0.0.1');
    platformView.navigation.finished!(uri.toString());
    await tester.pump();
    expect(platformView.controller.scripts.single, contains('panel.ready'));
    expect(
      await platformView.navigation.request!(const NavigationRequest(url: 'https://example.com', isMainFrame: true)),
      NavigationDecision.prevent,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(platformView.controller.cacheClears, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('native initialization failure shows the unavailable state', (tester) async {
    await mount(tester);
    platformView.controller.fail = true;
    platformView.initialization.complete();
    for (var i = 0; i < 40 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(lookupS(const Locale('en')).extPanelUnavailable), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('closing during initialization suppresses late WebView attachment', (tester) async {
    await mount(tester);
    await tester.pumpWidget(const SizedBox());
    platformView.initialization.complete();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pumpAndSettle();
    expect(platformView.controller.loaded, isEmpty);
    expect(platformView.controller.channels, isEmpty);
    expect(find.byType(WebViewWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
