import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fixnum/fixnum.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' as grpc;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/connections.dart';
import 'package:sora/src/ui/kit.dart';

class _Core extends CoreControlServiceBase {
  ListConnectionsResponse answer = ListConnectionsResponse();
  Completer<void>? gate;
  int calls = 0, active = 0, peak = 0;
  final serviceCalls = <grpc.ServiceCall>[];
  @override
  Future<HandshakeResponse> handshake(grpc.ServiceCall call, HandshakeRequest request) async =>
      HandshakeResponse(negotiatedVersion: apiVersion, controlAuthenticator: List.filled(32, 1));

  @override
  Future<ListConnectionsResponse> listConnections(grpc.ServiceCall call, ListConnectionsRequest request) async {
    expect(request.controlAuthenticator, List.filled(32, 1));
    serviceCalls.add(call);
    calls++;
    active++;
    if (active > peak) peak = active;
    final captured = answer.deepCopy(), wait = gate;
    try {
      await wait?.future;
      return captured;
    } finally {
      active--;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected RPC');
}

class _Link implements CoreLink {
  _Link(this.stub);
  @override
  final CoreControlClient stub;
  @override
  final List<int> token = List.filled(32, 1);
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected link operation');
}

class _State extends Sora {
  _State(super.settings);
  CoreLink? connection;
  @override
  CoreLink? get link => connection;
}

void main() {
  final capture = GlobalKey();
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'packages/material_symbols_icons/MaterialSymbolsRounded',
    )..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'))).load();
  });
  late _Core core;
  late grpc.Server server;
  late grpc.ClientChannel channel;
  late _State sora;
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final settings = await Settings.load();
    settings
      ..language = 'ru'
      ..animations = false;
    core = _Core();
    server = grpc.Server.create(services: [core]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
    channel = grpc.ClientChannel(
      '127.0.0.1',
      port: server.port!,
      options: const grpc.ChannelOptions(credentials: grpc.ChannelCredentials.insecure()),
    );
    await CoreControlClient(channel).handshake(HandshakeRequest(clientVersion: apiVersion));
    sora = _State(settings)
      ..connection = _Link(CoreControlClient(channel))
      ..phase = Phase.connected
      ..sessionId = 'first'
      ..stats = StatsTick(activeConnections: Int64(35))
      ..speedUp = 1200
      ..speedDown = 643;
  });
  tearDown(() async {
    if (core.gate case final gate? when !gate.isCompleted) gate.complete();
    sora.dispose();
    await channel.terminate();
    await server.shutdown();
  });
  Future<void> settle(WidgetTester tester, bool Function() ready) async {
    for (var i = 0; i < 100 && !ready(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(ready(), isTrue);
    await tester.pump();
  }

  Future<void> mount(
    WidgetTester tester, {
    double width = 1000,
    double scale = 1,
    Brightness brightness = Brightness.dark,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: SoraScope(
          sora: sora,
          child: MotionScope(
            enabled: false,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildTheme(brightness),
              locale: const Locale('ru'),
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const ConnectionsScreen(),
            ),
          ),
        ),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
    await settle(tester, () => core.calls > 0 || sora.sessionId == null);
  }

  Future<void> shot(WidgetTester tester, String name) async {
    final path = Platform.environment['SORA_CONNECTION_SHOTS'];
    if (path == null) return;
    final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(path).create(recursive: true);
      await File('$path/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('unavailable list is not empty and does not claim aggregate connections', (tester) async {
    try {
      core.answer = ListConnectionsResponse(error: SoraError(userMessageKey: 'core.connections.unavailable'));
      await mount(tester);
      await settle(tester, () => sora.backgroundFailure('connections') != null);
      expect(find.text(sora.strings.connEmpty), findsNothing);
      expect(find.text(sora.strings.connConnectionsCount(35)), findsNothing);
      expect(find.byType(CupertinoSearchTextField), findsNothing);
      expect(find.byType(Segments<bool>), findsNothing);
      expect(find.text(sora.strings.errConnections), findsOneWidget);
      await shot(tester, 'unavailable-dark');
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(channel.terminate);
      await tester.pump();
    }
  });
  testWidgets('list count comes from listed rows and filtered emptiness explains search', (tester) async {
    try {
      core.answer = ListConnectionsResponse(
        connections: [
          Connection(id: '1', host: 'one.example'),
          Connection(id: '2', host: 'two.example'),
        ],
      );
      await mount(tester);
      await settle(tester, () => find.text('one.example').evaluate().isNotEmpty);
      expect(find.text(sora.strings.connConnectionsCount(2)), findsOneWidget);
      expect(find.text(sora.strings.connConnectionsCount(35)), findsNothing);
      await tester.enterText(find.byType(CupertinoSearchTextField), 'absent');
      await tester.pump();
      expect(find.text(sora.strings.connEmpty), findsNothing);
      expect(find.text(sora.strings.speedtestEmpty), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(channel.terminate);
      await tester.pump();
    }
  });
  testWidgets('pending list requests do not overlap across polling ticks', (tester) async {
    try {
      core.gate = Completer<void>();
      await mount(tester);
      await tester.pump(const Duration(seconds: 3));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      expect(core.calls, 1);
      expect(core.peak, 1);
      core.gate!.complete();
      await settle(tester, () => core.active == 0);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(channel.terminate);
      await tester.pump();
    }
  });
  testWidgets('old session reply cannot display destinations after replacement', (tester) async {
    try {
      core.gate = Completer<void>();
      core.answer = ListConnectionsResponse(
        connections: [Connection(id: 'old', host: 'old.example')],
      );
      await mount(tester);
      sora.sessionId = 'second';
      sora.notifyListeners();
      await tester.pump();
      core.answer = ListConnectionsResponse(
        connections: [Connection(id: 'new', host: 'new.example')],
      );
      core.gate!.complete();
      await settle(tester, () => core.calls >= 2);
      await settle(tester, () => find.text('new.example').evaluate().isNotEmpty);
      expect(find.text('old.example'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(channel.terminate);
      await tester.pump();
    }
  });
  testWidgets('disconnected state hides retained aggregate stats and list tools', (tester) async {
    try {
      sora.sessionId = null;
      await mount(tester);
      expect(find.text(sora.strings.stateOff), findsOneWidget);
      expect(find.text(sora.strings.connEmpty), findsNothing);
      expect(find.text(sora.strings.connConnectionsCount(35)), findsNothing);
      expect(find.byType(CupertinoSearchTextField), findsNothing);
      expect(core.calls, 0);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(channel.terminate);
      await tester.pump();
    }
  });
  testWidgets('deadline exposes failure and releases the client request', (tester) async {
    try {
      core.gate = Completer<void>();
      await mount(tester);
      await tester.pump(const Duration(seconds: 5));
      await settle(tester, () => sora.backgroundFailure('connections') != null);
      expect(find.text(sora.strings.errTimeout), findsOneWidget);
      expect(find.text(sora.strings.connEmpty), findsNothing);
      expect(find.text(sora.strings.connConnectionsCount(35)), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(channel.terminate);
      await tester.pump();
    }
  });

  testWidgets('retry recovers a failed list without stale error text', (tester) async {
    try {
      core.answer = ListConnectionsResponse(error: SoraError(userMessageKey: 'core.connections.unavailable'));
      await mount(tester);
      await settle(tester, () => sora.backgroundFailure('connections') != null);
      core.answer = ListConnectionsResponse(
        connections: [Connection(id: '1', host: 'recovered.example')],
      );
      await tester.tap(find.text(sora.strings.refresh));
      await settle(tester, () => find.text('recovered.example').evaluate().isNotEmpty);
      expect(find.text(sora.strings.errConnections), findsNothing);
      expect(sora.backgroundFailure('connections'), isNull);
      expect(find.text(sora.strings.connConnectionsCount(1)), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(channel.terminate);
      await tester.pump();
    }
  });

  for (final brightness in Brightness.values) {
    testWidgets('unavailable state fits 320px large type $brightness', (tester) async {
      try {
        core.answer = ListConnectionsResponse(error: SoraError(userMessageKey: 'core.connections.unavailable'));
        await mount(tester, width: 320, scale: 1.6, brightness: brightness);
        await settle(tester, () => sora.backgroundFailure('connections') != null);
        expect(find.text(sora.strings.errConnections), findsOneWidget);
        expect(find.text(sora.strings.refresh), findsOneWidget);
        expect(tester.takeException(), isNull);
        await shot(tester, 'unavailable-narrow-$brightness');
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(channel.terminate);
        await tester.pump();
      }
    });
  }
  testWidgets('leaving the screen cancels its pending RPC without reporting a failure', (tester) async {
    try {
      core.gate = Completer<void>();
      await mount(tester);
      final call = core.serviceCalls.single;
      await tester.pumpWidget(const SizedBox());
      await settle(tester, () => call.isCanceled);
      await tester.pump(const Duration(seconds: 3));
      expect(core.calls, 1);
      expect(sora.backgroundFailure('connections'), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(channel.terminate);
      await tester.pump();
    }
  });
}
