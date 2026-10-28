import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' as grpc;
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
import 'package:sora/src/core/link.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';
import 'package:sora/src/notifications.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/extensions/panel_screen.dart';

class _DelayedSora extends Sora {
  _DelayedSora(super.settings, ExtensionStore extensions) : super(extensions: extensions);
  Completer<void>? replyGate;
  CoreLink? connection;
  @override
  CoreLink? get link => connection ?? super.link;
  @override
  Future<void> recordNotification(AppNotification notice) async {
    await super.recordNotification(notice);
    await replyGate?.future;
  }
}

class _ConnectionCore extends CoreControlServiceBase {
  bool fail = false;
  @override
  Future<HandshakeResponse> handshake(grpc.ServiceCall call, HandshakeRequest request) async =>
      HandshakeResponse(negotiatedVersion: apiVersion, controlAuthenticator: List.filled(32, 1));
  @override
  Future<ListConnectionsResponse> listConnections(grpc.ServiceCall call, ListConnectionsRequest request) async => fail
      ? ListConnectionsResponse(error: SoraError(userMessageKey: 'core.connections.unavailable'))
      : ListConnectionsResponse(
          connections: [Connection(id: 'fixture', host: 'fixture.example')],
        );
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected panel fixture RPC');
}

class _ConnectionLink implements CoreLink {
  _ConnectionLink(this.stub);
  @override
  final CoreControlClient stub;
  @override
  final List<int> token = List.filled(32, 1);
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected panel fixture link operation');
}

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
  late _DelayedSora sora;
  late _Platform platformView;
  WebViewPlatform? previous;
  const id = 'org.sora.hello-panel';
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    work = await Directory.systemTemp.createTemp('sora-panel-startup-');
    store = ExtensionStore(dir: work.path);
    await store.load();
    final entry = ExtensionCatalog.parse(File('../extensions/catalog.json').readAsBytesSync()).find(id)!;
    final bytes = File('../extensions/packages/${entry.downloadUrl.split('/').last}').readAsBytesSync();
    final package = ExtPackage.open(bytes);
    expect(bytes.length, entry.size);
    expect(package.manifest.id, entry.id);
    expect(package.manifest.version, entry.version);
    await store.installBytes(
      bytes,
      source: 'catalog',
      granted: entry.permissions,
      expectedSha256: entry.sha256,
      authorKeyPin: entry.authorKey,
    );
    sora = _DelayedSora(await Settings.load(), store);
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

  testWidgets('disabling an open root panel blocks late native-channel side effects', (tester) async {
    await mount(tester);
    platformView.initialization.complete();
    await ready(tester);
    final controller = platformView.controller;
    final channel = controller.channels.single;
    final origin = controller.loaded.single.toString();
    expect(
      await platformView.navigation.request!(NavigationRequest(url: origin, isMainFrame: true)),
      NavigationDecision.navigate,
    );
    await tester.runAsync(() async {
      channel.onMessageReceived(
        const platform.JavaScriptMessage(
          message: '{"id":101,"method":"notify","args":{"title":"Allowed fixture","body":"Synthetic only"}}',
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(sora.history, hasLength(1));
    expect(controller.scripts.any((script) => script.contains('_resolve(101, true')), isTrue);
    await tester.runAsync(() => store.setEnabled(id, false));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      channel.onMessageReceived(
        const platform.JavaScriptMessage(
          message: '{"id":102,"method":"notify","args":{"title":"Revoked fixture","body":"Must not be delivered"}}',
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(sora.history, hasLength(1), reason: 'A queued message after disable must not reach the host.');
    expect(find.byType(WebViewWidget), findsNothing);
    expect(controller.cacheClears, 1);
    expect(controller.scripts.any((script) => script.contains('_resolve(102, true')), isFalse);
    expect(
      await platformView.navigation.request!(NavigationRequest(url: origin, isMainFrame: true)),
      NavigationDecision.prevent,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('revocation discards a reply already waiting on host work', (tester) async {
    await mount(tester);
    platformView.initialization.complete();
    await ready(tester);
    final controller = platformView.controller;
    final channel = controller.channels.single;
    final gate = Completer<void>();
    sora.replyGate = gate;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await tester.runAsync(() async {
      channel.onMessageReceived(
        const platform.JavaScriptMessage(
          message:
              '{"id":103,"method":"notify","args":{"title":"In-flight fixture","body":"Authorized before disable"}}',
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    expect(sora.history, hasLength(1));
    expect(controller.scripts.any((script) => script.contains('_resolve(103,')), isFalse);
    await tester.runAsync(() => store.setEnabled(id, false));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      gate.complete();
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(controller.scripts.any((script) => script.contains('_resolve(103,')), isFalse);
    expect(controller.cacheClears, 1);
    expect(find.byType(WebViewWidget), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('disabling during initialization cannot attach a late panel', (tester) async {
    await mount(tester);
    await tester.runAsync(() => store.setEnabled(id, false));
    await tester.pump();
    platformView.initialization.complete();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pumpAndSettle();
    expect(platformView.controller.loaded, isEmpty);
    expect(platformView.controller.channels, isEmpty);
    expect(platformView.controller.cacheClears, 1);
    expect(find.byType(WebViewWidget), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
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
    expect(
      platformView.controller.cacheClears,
      1,
      reason: 'Closing before readiness must release the late controller.',
    );
    expect(find.byType(WebViewWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('a native initializer that never finishes cannot leave a permanent spinner', (tester) async {
    await mount(tester);
    final old = platformView.controller;
    try {
      await tester.pump(const Duration(seconds: 30));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(lookupS(const Locale('en')).extPanelUnavailable), findsOneWidget);
      expect(old.loaded, isEmpty);
      expect(old.cacheClears, 1);
      platformView.initialization.complete();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pumpAndSettle();
      expect(old.loaded, isEmpty);
      expect(old.channels, isEmpty);
      expect(old.cacheClears, 1);
    } finally {
      await tester.pumpWidget(const SizedBox());
      if (!platformView.initialization.isCompleted) platformView.initialization.complete();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('retry after the native startup deadline owns only the new controller', (tester) async {
    await mount(tester);
    final old = platformView.controller;
    try {
      await tester.pump(const Duration(seconds: 30));
      expect(find.text(lookupS(const Locale('en')).extPanelUnavailable), findsOneWidget);
      await tester.tap(find.text(lookupS(const Locale('en')).refresh));
      for (var i = 0; i < 40 && identical(old, platformView.controller); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump();
      }
      expect(identical(old, platformView.controller), isFalse);
      platformView.initialization.complete();
      await ready(tester);
      expect(old.loaded, isEmpty);
      expect(old.cacheClears, 1);
      expect(find.byType(WebViewWidget), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox());
      if (!platformView.initialization.isCompleted) platformView.initialization.complete();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pumpAndSettle();
    }
  });
  testWidgets('a core connection-list failure rejects the bridge promise instead of reporting zero rows', (
    tester,
  ) async {
    final core = _ConnectionCore();
    late grpc.Server server;
    late grpc.ClientChannel channel;
    await tester.runAsync(() async {
      server = grpc.Server.create(services: [core]);
      await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
      channel = grpc.ClientChannel(
        '127.0.0.1',
        port: server.port!,
        options: const grpc.ChannelOptions(credentials: grpc.ChannelCredentials.insecure()),
      );
      final stub = CoreControlClient(channel);
      await stub.handshake(HandshakeRequest(clientVersion: apiVersion));
      sora.connection = _ConnectionLink(stub);
      sora.sessionId = 'fixture-session';
    });
    try {
      await mount(tester);
      platformView.initialization.complete();
      await ready(tester);
      final controller = platformView.controller;
      final native = controller.channels.single;
      await tester.runAsync(() async {
        native.onMessageReceived(
          const platform.JavaScriptMessage(message: '{"id":201,"method":"getConnections","args":{}}'),
        );
        for (var i = 0; i < 100 && !controller.scripts.any((s) => s.contains('_resolve(201,')); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      expect(controller.scripts.any((s) => s.contains('_resolve(201, true') && s.contains('fixture.example')), isTrue);
      core.fail = true;
      await tester.runAsync(() async {
        native.onMessageReceived(
          const platform.JavaScriptMessage(message: '{"id":202,"method":"getConnections","args":{}}'),
        );
        for (var i = 0; i < 100 && !controller.scripts.any((s) => s.contains('_resolve(202,')); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      expect(controller.scripts.any((s) => s.contains('_resolve(202, false')), isTrue);
      expect(controller.scripts.any((s) => s.contains('_resolve(202, true')), isFalse);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await channel.terminate();
        await server.shutdown();
      });
      sora.connection = null;
    }
  });
}
