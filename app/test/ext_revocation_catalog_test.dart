import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sora/src/ext/catalog.dart';
import 'package:sora/src/ext/package.dart';
import 'package:sora/src/ext/store.dart';

/// Serve the signed catalog files committed in extensions/ and the
/// published revocation list. The revocation fixtures revoke only a test id.
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

  const legacyUrl = 'https://raw.githubusercontent.com/levvs-one/sora/main/extensions/catalog.json';
  const catalog113Url = 'https://raw.githubusercontent.com/levvs-one/sora/main/extensions/catalog-1.1.3.json';
  test('the compatible host uses its own catalog URL', () {
    expect(defaultCatalogUrl, 'https://raw.githubusercontent.com/levvs-one/sora/main/extensions/catalog-1.1.6.json');
    expect(defaultCatalogUrl, isNot(legacyUrl));
  });

  for (final (label, url, file) in [
    ('legacy published catalog', legacyUrl, 'catalog.json'),
    ('1.1.3 to 1.1.5 repository catalog', catalog113Url, 'catalog-1.1.3.json'),
    ('compatible-host repository catalog', defaultCatalogUrl, 'catalog-1.1.6.json'),
  ]) {
    test('$label verifies and every package matches and installs', () async {
      final client = serving({url: published(file), '$url.minisig': published('$file.minisig')});
      addTearDown(client.close);
      final catalog = await fetchCatalog(client: client, url: url);
      expect(catalog.entries, isNotEmpty);
      final store = ExtensionStore(dir: dir.path);
      addTearDown(store.dispose);
      await store.load();
      for (final entry in catalog.entries) {
        final bytes = await published('packages/${entry.downloadUrl.split('/').last}').readAsBytes();
        final manifest = ExtPackage.open(bytes).manifest;
        expect(bytes.length, entry.size, reason: entry.id);
        expect(manifest.id, entry.id);
        expect(manifest.version, entry.version, reason: entry.id);
        expect(manifest.minAppVersion, entry.minAppVersion, reason: entry.id);
        expect(manifest.permissions, unorderedEquals(entry.permissions), reason: entry.id);
        expect(manifest.capabilities, unorderedEquals(entry.capabilities), reason: entry.id);
        await store.installBytes(
          bytes,
          source: 'catalog',
          granted: entry.permissions,
          expectedSha256: entry.sha256,
          authorKeyPin: entry.authorKey,
        );
        expect(store.isEnabled(entry.id), isTrue, reason: entry.id);
      }
      expect(store.installed.map((value) => value.id).toSet(), catalog.entries.map((entry) => entry.id).toSet());
    });
  }

  test('a verified legacy cache survives an offline catalog transition', () async {
    final cache = CatalogCache(dir.path);
    final legacy = serving({
      legacyUrl: published('catalog.json'),
      '$legacyUrl.minisig': published('catalog.json.minisig'),
    });
    final offline = serving({});
    final compatible = serving({
      defaultCatalogUrl: published('catalog-1.1.6.json'),
      '$defaultCatalogUrl.minisig': published('catalog-1.1.6.json.minisig'),
    });
    addTearDown(legacy.close);
    addTearDown(offline.close);
    addTearDown(compatible.close);

    final original = await cache.refresh(client: legacy, url: legacyUrl);
    expect(original.fromCache, isFalse);
    final fallback = await cache.refresh(client: offline);
    expect(fallback.fromCache, isTrue);
    expect(
      fallback.catalog.entries.map((entry) => entry.id),
      orderedEquals(original.catalog.entries.map((entry) => entry.id)),
    );
    await expectLater(CatalogCache('${dir.path}/new').refresh(client: offline), throwsA(isA<CatalogError>()));
    final refreshed = await cache.refresh(client: compatible);
    expect(refreshed.fromCache, isFalse);
    expect(refreshed.catalog.entries, isNotEmpty);
  });

  test('release catalog is available with a trusted signature', () async {
    await fetchCatalog();
  }, skip: const bool.fromEnvironment('SORA_VERIFY_LIVE_CATALOG') ? false : 'tagged release check only');

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
