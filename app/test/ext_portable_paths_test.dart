import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/ext/manifest.dart';
import 'package:sora/src/ext/package.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/ext/verifier.dart';

void main() {
  final vectors = jsonDecode(File('test/fixtures/ext/portable_paths.json').readAsStringSync()) as Map<String, dynamic>;
  final fixture = File('test/fixtures/ext/fixture.soraext').readAsBytesSync();
  final unsafe = (vectors['unsafe'] as List).cast<String>();
  final conflicts = (vectors['conflicts'] as List).map((e) => (e as List).cast<String>());
  for (final names in [
    for (final name in unsafe) [name],
    ...conflicts,
  ]) {
    test('portable archive refuses ${names.join('+')}', () async {
      final archive = ZipDecoder().decodeBytes(fixture);
      for (final name in names) {
        archive.addFile(ArchiveFile.string(name, 'alias content'));
      }
      final bytes = ZipEncoder().encodeBytes(archive);
      expect(
        () => ExtPackage.open(bytes),
        throwsA(isA<PackageError>().having((e) => e.message, 'reason', contains('path'))),
      );
      final pkg = ExtPackage.open(fixture);
      final files = Map.of(pkg.files);
      for (final name in names) {
        files[name] = Uint8List.fromList(utf8.encode('changed after opening'));
      }
      await expectLater(
        ExtPackage.fromFiles(files, pkg.manifest).verify(),
        throwsA(isA<PackageError>().having((e) => e.message, 'reason', contains('path'))),
      );
    });
  }
  test('portable names preserve valid Unicode and bundle naming', () async {
    final archive = ZipDecoder().decodeBytes(fixture);
    for (final name in (vectors['valid'] as List).cast<String>()) {
      archive.addFile(ArchiveFile.string(name, 'portable content'));
    }
    final pkg = ExtPackage.open(ZipEncoder().encodeBytes(archive));
    expect(pkg.files.keys, containsAll((vectors['valid'] as List).cast<String>()));
    await expectLater(
      pkg.verify(),
      throwsA(isA<PackageError>().having((e) => e.message, 'reason', contains('not covered'))),
    );
  });
  for (final name in ['${'a' * 256}.js', 'я' * 128, String.fromCharCode(0xd800)]) {
    test('portable names reject invalid byte/component bounds ${name.length}', () async {
      final pkg = ExtPackage.open(fixture);
      final files = Map.of(pkg.files)..[name] = Uint8List(0);
      await expectLater(
        ExtPackage.fromFiles(files, pkg.manifest).verify(),
        throwsA(isA<PackageError>().having((e) => e.message, 'reason', contains('path'))),
      );
    });
  }
  test('an authentic signed alias package cannot change the store', () async {
    final bytes = File('test/fixtures/ext/signed_case_alias.soraext').readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    final files = <String, Uint8List>{for (final file in archive.files) file.name: file.readBytes()!};
    final manifest = ExtManifest.parse(utf8.decode(files[manifestName]!));
    await verifyPackageSignature(manifest.author.publicKey, utf8.decode(files[signatureName]!), files[checksumsName]!);
    expect(
      () => ExtPackage.open(bytes),
      throwsA(isA<PackageError>().having((e) => e.message, 'reason', contains('path'))),
    );
    final directory = await Directory.systemTemp.createTemp('sora-portable-store-');
    addTearDown(() => directory.delete(recursive: true));
    final store = ExtensionStore(dir: directory.path);
    addTearDown(store.dispose);
    final valid = ExtPackage.open(fixture);
    await store.install(valid, source: 'sideload', granted: valid.manifest.permissions);
    final registry = File('${directory.path}/installed.json');
    final before = await registry.readAsBytes();
    await expectLater(
      store.install(ExtPackage.fromFiles(files, manifest), source: 'sideload', granted: manifest.permissions),
      throwsA(isA<PackageError>().having((e) => e.message, 'reason', contains('path'))),
    );
    expect(await registry.readAsBytes(), before);
    expect(store.installed.map((e) => e.id), [valid.manifest.id]);
    expect(await Directory('${directory.path}/${manifest.id}@${manifest.version}').exists(), isFalse);
  });
  test('the ZIP library stops inflation at a false declared size', () {
    final archive = Archive()..addFile(ArchiveFile.string('entry.txt', 'x' * (128 * 1024)));
    final bytes = ZipEncoder().encodeBytes(archive);
    final headers = ZipDirectory()..read(InputMemoryStream(bytes));
    // The first central header's uncompressed-size field starts at byte 24.
    ByteData.sublistView(bytes).setUint32(headers.centralDirectoryOffset + 24, 1, Endian.little);
    expect(
      () => ExtPackage.open(bytes),
      throwsA(isA<PackageError>().having((e) => e.message, 'reason', contains('cannot decompress'))),
    );
  });
  for (final problem in ['filename', 'compression', 'encryption']) {
    test('ZIP local metadata cannot bypass central $problem checks', () {
      final archive = Archive()..addFile(ArchiveFile.string('entry.txt', 'content'));
      final bytes = ZipEncoder().encodeBytes(archive);
      final fields = ByteData.sublistView(bytes);
      if (problem == 'filename') {
        bytes.setRange(30, 39, utf8.encode('other.txt'));
      } else if (problem == 'compression') {
        fields.setUint16(8, 12, Endian.little);
      } else {
        fields.setUint16(6, 1, Endian.little);
      }
      expect(
        () => ExtPackage.open(bytes),
        throwsA(
          isA<PackageError>().having(
            (e) => e.message,
            'reason',
            contains(problem == 'encryption' ? 'encrypted' : 'metadata'),
          ),
        ),
      );
    });
  }
}
