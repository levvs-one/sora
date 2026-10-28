import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show Server, ServiceCall;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/main.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/generated/sora/custom/v1/custom.pbgrpc.dart';
import 'package:sora/src/sora.dart';
import 'package:flutter/material.dart' show ValueKey;

class _ProtectionCore extends CoreControlServiceBase {
  bool strict = false;
  bool reject = false;
  bool reconnect = false;
  int minor = 12;
  ConnectionState state = ConnectionState(value: ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED);
  final changes = <SetKillSwitchRequest>[];
  final events = StreamController<CoreEvent>.broadcast();
  Future<void> close() => events.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');

  @override
  Future<HandshakeResponse> handshake(ServiceCall call, HandshakeRequest request) async =>
      HandshakeResponse(negotiatedVersion: ApiVersion(major: 1, minor: minor));
  @override
  Future<GetAboutResponse> getAbout(ServiceCall call, GetAboutRequest request) async => GetAboutResponse(
    about: About(
      contract: ApiVersion(major: 1, minor: minor, capabilities: ['strict-kill-switch']),
    ),
  );
  @override
  Future<GetStatusResponse> getStatus(ServiceCall call, GetStatusRequest request) async => GetStatusResponse(
    status: SessionStatus(connection: state, strictKillSwitch: strict, killSwitch: strict),
  );
  @override
  Stream<SubscriptionState> watchSubscriptions(ServiceCall call, WatchSubscriptionsRequest request) => Stream.value(
    SubscriptionState(
      outbounds: [
        OutboundSpec(
          id: 'server',
          protocol: 'socks5',
          endpoint: Endpoint(host: '203.0.113.2', port: 443),
        ),
      ],
    ),
  );
  @override
  Stream<CoreEvent> watchEvents(ServiceCall call, WatchEventsRequest request) => events.stream;
  @override
  Future<ConnectResponse> connect(ServiceCall call, ConnectRequest request) async {
    strict = request.strictKillSwitch;
    reconnect = request.reconnect;
    state = ConnectionState(value: ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTED, sessionId: 'strict-session');
    return ConnectResponse(
      status: SessionStatus(connection: state, strictKillSwitch: strict, killSwitch: strict),
    );
  }

  @override
  Future<DisconnectResponse> disconnect(ServiceCall call, DisconnectRequest request) async {
    strict = false;
    state = ConnectionState(value: ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED);
    return DisconnectResponse(status: SessionStatus(connection: state));
  }

  @override
  Future<SetKillSwitchResponse> setKillSwitch(ServiceCall call, SetKillSwitchRequest request) async {
    changes.add(request);
    if (reject) return SetKillSwitchResponse(error: SoraError(userMessageKey: 'core.guard.firewall_failed'));
    strict = request.strict;
    return SetKillSwitchResponse(enabled: request.enabled, strict: strict);
  }
}

class _EmptyCustomServers extends CustomServersServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
  @override
  Future<ListCustomServersResponse> listCustomServers(ServiceCall call, ListCustomServersRequest request) async =>
      ListCustomServersResponse();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  testWidgets('mode panel exposes an opt-in strict switch and its warning', (tester) async {
    final settings = await Settings.load();
    await settings.completeTour();
    settings.animations = false;
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    expect(settings.strictKillSwitch, isFalse);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.tap(find.byKey(const ValueKey('mode-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('advanced-protection')));
    await tester.pumpAndSettle();
    expect(find.text(sora.strings.strictKillSwitchWarning), findsNothing);
    expect(find.byKey(ValueKey('info-${sora.strings.strictKillSwitch}')), findsNothing);
    await tester.tap(find.text(sora.strings.strictKillSwitch));
    await tester.pumpAndSettle();
    expect(find.text(sora.strings.strictKillSwitchWarning), findsOneWidget);
    expect(settings.strictKillSwitch, isFalse);
    await tester.tap(find.text(sora.strings.cancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(sora.strings.strictKillSwitch));
    await tester.pumpAndSettle();
    expect(settings.strictKillSwitch, isFalse);
    await tester.tap(find.text(sora.strings.strictKillSwitch).last);
    await tester.pumpAndSettle();
    expect(settings.strictKillSwitch, isTrue);
    expect(settings.killSwitch, isTrue);
  });

  final socket = Platform.environment['SORA_CORE_SOCKET'];
  test('strict RPC preference, reconnect intent, error toast and release after core restart', () async {
    final core = _ProtectionCore();
    final server = Server.create(services: [core, _EmptyCustomServers()]);
    await server.serve(address: InternetAddress(socket!, type: InternetAddressType.unix), port: 0);
    final settings = await Settings.load();
    final sora = Sora(settings);
    final running = sora.run();
    Future<void> until(bool Function() ready) async {
      final limit = DateTime.now().add(const Duration(seconds: 5));
      while (!ready()) {
        if (DateTime.now().isAfter(limit)) fail('RPC state timed out');
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    try {
      await until(() => sora.coreHandshakeDone && sora.servers.isNotEmpty);
      await sora.setStrictKillSwitch(true);
      settings.connectOnStart = true;
      await sora.connect();
      expect(core.strict, isTrue);
      expect(core.reconnect, isTrue);
      final notices = <Object>[];
      final subscription = sora.messages.listen(notices.add);
      core.reject = true;
      await sora.setStrictKillSwitch(false);
      expect(settings.strictKillSwitch, isTrue);
      await until(() => notices.isNotEmpty);
      core.reject = false;
      await sora.setStrictKillSwitch(false);
      expect(core.strict, isFalse);
      expect(settings.killSwitch, isFalse);
      await subscription.cancel();
      await sora.setStrictKillSwitch(true);
      await sora.disconnect();
      expect(core.strict, isFalse);
      core.strict = true;
      sora.strictBlocked = true;
      await sora.setStrictKillSwitch(false);
      expect(core.strict, isFalse);
      expect(core.changes.last.sessionId, isEmpty);
    } finally {
      await sora.disconnect();
      await core.close();
      sora.dispose();
      await running.timeout(const Duration(seconds: 10));
      await server.shutdown();
      if (await File(socket).exists()) await File(socket).delete();
    }
  }, skip: socket == null || !socket.startsWith('/tmp/sora-race-'));
}
