import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/updates.dart';

final recorded = File('test/fixtures/releases/latest.json').readAsStringSync();

/// S11a staged-rollout policy: parsing strictness, the client decision
/// table, and the versionRevoked warning. The kill-switch must be a tested
/// mechanism, not a declaration.
void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('RolloutPolicy.parse', () {
    test('accepts a well-formed policy and normalizes versions', () {
      final parsed = RolloutPolicy.parse(
        '{"format":1,"rollout":{"version":"v1.0.5","percent":10},'
        '"blocked_versions":["v1.0.4","1.0.4","1.0.3"]}',
      )!;
      expect(parsed.version, '1.0.5');
      expect(parsed.percent, 10);
      expect(parsed.blockedVersions, {'1.0.4', '1.0.3'});
    });

    test('accepts the percent boundaries 0 and 100', () {
      const zero = '{"format":1,"rollout":{"version":"1.0.5","percent":0}}';
      const hundred =
          '{"format":1,"rollout":{"version":"1.0.5","percent":100}}';
      expect(RolloutPolicy.parse(zero)!.percent, 0);
      expect(RolloutPolicy.parse(hundred)!.percent, 100);
    });

    test('a missing blocked_versions list means nothing is blocked', () {
      const body = '{"format":1,"rollout":{"version":"1.0.5","percent":100}}';
      expect(RolloutPolicy.parse(body)!.blockedVersions, isEmpty);
    });

    test('ignores unknown fields', () {
      const body =
          '{"format":1,"rollout":{"version":"1.0.5","percent":100,"note":"hi"},'
          '"blocked_versions":[],"extra":true}';
      expect(RolloutPolicy.parse(body)!.version, '1.0.5');
    });

    test('rejects malformed policies', () {
      for (final body in [
        '',
        'not json',
        '[]',
        '{}',
        '{"format":1}',
        '{"format":1,"rollout":{"version":"1.0.5"}}',
        '{"format":1,"rollout":{"percent":100}}',
        // Wrong or missing format version.
        '{"format":2,"rollout":{"version":"1.0.5","percent":100}}',
        '{"format":"1","rollout":{"version":"1.0.5","percent":100}}',
        '{"rollout":{"version":"1.0.5","percent":100}}',
        '{"format":1,"rollout":"nope"}',
        // Unusable versions.
        '{"format":1,"rollout":{"version":"bogus","percent":100}}',
        '{"format":1,"rollout":{"version":"1.0","percent":100}}',
        '{"format":1,"rollout":{"version":5,"percent":100}}',
        // Percent outside 0..100 or not an integer.
        '{"format":1,"rollout":{"version":"1.0.5","percent":-1}}',
        '{"format":1,"rollout":{"version":"1.0.5","percent":101}}',
        '{"format":1,"rollout":{"version":"1.0.5","percent":50.0}}',
        '{"format":1,"rollout":{"version":"1.0.5","percent":"50"}}',
        // Malformed blocked_versions.
        '{"format":1,"rollout":{"version":"1.0.5","percent":100},'
            '"blocked_versions":"nope"}',
        '{"format":1,"rollout":{"version":"1.0.5","percent":100},'
            '"blocked_versions":["bogus"]}',
        '{"format":1,"rollout":{"version":"1.0.5","percent":100},'
            '"blocked_versions":["1.0.5",42]}',
      ]) {
        expect(RolloutPolicy.parse(body), isNull, reason: body);
      }
    });
  });

  group('updateCohort', () {
    test('is deterministic and stays within 0..99', () {
      expect(updateCohort('test-uuid-1'), updateCohort('test-uuid-1'));
      for (final uuid in [
        'a',
        'b',
        'test-uuid-1',
        'test-uuid-2',
        'some-long-uuid-1234',
      ]) {
        expect(updateCohort(uuid), inInclusiveRange(0, 99));
      }
    });

    test('pins known cohort values', () {
      // SHA-256(uuid) mod 100; changing the algorithm must be deliberate.
      expect(updateCohort('test-uuid-1'), 35);
      expect(updateCohort('test-uuid-2'), 68);
    });
  });

  group('policy decision table', () {
    String policyBody({
      String version = '1.0.5',
      int percent = 100,
      List<String> blocked = const [],
    }) => jsonEncode({
      'format': 1,
      'rollout': {'version': version, 'percent': percent},
      'blocked_versions': blocked,
    });

    /// Runs one update check against the recorded 1.0.5 release; the
    /// rollout feed answers with [policyBody] (or [policyStatus], or throws
    /// when [policyThrows]).
    Future<({AppUpdater updater, int notices})> checkWithPolicy(
      Settings settings, {
      String? policyBody,
      int policyStatus = 200,
      bool policyThrows = false,
      String version = '1.0.4',
    }) async {
      var notices = 0;
      final updater = AppUpdater(
        settings,
        version: version,
        connection: () => UpdateConnection.idle,
        available: (_) async {
          notices++;
        },
        client: () => MockClient((request) async {
          if (request.url.toString() == rolloutPolicyUrl) {
            if (policyThrows) throw const SocketException('offline');
            return http.Response(
              policyBody ?? '',
              policyStatus,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response(
            recorded,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(updater.dispose);
      await updater.check(manual: true).timeout(const Duration(seconds: 5));
      return (updater: updater, notices: notices);
    }

    test('unreachable policy keeps the legacy offer-all behavior', () async {
      for (final (policyStatus: status, policyThrows: throws) in [
        (policyStatus: 404, policyThrows: false),
        (policyStatus: 200, policyThrows: true),
      ]) {
        final settings = await Settings.load();
        final (updater: updater, notices: notices) = await checkWithPolicy(
          settings,
          policyStatus: status,
          policyThrows: throws,
        );
        expect(updater.error, isNull);
        expect(
          updater.hasUpdate,
          isTrue,
          reason: 'status=$status throws=$throws',
        );
        expect(notices, 1);
        expect(updater.versionRevoked, isFalse);
        expect(updater.rolloutPending, isFalse);
      }
    });

    test('malformed policy withholds the update (fail-closed)', () async {
      final settings = await Settings.load();
      final (updater: updater, notices: notices) = await checkWithPolicy(
        settings,
        policyBody: '{"format":2,"rollout":{"version":"1.0.5","percent":100}}',
      );
      expect(updater.error, isNull);
      expect(updater.hasUpdate, isFalse);
      expect(notices, 0);
    });

    test('policy naming another version is ignored (fail-closed)', () async {
      final settings = await Settings.load();
      final (updater: updater, notices: notices) = await checkWithPolicy(
        settings,
        policyBody: policyBody(version: '1.0.6'),
      );
      expect(updater.hasUpdate, isFalse);
      expect(notices, 0);
    });

    test('kill-switch: a blocked candidate is never offered', () async {
      final settings = await Settings.load();
      final (updater: updater, notices: notices) = await checkWithPolicy(
        settings,
        policyBody: policyBody(blocked: ['1.0.5']),
      );
      expect(updater.hasUpdate, isFalse);
      expect(notices, 0);
    });

    test('cohort below percent is offered, at-or-above is withheld', () async {
      final settings = await Settings.load();
      final cohort = updateCohort(settings.installUuid);
      // cohort < percent -> included.
      final (updater: offered, notices: offeredNotices) = await checkWithPolicy(
        settings,
        policyBody: policyBody(percent: cohort + 1),
      );
      expect(offered.hasUpdate, isTrue);
      expect(offeredNotices, 1);
      expect(offered.rolloutPending, isFalse);
      // cohort >= percent -> excluded; the pending note says a newer
      // release is on its way.
      final (updater: held, notices: heldNotices) = await checkWithPolicy(
        settings,
        policyBody: policyBody(percent: cohort),
      );
      expect(held.hasUpdate, isFalse);
      expect(heldNotices, 0);
      expect(held.rolloutPending, isTrue);
    });

    test('percent boundaries: 0 withholds all, 100 offers all', () async {
      final settings = await Settings.load();
      final (updater: none, notices: noneNotices) = await checkWithPolicy(
        settings,
        policyBody: policyBody(percent: 0),
      );
      expect(none.hasUpdate, isFalse);
      expect(noneNotices, 0);
      expect(none.rolloutPending, isTrue);
      final (updater: all, notices: allNotices) = await checkWithPolicy(
        settings,
        policyBody: policyBody(percent: 100),
      );
      expect(all.hasUpdate, isTrue);
      expect(allNotices, 1);
      expect(all.rolloutPending, isFalse);
    });

    test('no pending note when already on the rolled-out version', () async {
      final settings = await Settings.load();
      final (updater: updater, notices: notices) = await checkWithPolicy(
        settings,
        version: '1.0.5',
        policyBody: policyBody(percent: 0),
      );
      expect(updater.hasUpdate, isFalse);
      expect(updater.rolloutPending, isFalse);
      expect(notices, 0);
    });

    test('blocked installed version raises versionRevoked warning', () async {
      final settings = await Settings.load();
      // The candidate is fine: the update is offered AND the installed
      // version is flagged as recalled.
      final (updater: updater, notices: notices) = await checkWithPolicy(
        settings,
        policyBody: policyBody(blocked: ['1.0.4']),
      );
      expect(updater.hasUpdate, isTrue);
      expect(notices, 1);
      expect(updater.versionRevoked, isTrue);
      // The warning is independent of the candidate decision: a recalled
      // installed version is flagged even when the candidate is
      // kill-switched.
      final (updater: blocked, notices: blockedNotices) = await checkWithPolicy(
        settings,
        policyBody: policyBody(blocked: ['1.0.4', '1.0.5']),
      );
      expect(blocked.hasUpdate, isFalse);
      expect(blockedNotices, 0);
      expect(blocked.versionRevoked, isTrue);
    });
  });
}
