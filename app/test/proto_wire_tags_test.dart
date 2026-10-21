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
  GeneratedMessage Function() create,
  void Function(GeneratedMessage) setOne,
  int fieldNumber,
  int wireType,
  String label,
) {
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
  expect(bytes.sublist(0, expected.length), expected, reason: '$label: field #$fieldNumber wire tag drifted');
}

void main() {
  group('benchmark history', () {
    test('GetBenchmarksRequest tags', () {
      expectFirstTag(
        () => GetBenchmarksRequest(),
        (m) => (m as GetBenchmarksRequest).serverIds.add('s1'),
        3,
        2,
        'GetBenchmarksRequest.server_ids',
      );
      expectFirstTag(
        () => GetBenchmarksRequest(),
        (m) => (m as GetBenchmarksRequest).controlAuthenticator = [1, 2],
        2,
        2,
        'GetBenchmarksRequest.control_authenticator',
      );
    });
    test('GetBenchmarksResponse tags', () {
      expectFirstTag(
        () => GetBenchmarksResponse(),
        (m) => (m as GetBenchmarksResponse).benchmarks.add(BenchmarkRecord()),
        1,
        2,
        'GetBenchmarksResponse.benchmarks',
      );
      expectFirstTag(
        () => GetBenchmarksResponse(),
        (m) => (m as GetBenchmarksResponse).error = SoraError(),
        2,
        2,
        'GetBenchmarksResponse.error',
      );
    });
    test('BenchmarkRecord tags', () {
      expectFirstTag(
        () => BenchmarkRecord(),
        (m) => (m as BenchmarkRecord).serverId = 's1',
        1,
        2,
        'BenchmarkRecord.server_id',
      );
      expectFirstTag(
        () => BenchmarkRecord(),
        (m) => (m as BenchmarkRecord).bytesPerSec = Int64(1000),
        2,
        0,
        'BenchmarkRecord.bytes_per_sec',
      );
      expectFirstTag(
        () => BenchmarkRecord(),
        (m) => (m as BenchmarkRecord).latencyMs = 42,
        3,
        0,
        'BenchmarkRecord.latency_ms',
      );
      expectFirstTag(
        () => BenchmarkRecord(),
        (m) => (m as BenchmarkRecord).measuredAtUnix = Int64(1700000000),
        4,
        0,
        'BenchmarkRecord.measured_at_unix',
      );
    });
  });

  group('subscription overrides', () {
    test('SaveSubscriptionOverrideRequest tags', () {
      expectFirstTag(
        () => SaveSubscriptionOverrideRequest(),
        (m) => (m as SaveSubscriptionOverrideRequest).subscriptionId = 'sub',
        3,
        2,
        'SaveSubscriptionOverrideRequest.subscription_id',
      );
      expectFirstTag(
        () => SaveSubscriptionOverrideRequest(),
        (m) => (m as SaveSubscriptionOverrideRequest).renames['s1'] = 'Home',
        4,
        2,
        'SaveSubscriptionOverrideRequest.renames',
      );
      expectFirstTag(
        () => SaveSubscriptionOverrideRequest(),
        (m) => (m as SaveSubscriptionOverrideRequest).hidden.add('s2'),
        5,
        2,
        'SaveSubscriptionOverrideRequest.hidden',
      );
      expectFirstTag(
        () => SaveSubscriptionOverrideRequest(),
        (m) => (m as SaveSubscriptionOverrideRequest).pinnedOrder.add('s1'),
        6,
        2,
        'SaveSubscriptionOverrideRequest.pinned_order',
      );
      expectFirstTag(
        () => SaveSubscriptionOverrideRequest(),
        (m) => (m as SaveSubscriptionOverrideRequest).clear_7 = true,
        7,
        0,
        'SaveSubscriptionOverrideRequest.clear',
      );
    });
    test('renames map round-trips', () {
      final request = SaveSubscriptionOverrideRequest()
        ..renames['srv-1'] = 'Home'
        ..renames['srv-2'] = 'Work';
      final back = SaveSubscriptionOverrideRequest.fromBuffer(request.writeToBuffer());
      expect(back.renames, {'srv-1': 'Home', 'srv-2': 'Work'});
    });
    test('SaveSubscriptionOverrideResponse tags', () {
      expectFirstTag(
        () => SaveSubscriptionOverrideResponse(),
        (m) => (m as SaveSubscriptionOverrideResponse).error = SoraError(),
        1,
        2,
        'SaveSubscriptionOverrideResponse.error',
      );
      expectFirstTag(
        () => SaveSubscriptionOverrideResponse(),
        (m) => (m as SaveSubscriptionOverrideResponse).state = SubscriptionState(),
        2,
        2,
        'SaveSubscriptionOverrideResponse.state',
      );
    });
    test('GetSubscriptionOverrideRequest tags', () {
      expectFirstTag(
        () => GetSubscriptionOverrideRequest(),
        (m) => (m as GetSubscriptionOverrideRequest).subscriptionId = 'sub',
        3,
        2,
        'GetSubscriptionOverrideRequest.subscription_id',
      );
    });
    test('GetSubscriptionOverrideResponse tags', () {
      expectFirstTag(
        () => GetSubscriptionOverrideResponse(),
        (m) => (m as GetSubscriptionOverrideResponse).renames['s1'] = 'Home',
        1,
        2,
        'GetSubscriptionOverrideResponse.renames',
      );
      expectFirstTag(
        () => GetSubscriptionOverrideResponse(),
        (m) => (m as GetSubscriptionOverrideResponse).hidden.add('s2'),
        2,
        2,
        'GetSubscriptionOverrideResponse.hidden',
      );
      expectFirstTag(
        () => GetSubscriptionOverrideResponse(),
        (m) => (m as GetSubscriptionOverrideResponse).pinnedOrder.add('s1'),
        3,
        2,
        'GetSubscriptionOverrideResponse.pinned_order',
      );
      expectFirstTag(
        () => GetSubscriptionOverrideResponse(),
        (m) => (m as GetSubscriptionOverrideResponse).extraRules.add(OverrideRule()),
        4,
        2,
        'GetSubscriptionOverrideResponse.extra_rules',
      );
      expectFirstTag(
        () => GetSubscriptionOverrideResponse(),
        (m) => (m as GetSubscriptionOverrideResponse).error = SoraError(),
        5,
        2,
        'GetSubscriptionOverrideResponse.error',
      );
    });
    test('OverrideRule tags', () {
      expectFirstTag(
        () => OverrideRule(),
        (m) => (m as OverrideRule).destination = 'geosite:ads',
        1,
        2,
        'OverrideRule.destination',
      );
      expectFirstTag(
        () => OverrideRule(),
        (m) => (m as OverrideRule).outboundId = 'direct',
        2,
        2,
        'OverrideRule.outbound_id',
      );
    });
  });

  group('network profiles', () {
    test('ProfileMatched tags (incl. CoreEvent oneof)', () {
      expectFirstTag(
        () => ProfileMatched(),
        (m) => (m as ProfileMatched).profileId = 'p1',
        1,
        2,
        'ProfileMatched.profile_id',
      );
      expectFirstTag(
        () => ProfileMatched(),
        (m) => (m as ProfileMatched).profileName = 'Home',
        2,
        2,
        'ProfileMatched.profile_name',
      );
      expectFirstTag(
        () => ProfileMatched(),
        (m) => (m as ProfileMatched).autoApply = true,
        3,
        0,
        'ProfileMatched.auto_apply',
      );
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
      expectFirstTag(() => NetworkProfile(), (m) => (m as NetworkProfile).id = 'p1', 1, 2, 'NetworkProfile.id');
      expectFirstTag(() => NetworkProfile(), (m) => (m as NetworkProfile).name = 'Home', 2, 2, 'NetworkProfile.name');
      expectFirstTag(
        () => NetworkProfile(),
        (m) => (m as NetworkProfile).triggers = ProfileTriggers(),
        3,
        2,
        'NetworkProfile.triggers',
      );
      expectFirstTag(
        () => NetworkProfile(),
        (m) => (m as NetworkProfile).apply = ProfileApply(),
        4,
        2,
        'NetworkProfile.apply',
      );
      expectFirstTag(
        () => NetworkProfile(),
        (m) => (m as NetworkProfile).autoApply = true,
        5,
        0,
        'NetworkProfile.auto_apply',
      );
    });
    test('ProfileTriggers tags', () {
      expectFirstTag(
        () => ProfileTriggers(),
        (m) => (m as ProfileTriggers).ssids.add('Home'),
        1,
        2,
        'ProfileTriggers.ssids',
      );
      expectFirstTag(
        () => ProfileTriggers(),
        (m) => (m as ProfileTriggers).gateways.add('192.168.1.1'),
        2,
        2,
        'ProfileTriggers.gateways',
      );
      expectFirstTag(
        () => ProfileTriggers(),
        (m) => (m as ProfileTriggers).asns.add('12389'),
        3,
        2,
        'ProfileTriggers.asns',
      );
    });
    test('ProfileApply tags', () {
      expectFirstTag(() => ProfileApply(), (m) => (m as ProfileApply).mode = 'tun', 1, 2, 'ProfileApply.mode');
      expectFirstTag(() => ProfileApply(), (m) => (m as ProfileApply).dns.add('1.1.1.1'), 2, 2, 'ProfileApply.dns');
      expectFirstTag(
        () => ProfileApply(),
        (m) => (m as ProfileApply).rulesPreset = 'ru',
        3,
        2,
        'ProfileApply.rules_preset',
      );
      expectFirstTag(() => ProfileApply(), (m) => (m as ProfileApply).serverId = 's1', 4, 2, 'ProfileApply.server_id');
      expectFirstTag(() => ProfileApply(), (m) => (m as ProfileApply).engine = 'sing-box', 5, 2, 'ProfileApply.engine');
    });
    test('ListProfiles RPC messages', () {
      expectFirstTag(
        () => ListProfilesRequest(),
        (m) => (m as ListProfilesRequest).controlAuthenticator = [9],
        2,
        2,
        'ListProfilesRequest.control_authenticator',
      );
      expectFirstTag(
        () => ListProfilesResponse(),
        (m) => (m as ListProfilesResponse).profiles.add(NetworkProfile()),
        1,
        2,
        'ListProfilesResponse.profiles',
      );
      expectFirstTag(
        () => ListProfilesResponse(),
        (m) => (m as ListProfilesResponse).error = SoraError(),
        2,
        2,
        'ListProfilesResponse.error',
      );
    });
    test('SaveProfile RPC messages', () {
      expectFirstTag(
        () => SaveProfileRequest(),
        (m) => (m as SaveProfileRequest).profile = NetworkProfile(),
        3,
        2,
        'SaveProfileRequest.profile',
      );
      expectFirstTag(
        () => SaveProfileResponse(),
        (m) => (m as SaveProfileResponse).profile = NetworkProfile(),
        1,
        2,
        'SaveProfileResponse.profile',
      );
    });
    test('DeleteProfile RPC messages', () {
      expectFirstTag(
        () => DeleteProfileRequest(),
        (m) => (m as DeleteProfileRequest).profileId = 'p1',
        3,
        2,
        'DeleteProfileRequest.profile_id',
      );
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
      expectFirstTag(
        () => GetNetworkFingerprintResponse(),
        (m) => (m as GetNetworkFingerprintResponse).fingerprint = NetworkFingerprint(),
        1,
        2,
        'GetNetworkFingerprintResponse.fingerprint',
      );
      expectFirstTag(
        () => NetworkFingerprint(),
        (m) => (m as NetworkFingerprint).ssid = 'x',
        1,
        2,
        'NetworkFingerprint.ssid',
      );
      expectFirstTag(
        () => NetworkFingerprint(),
        (m) => (m as NetworkFingerprint).gateway = 'x',
        2,
        2,
        'NetworkFingerprint.gateway',
      );
      expectFirstTag(
        () => NetworkFingerprint(),
        (m) => (m as NetworkFingerprint).asn = 'x',
        3,
        2,
        'NetworkFingerprint.asn',
      );
      expectFirstTag(
        () => NetworkFingerprint(),
        (m) => (m as NetworkFingerprint).fingerprint = 'x',
        4,
        2,
        'NetworkFingerprint.fingerprint',
      );
    });
  });

  group('proxy chains', () {
    test('ProbeChainRequest tags', () {
      expectFirstTag(
        () => ProbeChainRequest(),
        (m) => (m as ProbeChainRequest).requestId = 'r1',
        3,
        2,
        'ProbeChainRequest.request_id',
      );
      expectFirstTag(
        () => ProbeChainRequest(),
        (m) => (m as ProbeChainRequest).serverIds.add('s1'),
        4,
        2,
        'ProbeChainRequest.server_ids',
      );
    });
    test('ProbeChainResponse tags', () {
      expectFirstTag(
        () => ProbeChainResponse(),
        (m) => (m as ProbeChainResponse).hops.add(ChainHop()),
        1,
        2,
        'ProbeChainResponse.hops',
      );
      expectFirstTag(
        () => ProbeChainResponse(),
        (m) => (m as ProbeChainResponse).totalLatencyMs = 120,
        2,
        0,
        'ProbeChainResponse.total_latency_ms',
      );
      expectFirstTag(
        () => ProbeChainResponse(),
        (m) => (m as ProbeChainResponse).engines.add('sing-box'),
        3,
        2,
        'ProbeChainResponse.engines',
      );
      expectFirstTag(
        () => ProbeChainResponse(),
        (m) => (m as ProbeChainResponse).error = SoraError(),
        4,
        2,
        'ProbeChainResponse.error',
      );
    });
    test('ChainHop tags', () {
      expectFirstTag(() => ChainHop(), (m) => (m as ChainHop).serverId = 's1', 1, 2, 'ChainHop.server_id');
      expectFirstTag(() => ChainHop(), (m) => (m as ChainHop).reachable = true, 2, 0, 'ChainHop.reachable');
      expectFirstTag(() => ChainHop(), (m) => (m as ChainHop).latencyMs = 42, 3, 0, 'ChainHop.latency_ms');
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
      expectFirstTag(
        () => BenchmarkServersRequest(),
        (m) => (m as BenchmarkServersRequest).serverIds.add('s1'),
        4,
        2,
        'BenchmarkServersRequest.server_ids',
      );
      expectFirstTag(
        () => BenchmarkServersRequest(),
        (m) => (m as BenchmarkServersRequest).durationS = 10,
        5,
        0,
        'BenchmarkServersRequest.duration_s',
      );
      expectFirstTag(
        () => BenchmarkServersRequest(),
        (m) => (m as BenchmarkServersRequest).url = 'https://example.test',
        7,
        2,
        'BenchmarkServersRequest.url',
      );
    });
  });
}
