// Pin test for the hand-written protobuf stubs in
// lib/src/generated/sora/core/v1/core_control.pb.dart.
//
// Precedent: BenchmarkServersRequest once carried shifted wire tags and was
// dead on the wire; the feature-wave messages (F2 history, F6 overrides, F5
// profiles, F8 chains) and CoreEvent.profile_matched were added the same way.
// This test pins every field number of those messages against the .proto
// schema by encoding a single set field and asserting the exact tag varint
// that must lead the buffer. If a tag drifts, the core will misread or drop
// the field, so any failure here is a wire-compatibility break.

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/protobuf.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';

/// Encodes [message] after applying [setOne] and asserts the buffer starts
/// with the tag varint for [fieldNumber] of [wireType] (0 = varint, 2 = LEN).
void expectFirstTag(
    GeneratedMessage Function() create, void Function(GeneratedMessage) setOne,
    int fieldNumber, int wireType, String label) {
  final message = create();
  setOne(message);
  final bytes = message.writeToBuffer();
  var tag = (fieldNumber << 3) | wireType;
  final expected = <int>[];
  do {
    var b = tag & 0x7f;
    tag >>= 7;
    if (tag != 0) b |= 0x80;
    expected.add(b);
  } while (tag != 0);
  expect(bytes.sublist(0, expected.length), expected,
      reason: '$label: field #$fieldNumber wire tag drifted');
}

void main() {
  group('wave F2: benchmark history', () {
    test('GetBenchmarksRequest tags', () {
      expectFirstTag(() => GetBenchmarksRequest(), (m) => (m as GetBenchmarksRequest).serverIds.add('s1'), 3, 2,
          'GetBenchmarksRequest.server_ids');
      expectFirstTag(() => GetBenchmarksRequest(),
          (m) => (m as GetBenchmarksRequest).controlAuthenticator = [1, 2], 2, 2,
          'GetBenchmarksRequest.control_authenticator');
    });
    test('GetBenchmarksResponse tags', () {
      expectFirstTag(() => GetBenchmarksResponse(),
          (m) => (m as GetBenchmarksResponse).benchmarks.add(BenchmarkRecord()), 1, 2,
          'GetBenchmarksResponse.benchmarks');
      expectFirstTag(() => GetBenchmarksResponse(),
          (m) => (m as GetBenchmarksResponse).error = SoraError(), 2, 2,
          'GetBenchmarksResponse.error');
    });
    test('BenchmarkRecord tags', () {
      expectFirstTag(() => BenchmarkRecord(), (m) => (m as BenchmarkRecord).serverId = 's1', 1, 2,
          'BenchmarkRecord.server_id');
      expectFirstTag(() => BenchmarkRecord(),
          (m) => (m as BenchmarkRecord).bytesPerSec = Int64(1000), 2, 0,
          'BenchmarkRecord.bytes_per_sec');
      expectFirstTag(() => BenchmarkRecord(), (m) => (m as BenchmarkRecord).latencyMs = 42, 3, 0,
          'BenchmarkRecord.latency_ms');
      expectFirstTag(() => BenchmarkRecord(),
          (m) => (m as BenchmarkRecord).measuredAtUnix = Int64(1700000000), 4, 0,
          'BenchmarkRecord.measured_at_unix');
    });
  });

  group('wave F6: subscription overrides', () {
    test('SaveSubscriptionOverrideRequest tags', () {
      expectFirstTag(() => SaveSubscriptionOverrideRequest(),
          (m) => (m as SaveSubscriptionOverrideRequest).subscriptionId = 'sub', 3, 2,
          'SaveSubscriptionOverrideRequest.subscription_id');
      expectFirstTag(() => SaveSubscriptionOverrideRequest(),
          (m) => (m as SaveSubscriptionOverrideRequest).renames['s1'] = 'Home', 4, 2,
          'SaveSubscriptionOverrideRequest.renames');
      expectFirstTag(() => SaveSubscriptionOverrideRequest(),
          (m) => (m as SaveSubscriptionOverrideRequest).hidden.add('s2'), 5, 2,
          'SaveSubscriptionOverrideRequest.hidden');
      expectFirstTag(() => SaveSubscriptionOverrideRequest(),
          (m) => (m as SaveSubscriptionOverrideRequest).pinnedOrder.add('s1'), 6, 2,
          'SaveSubscriptionOverrideRequest.pinned_order');
      expectFirstTag(() => SaveSubscriptionOverrideRequest(),
          (m) => (m as SaveSubscriptionOverrideRequest).clear_7 = true, 7, 0,
          'SaveSubscriptionOverrideRequest.clear');
    });
    test('renames map round-trips', () {
      final request = SaveSubscriptionOverrideRequest()
        ..renames['srv-1'] = 'Home'
        ..renames['srv-2'] = 'Work';
      final back = SaveSubscriptionOverrideRequest.fromBuffer(request.writeToBuffer());
      expect(back.renames, {'srv-1': 'Home', 'srv-2': 'Work'});
    });
    test('SaveSubscriptionOverrideResponse tags', () {
      expectFirstTag(() => SaveSubscriptionOverrideResponse(),
          (m) => (m as SaveSubscriptionOverrideResponse).error = SoraError(), 1, 2,
          'SaveSubscriptionOverrideResponse.error');
      expectFirstTag(() => SaveSubscriptionOverrideResponse(),
          (m) => (m as SaveSubscriptionOverrideResponse).state = SubscriptionState(), 2, 2,
          'SaveSubscriptionOverrideResponse.state');
    });
    test('GetSubscriptionOverrideRequest tags', () {
      expectFirstTag(() => GetSubscriptionOverrideRequest(),
          (m) => (m as GetSubscriptionOverrideRequest).subscriptionId = 'sub', 3, 2,
          'GetSubscriptionOverrideRequest.subscription_id');
    });
    test('GetSubscriptionOverrideResponse tags', () {
      expectFirstTag(() => GetSubscriptionOverrideResponse(),
          (m) => (m as GetSubscriptionOverrideResponse).renames['s1'] = 'Home', 1, 2,
          'GetSubscriptionOverrideResponse.renames');
      expectFirstTag(() => GetSubscriptionOverrideResponse(),
          (m) => (m as GetSubscriptionOverrideResponse).hidden.add('s2'), 2, 2,
          'GetSubscriptionOverrideResponse.hidden');
      expectFirstTag(() => GetSubscriptionOverrideResponse(),
          (m) => (m as GetSubscriptionOverrideResponse).pinnedOrder.add('s1'), 3, 2,
          'GetSubscriptionOverrideResponse.pinned_order');
      expectFirstTag(() => GetSubscriptionOverrideResponse(),
          (m) => (m as GetSubscriptionOverrideResponse).extraRules.add(OverrideRule()), 4, 2,
          'GetSubscriptionOverrideResponse.extra_rules');
      expectFirstTag(() => GetSubscriptionOverrideResponse(),
          (m) => (m as GetSubscriptionOverrideResponse).error = SoraError(), 5, 2,
          'GetSubscriptionOverrideResponse.error');
      expectFirstTag(() => GetSubscriptionOverrideResponse(),
          (m) => (m as GetSubscriptionOverrideResponse).providerRouting.add(OverrideRule()), 6, 2,
          'GetSubscriptionOverrideResponse.provider_routing');
    });
    test('OverrideRule tags', () {
      expectFirstTag(() => OverrideRule(), (m) => (m as OverrideRule).destination = 'geosite:ads', 1, 2,
          'OverrideRule.destination');
      expectFirstTag(() => OverrideRule(), (m) => (m as OverrideRule).outboundId = 'direct', 2, 2,
          'OverrideRule.outbound_id');
    });
  });

  group('wave F5: network profiles', () {
    test('ProfileMatched tags (incl. CoreEvent oneof)', () {
      expectFirstTag(() => ProfileMatched(), (m) => (m as ProfileMatched).profileId = 'p1', 1, 2,
          'ProfileMatched.profile_id');
      expectFirstTag(() => ProfileMatched(), (m) => (m as ProfileMatched).profileName = 'Home', 2, 2,
          'ProfileMatched.profile_name');
      expectFirstTag(() => ProfileMatched(), (m) => (m as ProfileMatched).autoApply = true, 3, 0,
          'ProfileMatched.auto_apply');
      final event = CoreEvent()..profileMatched = (ProfileMatched()..profileId = 'p1');
      expect(event.whichPayload(), CoreEvent_Payload.profileMatched);
      final bytes = event.writeToBuffer();
      // field 12, LEN: tag varint is 0x62.
      expect(bytes[0], 0x62, reason: 'CoreEvent.profile_matched must be field #12');
      final back = CoreEvent.fromBuffer(bytes);
      expect(back.whichPayload(), CoreEvent_Payload.profileMatched);
      expect(back.profileMatched.profileId, 'p1');
    });
    test('NetworkProfile tags', () {
      expectFirstTag(() => NetworkProfile(), (m) => (m as NetworkProfile).id = 'p1', 1, 2,
          'NetworkProfile.id');
      expectFirstTag(() => NetworkProfile(), (m) => (m as NetworkProfile).name = 'Home', 2, 2,
          'NetworkProfile.name');
      expectFirstTag(() => NetworkProfile(),
          (m) => (m as NetworkProfile).triggers = ProfileTriggers(), 3, 2,
          'NetworkProfile.triggers');
      expectFirstTag(
          () => NetworkProfile(), (m) => (m as NetworkProfile).apply = ProfileApply(), 4, 2,
          'NetworkProfile.apply');
      expectFirstTag(() => NetworkProfile(), (m) => (m as NetworkProfile).autoApply = true, 5, 0,
          'NetworkProfile.auto_apply');
    });
    test('ProfileTriggers tags', () {
      expectFirstTag(() => ProfileTriggers(), (m) => (m as ProfileTriggers).ssids.add('Home'), 1, 2,
          'ProfileTriggers.ssids');
      expectFirstTag(() => ProfileTriggers(),
          (m) => (m as ProfileTriggers).gateways.add('192.168.1.1'), 2, 2,
          'ProfileTriggers.gateways');
      expectFirstTag(() => ProfileTriggers(), (m) => (m as ProfileTriggers).asns.add('12389'), 3, 2,
          'ProfileTriggers.asns');
    });
    test('ProfileApply tags', () {
      expectFirstTag(() => ProfileApply(), (m) => (m as ProfileApply).mode = 'tun', 1, 2,
          'ProfileApply.mode');
      expectFirstTag(() => ProfileApply(), (m) => (m as ProfileApply).dns.add('1.1.1.1'), 2, 2,
          'ProfileApply.dns');
      expectFirstTag(() => ProfileApply(), (m) => (m as ProfileApply).rulesPreset = 'ru', 3, 2,
          'ProfileApply.rules_preset');
      expectFirstTag(() => ProfileApply(), (m) => (m as ProfileApply).serverId = 's1', 4, 2,
          'ProfileApply.server_id');
      expectFirstTag(() => ProfileApply(), (m) => (m as ProfileApply).engine = 'sing-box', 5, 2,
          'ProfileApply.engine');
    });
    test('ListProfiles RPC messages', () {
      expectFirstTag(() => ListProfilesRequest(),
          (m) => (m as ListProfilesRequest).controlAuthenticator = [9], 2, 2,
          'ListProfilesRequest.control_authenticator');
      expectFirstTag(() => ListProfilesResponse(),
          (m) => (m as ListProfilesResponse).profiles.add(NetworkProfile()), 1, 2,
          'ListProfilesResponse.profiles');
      expectFirstTag(() => ListProfilesResponse(),
          (m) => (m as ListProfilesResponse).error = SoraError(), 2, 2,
          'ListProfilesResponse.error');
    });
    test('SaveProfile RPC messages', () {
      expectFirstTag(() => SaveProfileRequest(),
          (m) => (m as SaveProfileRequest).profile = NetworkProfile(), 3, 2,
          'SaveProfileRequest.profile');
      expectFirstTag(() => SaveProfileResponse(),
          (m) => (m as SaveProfileResponse).profile = NetworkProfile(), 1, 2,
          'SaveProfileResponse.profile');
    });
    test('DeleteProfile RPC messages', () {
      expectFirstTag(() => DeleteProfileRequest(),
          (m) => (m as DeleteProfileRequest).profileId = 'p1', 3, 2,
          'DeleteProfileRequest.profile_id');
      final response = DeleteProfileResponse()..error = SoraError();
      expect(response.hasError(), isTrue);
    });
    test('GetNetworkFingerprint RPC messages', () {
      final response = GetNetworkFingerprintResponse()
        ..fingerprint = (NetworkFingerprint()
          ..ssid = 'Home'
          ..gateway = '192.168.1.1'
          ..asn = '12389'
          ..fingerprint = 'fp');
      final back = GetNetworkFingerprintResponse.fromBuffer(response.writeToBuffer());
      expect(back.fingerprint.ssid, 'Home');
      expect(back.fingerprint.fingerprint, 'fp');
      expectFirstTag(() => GetNetworkFingerprintResponse(),
          (m) => (m as GetNetworkFingerprintResponse).fingerprint = NetworkFingerprint(), 1, 2,
          'GetNetworkFingerprintResponse.fingerprint');
      expectFirstTag(() => NetworkFingerprint(), (m) => (m as NetworkFingerprint).ssid = 'x', 1, 2,
          'NetworkFingerprint.ssid');
      expectFirstTag(() => NetworkFingerprint(), (m) => (m as NetworkFingerprint).gateway = 'x', 2, 2,
          'NetworkFingerprint.gateway');
      expectFirstTag(() => NetworkFingerprint(), (m) => (m as NetworkFingerprint).asn = 'x', 3, 2,
          'NetworkFingerprint.asn');
      expectFirstTag(() => NetworkFingerprint(), (m) => (m as NetworkFingerprint).fingerprint = 'x',
          4, 2, 'NetworkFingerprint.fingerprint');
    });
  });

  group('wave F8: proxy chains', () {
    test('ProbeChainRequest tags', () {
      expectFirstTag(() => ProbeChainRequest(),
          (m) => (m as ProbeChainRequest).requestId = 'r1', 3, 2,
          'ProbeChainRequest.request_id');
      expectFirstTag(() => ProbeChainRequest(),
          (m) => (m as ProbeChainRequest).serverIds.add('s1'), 4, 2,
          'ProbeChainRequest.server_ids');
    });
    test('ProbeChainResponse tags', () {
      expectFirstTag(() => ProbeChainResponse(),
          (m) => (m as ProbeChainResponse).hops.add(ChainHop()), 1, 2,
          'ProbeChainResponse.hops');
      expectFirstTag(() => ProbeChainResponse(),
          (m) => (m as ProbeChainResponse).totalLatencyMs = 120, 2, 0,
          'ProbeChainResponse.total_latency_ms');
      expectFirstTag(() => ProbeChainResponse(),
          (m) => (m as ProbeChainResponse).engines.add('sing-box'), 3, 2,
          'ProbeChainResponse.engines');
      expectFirstTag(() => ProbeChainResponse(),
          (m) => (m as ProbeChainResponse).error = SoraError(), 4, 2,
          'ProbeChainResponse.error');
    });
    test('ChainHop tags', () {
      expectFirstTag(() => ChainHop(), (m) => (m as ChainHop).serverId = 's1', 1, 2,
          'ChainHop.server_id');
      expectFirstTag(() => ChainHop(), (m) => (m as ChainHop).reachable = true, 2, 0,
          'ChainHop.reachable');
      expectFirstTag(() => ChainHop(), (m) => (m as ChainHop).latencyMs = 42, 3, 0,
          'ChainHop.latency_ms');
    });
  });

  group('API 1.12: fast server switch', () {
    test('GroupSpec.selected is field #7', () {
      expectFirstTag(() => GroupSpec(), (m) => (m as GroupSpec).selected = 's1', 7, 2,
          'GroupSpec.selected');
      final back = GroupSpec.fromBuffer((GroupSpec()..selected = 'srv-2').writeToBuffer());
      expect(back.selected, 'srv-2');
    });
    test('SelectServerRequest tags', () {
      expectFirstTag(() => SelectServerRequest(),
          (m) => (m as SelectServerRequest).apiVersion = ApiVersion(), 1, 2,
          'SelectServerRequest.api_version');
      expectFirstTag(() => SelectServerRequest(),
          (m) => (m as SelectServerRequest).controlAuthenticator = [1, 2], 2, 2,
          'SelectServerRequest.control_authenticator');
      expectFirstTag(() => SelectServerRequest(),
          (m) => (m as SelectServerRequest).requestId = 'r1', 3, 2,
          'SelectServerRequest.request_id');
      expectFirstTag(() => SelectServerRequest(),
          (m) => (m as SelectServerRequest).sessionId = 's1', 4, 2,
          'SelectServerRequest.session_id');
      expectFirstTag(() => SelectServerRequest(), (m) => (m as SelectServerRequest).group = 'sora:pick',
          5, 2, 'SelectServerRequest.group');
      expectFirstTag(() => SelectServerRequest(), (m) => (m as SelectServerRequest).target = 'srv-1',
          6, 2, 'SelectServerRequest.target');
    });
    test('SelectServerResponse tags', () {
      expectFirstTag(() => SelectServerResponse(),
          (m) => (m as SelectServerResponse).status = SessionStatus(), 1, 2,
          'SelectServerResponse.status');
      expectFirstTag(() => SelectServerResponse(),
          (m) => (m as SelectServerResponse).error = SoraError(), 2, 2,
          'SelectServerResponse.error');
    });
    test('SelectServer round-trips', () {
      final request = SelectServerRequest()
        ..group = 'sora:pick'
        ..target = 'srv-9';
      final back = SelectServerRequest.fromBuffer(request.writeToBuffer());
      expect(back.group, 'sora:pick');
      expect(back.target, 'srv-9');
    });
  });

  group('previously covered fields still pinned', () {
    test('SessionPlan.zapret_strategy is field #17', () {
      final plan = SessionPlan()..zapretStrategy = (BypassStrategy()..disorder = true);
      final bytes = plan.writeToBuffer();
      // field 17, LEN: tag varint is 0x8A 0x01.
      expect(bytes.sublist(0, 2), [0x8a, 0x01]);
      final back = SessionPlan.fromBuffer(bytes);
      expect(back.hasZapretStrategy(), isTrue);
      expect(back.zapretStrategy.disorder, isTrue);
    });
    test('BenchmarkServersRequest tags (precedent)', () {
      expectFirstTag(() => BenchmarkServersRequest(),
          (m) => (m as BenchmarkServersRequest).serverIds.add('s1'), 4, 2,
          'BenchmarkServersRequest.server_ids');
      expectFirstTag(() => BenchmarkServersRequest(),
          (m) => (m as BenchmarkServersRequest).durationS = 10, 5, 0,
          'BenchmarkServersRequest.duration_s');
      expectFirstTag(() => BenchmarkServersRequest(),
          (m) => (m as BenchmarkServersRequest).url = 'https://example.test', 7, 2,
          'BenchmarkServersRequest.url');
    });
  });

  group('BypassStrategy full field set (contract: 29 fields)', () {
    test('BypassStrategy tags 8-29', () {
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).disorderScope = 'tls', 8, 2,
          'BypassStrategy.disorder_scope');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).oobScope = 'http', 9, 2,
          'BypassStrategy.oob_scope');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).hostDot = true, 10, 0,
          'BypassStrategy.host_dot');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).hostTab = true, 11, 0,
          'BypassStrategy.host_tab');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).hostNoSpace = true, 12, 0,
          'BypassStrategy.host_no_space');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).methodSpace = true, 13, 0,
          'BypassStrategy.method_space');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).unixEol = true, 14, 0,
          'BypassStrategy.unix_eol');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).splitAnyProtocol = true, 15, 0,
          'BypassStrategy.split_any_protocol');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).tamperStart = 'n1', 16, 2,
          'BypassStrategy.tamper_start');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).tamperCutoff = '10', 17, 2,
          'BypassStrategy.tamper_cutoff');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).oobData = '0x41', 18, 2,
          'BypassStrategy.oob_data');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).mss = '1200', 19, 2,
          'BypassStrategy.mss');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).desync.add('fake'), 20, 2,
          'BypassStrategy.desync');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).fakeTls = 'tls', 21, 2,
          'BypassStrategy.fake_tls');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).fakeQuic = 'quic.bin', 22, 2,
          'BypassStrategy.fake_quic');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).fooling = 'badseq', 23, 2,
          'BypassStrategy.fooling');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).ttl = 8, 24, 0, 'BypassStrategy.ttl');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).autoTtl = true, 25, 0,
          'BypassStrategy.auto_ttl');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).repeats = 3, 26, 0,
          'BypassStrategy.repeats');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).filterTcp = '80,443', 27, 2,
          'BypassStrategy.filter_tcp');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).filterUdp = '443', 28, 2,
          'BypassStrategy.filter_udp');
      expectFirstTag(() => BypassStrategy(), (m) => (m as BypassStrategy).filterL7 = 'tls,quic', 29, 2,
          'BypassStrategy.filter_l7');
    });
    test('BypassStrategy new fields round-trip', () {
      final strategy = BypassStrategy()
        ..disorderScope = 'tls'
        ..hostDot = true
        ..tamperStart = 'n1'
        ..desync.addAll(['fake', 'split2'])
        ..fakeQuic = 'quic.bin'
        ..ttl = 8
        ..autoTtl = true
        ..repeats = 3
        ..filterL7 = 'tls,quic';
      final back = BypassStrategy.fromBuffer(strategy.writeToBuffer());
      expect(back.disorderScope, 'tls');
      expect(back.hostDot, isTrue);
      expect(back.tamperStart, 'n1');
      expect(back.desync, ['fake', 'split2']);
      expect(back.fakeQuic, 'quic.bin');
      expect(back.ttl, 8);
      expect(back.autoTtl, isTrue);
      expect(back.repeats, 3);
      expect(back.filterL7, 'tls,quic');
    });
  });
}
