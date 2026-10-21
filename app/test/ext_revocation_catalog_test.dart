import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sora/src/ext/catalog.dart';
import 'package:sora/src/ext/package.dart';
import 'package:sora/src/ext/store.dart';

/// The team catalog and revocation list the app downloads are the signed
/// files in extensions/ of the repository; these tests serve exactly those
/// bytes. The revocation fixtures revoke only a test id.
void main() {
  final repo = Directory('..').absolute.path;
  File published(String name) => File('$repo/extensions/$name');
  File fixture(String name) => File('test/fixtures/ext/$name');

  MockClient serving(Map<String, File> files) => MockClient((request) async {
    for (final e in files.entries) {
      if (request.url.toString() == e.key) return http.Response.bytes(await e.value.readAsBytes(), 200);
    }
    return http.Response('missing', 404);
  });

  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('sora-ext-store-'));
  tearDown(() => dir.delete(recursive: true));

  Future<void> cacheRevocations(String name) async {
    await File('${dir.path}/revocations.json').writeAsBytes(await fixture('$name.json').readAsBytes());
    await File('${dir.path}/revocations.json.minisig').writeAsBytes(await fixture('$name.json.minisig').readAsBytes());
  }

  Future<ExtPackage> revokedPackage() async => ExtPackage.open(await fixture('revoked.soraext').readAsBytes());

  test('the published catalog verifies and its package installs from the catalog', () async {
    final client = serving({
      defaultCatalogUrl: published('catalog.json'),
      '$defaultCatalogUrl.minisig': published('catalog.json.minisig'),
    });
    final catalog = await fetchCatalog(client: client);
    final entry = catalog.entries.single;
    final bytes = await published('packages/${entry.downloadUrl.split('/').last}').readAsBytes();
    expect(bytes.length, entry.size);
    final store = ExtensionStore(dir: dir.path);
    await store.load();
    await store.install(
      ExtPackage.open(bytes),
      source: 'catalog',
      granted: entry.permissions,
      authorKeyPin: entry.authorKey,
    );
    expect(store.isEnabled(entry.id), isTrue);
  });

  test('the published revocation list verifies and revokes nothing installed', () async {
    final store = ExtensionStore(dir: dir.path);
    await store.load();
    final client = serving({
      'https://raw.githubusercontent.com/levvs-one/sora/main/extensions/revocations.json': published(
        'revocations.json',
      ),
      'https://raw.githubusercontent.com/levvs-one/sora/main/extensions/revocations.json.minisig': published(
        'revocations.json.minisig',
      ),
    });
    expect(await store.refreshRevocations(client: client), isEmpty);
  });

  test('a revoked extension is disabled, cannot be enabled and cannot be reinstalled', () async {
    var store = ExtensionStore(dir: dir.path);
    await store.load();
    final pkg = await revokedPackage();
    await store.install(pkg, source: 'sideload', granted: pkg.manifest.permissions);
    expect(store.isEnabled(pkg.manifest.id), isTrue);

    await cacheRevocations('revocations-revoked');
    store = ExtensionStore(dir: dir.path);
    await store.load();
    expect(store.isEnabled(pkg.manifest.id), isFalse);
    expect(store.revocationOf(pkg.manifest.id)?.reason, 'test fixture');
    await expectLater(store.setEnabled(pkg.manifest.id, true), throwsA(isA<ExtStoreError>()));
    await store.uninstall(pkg.manifest.id);
    await expectLater(
      store.install(await revokedPackage(), source: 'sideload', granted: pkg.manifest.permissions),
      throwsA(isA<ExtStoreError>()),
    );
  });

  test('an expired list blocks installs but keeps installed extensions', () async {
    var store = ExtensionStore(dir: dir.path);
    await store.load();
    final pkg = await revokedPackage();
    await store.install(pkg, source: 'sideload', granted: pkg.manifest.permissions);
    await cacheRevocations('revocations-expired');
    store = ExtensionStore(dir: dir.path);
    await store.load();
    expect(store.isEnabled(pkg.manifest.id), isTrue);
    final fresh = ExtensionStore(dir: '${dir.path}/fresh');
    await fresh.load();
    await Directory('${dir.path}/fresh').create(recursive: true);
    for (final name in ['revocations.json', 'revocations.json.minisig']) {
      await File('${dir.path}/$name').copy('${dir.path}/fresh/$name');
    }
    final reloaded = ExtensionStore(dir: '${dir.path}/fresh');
    await reloaded.load();
    await expectLater(
      reloaded.install(await revokedPackage(), source: 'sideload', granted: pkg.manifest.permissions),
      throwsA(isA<ExtStoreError>()),
    );
  });

  test('a tampered cached list is ignored', () async {
    await cacheRevocations('revocations-revoked');
    final raw = await File('${dir.path}/revocations.json').readAsString();
    await File('${dir.path}/revocations.json').writeAsString(raw.replaceFirst('test fixture', 'tampered'));
    final store = ExtensionStore(dir: dir.path);
    await store.load();
    final pkg = await revokedPackage();
    await store.install(pkg, source: 'sideload', granted: pkg.manifest.permissions);
    expect(store.isEnabled(pkg.manifest.id), isTrue);
  });
}
