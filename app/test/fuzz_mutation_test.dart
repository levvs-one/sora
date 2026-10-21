import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/desktop/happ_routing.dart';
import 'package:sora/src/ext/catalog.dart';
import 'package:sora/src/ext/manifest.dart';
import 'package:sora/src/ext/revoke.dart';
import 'package:sora/src/sync.dart';

/// Wave-B mutation fuzzing for the Dart parser mirrors.
///
/// Dart has no coverage-guided fuzz engine under flutter test, so this
/// drives the parsers with deterministic (seeded-PRNG) mutations of
/// valid documents. The pinned contract is the one callers rely on: a
/// parser may accept the input or throw its declared Exception type —
/// but a raw Error (a failed cast, a range error, a null check) must
/// never escape, because callers catch the declared types and an
/// escaping Error is a production crash. Parsers that promise null on
/// bad input (convertHappRouting, SyncPairing.decodePairPayload) must
/// not throw at all.
void main() {
  group('mutation fuzz: Dart parser error contracts', () {
    test('ExtManifest.parse only throws ManifestError', () {
      const seed =
          '{"manifest_version":1,"id":"com.example.x","name":"x","version":"1.0.0",'
          '"min_app_version":"1.0.0","author":{"name":"a","identity":"i","public_key":"RWTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="},'
          '"permissions":["ui.panel"],"capabilities":[],"ui":{"panels":[{"id":"main","title":"t"}]},'
          '"network_hosts":["*.example.com"],"background_task":{"interval_seconds":60}}';
      _run(seed, 6000, (s) {
        try {
          ExtManifest.parse(s);
        } on ManifestError {
          // declared contract
        }
      });
    });

    test('ExtensionCatalog.parse only throws CatalogError', () {
      const seed =
          '{"catalog_version":1,"updated_at":"2026-01-01T00:00:00Z","max_age":3600,'
          '"extensions":[{"id":"com.example.x","name":"x","version":"1.0.0","date":"2026-01-01T00:00:00Z"}]}';
      _run(seed, 4000, (s) {
        try {
          ExtensionCatalog.parse(Uint8List.fromList(utf8.encode(s)));
        } on CatalogError {
          // declared contract
        }
      });
    });

    test('RevocationList.parse only throws RevocationError', () {
      const seed =
          '{"revocation_version":1,"updated_at":"2026-01-01T00:00:00Z",'
          '"expires_at":"2027-01-01T00:00:00Z","entries":[{"id":"com.example.x","versions":["1.0.0"]}]}';
      _run(seed, 4000, (s) {
        try {
          RevocationList.parse(Uint8List.fromList(utf8.encode(s)));
        } on RevocationError {
          // declared contract
        }
      });
    });

    test('convertHappRouting never throws (null on bad input)', () {
      final seed = base64Encode(utf8.encode(
          '{"Name":"seed","GlobalProxy":true,"RemoteDNS":"1.1.1.1","DirectSites":["example.com"],"ProxyIP":["10.0.0.0/8"]}'));
      _run(seed, 4000, (s) {
        convertHappRouting(s);
        convertHappRouting('happ://routing/onadd/$s');
      });
    });

    test('wave-B regression inputs: malformed percent escapes return null', () {
      // Found by this harness (4000-mutation runs): Uri.decodeComponent
      // throws ArgumentError (not the caught FormatException) on a bad
      // escape, and Uri's lazy query getters throw FormatException on
      // one. Both decoders promise null on bad input.
      expect(convertHappRouting('abc%zz'), isNull);
      expect(convertHappRouting('%'), isNull);
      expect(
        convertHappRouting(
            'eyJOYW1lIjoic2VlZCIsIkdsb2JhbFByb3h5Ijp0c>nVlLCJSZW1vdGVETlMiO%ZIxLjEuMS4xIiwyRGlyZWN0U2l0ZXMiOlsiZXhhbXBsZS5jb20iXSwiUHJveHlJUCI6WiIxMC4wLjAuMC84Il19'),
        isNull,
      );
      final pub = 'A' * 43;
      final token = 'A' * 22;
      // %AA decodes to a lone UTF-8 continuation byte: the lazy query
      // decode throws FormatException (the fuzz-found crash shape).
      expect(
        SyncPairing.decodePairPayload(
            'sora-sync://pair?id=%AA&port=12345&pub=$pub&token=$token&v=1'),
        isNull,
      );
      expect(
        SyncPairing.decodePairPayload(
            'sora-sync://pair?id=device-a&port=12345&pub=$pub&pub=%zz&token=$token&v=1'),
        isNull,
      );
    });

    test('SyncPairing.decodePairPayload never throws (null on bad input)', () {
      final pub = 'A' * 43; // base64url of 32 bytes
      final token = 'A' * 22; // base64url of 16 bytes
      final seed = 'sora-sync://pair?id=device-a&port=12345&pub=$pub&token=$token&v=1';
      _run(seed, 4000, (s) {
        SyncPairing.decodePairPayload(s);
      });
    });
  });
}

/// Runs [body] over [iterations] deterministic mutations of [seed].
/// Any escape that is not one of the declared exceptions rethrows here
/// and fails the test with the offending input in the message.
void _run(String seed, int iterations, void Function(String) body) {
  final rnd = Random(0xF022);
  const alphabet = '{}[]",:0123456789.eE+-truefalsn\\/ \t\n'
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
      '_-.*|&=?#<>@\$%';
  for (var i = 0; i < iterations; i++) {
    final mutated = _mutate(seed, rnd, alphabet);
    try {
      body(mutated);
    } catch (e) {
      // Bodies catch only their parser's declared error type, so any
      // escape reaching this point — another Exception type or a raw
      // Error — is a contract break worth a reproducer.
      fail('parser leaked ${e.runtimeType} on mutated input: $mutated\n$e');
    }
  }
}

String _mutate(String seed, Random rnd, String alphabet) {
  final units = seed.codeUnits.toList();
  final ops = 1 + rnd.nextInt(4);
  for (var op = 0; op < ops; op++) {
    if (units.isEmpty) break;
    switch (rnd.nextInt(6)) {
      case 0: // replace one char with an alphabet char
        units[rnd.nextInt(units.length)] =
            alphabet.codeUnitAt(rnd.nextInt(alphabet.length));
      case 1: // insert an alphabet char
        units.insert(rnd.nextInt(units.length + 1),
            alphabet.codeUnitAt(rnd.nextInt(alphabet.length)));
      case 2: // delete a span
        final at = rnd.nextInt(units.length);
        final len = 1 + rnd.nextInt(min(24, units.length - at));
        units.removeRange(at, at + len);
      case 3: // duplicate a span
        final at = rnd.nextInt(units.length);
        final len = 1 + rnd.nextInt(min(24, units.length - at));
        units.insertAll(at, units.sublist(at, at + len));
      case 4: // truncate
        units.removeRange(rnd.nextInt(units.length), units.length);
      case 5: // swap two chars
        final a = rnd.nextInt(units.length);
        final b = rnd.nextInt(units.length);
        final tmp = units[a];
        units[a] = units[b];
        units[b] = tmp;
    }
  }
  return String.fromCharCodes(units);
}
