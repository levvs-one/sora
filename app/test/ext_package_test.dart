import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/ext/package.dart';
import 'package:sora/src/ext/verifier.dart';

/// The fixture is a real package built and signed by tools/sora-ext
/// (scaffold, pack, sign). The app must accept exactly what the CLI and
/// core/ext produce, and refuse any change to it.
void main() {
  final fixture = File('test/fixtures/ext/fixture.soraext').readAsBytesSync();

  test('a package signed by sora-ext verifies', () async {
    final pkg = ExtPackage.open(fixture);
    expect(pkg.manifest.id, 'com.sora.fixture');
    await pkg.verify();
  });

  test('a pinned author key that is not the signer is refused', () async {
    final pkg = ExtPackage.open(fixture);
    // A valid key envelope for a different key id.
    final other = base64Encode([0x45, 0x64, ...List.filled(8, 7), ...List.filled(32, 9)]);
    await expectLater(pkg.verify(authorKeyLine: other), throwsA(isA<PackageError>()));
  });

  test('a changed file is refused', () async {
    final pkg = ExtPackage.open(fixture);
    final files = Map.of(pkg.files);
    final panel = Uint8List.fromList(files['panel.html']!);
    panel[0] ^= 1;
    files['panel.html'] = panel;
    await expectLater(ExtPackage.fromFiles(files, pkg.manifest).verify(), throwsA(isA<PackageError>()));
  });

  test('a changed trusted comment is refused even with a matching digest', () async {
    final pkg = ExtPackage.open(fixture);
    final sig = utf8.decode(pkg.files[signatureName]!).split('\n');
    sig[2] = sig[2].replaceFirst('timestamp:', 'timestamp:1');
    final files = Map.of(pkg.files)..[signatureName] = Uint8List.fromList(utf8.encode(sig.join('\n')));
    await expectLater(ExtPackage.fromFiles(files, pkg.manifest).verify(), throwsA(isA<PackageError>()));
  });

  test('a team signature only verifies for its own role', () async {
    final revocations = File('../extensions/revocations.json').readAsBytesSync();
    final sig = File('../extensions/revocations.json.minisig').readAsStringSync();
    await expectLater(verifyCatalogSignature(sig, revocations), throwsA(isA<SignatureError>()));
  });
}
