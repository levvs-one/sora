import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/ext/manifest.dart' show compareVersions;
import 'package:sora/src/ext/package.dart';
import 'package:sora/src/ext/store.dart';
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

  test('published Hello can update and roll back with the same temporary author', () async {
    final publishedBytes = await File('test/fixtures/ext/hello-panel-published-1.0.0.soraext').readAsBytes();
    expect(
      crypto.sha256.convert(publishedBytes).toString(),
      'ba5fffb5b9c9b521fa39aebc8d2bb2efee048ad4da34af281d555e338fb19012',
    );
    final published = ExtPackage.open(publishedBytes);
    expect(published.manifest.id, 'org.sora.hello-panel');
    expect(published.manifest.version, '1.0.0');
    await published.verify();

    final work = await Directory.systemTemp.createTemp('sora-hello-upgrade-');
    addTearDown(() => work.delete(recursive: true));
    final tool = '${work.path}/sora-ext${Platform.isWindows ? '.exe' : ''}';
    final build = await Process.run('go', [
      'build',
      '-o',
      tool,
      './cmd/sora-ext',
    ], workingDirectory: '../tools/sora-ext');
    expect(build.exitCode, 0, reason: '${build.stderr}');
    Future<void> run(List<String> args) async {
      final result = await Process.run(tool, args);
      expect(result.exitCode, 0, reason: '${args.first}: ${result.stderr}');
    }

    final key = '${work.path}/temporary-author';
    await run(['keygen', '-o', key]);
    final author = (await File('$key.pub').readAsLines()).last.trim();

    final oldSource = await Directory('${work.path}/old').create();
    for (final file in published.files.entries) {
      if (file.key == checksumsName || file.key == signatureName) continue;
      final target = File('${oldSource.path}/${file.key}');
      await target.parent.create(recursive: true);
      await target.writeAsBytes(file.value);
    }
    final newSource = await Directory('${work.path}/new').create();
    final current = Directory('../examples/hello-panel');
    await for (final file in current.list(recursive: true, followLinks: false)) {
      if (file is! File) continue;
      final relative = file.path.substring(current.path.length + 1);
      final target = File('${newSource.path}/$relative');
      await target.parent.create(recursive: true);
      await file.copy(target.path);
    }
    final packages = <Uint8List>[];
    for (final source in [oldSource, newSource]) {
      final file = File('${source.path}/sora-extension.json');
      final manifest = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      (manifest['author'] as Map<String, dynamic>)['public_key'] = author;
      await file.writeAsString(jsonEncode(manifest));
      final output = '${source.path}.soraext';
      await run(['pack', source.path, '-o', output]);
      await run(['sign', '--key', '$key.key', output]);
      packages.add(await File(output).readAsBytes());
    }
    final before = ExtPackage.open(packages[0]);
    final after = ExtPackage.open(packages[1]);
    expect(after.manifest.id, before.manifest.id);
    expect(compareVersions(after.manifest.version, before.manifest.version), greaterThan(0));
    expect(after.files['panel.html'], isNot(equals(before.files['panel.html'])));
    final store = ExtensionStore(dir: '${work.path}/store');
    addTearDown(store.dispose);
    await store.load();
    await store.install(before, source: 'catalog', granted: before.manifest.permissions, authorKeyPin: author);
    await store.setSettings(before.manifest.id, {'refresh_seconds': 11});
    await store.setEnabled(before.manifest.id, false);

    final digest = crypto.sha256.convert(packages[1]).toString();
    final corrupted = Uint8List.fromList(packages[1])..[0] ^= 1;
    await expectLater(
      store.installBytes(
        corrupted,
        source: 'catalog',
        granted: after.manifest.permissions,
        expectedSha256: digest,
        authorKeyPin: author,
      ),
      throwsA(isA<ExtStoreError>()),
    );
    await expectLater(
      store.installBytes(
        packages[1],
        source: 'catalog',
        granted: after.manifest.permissions,
        expectedSha256: digest,
        authorKeyPin: published.manifest.author.publicKey,
      ),
      throwsA(isA<ExtStoreError>()),
    );
    expect(store.get(before.manifest.id)!.version, before.manifest.version);
    await store.installBytes(
      packages[1],
      source: 'catalog',
      granted: after.manifest.permissions,
      expectedSha256: digest,
      authorKeyPin: author,
    );
    expect(store.get(before.manifest.id)!.version, after.manifest.version);
    expect(store.get(before.manifest.id)!.previous, before.manifest.version);
    expect(store.isEnabled(before.manifest.id), isFalse);
    expect((await store.getSettings(before.manifest.id))['refresh_seconds'], 11);

    final reloaded = ExtensionStore(dir: '${work.path}/store');
    addTearDown(reloaded.dispose);
    await reloaded.load();
    expect(reloaded.get(before.manifest.id)!.version, after.manifest.version);
    expect((await reloaded.getSettings(before.manifest.id))['refresh_seconds'], 11);
    final previousPanel = File('${work.path}/store/${before.manifest.id}@${before.manifest.version}/panel.html');
    final originalPanel = before.files['panel.html']!;
    await previousPanel.writeAsBytes(Uint8List.fromList(originalPanel)..[0] ^= 1);
    await expectLater(reloaded.rollback(before.manifest.id), throwsA(isA<ExtStoreError>()));
    expect(reloaded.get(before.manifest.id)!.version, after.manifest.version);
    await previousPanel.writeAsBytes(originalPanel);
    await reloaded.rollback(before.manifest.id);
    expect(reloaded.get(before.manifest.id)!.version, before.manifest.version);
    expect(reloaded.isEnabled(before.manifest.id), isFalse);
    expect((await reloaded.getSettings(before.manifest.id))['refresh_seconds'], 11);
    final restored = await File('${work.path}/store/${before.manifest.id}@${before.manifest.version}/panel.html')
        .readAsBytes();
    expect(restored, published.files['panel.html']);
  });

  test('a team signature only verifies for its own role', () async {
    final revocations = File('../extensions/revocations.json').readAsBytesSync();
    final sig = File('../extensions/revocations.json.minisig').readAsStringSync();
    await expectLater(verifyCatalogSignature(sig, revocations), throwsA(isA<SignatureError>()));
  });
}
