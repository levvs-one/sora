import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/sync.dart';

/// Dart mirror of the Go QR wire vectors
/// (`service/sync/pairing/pairing_test.go`: `TestVectorT1Decodes` /
/// `TestVectorsReject`, pinned by `F9-SYNC-CONTRACT.md` §1).
///
/// The contract is normative: a payload the app accepts is a payload the
/// daemon accepts, so both sides must agree on every vector here.
void main() {
  // Key material is the byte sequence 0..31 / 0..15.
  const pub32 = 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8';
  const pub31 = 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHg';
  const tok16 = 'AAECAwQFBgcICQoLDA0ODw';
  const tok15 = 'AAECAwQFBgcICQoLDA0O';
  const t1 =
      'sora-sync://pair?id=device-a&port=12345&pub=$pub32&token=$tok16&v=1';

  group('T1 accept vector', () {
    test('decodes to the pinned fields', () {
      final inv = SyncPairing.decodePairPayload(t1);
      expect(inv, isNotNull);
      expect(inv!.deviceId, 'device-a');
      expect(inv.port, 12345);
      expect(inv.publicKey, List.generate(32, (i) => i));
      expect(inv.token, List.generate(16, (i) => i));
    });

    test('query keys are in canonical sorted order', () {
      // Encoders must emit url.Values.Encode order so payloads are
      // byte-comparable; the T1 literal pins it: id, port, pub, token, v.
      final order = ['id=', 'port=', 'pub=', 'token=', 'v='];
      var last = -1;
      for (final key in order) {
        final at = t1.indexOf(key);
        expect(at, greaterThan(last), reason: '$key out of order in $t1');
        last = at;
      }
    });

    test('uppercase scheme is accepted and equivalent', () {
      final upper = t1.replaceFirst('sora-sync://', 'SORA-SYNC://');
      final inv = SyncPairing.decodePairPayload(upper);
      expect(inv, isNotNull);
      expect(inv!.deviceId, 'device-a');
      expect(inv.port, 12345);
    });

    test('surrounding whitespace is tolerated', () {
      expect(SyncPairing.decodePairPayload('  $t1\n'), isNotNull);
    });
  });

  group('reject vectors', () {
    final cases = <String, String>{
      'wrong scheme':
          'http://pair?id=device-a&port=12345&pub=$pub32&token=$tok16&v=1',
      'wrong host':
          'sora-sync://join?id=device-a&port=12345&pub=$pub32&token=$tok16&v=1',
      'v=2':
          'sora-sync://pair?id=device-a&port=12345&pub=$pub32&token=$tok16&v=2',
      'missing v':
          'sora-sync://pair?id=device-a&port=12345&pub=$pub32&token=$tok16',
      'pub 31 bytes':
          'sora-sync://pair?id=device-a&port=12345&pub=$pub31&token=$tok16&v=1',
      'pub not base64':
          'sora-sync://pair?id=device-a&port=12345&pub=!!!not-base64!!!&token=$tok16&v=1',
      'token 15 bytes':
          'sora-sync://pair?id=device-a&port=12345&pub=$pub32&token=$tok15&v=1',
      'token with padding':
          'sora-sync://pair?id=device-a&port=12345&pub=$pub32&token=$tok16==&v=1',
      'port 0':
          'sora-sync://pair?id=device-a&port=0&pub=$pub32&token=$tok16&v=1',
      'port 65536':
          'sora-sync://pair?id=device-a&port=65536&pub=$pub32&token=$tok16&v=1',
      'port not a number':
          'sora-sync://pair?id=device-a&port=abc&pub=$pub32&token=$tok16&v=1',
      'empty id':
          'sora-sync://pair?id=&port=12345&pub=$pub32&token=$tok16&v=1',
      'missing id':
          'sora-sync://pair?port=12345&pub=$pub32&token=$tok16&v=1',
      'fragment': '$t1#frag',
      'bare trailing fragment': '$t1#',
      'duplicated key': '$t1&port=1',
      'duplicated pub': '$t1&pub=$pub32',
      'uppercase host is rejected':
          'sora-sync://PAIR?id=device-a&port=12345&pub=$pub32&token=$tok16&v=1',
    };
    for (final entry in cases.entries) {
      test(entry.key, () {
        expect(
          SyncPairing.decodePairPayload(entry.value),
          isNull,
          reason: '${entry.key} must be rejected: ${entry.value}',
        );
      });
    }

    test('unknown extra keys are ignored', () {
      final inv = SyncPairing.decodePairPayload('$t1&future=1');
      expect(inv, isNotNull);
      expect(inv!.deviceId, 'device-a');
    });
  });
}
