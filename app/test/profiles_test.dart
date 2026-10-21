import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show Server, ServiceCall, GrpcError;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart' as wire;
import 'package:sora/src/profiles.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

class _ProfileCore extends wire.CoreControlServiceBase {
  final profiles = <String, wire.NetworkProfile>{};
  final events = StreamController<wire.CoreEvent>.broadcast();
  final subscriptions = StreamController<wire.SubscriptionState>.broadcast();
  int handshakes = 0;
  int connections = 0;
  int sequence = 0;
  wire.SessionPlan? plan;
  bool reject = false;
  Completer<void>? saveGate;
  final watched = Completer<void>();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');

  @override
  Future<wire.HandshakeResponse> handshake(ServiceCall call, wire.HandshakeRequest request) async {
    handshakes++;
    return wire.HandshakeResponse(negotiatedVersion: wire.ApiVersion(major: 1, minor: 10));
  }

  wire.SessionStatus get status => wire.SessionStatus(
    connection: wire.ConnectionState(
      value: wire.ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTED,
      sessionId: 'profile-session',
    ),
  );

  @override
  Future<wire.GetStatusResponse> getStatus(ServiceCall call, wire.GetStatusRequest request) async =>
      wire.GetStatusResponse(status: status);

  @override
  Future<wire.GetAboutResponse> getAbout(ServiceCall call, wire.GetAboutRequest request) async =>
      wire.GetAboutResponse(about: wire.About(contract: wire.ApiVersion(major: 1, minor: 10)));

  @override
  Stream<wire.SubscriptionState> watchSubscriptions(ServiceCall call, wire.WatchSubscriptionsRequest request) async* {
    yield wire.SubscriptionState(
      outbounds: [wire.OutboundSpec(id: 'server', protocol: 'socks5')],
    );
    yield* subscriptions.stream;
  }

  @override
  Stream<wire.CoreEvent> watchEvents(ServiceCall call, wire.WatchEventsRequest request) {
    if (!watched.isCompleted) watched.complete();
    return events.stream;
  }

  @override
  Future<wire.ListProfilesResponse> listProfiles(ServiceCall call, wire.ListProfilesRequest request) async =>
      wire.ListProfilesResponse(profiles: profiles.values);

  @override
  Future<wire.SaveProfileResponse> saveProfile(ServiceCall call, wire.SaveProfileRequest request) async {
    await saveGate?.future;
    if (reject) return wire.SaveProfileResponse(error: wire.SoraError(userMessageKey: 'core.internal.unexpected'));
    profiles[request.profile.id] = request.profile.deepCopy();
    return wire.SaveProfileResponse(profile: request.profile);
  }

  @override
  Future<wire.DeleteProfileResponse> deleteProfile(ServiceCall call, wire.DeleteProfileRequest request) async {
    profiles.remove(request.profileId);
    return wire.DeleteProfileResponse();
  }

  @override
  Future<wire.ConnectResponse> connect(ServiceCall call, wire.ConnectRequest request) async {
    connections++;
    plan = request.sessionPlan;
    return wire.ConnectResponse(status: status);
  }

  @override
  Future<wire.GetNetworkFingerprintResponse> getNetworkFingerprint(
    ServiceCall call,
    wire.GetNetworkFingerprintRequest request,
  ) async => wire.GetNetworkFingerprintResponse(fingerprint: wire.NetworkFingerprint(ssid: 'Home'));

  void match(String id) => events.add(
    wire.CoreEvent(
      sessionId: 'profile-session',
      sequence: Int64(++sequence),
      profileMatched: wire.ProfileMatched(profileId: id, autoApply: profiles[id]?.autoApply),
    ),
  );

  Future<void> close() async {
    await events.close();
    await subscriptions.close();
  }
}

Future<void> _until(bool Function() ready) async {
  final limit = DateTime.now().add(const Duration(seconds: 10));
  while (!ready()) {
    if (DateTime.now().isAfter(limit)) fail('Profile state timed out');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('profile snapshots preserve absent, empty and complete values on the wire', () {
    for (final profile in [
      NetworkProfile(id: 'empty', name: 'Empty'),
      NetworkProfile(id: 'defaults', name: 'Defaults', dns: [], preset: '', engine: '', dnsPreset: 'auto'),
      NetworkProfile(
        id: 'home',
        name: 'Home',
        ssids: ['Home'],
        gateways: ['192.168.1.1'],
        asns: ['64500'],
        autoApply: true,
        tunnel: 'proxy',
        preset: 'ru',
        dns: ['https://dns.example.com/dns-query'],
        dnsPreset: 'custom',
        engine: 'mihomo',
        serverId: 'server',
      ),
    ]) {
      final encoded = wire.NetworkProfile.fromBuffer(profile.toWire().writeToBuffer());
      expect(NetworkProfile.fromWire(encoded).toJson(), profile.toJson());
    }
  });

  final socket = Platform.environment['SORA_CORE_SOCKET'];
  test('runtime mirror, ProfileMatched apply, ask, undo and reconnect', () async {
    final core = _ProfileCore();
    core.profiles['stale'] = wire.NetworkProfile(id: 'stale', name: 'Stale');
    final server = Server.create(services: [core]);
    await server.serve(address: InternetAddress(socket!, type: InternetAddressType.unix), port: 0);
    final settings = await Settings.load();
    final profile = NetworkProfile(
      id: 'home',
      name: 'Home',
      ssids: ['Home'],
      autoApply: true,
      tunnel: 'proxy',
      preset: 'ru',
      dns: ['https://dns.example.com/dns-query'],
      dnsPreset: 'custom',
      engine: 'mihomo',
      serverId: 'server',
    );
    settings.networkProfiles = jsonEncode([profile.toJson()]);
    final sora = Sora(settings);
    final running = sora.run();
    try {
      await core.watched.future.timeout(const Duration(seconds: 10));
      await _until(() => sora.servers.isNotEmpty);
      expect(core.profiles.keys, ['home']);
      expect(NetworkProfile.fromWire(core.profiles['home']!).toJson(), profile.toJson());
      final before = settings.tunnel;
      core.match('home');
      await _until(() => sora.history.any((n) => n.action == 'undo-profile'));
      expect(settings.tunnel, 'proxy');
      expect(settings.dnsPreset, 'custom');
      expect(core.plan!.dnsPolicy.servers, profile.dns);
      expect(core.plan!.engines, ['mihomo']);
      expect(core.connections, 1);
      await sora.undoProfileApply(sora.history.firstWhere((n) => n.action == 'undo-profile').argument);
      expect(settings.tunnel, before);
      expect(core.connections, 2);

      profile.autoApply = false;
      profile.name = 'Ask first';
      sora.profiles.update(profile);
      await sora.syncProfiles();
      expect(core.profiles['home']!.autoApply, isFalse);
      core.match('home');
      await _until(() => sora.history.any((n) => n.action == 'apply-profile'));
      expect(settings.tunnel, before);
      expect(core.connections, 2);
      final notices = sora.history.length;
      await sora.refreshFingerprint();
      expect(sora.history.length, notices);
      expect(core.connections, 2);
      core.match('missing');
      await sora.syncProfiles();
      expect(sora.history.length, notices);

      core.saveGate = Completer<void>();
      sora.profiles.add(NetworkProfile(id: 'temporary', name: 'Temporary'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      sora.profiles.remove('temporary');
      core.saveGate!.complete();
      core.saveGate = null;
      await sora.syncProfiles();
      expect(core.profiles.keys, ['home']);

      core.reject = true;
      profile.name = 'Retry edit';
      sora.profiles.update(profile);
      await sora.syncProfiles();
      expect(core.profiles['home']!.name, 'Ask first');
      expect(sora.history.first.body, isNotEmpty);
      core.reject = false;
      await sora.syncProfiles();
      expect(core.profiles['home']!.name, 'Retry edit');

      settings.networkProfiles = jsonEncode([NetworkProfile(id: 'first', name: 'First').toJson(), profile.toJson()]);
      sora.profiles.reload();
      await sora.syncProfiles();
      expect(core.profiles.keys, ['first', 'home']);
      final handshakes = core.handshakes;
      core.profiles.clear();
      core.subscriptions.addError(const GrpcError.unavailable('reconnect'));
      await _until(() => core.handshakes > handshakes && core.profiles.length == 2);
      expect(core.profiles.keys, ['first', 'home']);
      sora.profiles.remove('home');
      sora.profiles.remove('first');
      await sora.syncProfiles();
      expect(core.profiles, isEmpty);
    } finally {
      sora.dispose();
      await running.timeout(const Duration(seconds: 10));
      await server.shutdown();
      await core.close();
      if (await File(socket).exists()) await File(socket).delete();
    }
  }, skip: socket == null || !socket.startsWith('/tmp/sora-race-'));
}
