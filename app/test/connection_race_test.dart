import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'
    show SizedBox, Text, EditableText, Scrollable, ScrollableState, ValueKey, Semantics;
import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart' show Server, ServiceCall;
import 'package:sora/main.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/logs.dart';
import 'package:sora/src/ui/kit.dart' show RoundButton;

import 'desktop_shell_test.dart' show section;

class _Core extends CoreControlServiceBase {
  ConnectionState state = ConnectionState(value: ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED);
  Completer<void>? gate;
  Completer<void>? handshakeGate;
  int handshakes = 0;
  bool reject = false;
  bool failCleanup = false;
  bool failStartCleanup = false;
  int minor = 7;
  int connects = 0, disconnects = 0, busyReplies = 0;
  final kills = <bool>[];
  final probeRequests = <ProbeServersRequest>[];
  final probeCalls = <ServiceCall>[];
  Completer<void>? probeGate;
  final subscriptions = [
    SubscriptionState(
      settings: SubscriptionSettings(id: 'first'),
      outbounds: [
        OutboundSpec(id: 'a'),
        OutboundSpec(id: 'b'),
      ],
    ),
    SubscriptionState(
      settings: SubscriptionSettings(id: 'second'),
      outbounds: [OutboundSpec(id: 'c')],
    ),
  ];
  SessionPlan? plan;
  final events = StreamController<CoreEvent>.broadcast();
  final logs = StreamController<LogEntry>.broadcast();
  final logQueries = <LogFilter>[];
  final logPages = <QueryLogsRequest>[];
  final logWatches = <LogFilter>[];
  final exportRequests = <ExportLogsRequest>[];
  Completer<void>? exportGate;
  final diagnosticCalls = <ServiceCall>[];
  final diagnosticRequests = <ExportDiagnosticsRequest>[];
  Completer<void>? diagnosticGate;
  List<LogEntry> logPage = [
    LogEntry(sequence: Int64(1), source: 'core', message: 'Service started', level: LogLevel.LOG_LEVEL_INFO),
  ];

  Future<void> close() async {
    await events.close();
    await logs.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');

  @override
  Future<HandshakeResponse> handshake(ServiceCall call, HandshakeRequest request) async {
    handshakes++;
    await handshakeGate?.future;
    return HandshakeResponse(
      negotiatedVersion: apiVersion.deepCopy()..minor = minor,
      controlAuthenticator: List.filled(32, 1),
    );
  }

  @override
  Future<GetAboutResponse> getAbout(ServiceCall call, GetAboutRequest request) async => GetAboutResponse(
    about: About(
      contract: apiVersion.deepCopy()..capabilities.addAll(['serverless', 'log-export-formats', 'native-diagnostics']),
    ),
  );

  @override
  Future<ExportLogsResponse> exportLogs(ServiceCall call, ExportLogsRequest request) async {
    exportRequests.add(request.deepCopy());
    await exportGate?.future;
    return ExportLogsResponse();
  }

  @override
  Future<ExportDiagnosticsResponse> exportDiagnostics(ServiceCall call, ExportDiagnosticsRequest request) async {
    diagnosticRequests.add(request.deepCopy());
    diagnosticCalls.add(call);
    await diagnosticGate?.future;
    return ExportDiagnosticsResponse();
  }

  @override
  Future<GetStatusResponse> getStatus(ServiceCall call, GetStatusRequest request) async =>
      GetStatusResponse(status: SessionStatus(connection: state.deepCopy()));

  @override
  Future<GetStatsResponse> getStats(ServiceCall call, GetStatsRequest request) async =>
      GetStatsResponse(stats: StatsTick());

  @override
  Stream<SubscriptionState> watchSubscriptions(ServiceCall call, WatchSubscriptionsRequest request) =>
      Stream.fromIterable(subscriptions);

  @override
  Stream<ProbeResult> probeServers(ServiceCall call, ProbeServersRequest request) async* {
    probeRequests.add(request);
    probeCalls.add(call);
    await probeGate?.future;
    for (final outbound in request.outbounds) {
      yield ProbeResult(serverId: outbound.id, reachable: true, latencyMs: 42);
    }
  }

  @override
  Stream<CoreEvent> watchEvents(ServiceCall call, WatchEventsRequest request) => events.stream;

  @override
  Future<QueryLogsResponse> queryLogs(ServiceCall call, QueryLogsRequest request) async {
    logQueries.add(request.filter.deepCopy());
    logPages.add(request.deepCopy());
    final candidates = logPage
        .where((entry) => request.beforeSequence == Int64.ZERO || entry.sequence < request.beforeSequence)
        .toList();
    final entries = candidates.take(request.limit == 0 ? 500 : request.limit).toList();
    return QueryLogsResponse(
      entries: entries,
      beforeSequence: candidates.length > entries.length ? entries.last.sequence : Int64.ZERO,
    );
  }

  @override
  Stream<LogEntry> watchLogs(ServiceCall call, WatchLogsRequest request) {
    logWatches.add(request.filter.deepCopy());
    return logs.stream;
  }

  @override
  Future<ConnectResponse> connect(ServiceCall call, ConnectRequest request) async {
    connects++;
    plan = request.sessionPlan;
    await gate?.future;
    if (failStartCleanup) {
      state = ConnectionState(value: ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED);
      return ConnectResponse(error: SoraError(userMessageKey: 'core.guard.restore_failed'));
    }
    if (reject) return ConnectResponse(error: SoraError(userMessageKey: 'core.engine.binary_missing'));
    state = ConnectionState(
      value: ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTED,
      sessionId: 'session-$connects',
    );
    return ConnectResponse(status: SessionStatus(connection: state.deepCopy()));
  }

  @override
  Future<DisconnectResponse> disconnect(ServiceCall call, DisconnectRequest request) async {
    disconnects++;
    if (busyReplies-- > 0) return DisconnectResponse(error: SoraError(userMessageKey: 'core.session.busy'));
    state = ConnectionState(value: ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED);
    if (failCleanup) return DisconnectResponse(error: SoraError(userMessageKey: 'core.guard.restore_failed'));
    return DisconnectResponse(status: SessionStatus(connection: state.deepCopy()));
  }

  @override
  Future<SetKillSwitchResponse> setKillSwitch(ServiceCall call, SetKillSwitchRequest request) async {
    kills.add(request.enabled);
    return SetKillSwitchResponse();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final socket = Platform.environment['SORA_CORE_SOCKET'];
  final isolated = socket != null && socket.startsWith('/tmp/sora-race-');
  late _Core core;
  late Server server;
  late Sora sora;
  late Future<void> running;
  bool disposed = false;

  Future<void> until(bool Function() ready) async {
    final limit = DateTime.now().add(const Duration(seconds: 5));
    while (!ready()) {
      if (DateTime.now().isAfter(limit)) fail('state change timed out');
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  setUp(() async {
    if (!isolated) return;
    disposed = false;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    core = _Core();
    server = Server.create(services: [core]);
    await server.serve(address: InternetAddress(socket, type: InternetAddressType.unix), port: 0);
    final settings = await Settings.load();
    settings.server = 'bypass';
    sora = Sora(settings);
    running = sora.run();
    await until(() => sora.serverlessAvailable && sora.servers.length == 3);
  });

  tearDown(() async {
    if (!isolated) return;
    if (core.gate case final gate? when !gate.isCompleted) gate.complete();
    if (core.handshakeGate case final gate? when !gate.isCompleted) gate.complete();
    if (core.probeGate case final gate? when !gate.isCompleted) gate.complete();
    if (core.diagnosticGate case final gate? when !gate.isCompleted) gate.complete();
    if (core.exportGate case final gate? when !gate.isCompleted) gate.complete();
    if (!disposed) sora.dispose();
    try {
      await running.timeout(const Duration(seconds: 10));
    } finally {
      await server.shutdown();
      await core.close();
      if (await File(socket).exists()) await File(socket).delete();
    }
  });

  group('commands over an isolated RPC socket', () {
    testWidgets('exports carry the selected category, search and format; old cores cannot mislabel data', (
      tester,
    ) async {
      await sora.settings.completeTour();
      sora.settings.animations = false;
      final saves = <String>[];
      const chooser = MethodChannel('plugins.flutter.io/file_selector');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(chooser, (call) async {
        saves.add((call.arguments as Map)['suggestedName'] as String);
        return null;
      });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(chooser, null),
      );
      try {
        await tester.pumpWidget(SoraApp(sora: sora));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('logs-section-dns')));
        await tester.enterText(
          find.descendant(of: find.byType(LogsScreen), matching: find.byType(EditableText)),
          'resolver',
        );
        await tester.pump(const Duration(milliseconds: 300));
        for (final extension in ['log', 'txt', 'json', 'jsonl', 'csv', 'xml', 'zip', 'gz']) {
          final before = core.exportRequests.length;
          await tester.tap(find.byWidgetPredicate((w) => w is RoundButton && w.label == sora.strings.export));
          await tester.pump(const Duration(milliseconds: 250));
          await tester.tap(find.byWidgetPredicate((w) => w is Text && (w.data?.endsWith('.$extension') ?? false)));
          await tester.pump();
          for (var i = 0; i < 30 && saves.length == before; i++) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
            await tester.pump(const Duration(milliseconds: 100));
          }
          final request = core.exportRequests.last;
          expect(request.category, 'dns');
          expect(request.filter.contains, 'resolver');
          expect(request.filter.pattern, contains('dns'));
          expect(saves.last, matches(RegExp('^sora-log_dns_[0-9]{2}_[0-9]{2}_[0-9]{4}\\.$extension\$')));
        }
        expect(core.exportRequests.map((r) => r.format), [
          LogExportFormat.LOG_EXPORT_FORMAT_LOG,
          LogExportFormat.LOG_EXPORT_FORMAT_UNSPECIFIED,
          LogExportFormat.LOG_EXPORT_FORMAT_JSON,
          LogExportFormat.LOG_EXPORT_FORMAT_JSON_LINES,
          LogExportFormat.LOG_EXPORT_FORMAT_CSV,
          LogExportFormat.LOG_EXPORT_FORMAT_XML,
          LogExportFormat.LOG_EXPORT_FORMAT_ZIP,
          LogExportFormat.LOG_EXPORT_FORMAT_GZIP,
        ]);
        core.exportGate = Completer<void>();
        await tester.tap(find.byWidgetPredicate((w) => w is RoundButton && w.label == sora.strings.export));
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.byWidgetPredicate((w) => w is Text && (w.data?.endsWith('.json') ?? false)));
        await tester.pump();
        await tester.runAsync(() => until(() => core.exportRequests.length == 9));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        expect(find.byType(LogsScreen), findsNothing);
        core.exportGate!.complete();
        for (var i = 0; i < 20 && saves.length == 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        }
        expect(saves, hasLength(8), reason: 'Leaving logs must suppress the late save dialog');
        for (final extension in ['json', 'har', 'pcapng']) {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pump();
          await tester.tap(find.byWidgetPredicate((w) => w is RoundButton && w.label == sora.strings.export));
          await tester.pump(const Duration(milliseconds: 250));
          await tester.tap(find.byWidgetPredicate((w) => w is Text && (w.data?.endsWith('.$extension') ?? false)));
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(sora.history, isEmpty);
          expect(core.exportRequests, hasLength(9));
          expect(core.diagnosticRequests, isEmpty);
        }
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        sora.coreCapabilities.remove('log-export-formats');
        await tester.tap(find.byWidgetPredicate((w) => w is RoundButton && w.label == sora.strings.export));
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.byWidgetPredicate((w) => w is Text && (w.data?.endsWith('.json') ?? false)));
        await tester.pump(const Duration(milliseconds: 250));
        expect(core.exportRequests, hasLength(9));
        expect(saves, hasLength(8));
        expect(sora.history, hasLength(1));
      } finally {
        await tester.pumpWidget(const SizedBox());
        sora.dispose();
        disposed = true;
        await tester.runAsync(() => running.timeout(const Duration(seconds: 10)));
      }
    });

    testWidgets('packet capture requires TUN; cancel and leaving logs suppress late replies', (tester) async {
      await sora.settings.completeTour();
      sora.settings.animations = false;
      core.diagnosticGate = Completer<void>();
      Future<void> packetMenu() async {
        await tester.tap(find.byWidgetPredicate((w) => w is RoundButton && w.label == sora.strings.export));
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.byWidgetPredicate((w) => w is Text && (w.data?.endsWith('.pcapng') ?? false)));
        await tester.pump();
      }

      Future<void> waitFor(bool Function() ready) async {
        for (var i = 0; i < 50 && !ready(); i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(ready(), isTrue);
      }

      try {
        await tester.pumpWidget(SoraApp(sora: sora));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        await packetMenu();
        expect(core.diagnosticRequests, isEmpty);
        expect(sora.history.single.body, sora.strings.diagnosticRequiresTun);
        await tester.runAsync(sora.clearNotifications);
        final close = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == sora.strings.close);
        await waitFor(() => close.evaluate().isNotEmpty);
        await tester.tap(close);
        await tester.pump();
        await tester.runAsync(sora.connect);
        await tester.pump();
        await packetMenu();
        await waitFor(() => core.diagnosticRequests.length == 1);
        expect(core.diagnosticRequests.single.sessionId, sora.sessionId);
        expect(core.diagnosticRequests.single.controlAuthenticator, isNotEmpty);
        expect(core.diagnosticRequests.single.format, DiagnosticFormat.DIAGNOSTIC_FORMAT_PCAPNG);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byWidgetPredicate((w) => w is RoundButton && w.label == sora.strings.cancel));
        await waitFor(() => core.diagnosticCalls.single.isCanceled);
        await packetMenu();
        await waitFor(() => core.diagnosticRequests.length == 2);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        await waitFor(() => core.diagnosticCalls.last.isCanceled);
        core.diagnosticGate!.complete();
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
        expect(sora.history, isEmpty);
        expect(sora.phase, Phase.connected);
        expect(tester.takeException(), isNull);
      } finally {
        if (!core.diagnosticGate!.isCompleted) core.diagnosticGate!.complete();
        await tester.pumpWidget(const SizedBox());
        sora.dispose();
        disposed = true;
        await tester.runAsync(() => running.timeout(const Duration(seconds: 10)));
      }
    });

    for (final initiallyConnected in [false, true]) {
      testWidgets(
        'connect orb remains clickable after reset while ${initiallyConnected ? "connected" : "disconnected"}',
        (tester) async {
          await sora.settings.completeTour();
          sora.settings.animations = false;
          if (initiallyConnected) await tester.runAsync(sora.connect);
          try {
            await tester.pumpWidget(SoraApp(sora: sora));
            await tester.pump();
            await tester.runAsync(sora.reset);
            await tester.pump(const Duration(milliseconds: 250));
            final connect = find.byKey(const ValueKey('connect-control'));
            expect(connect, findsOneWidget);
            await tester.runAsync(() => tester.tap(connect));
            for (var i = 0; i < 50 && sora.phase != (initiallyConnected ? Phase.off : Phase.connected); i++) {
              await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
              await tester.pump(const Duration(milliseconds: 100));
            }
            await tester.pump(const Duration(milliseconds: 250));
            expect(sora.phase, initiallyConnected ? Phase.off : Phase.connected);
            expect(sora.settings.tourDone, isTrue);
            if (initiallyConnected) {
              await tester.runAsync(() => tester.tap(connect));
              for (var i = 0; i < 50 && sora.phase != Phase.connected; i++) {
                await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
                await tester.pump(const Duration(milliseconds: 100));
              }
              await tester.pump(const Duration(milliseconds: 250));
              expect(sora.phase, Phase.connected);
            }
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox());
            sora.dispose();
            disposed = true;
            await tester.runAsync(() => running.timeout(const Duration(seconds: 10)));
          }
        },
      );
    }

    testWidgets('log sections combine with severity and search in both history and stream', (tester) async {
      await sora.settings.completeTour();
      sora.settings.animations = false;
      try {
        await tester.pumpWidget(SoraApp(sora: sora));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        for (var i = 0; i < 30 && core.logWatches.isEmpty; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(core.logWatches, isNotEmpty);
        for (final category in ['engine', 'tun', 'dns', 'subscriptions', 'core', 'all']) {
          final count = core.logWatches.length;
          await tester.tap(find.byKey(ValueKey('logs-section-$category')));
          await tester.pump();
          for (var i = 0; i < 30 && core.logWatches.length == count; i++) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(core.logWatches.length, count + 1);
          expect(core.logWatches.last, core.logQueries.last);
          final filter = core.logQueries.last;
          expect(filter.sources, switch (category) {
            'engine' => ['sing-box', 'xray', 'mihomo', 'zapret'],
            'subscriptions' => ['subscription'],
            'core' => ['core'],
            _ => <String>[],
          });
          expect(filter.pattern.isNotEmpty, category == 'tun' || category == 'dns');
        }
        await tester.tap(find.byKey(const ValueKey('logs-section-tun')));
        await tester.tap(find.text(sora.strings.logsErrors));
        await tester.enterText(
          find.descendant(of: find.byType(LogsScreen), matching: find.byType(EditableText)),
          'adapter',
        );
        await tester.pump(const Duration(milliseconds: 300));
        for (var i = 0; i < 30 && core.logWatches.last.contains != 'adapter'; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        final filter = core.logQueries.last;
        expect(filter, core.logWatches.last);
        expect(filter.contains, 'adapter');
        expect(filter.minLevel, LogLevel.LOG_LEVEL_ERROR);
        expect(filter.pattern, contains('tun'));
      } finally {
        await tester.pumpWidget(const SizedBox());
        sora.dispose();
        disposed = true;
        await tester.runAsync(() => running.timeout(const Duration(seconds: 10)));
      }
    });

    testWidgets('logs opened before the service link arrives load and continue streaming', (tester) async {
      final waiting = Sora(sora.settings);
      await waiting.settings.completeTour();
      waiting.settings.animations = false;
      Future<void>? waitingWork;
      try {
        await tester.pumpWidget(SoraApp(sora: waiting));
        await section(tester, 4);
        expect(find.byType(LogsScreen), findsOneWidget);
        await tester.runAsync(() async {
          waitingWork = waiting.run();
          await until(() => waiting.serverlessAvailable);
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        for (var i = 0; i < 30 && !core.logs.hasListener; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(core.logs.hasListener, isTrue);
        await tester.pump();
        expect(find.text('Service started'), findsOneWidget);
        core.logs.add(
          LogEntry(sequence: Int64(2), source: 'xray', message: 'Engine started', level: LogLevel.LOG_LEVEL_INFO),
        );
        for (var i = 0; i < 30 && find.text('Engine started').evaluate().isEmpty; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Engine started'), findsOneWidget);
        expect(waiting.history, isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox());
        waiting.dispose();
        await tester.runAsync(() async => await waitingWork?.timeout(const Duration(seconds: 10)));
      }
    });

    testWidgets('new log entries preserve the visible text until the reader returns to the top', (tester) async {
      core.logPage = List.generate(80, (i) => LogEntry(sequence: Int64(80 - i), source: 'core', message: 'History $i'));
      await sora.settings.completeTour();
      sora.settings.animations = false;
      try {
        await tester.pumpWidget(SoraApp(sora: sora));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        for (var i = 0; i < 30 && !core.logs.hasListener; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(core.logs.hasListener, isTrue);
        final scrollable = find.descendant(of: find.byType(LogsScreen), matching: find.byType(Scrollable)).last;
        await tester.drag(scrollable, const Offset(0, -450));
        await tester.pumpAndSettle();
        final bounds = tester.getRect(scrollable);
        final visible = find
            .byWidgetPredicate((w) => w is Text && (w.data?.startsWith('History ') ?? false))
            .evaluate();
        final anchor =
            visible.firstWhere((element) {
                  final point = tester.getTopLeft(find.byWidget(element.widget));
                  return point.dy > bounds.top + 40 && point.dy < bounds.bottom - 80;
                }).widget
                as Text;
        final anchored = find.text(anchor.data!);
        final before = tester.getTopLeft(anchored);
        await tester.runAsync(() async {
          for (var i = 0; i < 30; i++) {
            core.logs.add(
              LogEntry(
                sequence: Int64(81 + i),
                source: 'xray',
                message: 'New $i${i.isEven ? '\nSecond line\nThird line' : ''}',
              ),
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(anchored), before);
        final position = tester.state<ScrollableState>(scrollable).position;
        position.jumpTo(position.minScrollExtent);
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          core.logs.add(LogEntry(sequence: Int64(111), source: 'core', message: 'Latest entry'));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();
        expect(find.text('Latest entry'), findsOneWidget);
        expect(position.pixels, position.minScrollExtent);
      } finally {
        await tester.pumpWidget(const SizedBox());
        sora.dispose();
        disposed = true;
        await tester.runAsync(() => running.timeout(const Duration(seconds: 10)));
      }
    });

    testWidgets('scrolling through history loads older pages without moving the reader', (tester) async {
      core.logPage = List.generate(
        700,
        (i) => LogEntry(sequence: Int64(700 - i), source: 'core', message: 'History $i'),
      );
      await sora.settings.completeTour();
      sora.settings.animations = false;
      try {
        await tester.pumpWidget(SoraApp(sora: sora));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        for (var i = 0; i < 30 && !core.logs.hasListener; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(core.logPages.single.limit, 500);
        final scrollable = find.descendant(of: find.byType(LogsScreen), matching: find.byType(Scrollable)).last;
        final position = tester.state<ScrollableState>(scrollable).position;
        // SliverList estimates the height of unseen variable-height entries.
        for (var i = 0; i < 30 && core.logPages.length == 1; i++) {
          position.jumpTo(position.maxScrollExtent);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(core.logPages.last.beforeSequence, Int64(201));
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          position.jumpTo(position.maxScrollExtent);
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('History 699'), findsOneWidget);
        expect(core.logPages.length, 2);
        final before = tester.getTopLeft(find.text('History 699'));
        await tester.runAsync(() async {
          core.logs.add(LogEntry(sequence: Int64(701), source: 'core', message: 'New entry'));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
        expect(tester.getTopLeft(find.text('History 699')), before);
      } finally {
        await tester.pumpWidget(const SizedBox());
        sora.dispose();
        disposed = true;
        await tester.runAsync(() => running.timeout(const Duration(seconds: 10)));
      }
    });

    test('subscription probing stays scoped and a click burst starts one request', () async {
      await until(() => sora.servers.length == 3);
      core.probeGate = Completer<void>();
      final probes = List.generate(30, (_) => sora.probe(subscriptionId: 'first'));
      await until(() => core.probeRequests.length == 1);
      expect(core.probeRequests.single.outbounds.map((o) => o.id), ['a', 'b']);
      expect(sora.probingSubscription, 'first');
      await sora.probe(subscriptionId: 'second');
      expect(core.probeRequests, hasLength(1));
      core.probeGate!.complete();
      await Future.wait(probes);
      expect(sora.latency, {'a': 42, 'b': 42});
      expect(sora.probing, isFalse);
      expect(sora.probingSubscription, isNull);
      await sora.probe(subscriptionId: 'missing');
      expect(core.probeRequests, hasLength(1));
      await sora.probe(subscriptionId: 'second');
      expect(core.probeRequests.last.outbounds.single.id, 'c');
      expect(sora.latency['c'], 42);
    });

    test('probing does not start while connection routes are changing', () async {
      core.gate = Completer<void>();
      final start = sora.connect();
      await until(() => core.connects == 1);
      await sora.probe();
      expect(core.probeRequests, isEmpty);
      core.gate!.complete();
      await start;
      await sora.probe(subscriptionId: 'second');
      expect(sora.latency, {'c': 42});
    });

    for (final stop in [false, true]) {
      test('${stop ? 'disconnect' : 'connect'} cancels probing and ignores its late results', () async {
        if (stop) await sora.connect();
        sora.latency['a'] = 17;
        core.probeGate = Completer<void>();
        final measurement = sora.probe();
        await until(() => core.probeRequests.length == 1);
        await (stop ? sora.disconnect() : sora.connect());
        await until(() => core.probeCalls.single.isCanceled);
        await measurement;
        expect(sora.probing, isFalse);
        expect(sora.probingSubscription, isNull);
        core.probeGate!.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(sora.latency, {'a': 17});
        expect(sora.history, isEmpty);
      });
    }
    test('a click burst starts once, and disconnect wins while connecting', () async {
      core.gate = Completer<void>();
      final starts = List.generate(30, (_) => sora.connect());
      await until(() => core.connects == 1);
      final stops = List.generate(30, (_) => sora.disconnect());
      expect(sora.phase, Phase.disconnecting);
      expect(core.disconnects, 0);
      core.gate!.complete();
      await Future.wait([...starts, ...stops]);
      expect(core.connects, 1);
      expect(core.disconnects, 1);
      expect(sora.phase, Phase.off);
      expect(sora.sessionId, isNull);
      expect(sora.history, isEmpty);
    });

    test('settings during startup remain pending until explicit application', () async {
      core.gate = Completer<void>();
      final start = sora.connect();
      await until(() => core.connects == 1);
      await sora.change((s) => s.engine = 'xray');
      core.gate!.complete();
      await start;
      expect(sora.needsReconnect, isTrue);
      expect(core.connects, 1);
      core.gate = null;
      await sora.connect();
      expect(core.plan!.engines, ['xray']);
      expect(sora.needsReconnect, isFalse);
    });

    test('location clicks coalesce to the last choice while a replacement is starting', () async {
      await sora.select('a');
      await sora.connect();
      core.gate = Completer<void>();
      final first = sora.select('b');
      await until(() => core.connects == 2);
      final burst = List.generate(100, (i) => sora.select(['a', 'b', 'c'][i % 3]));
      core.gate!.complete();
      await Future.wait([first, ...burst]);
      expect(core.connects, 3);
      expect(core.plan!.groups.single.members.first, 'a');
      expect(sora.phase, Phase.connected);
      expect(sora.needsReconnect, isFalse);
      expect(sora.history, isEmpty);
    });

    test('explicit disconnect cancels queued location changes without restarting', () async {
      await sora.select('a');
      await sora.connect();
      core.gate = Completer<void>();
      final replacement = sora.select('b');
      await until(() => core.connects == 2);
      final choice = sora.select('c');
      final stop = sora.disconnect();
      core.gate!.complete();
      await Future.wait([replacement, choice, stop]);
      expect(core.connects, 2);
      expect(core.disconnects, 1);
      expect(sora.phase, Phase.off);
      expect(sora.history, isEmpty);
    });

    test('the latest location survives replacement of the service link', () async {
      await sora.select('a');
      await sora.connect();
      final previous = sora.link!;
      final close = previous.close();
      final choice = sora.select('b');
      await Future.wait([close, choice]);
      await until(() => sora.link != null && sora.link != previous && sora.phase == Phase.connected);
      await until(() => core.connects == 2);
      await until(() => !sora.busy && !sora.needsReconnect);
      expect(core.plan!.groups.single.members.first, 'b');
      expect(sora.needsReconnect, isFalse);
    });

    for (final stop in [false, true]) {
      test(
        'a selection while the link is missing ${stop ? 'is cancelled by disconnect' : 'is replayed after recovery'}',
        () async {
          await sora.select('a');
          await sora.connect();
          core.handshakeGate = Completer<void>();
          await sora.link!.close();
          await until(() => core.handshakes == 2);
          expect(sora.link, isNull);
          await sora.select('c');
          if (stop) await sora.disconnect();
          core.handshakeGate!.complete();
          await until(() => sora.link != null && sora.serverlessAvailable && sora.phase == Phase.connected);
          if (stop) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            expect(core.connects, 1);
          } else {
            await until(() => core.connects == 2);
            await until(() => !sora.busy && !sora.needsReconnect);
            expect(core.plan!.groups.single.members.first, 'c');
            expect(sora.needsReconnect, isFalse);
          }
        },
      );
    }

    test('a location selected during the first connection applies automatically', () async {
      await sora.select('a');
      core.gate = Completer<void>();
      final start = sora.connect();
      await until(() => core.connects == 1);
      final choice = sora.select('c');
      core.gate!.complete();
      await Future.wait([start, choice]);
      expect(core.connects, 2);
      expect(core.plan!.groups.single.members.first, 'c');
      expect(sora.needsReconnect, isFalse);
    });

    test('an unsupported location keeps the working connection and reports the error once', () async {
      await sora.select('a');
      await sora.connect();
      final id = sora.sessionId;
      core.reject = true;
      await sora.select('b');
      expect(sora.phase, Phase.connected);
      expect(sora.sessionId, id);
      expect(core.disconnects, 0);
      expect(sora.history, hasLength(1));
    });

    for (final selectedEngine in ['mihomo', 'xray']) {
      test('$selectedEngine TUN stack click bursts are staged until one explicit reconnect', () async {
        await sora.change(
          (s) => s
            ..server = 'a'
            ..engine = selectedEngine,
        );
        await sora.connect();
        final original = selectedEngine == 'mihomo' ? 'mixed' : 'gvisor';
        void stack(Settings s, String value) {
          if (selectedEngine == 'mihomo') {
            s.mihomoTunStack = value;
          } else {
            s.xrayTunStack = value;
          }
        }

        expect(core.plan!.tunStack, selectedEngine == 'mihomo' ? 'mixed' : '');
        for (var i = 0; i < 50; i++) {
          await sora.change((s) => stack(s, i.isEven ? 'system' : 'mips'));
        }
        expect(core.connects, 1);
        expect(sora.needsReconnect, isTrue);
        await sora.change((s) => stack(s, original));
        expect(sora.needsReconnect, isFalse);
        await sora.change((s) => stack(s, 'mips'));
        core.gate = Completer<void>();
        final starts = List.generate(30, (_) => sora.connect());
        await until(() => core.connects == 2);
        final stop = sora.disconnect();
        core.gate!.complete();
        await Future.wait([...starts, stop]);
        expect(core.plan!.tunStack, 'mips');
        expect(core.connects, 2);
        expect(sora.phase, Phase.off);
      });
    }

    test('an older core cannot silently ignore an explicit stack', () async {
      await sora.connect();
      final active = sora.sessionId;
      core.minor = 6;
      await sora.link!.close();
      await until(
        () =>
            sora.link?.minor == 6 &&
            sora.phase == Phase.connected &&
            sora.serverlessAvailable &&
            core.events.hasListener,
      );
      await sora.change(
        (s) => s
          ..server = 'a'
          ..engine = 'mihomo'
          ..mihomoTunStack = 'system',
      );
      await sora.connect();
      expect(core.connects, 1);
      expect(core.disconnects, 0);
      expect(sora.sessionId, active);
      expect(sora.phase, Phase.connected);
      expect(sora.failure!.key, 'core.api.version_mismatch');
    });

    test('a rejected replacement preserves the tunnel and reports one failure', () async {
      await sora.connect();
      final id = sora.sessionId;
      for (var i = 0; i < 100; i++) {
        await sora.change((s) => s.engine = i.isEven ? 'xray' : 'mihomo');
      }
      expect(core.connects, 1);
      await sora.change((s) => s.engine = '');
      expect(sora.needsReconnect, isFalse, reason: 'reverting settings needs no reconnect');
      await sora.change((s) => s.engine = 'sing-box');
      core.reject = true;
      await sora.connect();
      expect(sora.phase, Phase.connected);
      expect(sora.sessionId, id);
      expect(sora.needsReconnect, isTrue);
      expect(sora.failure!.key, 'core.engine.binary_missing');
      expect(sora.history, hasLength(1));
      await sora.disconnect();
      expect(sora.phase, Phase.off);
    });

    test('disconnect retries a busy core without duplicate notices', () async {
      await sora.connect();
      core.busyReplies = 2;
      await sora.disconnect();
      expect(core.disconnects, 3);
      expect(sora.phase, Phase.off);
      expect(sora.history, isEmpty);
    });

    test('events from a replaced session cannot change the new session', () async {
      await sora.connect();
      final old = sora.sessionId!;
      await sora.connect();
      final current = sora.sessionId;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      core.events.add(
        CoreEvent(
          sessionId: old,
          stateChanged: StateChanged(
            state: ConnectionState(
              sessionId: old,
              value: ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED,
              reason: SoraErrorCode.SORA_ERROR_CODE_UNAVAILABLE,
            ),
          ),
        ),
      );
      core.events.add(
        CoreEvent(
          stateChanged: StateChanged(
            state: ConnectionState(sessionId: old, value: ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(sora.phase, Phase.connected);
      expect(sora.sessionId, current);
      expect(sora.history, isEmpty);
    });

    test('a failed cleanup stays retryable even when the engine is already off', () async {
      await sora.connect();
      core.failCleanup = true;
      await sora.disconnect();
      expect(sora.phase, Phase.off);
      expect(sora.cleanupPending, isTrue);
      core.failCleanup = false;
      await sora.toggle();
      expect(core.connects, 1);
      expect(core.disconnects, 2);
      expect(sora.cleanupPending, isFalse);
      expect(sora.phase, Phase.off);
    });

    test('kill-switch clicks during connect apply only the final requested value', () async {
      core.gate = Completer<void>();
      final start = sora.connect();
      await until(() => core.connects == 1);
      await Future.wait(List.generate(31, (i) => sora.setKillSwitch(i.isEven)));
      expect(core.kills, isEmpty);
      core.gate!.complete();
      await start;
      expect(core.kills, [true]);
      await sora.disconnect();
      expect(sora.phase, Phase.off);
    });

    test('a failed startup with retained settings offers disconnect before another start', () async {
      core.failStartCleanup = true;
      await sora.connect();
      expect(sora.phase, Phase.off);
      expect(sora.cleanupPending, isTrue);
      expect(sora.failure!.key, 'core.guard.restore_failed');
      await sora.toggle();
      expect(core.connects, 1);
      expect(core.disconnects, 1);
      expect(sora.cleanupPending, isFalse);
      expect(sora.phase, Phase.off);
    });

    test('closing the app during startup does not publish late notices', () async {
      core.gate = Completer<void>();
      final start = sora.connect();
      await until(() => core.connects == 1);
      sora.dispose();
      disposed = true;
      core.gate!.complete();
      await start;
      await running.timeout(const Duration(seconds: 5));
      expect(sora.history, isEmpty);
    });
  }, skip: isolated ? false : 'run with SORA_CORE_SOCKET=/tmp/sora-race-unique.sock');
}
