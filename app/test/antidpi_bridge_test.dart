import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/ext/bridge.dart';
import 'package:sora/src/ext/bypass.dart';
import 'package:sora/src/ext/bypass_host.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

PanelBridge bridge({
  Set<String> granted = const {},
  Future<Map<String, dynamic>> Function()? capabilities,
  Future<Map<String, dynamic>> Function()? state,
  Future<Map<String, dynamic>> Function()? layer,
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? apply,
  Future<Map<String, dynamic>> Function(String)? tune,
}) {
  return PanelBridge(
    extensionId: 'com.example.antidpi',
    granted: granted,
    getConnections: () async => const [],
    servers: () => const [],
    notify: (_, _) async {},
    getSettings: () async => const {},
    setSettings: (_) async {},
    getBypassCapabilities:
        capabilities ?? () async => {'platform': 'linux', 'backends': const <Map<String, dynamic>>[]},
    getBypassState: state ?? () async => {'platform': 'linux'},
    getBypassLayer: layer ?? () async => {'global': null, 'bindings': const <Map<String, dynamic>>[]},
    applyBypassLayer: apply ?? (_) async => {'updated_at': '2026-10-21T00:00:00.000Z'},
    tuneDesync: tune ?? (_) async => {'winner_id': 'w', 'strategy': null},
  );
}

Future<Map<String, dynamic>> call(PanelBridge b, String method, [Map<String, dynamic> args = const {}]) async {
  final reply =
      jsonDecode(await b.handle(jsonEncode({'id': 7, 'method': method, 'args': args}))) as Map<String, dynamic>;
  return reply;
}

/// A strategy with a distinctive value in every one of the 29 fields.
BypassStrategy fullStrategy() => BypassStrategy(
  splitPos: ['1', 'midsld'],
  disorder: true,
  oob: true,
  tlsRecord: 'sniext',
  hostCase: true,
  domainCase: true,
  methodEol: true,
  disorderScope: 'tls',
  oobScope: 'http',
  hostDot: true,
  hostTab: true,
  hostNoSpace: true,
  methodSpace: true,
  unixEol: true,
  splitAnyProtocol: true,
  tamperStart: 'n1',
  tamperCutoff: 'n5',
  oobData: 'x',
  mss: '1200',
  desync: ['fake', 'split2'],
  fakeTls: 'tls',
  fakeQuic: 'quic.bin',
  fooling: 'badseq',
  ttl: 7,
  autoTtl: true,
  repeats: 3,
  filterTcp: '80,443',
  filterUdp: '443',
  filterL7: 'tls,quic',
);

void main() {
  group('bypass strategy JSON conversion', () {
    test('round-trips all 29 fields losslessly', () {
      final json = bypassStrategyToJson(fullStrategy());
      expect(json.keys.toSet(), {
        'split_pos',
        'disorder',
        'oob',
        'tls_record',
        'host_case',
        'domain_case',
        'method_eol',
        'disorder_scope',
        'oob_scope',
        'host_dot',
        'host_tab',
        'host_no_space',
        'method_space',
        'unix_eol',
        'split_any_protocol',
        'tamper_start',
        'tamper_cutoff',
        'oob_data',
        'mss',
        'desync',
        'fake_tls',
        'fake_quic',
        'fooling',
        'ttl',
        'auto_ttl',
        'repeats',
        'filter_tcp',
        'filter_udp',
        'filter_l7',
      });
      expect(json, bypassStrategyToJson(bypassStrategyFromJson(json)));
    });

    test('missing fields take proto defaults', () {
      final s = bypassStrategyFromJson(const {});
      expect(s.splitPos, isEmpty);
      expect(s.disorder, isFalse);
      expect(s.ttl, 0);
      expect(bypassStrategyToJson(s).length, 29);
    });

    test('unknown fields and wrong types are rejected', () {
      expect(() => bypassStrategyFromJson({'bogus': 1}), throwsFormatException);
      expect(() => bypassStrategyFromJson({'ttl': 'seven'}), throwsFormatException);
      expect(() => bypassStrategyFromJson({'disorder': 'yes'}), throwsFormatException);
      expect(() => bypassStrategyFromJson({'split_pos': '1'}), throwsFormatException);
    });

    test('layer round-trips global and bindings', () {
      final layer = bypassLayerToJson(
        global: fullStrategy(),
        bindings: [
          (match: 'domain:example.com', strategy: BypassStrategy(splitPos: ['2'])),
        ],
        updatedAt: DateTime.utc(2026, 10, 21),
      );
      final parsed = bypassLayerFromJson(layer);
      expect(bypassStrategyToJson(parsed.global!), bypassStrategyToJson(fullStrategy()));
      expect(parsed.bindings.single.match, 'domain:example.com');
      expect(parsed.bindings.single.strategy.splitPos, ['2']);
      expect(layer['updated_at'], '2026-10-21T00:00:00.000Z');
      expect(
        () => bypassLayerFromJson({
          'bindings': <Map<String, dynamic>>[
            {'match': '', 'strategy': <String, dynamic>{}},
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('bridge bypass gating', () {
    test('applyBypassLayer without bypass.write is permission-denied', () async {
      final b = bridge(granted: {'bypass.read'});
      final reply = await call(b, 'applyBypassLayer', {'global': null, 'bindings': <dynamic>[]});
      expect(reply['ok'], isFalse);
      expect(reply['error'], 'permission-denied');
    });

    test('reads without bypass.read and tune without bypass.tune are denied', () async {
      final b = bridge(granted: {'bypass.write'});
      for (final m in ['getBypassCapabilities', 'getBypassState', 'getBypassLayer']) {
        final reply = await call(b, m);
        expect(reply['error'], 'permission-denied', reason: m);
      }
      final tune = await call(b, 'tuneDesync', {'engine': 'nfqws'});
      expect(tune['error'], 'permission-denied');
    });

    test('granted methods dispatch and return their shapes', () async {
      final b = bridge(granted: {'bypass.read', 'bypass.write', 'bypass.tune'});
      expect((await call(b, 'getBypassCapabilities'))['ok'], isTrue);
      expect((await call(b, 'getBypassState'))['result']['platform'], 'linux');
      final tune = await call(b, 'tuneDesync', {'engine': 'nfqws'});
      expect(tune['result']['winner_id'], 'w');
    });

    test('a full strategy survives dispatch through applyBypassLayer', () async {
      Map<String, dynamic>? seen;
      final b = bridge(
        granted: {'bypass.write'},
        apply: (args) async {
          seen = args;
          // The panel host parses with the same helper the core seam uses.
          final layer = bypassLayerFromJson(args);
          return {'updated_at': '2026-10-21T00:00:00.000Z', 'echo': bypassStrategyToJson(layer.global!)};
        },
      );
      final layerJson = bypassLayerToJson(global: fullStrategy(), bindings: const []);
      final reply = await call(b, 'applyBypassLayer', layerJson);
      expect(reply['ok'], isTrue, reason: '$reply');
      expect(seen, layerJson);
      expect(reply['result']['echo'], bypassStrategyToJson(fullStrategy()));
    });

    test('tuneDesync rejects a non-string engine as invalid-argument', () async {
      final b = bridge(granted: {'bypass.tune'});
      final reply = await call(b, 'tuneDesync', {'engine': 42});
      expect(reply['error'], 'invalid-argument');
    });
  });

  group('bypass host error mapping', () {
    test('gRPC codes map to the bridge contract', () {
      expect(mapBypassHostError(GrpcError.permissionDenied('no')).code, 'permission-denied');
      expect(mapBypassHostError(GrpcError.unauthenticated('revoked')).code, 'permission-denied');
      final invalid = mapBypassHostError(GrpcError.invalidArgument('bad layer'));
      expect(invalid.code, 'invalid-argument');
      expect(invalid.message, 'bad layer');
      expect(mapBypassHostError(GrpcError.unavailable('down')).code, 'internal');
      expect(mapBypassHostError(GrpcError.unimplemented('nope')).code, 'internal');
      expect(mapBypassHostError(const FormatException('shape')).code, 'invalid-argument');
      expect(mapBypassHostError(StateError('x')).code, 'internal');
    });
  });

  group('antidpi write-through slot', () {
    late Settings settings;
    setUp(() async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      settings = await Settings.load();
    });

    test('buildPlan uses the full slot strategy for the bypass outbound', () {
      settings.antidpiStrategyJson = jsonEncode(bypassStrategyToJson(fullStrategy()));
      settings.antidpiStrategySource = 'com.example.antidpi';
      final plan = buildPlan(servers: const [], choice: 'bypass', settings: settings);
      final s = plan.outbounds.single.bypass;
      expect(bypassStrategyToJson(s), bypassStrategyToJson(fullStrategy()));
    });

    test('buildPlan uses the slot strategy for zapret-with-VPN too', () {
      settings.antidpiStrategyJson = jsonEncode(bypassStrategyToJson(fullStrategy()));
      settings.antidpiStrategySource = 'com.example.antidpi';
      final servers = [OutboundSpec(id: 'a', displayName: 'A', protocol: 'vless')];
      final plan = buildPlan(servers: servers, choice: 'a', settings: settings, zapretWithVpn: true);
      expect(bypassStrategyToJson(plan.zapretStrategy), bypassStrategyToJson(fullStrategy()));
    });

    test('a broken slot falls back to the legacy fields', () {
      settings
        ..splitPos = ['2']
        ..antidpiStrategyJson = '{"ttl": "seven"}';
      final plan = buildPlan(servers: const [], choice: 'bypass', settings: settings);
      expect(plan.outbounds.single.bypass.splitPos, ['2']);
      expect(plan.outbounds.single.bypass.ttl, 0);
    });

    test('any legacy zapret edit clears the slot (the user wins)', () {
      void seed() {
        settings.antidpiStrategyJson = jsonEncode(bypassStrategyToJson(fullStrategy()));
        settings.antidpiStrategySource = 'com.example.antidpi';
      }

      seed();
      settings.splitPos = ['3'];
      expect(settings.antidpiStrategyJson, isEmpty);
      expect(settings.antidpiStrategySource, isEmpty);

      seed();
      settings.disorder = false;
      expect(settings.antidpiStrategyJson, isEmpty);

      seed();
      settings.tlsRecord = '1';
      expect(settings.antidpiStrategyJson, isEmpty);

      seed();
      settings.hostCase = false;
      expect(settings.antidpiStrategyJson, isEmpty);
      expect(settings.antidpiStrategySource, isEmpty);
    });

    test('clearAntidpiStrategy drops both keys', () {
      settings.antidpiStrategyJson = '{}';
      settings.antidpiStrategySource = 'com.example.antidpi';
      settings.clearAntidpiStrategy();
      expect(settings.antidpiStrategyJson, isEmpty);
      expect(settings.antidpiStrategySource, isEmpty);
    });
  });
}
