import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/ext/catalog.dart';
import 'package:sora/src/ext/manifest.dart';

/// Dart↔Go parity pins for the seams-S4 review residuals
/// (reports/seams/s4-review.md §2–§3). Every expectation below is the
/// verdict of the Go validator on the same input, probed through
/// `ext.ParseCatalog` / `ext.ParseManifestFull` (core/ext): the app must
/// never accept what the core rejects, nor reject what it accepts.
///
///  1. Catalog timestamps: Go validates `updated_at` and changelog dates
///     with `time.Parse(time.RFC3339)`. That parser's UTC-offset range is
///     easy to misstate: probing it shows the offset hour may reach 24
///     and the offset minute 60 (so `+24:00`, `+00:60`, `+24:60` are
///     ACCEPTED by Go), while hour 25+ and minute 61+ are rejected.
///     These pins mirror the probed Go boundary exactly — neither the
///     textbook 23/59 (which would falsely reject Go-valid catalogs)
///     nor Dart's old anything-goes normalization.
///  2. Manifest author fields: Go measures the RAW string's byte length
///     (`len()` in manifest.go Validate); trimming is used only for the
///     emptiness check. Dart used to trim author name/identity before
///     measuring, accepting raw values over the limit.
///  3. network_hosts: Go's normalizeHostPattern strips a leading `*.`
///     before applying the 253-byte limit; Dart used to measure the
///     whole string, falsely rejecting long wildcard hosts.
void main() {
  // Minisign key line for the fixed seed 0..31 (same key the Go tests
  // build in core/ext/ext_test.go testPubKeyLine).
  const pubKey = 'RWQAAAAAAAAAAAOhB7/zzhC+HXDdGOdLwJln5NYwm6UNXx3chmQSVTG4';

  group('catalog timestamps (Go time.Parse RFC3339 parity)', () {
    bool accepts(String updatedAt, {String changelogDate = '2026-10-20T00:00:00Z'}) {
      final doc = {
        'catalog_version': 1,
        'updated_at': updatedAt,
        'extensions': [
          {
            'id': 'com.example.hello',
            'name': 'Hello',
            'version': '1.0.0',
            'description': 'd',
            'author': 'Example',
            'author_identity': 'github:example',
            'author_key': pubKey,
            'icon_url': 'https://example.com/icon.png',
            'rating': 4.5,
            'ratings_count': 10,
            'installs': 100,
            'badges': ['verified'],
            'categories': ['tools'],
            'capabilities': ['ui-panel'],
            'permissions': ['notifications'],
            'download_url': 'https://example.com/hello.soraext',
            'sha256':
                '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
            'size': 1024,
            'min_app_version': '1.9.0',
            'screenshots': ['https://example.com/shot1.png'],
            'changelog': [
              {'version': '1.0.0', 'date': changelogDate, 'notes': 'First release.'},
            ],
          },
        ],
      };
      try {
        ExtensionCatalog.parse(Uint8List.fromList(utf8.encode(jsonEncode(doc))));
        return true;
      } on CatalogError {
        return false;
      }
    }

    final acceptCases = <String, String>{
      'zulu': '2026-10-20T00:00:00Z',
      'zero-offset': '2026-10-20T00:00:00+00:00',
      'plus03': '2026-10-20T00:00:00+03:00',
      'fractional': '2026-10-20T00:00:00.123Z',
      'max-strict': '2026-10-20T00:00:00+23:59',
      'min-strict': '2026-10-20T00:00:00-23:59',
      // Go's parser admits these liberal edges; Dart must too (parity),
      // even though strict RFC3339 would not.
      'go-liberal-h24': '2026-10-20T00:00:00+24:00',
      'go-liberal-h24-neg': '2026-10-20T00:00:00-24:00',
      'go-liberal-m60': '2026-10-20T00:00:00+00:60',
      'go-liberal-h23m60': '2026-10-20T00:00:00+23:60',
      'go-liberal-h24m60': '2026-10-20T00:00:00+24:60',
      'leap-day-valid': '2024-02-29T00:00:00Z',
    };
    for (final e in acceptCases.entries) {
      test('updated_at accept: ${e.key}', () {
        expect(accepts(e.value), isTrue, reason: 'Go accepts ${e.value}');
      });
    }

    final rejectCases = <String, String>{
      'off-h25': '2026-10-20T00:00:00+25:00',
      'off-h48': '2026-10-20T00:00:00+48:00',
      'off-h99': '2026-10-20T00:00:00+99:00',
      'off-h25-neg': '2026-10-20T00:00:00-25:00',
      'off-m61': '2026-10-20T00:00:00+00:61',
      'off-m99': '2026-10-20T00:00:00+00:99',
      'off-h23m61': '2026-10-20T00:00:00+23:61',
      'off-h23m99': '2026-10-20T00:00:00+23:99',
      'off-h24m61': '2026-10-20T00:00:00+24:61',
      'off-h24m99': '2026-10-20T00:00:00+24:99',
      'off-h99m99': '2026-10-20T00:00:00+99:99',
      'date-only': '2026-10-20',
      'space-sep': '2026-10-20 00:00:00Z',
      'lowercase-t': '2026-10-20t00:00:00Z',
      'lowercase-z': '2026-10-20T00:00:00z',
      'feb31': '2026-02-31T00:00:00Z',
      'feb29-nonleap': '2026-02-29T00:00:00Z',
      'second60': '2026-10-20T00:00:60Z',
      'local-hour24': '2026-10-20T24:00:00Z',
      'local-minute60': '2026-10-20T00:60:00Z',
      'month13': '2026-13-01T00:00:00Z',
      'no-offset': '2026-10-20T00:00:00',
      'offset-no-colon': '2026-10-20T00:00:00+0000',
    };
    for (final e in rejectCases.entries) {
      test('updated_at reject: ${e.key}', () {
        expect(accepts(e.value), isFalse, reason: 'Go rejects ${e.value}');
      });
    }

    test('changelog date reject: off-h25', () {
      expect(
        accepts('2026-10-20T00:00:00Z',
            changelogDate: '2026-10-20T00:00:00+25:00'),
        isFalse,
      );
    });
    test('changelog date reject: off-m99', () {
      expect(
        accepts('2026-10-20T00:00:00Z',
            changelogDate: '2026-10-20T00:00:00+00:99'),
        isFalse,
      );
    });
    test('changelog date accept: valid offset', () {
      expect(
        accepts('2026-10-20T00:00:00Z',
            changelogDate: '2026-10-20T00:00:00+03:00'),
        isTrue,
      );
    });
  });

  group('rollout pinned vectors stay green (Go TestRolloutEligiblePinnedVectors)', () {
    CatalogEntry entry(String id, String version, double fraction) => CatalogEntry(
          id: id,
          name: 'n',
          version: version,
          description: '',
          author: 'a',
          authorIdentity: '',
          authorKey: '',
          iconUrl: '',
          rating: 0,
          ratingsCount: 0,
          installs: 0,
          badges: const [],
          categories: const [],
          capabilities: const [],
          permissions: const [],
          downloadUrl: '',
          sha256: '',
          size: 0,
          minAppVersion: '',
          rolloutFraction: fraction,
          screenshotUrls: const [],
          changelog: const [],
        );

    final vectors = <(String, String, String, double, bool)>[
      ('install-0001', 'com.example.alpha', '1.0.0', 0.5, true),
      ('install-0005', 'com.example.alpha', '1.0.0', 0.5, false),
      ('install-0008', 'com.example.alpha', '1.0.0', 0.5, false),
      ('install-0010', 'com.example.alpha', '1.0.0', 0.5, true),
      ('install-0004', 'com.example.beta', '2.3.1', 0.25, false),
      ('device-xyz', 'org.sora.hello-panel', '1.1.0', 0.25, false),
      ('device-xyz', 'org.sora.hello-panel', '1.1.0', 0.5, true),
    ];
    for (var i = 0; i < vectors.length; i++) {
      final v = vectors[i];
      test('rollout vector $i', () {
        expect(entry(v.$2, v.$3, v.$4).rolloutEligible(v.$1), v.$5);
      });
    }
  });

  group('manifest author raw-length (Go len() parity)', () {
    bool accepts(void Function(Map<String, dynamic> author) mutate) {
      final author = <String, dynamic>{
        'name': 'Example',
        'identity': 'github:example',
        'public_key': pubKey,
      };
      mutate(author);
      final doc = {
        'manifest_version': 1,
        'id': 'com.example.hello',
        'name': 'Hello',
        'version': '1.0.0',
        'min_app_version': '1.0.0',
        'description': 'd',
        'author': author,
        'permissions': <String>[],
        'capabilities': <String>[],
      };
      try {
        ExtManifest.parse(jsonEncode(doc));
        return true;
      } on ManifestError {
        return false;
      }
    }

    final acceptCases = <String, void Function(Map<String, dynamic>)>{
      'name-80': (a) => a['name'] = 'A' * 80,
      // 80 raw bytes including spaces: Go accepts — the limit is on the
      // raw value, and only emptiness is judged trimmed.
      'name-80-raw-trailing-spaces': (a) => a['name'] = '${'A' * 78}  ',
      'name-80-raw-leading-space': (a) => a['name'] = ' ${'A' * 79}',
      'identity-160': (a) => a['identity'] = 'i' * 160,
      'identity-160-raw-trailing-spaces': (a) => a['identity'] = '${'i' * 158}  ',
      // Go's ParsePublicKey trims the line itself, so a padded key is
      // valid on both sides.
      'pubkey-surrounding-spaces': (a) => a['public_key'] = '  $pubKey  ',
      'name-cyrillic-80-raw': (a) => a['name'] = '${'я' * 39}  ',
    };
    for (final e in acceptCases.entries) {
      test('author accept: ${e.key}', () {
        expect(accepts(e.value), isTrue, reason: 'Go accepts ${e.key}');
      });
    }

    final rejectCases = <String, void Function(Map<String, dynamic>)>{
      'name-81': (a) => a['name'] = 'A' * 81,
      // 81 raw bytes (79 chars + 2 spaces): Go rejects on raw length;
      // Dart used to trim first and accept.
      'name-81-trailing-spaces': (a) => a['name'] = '${'A' * 79}  ',
      'name-81-leading-spaces': (a) => a['name'] = '  ${'A' * 79}',
      'identity-161': (a) => a['identity'] = 'i' * 161,
      'identity-161-trailing-spaces': (a) => a['identity'] = '${'i' * 159}  ',
      'identity-161-leading-spaces': (a) => a['identity'] = '  ${'i' * 159}',
      'name-spaces-only': (a) => a['name'] = '   ',
      'identity-spaces-only': (a) => a['identity'] = '  ',
      // 40 Cyrillic chars = 80 bytes, plus one space = 81 raw bytes.
      'name-cyrillic-81-raw': (a) => a['name'] = '${'я' * 40} ',
      'pubkey-spaces-only': (a) => a['public_key'] = '   ',
    };
    for (final e in rejectCases.entries) {
      test('author reject: ${e.key}', () {
        expect(accepts(e.value), isFalse, reason: 'Go rejects ${e.key}');
      });
    }
  });

  group('manifest network_hosts wildcard length (Go normalizeHostPattern parity)', () {
    String hostName(int lastLen) =>
        '${'a' * 63}.${'b' * 63}.${'c' * 63}.${'d' * lastLen}';
    // hostName(60) is 252 chars, (61) is 253, (62) is 254.

    bool accepts(String host) {
      final doc = {
        'manifest_version': 1,
        'id': 'com.example.hello',
        'name': 'Hello',
        'version': '1.0.0',
        'min_app_version': '1.0.0',
        'description': 'd',
        'author': {
          'name': 'Example',
          'identity': 'github:example',
          'public_key': pubKey,
        },
        'permissions': ['net.fetch'],
        'capabilities': <String>[],
        'network_hosts': [host],
      };
      try {
        ExtManifest.parse(jsonEncode(doc));
        return true;
      } on ManifestError {
        return false;
      }
    }

    final acceptCases = <String, String>{
      'plain-253': hostName(61),
      // Go strips `*.` before the 253-byte limit: 252/253-char names
      // behind a wildcard are valid (total string 254/255 chars).
      'wild-252': '*.${hostName(60)}',
      'wild-253': '*.${hostName(61)}',
      'wild-short': '*.example.com',
      'plain-short': 'api.example.com',
      'wild-uppercase': '*.EXAMPLE.com',
    };
    for (final e in acceptCases.entries) {
      test('hosts accept: ${e.key}', () {
        expect(accepts(e.value), isTrue, reason: 'Go accepts ${e.key}');
      });
    }

    final rejectCases = <String, String>{
      'plain-254': hostName(62),
      'wild-254': '*.${hostName(62)}',
      // Go checks IP-literals on the stripped name: a wildcard does
      // not launder an IP literal into an allowlistable host.
      'wild-ip': '*.1.2.3.4',
      'plain-ip': '1.2.3.4',
    };
    for (final e in rejectCases.entries) {
      test('hosts reject: ${e.key}', () {
        expect(accepts(e.value), isFalse, reason: 'Go rejects ${e.key}');
      });
    }
  });
}
