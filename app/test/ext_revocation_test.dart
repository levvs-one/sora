/// Revocation on the live (Dart) path: parser/signature/cache parity with
/// core/ext (revoke.go, revocation_cache.go) and enforcement in the Dart
/// ExtensionStore (install / setEnabled / load-time disable sweep).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart' as cry;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:sora/src/ext/manifest.dart';
import 'package:sora/src/ext/package.dart';
import 'package:sora/src/ext/revoke.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/ext/verifier.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

// ---------------------------------------------------------------------------
// Minisign signing helper (mirrors core/ext SignPayload + testPubKeyLine).
// ---------------------------------------------------------------------------

class _Signer {
  _Signer(this.pubLine, this._keyPair);
  final String pubLine;
  final cry.KeyPair _keyPair;

  /// Signs [payload] in the minisign role [file], returning .minisig text.
  Future<String> sign(String file, Uint8List payload) async {
    final sum = crypto.sha256.convert(payload).toString();
    final tc = 'timestamp:1700000000\tfile:$file\tsha256:$sum';
    final sig = await cry.Ed25519().sign(utf8.encode(tc), keyPair: _keyPair);
    final blob = <int>[...sig.bytes, ...utf8.encode(tc)];
    return 'untrusted comment: test key\n${base64Encode(blob)}\ntrusted comment: $tc\n';
  }
}

Future<_Signer> _makeSigner() async {
  final seed = List<int>.generate(32, (i) => i);
  final kp = await cry.Ed25519().newKeyPairFromSeed(seed);
  final pub = await kp.extractPublicKey();
  final raw = <int>[0x45, 0x64, ...List<int>.filled(8, 0), ...pub.bytes];
  return _Signer(base64Encode(raw), kp);
}

// ---------------------------------------------------------------------------
// Revocation list JSON builders.
// ---------------------------------------------------------------------------

String _fmt(DateTime d) => d.toUtc().toIso8601String();

String _revJson(List<Map<String, String>> entries, {DateTime? updated, DateTime? expires}) {
  final now = DateTime.now().toUtc();
  return jsonEncode({
    'revocation_version': 1,
    'updated_at': _fmt(updated ?? now.subtract(const Duration(days: 1))),
    'expires_at': _fmt(expires ?? now.add(const Duration(days: 7))),
    'entries': entries,
  });
}

RevocationList _revList(List<Map<String, String>> entries, {DateTime? updated, DateTime? expires}) =>
    RevocationList.parse(utf8.encode(_revJson(entries, updated: updated, expires: expires)));

// ---------------------------------------------------------------------------
// Signed .soraext builder for store tests (in-memory files, no zip: the
// store verifies through ExtPackage.fromFiles exactly like rollback does).
// ---------------------------------------------------------------------------

Future<ExtPackage> _buildPackage(_Signer author, String id, String version) async {
  final manifestJson = {
    'manifest_version': 1,
    'id': id,
    'name': 'Hello Panel',
    'version': version,
    'min_app_version': '1.0.0',
    'description': 'An example panel.',
    'author': {'name': 'Example', 'identity': 'github:example', 'public_key': author.pubLine},
    'permissions': <String>[],
    'capabilities': <String>[],
    'ui': {'panels': <dynamic>[]},
  };
  final manBytes = utf8.encode(jsonEncode(manifestJson));
  final checksums = '${crypto.sha256.convert(manBytes)}  $manifestName\n';
  final sig = await author.sign('checksums.txt', utf8.encode(checksums));
  final files = <String, Uint8List>{
    manifestName: Uint8List.fromList(manBytes),
    checksumsName: utf8.encode(checksums),
    signatureName: utf8.encode(sig),
  };
  return ExtPackage.fromFiles(files, ExtManifest.parse(utf8.decode(manBytes)));
}

void main() {
  late _Signer team;
  late _Signer author;

  setUpAll(() async {
    team = await _makeSigner();
    // A different seed for the author key so the two trust roots differ.
    final seed = List<int>.generate(32, (i) => 0x40 + i);
    final kp = await cry.Ed25519().newKeyPairFromSeed(seed);
    final pub = await kp.extractPublicKey();
    final raw = <int>[0x45, 0x64, ...List<int>.filled(8, 0), ...pub.bytes];
    author = _Signer(base64Encode(raw), kp);
  });

  group('RevocationList.parse (mirrors Go TestParseRevocationListValid)', () {
    test('valid list: * and <= constraints', () {
      final l = _revList([
        {'id': 'com.evil.miner', 'versions': '*', 'reason': 'cryptominer'},
        {'id': 'com.buggy.sync', 'versions': '<=1.2.0', 'reason': 'deletes user data'},
      ]);
      expect(l.isRevoked('com.evil.miner', '9.9.9'), isTrue);
      expect(l.isRevoked('com.buggy.sync', '1.2.0'), isTrue);
      expect(l.isRevoked('com.buggy.sync', '1.0.0'), isTrue);
      expect(l.isRevoked('com.buggy.sync', '1.2.1'), isFalse);
      expect(l.isRevoked('com.clean.app', '1.0.0'), isFalse);
      expect(l.expired(DateTime.now()), isFalse);
    });

    test('versionMatches matrix (mirrors Go TestVersionMatches)', () {
      final cases = <(String, String, bool)>[
        ('*', '1.0.0', true),
        ('*', '99.0.0-alpha', true),
        ('=1.2.3', '1.2.3', true),
        ('=1.2.3', '1.2.4', false),
        ('<1.2.3', '1.2.2', true),
        ('<1.2.3', '1.2.3', false),
        ('<=1.2.3', '1.2.3', true),
        ('<=1.2.3', '1.2.4', false),
        ('>=1.2.3', '1.2.3', false), // unsupported operator
        ('1.2.3', '1.2.3', false), // missing operator
        ('', '1.2.3', false),
      ];
      for (final (constraint, version, want) in cases) {
        expect(RevocationList.versionMatches(constraint, version), want,
            reason: 'versionMatches($constraint, $version)');
      }
    });

    test('expired is !expires_at.After(now)', () {
      final past = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final l = _revList(const [], expires: past);
      expect(l.expired(DateTime.now()), isTrue);
    });
  });

  group('RevocationList.parse rejects (mirrors Go TestParseRevocationListRejects)', () {
    final entryCases = <String, List<Map<String, String>>>{
      'bad version': [
        {'id': 'com.a.b', 'versions': 'v1', 'reason': 'x'}
      ],
      'range op': [
        {'id': 'com.a.b', 'versions': '>=1.0.0', 'reason': 'x'}
      ],
      'bad id': [
        {'id': 'not an id!', 'versions': '*', 'reason': 'x'}
      ],
      'bad semver': [
        {'id': 'com.a.b', 'versions': '<=1.0', 'reason': 'x'}
      ],
      'duplicate': [
        {'id': 'com.a.b', 'versions': '*', 'reason': 'x'},
        {'id': 'com.a.b', 'versions': '*', 'reason': 'y'},
      ],
      'long reason': [
        {'id': 'com.a.b', 'versions': '*', 'reason': 'x' * 281}
      ],
    };
    for (final e in entryCases.entries) {
      test(e.key, () {
        expect(() => _revList(e.value), throwsA(isA<RevocationError>()));
      });
    }

    final rawCases = <String, String>{
      'unknown entry field':
          '{"revocation_version":1,"updated_at":"2026-10-20T00:00:00Z","expires_at":"2026-10-27T00:00:00Z","entries":[{"id":"com.a.b","versions":"*","reason":"x","extra":1}]}',
      'unknown top field':
          '{"revocation_version":1,"updated_at":"2026-10-20T00:00:00Z","expires_at":"2026-10-27T00:00:00Z","entries":[],"extra":1}',
      'expires before updated':
          '{"revocation_version":1,"updated_at":"2026-10-27T00:00:00Z","expires_at":"2026-10-20T00:00:00Z","entries":[]}',
      'bad list version':
          '{"revocation_version":2,"updated_at":"2026-10-20T00:00:00Z","expires_at":"2026-10-27T00:00:00Z","entries":[]}',
      'float list version':
          '{"revocation_version":1.0,"updated_at":"2026-10-20T00:00:00Z","expires_at":"2026-10-27T00:00:00Z","entries":[]}',
      'missing timestamps': '{"revocation_version":1,"entries":[]}',
      // Go's json.Decoder rejects a UTF-8 BOM prefix; Dart's utf8.decode
      // silently strips it, so parse must refuse it explicitly (З-2).
      // '\uFEFF' utf8-encodes to exactly EF BB BF.
      'bom prefix':
          '\uFEFF{"revocation_version":1,"updated_at":"2026-10-20T00:00:00Z","expires_at":"2026-10-27T00:00:00Z","entries":[]}',
      'empty': '',
      'not json': 'definitely not json',
      'oversize': 'x' * (maxRevocationBytes + 1),
    };
    for (final e in rawCases.entries) {
      test('raw: ${e.key}', () {
        expect(() => RevocationList.parse(utf8.encode(e.value)),
            throwsA(isA<RevocationError>()));
      });
    }
  });

  group('verifyRevocationList (signature gate)', () {
    test('a correctly team-signed list verifies and parses', () async {
      final payload = utf8.encode(_revJson([
        {'id': 'com.evil.miner', 'versions': '*', 'reason': 'cryptominer'},
      ]));
      final sig = await team.sign('revocations.json', payload);
      final l = await verifyRevocationList(sig, payload, teamKeyOverride: team.pubLine);
      expect(l.isRevoked('com.evil.miner', '1.0.0'), isTrue);
    });

    test('a tampered payload is refused (fail closed, not "empty list")', () async {
      final payload = utf8.encode(_revJson([
        {'id': 'com.evil.miner', 'versions': '*', 'reason': 'cryptominer'},
      ]));
      final sig = await team.sign('revocations.json', payload);
      final tampered = Uint8List.fromList([...payload]);
      tampered[40] = tampered[40] ^ 0x01;
      await expectLater(
          verifyRevocationList(sig, tampered, teamKeyOverride: team.pubLine),
          throwsA(isA<RevocationError>()));
    });

    test('a signature for another role (catalog.json) is refused', () async {
      final payload = utf8.encode(_revJson(const []));
      final sig = await team.sign('catalog.json', payload);
      await expectLater(
          verifyRevocationList(sig, payload, teamKeyOverride: team.pubLine),
          throwsA(isA<RevocationError>()));
    });

    test('fails closed while the team key ceremony is pending', () async {
      if (teamSigningConfigured) return; // mirrors the Go test's skip
      final payload = utf8.encode(_revJson(const []));
      final sig = await team.sign('revocations.json', payload);
      await expectLater(
          verifyRevocationList(sig, payload),
          throwsA(isA<RevocationError>()
              .having((e) => e.kind, 'kind', RevocationErrorKind.unconfigured)));
    });
  });

  group('RevocationCache (mirrors Go revocation_cache_test.go)', () {
    late Directory dir;
    late RevocationCache cache;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('sora_revoke_cache');
      cache = RevocationCache(dir.path);
    });
    tearDown(() async => dir.delete(recursive: true));

    test('roundtrip: stored verified bytes load back', () async {
      final raw = utf8.encode(_revJson([
        {'id': 'com.evil.miner', 'versions': '*', 'reason': 'cryptominer'},
      ]));
      await cache.store(raw);
      final l = await cache.load();
      expect(l, isNotNull);
      expect(l!.isRevoked('com.evil.miner', '9.9.9'), isTrue);
      expect(l.isRevoked('com.good.tool', '1.0.0'), isFalse);
    });

    test('store refuses unparseable bytes', () async {
      for (final bad in ['not json', '{"revocation_version":99}', 'x' * (maxRevocationBytes + 1)]) {
        await expectLater(cache.store(utf8.encode(bad)), throwsA(isA<RevocationError>()));
      }
      expect(await cache.load(), isNull);
    });

    test('a corrupt cache file is "no cache", never a crash', () async {
      await File('${dir.path}${Platform.pathSeparator}revocations.json')
          .writeAsString('{corrupt');
      expect(await cache.load(), isNull);
    });

    test('refresh falls back to the cache when verification cannot succeed', () async {
      final raw = utf8.encode(_revJson([
        {'id': 'com.evil.miner', 'versions': '*', 'reason': 'cryptominer'},
      ]));
      await cache.store(raw);
      // The endpoint answers 500: refresh must serve the verified cache.
      final failing = MockClient((_) async => http.Response('no', 500));
      final r = await cache.refresh(
          client: failing, url: 'https://example.test/v1/revocations.json');
      expect(r.fromCache, isTrue);
      expect(r.list.isRevoked('com.evil.miner', '1.0.0'), isTrue);
    });

    test('refresh with no cache and a broken endpoint throws', () async {
      final failing = MockClient((_) async => http.Response('no', 418));
      await expectLater(
          cache.refresh(client: failing, url: 'https://example.test/v1/revocations.json'),
          throwsA(isA<RevocationError>()));
    });

    test('refresh fetches, verifies and caches a fresh list', () async {
      final payload = utf8.encode(_revJson([
        {'id': 'com.evil.miner', 'versions': '*', 'reason': 'cryptominer'},
      ]));
      final sig = await team.sign('revocations.json', payload);
      final ok = MockClient((req) async {
        if (req.url.path.endsWith('.minisig')) return http.Response(sig, 200);
        return http.Response.bytes(payload, 200);
      });
      final r = await cache.refresh(
          client: ok,
          url: 'https://example.test/v1/revocations.json',
          teamKeyOverride: team.pubLine);
      expect(r.fromCache, isFalse);
      expect(r.list.isRevoked('com.evil.miner', '2.0.0'), isTrue);
      // …and the verified bytes are now the cache.
      final cached = await cache.load();
      expect(cached!.isRevoked('com.evil.miner', '2.0.0'), isTrue);
    });

    test('refresh refuses a list whose signature is invalid', () async {
      final payload = utf8.encode(_revJson(const []));
      final badSig = await author.sign('revocations.json', payload); // wrong key
      final ok = MockClient((req) async {
        if (req.url.path.endsWith('.minisig')) return http.Response(badSig, 200);
        return http.Response.bytes(payload, 200);
      });
      await expectLater(
          cache.refresh(
              client: ok,
              url: 'https://example.test/v1/revocations.json',
              teamKeyOverride: team.pubLine),
          throwsA(isA<RevocationError>()));
      expect(await cache.load(), isNull);
    });
  });

  group('ExtensionStore enforcement (mirrors Go revoke store tests)', () {
    late Directory dir;
    late ExtensionStore store;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('sora_revoke_store');
      store = ExtensionStore(dir: dir.path);
      await store.load();
    });
    tearDown(() async {
      store.dispose();
      await dir.delete(recursive: true);
    });

    test('no list cached: install proceeds (catalog is the gate)', () async {
      final pkg = await _buildPackage(author, 'com.example.hello', '1.0.0');
      await store.install(pkg, source: 'sideload', granted: const []);
      expect(store.isEnabled('com.example.hello'), isTrue);
    });

    test('revoked: apply disables, enable and install are refused', () async {
      final pkg = await _buildPackage(author, 'com.example.hello', '1.0.0');
      await store.install(pkg, source: 'sideload', granted: const []);
      expect(store.isEnabled('com.example.hello'), isTrue);

      // The kill order lands: the already-installed extension is disabled.
      final disabled = await store.applyRevocations(_revList([
        {'id': 'com.example.hello', 'versions': '*', 'reason': 'kill'},
      ]));
      expect(disabled, ['com.example.hello']);
      expect(store.isEnabled('com.example.hello'), isFalse);

      // Re-enabling is refused with the revoked kind…
      await expectLater(
          store.setEnabled('com.example.hello', true),
          throwsA(isA<RevocationError>()
              .having((e) => e.kind, 'kind', RevocationErrorKind.revoked)));
      // …but disabling still works (the kill path).
      await store.setEnabled('com.example.hello', false);

      // A newer version is still revoked under "*": install is refused.
      final pkg2 = await _buildPackage(author, 'com.example.hello', '1.0.1');
      await expectLater(store.install(pkg2, source: 'sideload', granted: const []),
          throwsA(isA<RevocationError>()));

      // An unrelated extension installs fine under the same list.
      final other = await _buildPackage(author, 'com.example.other', '1.0.0');
      await store.install(other, source: 'sideload', granted: const []);
      expect(store.isEnabled('com.example.other'), isTrue);
    });

    test('version-scoped revocation: only the revoked range is blocked', () async {
      await store.applyRevocations(_revList([
        {'id': 'com.example.hello', 'versions': '<=1.0.0', 'reason': 'test'},
      ]));
      final old = await _buildPackage(author, 'com.example.hello', '1.0.0');
      await expectLater(store.install(old, source: 'sideload', granted: const []),
          throwsA(isA<RevocationError>()));
      final fixed = await _buildPackage(author, 'com.example.hello', '1.0.1');
      await store.install(fixed, source: 'sideload', granted: const []);
      expect(store.isEnabled('com.example.hello'), isTrue);
    });

    test('expired list: installs and enabling blocked, installed keep running', () async {
      final pkg = await _buildPackage(author, 'com.example.hello', '1.0.0');
      await store.install(pkg, source: 'sideload', granted: const []);

      final expired = _revList(
        [
          {'id': 'com.example.hello', 'versions': '*', 'reason': 'kill'},
        ],
        updated: DateTime.now().toUtc().subtract(const Duration(days: 2)),
        expires: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );
      // Stale intel does NOT force-disable what is already installed…
      final disabled = await store.applyRevocations(expired);
      expect(disabled, isEmpty);
      expect(store.isEnabled('com.example.hello'), isTrue);
      expect(store.isRevoked('com.example.hello', '1.0.0'), isFalse);

      // …but enabling after a manual disable is refused as expired…
      await store.setEnabled('com.example.hello', false);
      await expectLater(
          store.setEnabled('com.example.hello', true),
          throwsA(isA<RevocationError>()
              .having((e) => e.kind, 'kind', RevocationErrorKind.expired)));
      // …and every install is refused while the list is stale.
      final other = await _buildPackage(author, 'com.example.other', '1.0.0');
      await expectLater(
          store.install(other, source: 'sideload', granted: const []),
          throwsA(isA<RevocationError>()
              .having((e) => e.kind, 'kind', RevocationErrorKind.expired)));
    });

    test('cached list arms enforcement and disables matches at load', () async {
      final pkg = await _buildPackage(author, 'com.example.hello', '1.0.0');
      await store.install(pkg, source: 'sideload', granted: const []);
      expect(store.isEnabled('com.example.hello'), isTrue);

      // A verified list lands in the store's own cache directory (as a
      // refresh would have written it), then the app restarts.
      await RevocationCache(dir.path).store(utf8.encode(_revJson([
        {'id': 'com.example.hello', 'versions': '*', 'reason': 'kill'},
      ])));
      final store2 = ExtensionStore(dir: dir.path);
      addTearDown(store2.dispose);
      await store2.load();
      expect(store2.revocations, isNotNull);
      expect(store2.isEnabled('com.example.hello'), isFalse);
      await expectLater(store2.setEnabled('com.example.hello', true),
          throwsA(isA<RevocationError>()));
    });

    test('app-start sweep drops a revoked extension antidpi slot (B-M2)', () async {
      // Regression (review B-M2): the revocation sweep and the
      // onExtensionGone slot cleanup used to exist only inside the
      // Extensions screen's own store instance, created when the user
      // opened that section. A revoked extension's applied strategy
      // therefore survived every restart in Settings.antidpiStrategyJson
      // and buildPlan kept applying it. Now Sora owns the one store,
      // wires onExtensionGone in its constructor, and main() loads the
      // store before the first connect — this test replays exactly
      // that startup sequence.
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final settings = await Settings.load();

      final store = ExtensionStore(dir: dir.path);
      final sora = Sora(settings, extensionStore: store);
      addTearDown(sora.dispose);
      await store.load();
      final pkg = await _buildPackage(author, 'com.example.hello', '1.0.0');
      await store.install(pkg, source: 'sideload', granted: const []);
      // The extension applied a global strategy through the panel:
      // the write-through slot is owned by it.
      settings.antidpiStrategyJson = '{"split_pos":["1"]}';
      settings.antidpiStrategySource = 'com.example.hello';
      expect(
          buildPlan(servers: const [], choice: 'bypass', settings: settings)
              .outbounds
              .single
              .bypass
              .splitPos,
          ['1']);

      // The kill order lands in the cache while the app is closed.
      await RevocationCache(dir.path).store(utf8.encode(_revJson([
        {'id': 'com.example.hello', 'versions': '*', 'reason': 'kill'},
      ])));

      // Restart: a fresh Sora + fresh store over the same directory
      // and settings; main()'s startup load runs before any connect.
      final store2 = ExtensionStore(dir: dir.path);
      final sora2 = Sora(settings, extensionStore: store2);
      addTearDown(sora2.dispose);
      await store2.load();

      expect(store2.isEnabled('com.example.hello'), isFalse);
      // The slot is gone with its owner — the user never opened the
      // Extensions section in this "run".
      expect(settings.antidpiStrategyJson, isEmpty);
      expect(settings.antidpiStrategySource, isEmpty);
      // And the next plan no longer carries the revoked strategy: it
      // falls back to the legacy fields (the settings defaults).
      expect(
          buildPlan(servers: const [], choice: 'bypass', settings: settings)
              .outbounds
              .single
              .bypass
              .splitPos,
          ['1', 'midsld']);
    });

    test('rollback after a revocation sweep returns to the clean previous version', () async {
      // Regression (revocation review З-1), the reviewer's exact
      // scenario: 1.0.0 installed, updated to 2.0.0, then a list
      // revoking only =2.0.0 lands in the cache and the load-time sweep
      // disables the extension. The sweep goes through
      // InstalledExtension.copyWith(enabled:) — which used to drop
      // `previous` — so rollback then died with "has no previous
      // version" and the emergency exit to the clean 1.0.0 was gone.
      final v1 = await _buildPackage(author, 'com.example.hello', '1.0.0');
      await store.install(v1, source: 'sideload', granted: const []);
      final v2 = await _buildPackage(author, 'com.example.hello', '2.0.0');
      await store.install(v2, source: 'sideload', granted: const []);
      expect(store.get('com.example.hello')!.version, '2.0.0');
      expect(store.get('com.example.hello')!.previous, '1.0.0');
      expect(store.isEnabled('com.example.hello'), isTrue);

      await RevocationCache(dir.path).store(utf8.encode(_revJson([
        {'id': 'com.example.hello', 'versions': '=2.0.0', 'reason': 'bad build'},
      ])));
      final store2 = ExtensionStore(dir: dir.path);
      addTearDown(store2.dispose);
      await store2.load();

      // The sweep ran — and the rollback pointer survived it.
      expect(store2.get('com.example.hello')!.version, '2.0.0');
      expect(store2.isEnabled('com.example.hello'), isFalse);
      expect(store2.get('com.example.hello')!.previous, '1.0.0');
      expect(store2.isRevoked('com.example.hello', '2.0.0'), isTrue);

      // The emergency exit works again: rollback restores clean 1.0.0.
      await store2.rollback('com.example.hello');
      expect(store2.get('com.example.hello')!.version, '1.0.0');
      expect(store2.isRevoked('com.example.hello', '1.0.0'), isFalse);

      // Rollback itself preserves the swept (disabled) state — Go's
      // Rollback never touches Enabled either — but re-enabling the
      // clean version passes the enable/panel gate, so the extension
      // ends up back on 1.0.0, enabled.
      await store2.setEnabled('com.example.hello', true);
      expect(store2.isEnabled('com.example.hello'), isTrue);
    });
  });
}
