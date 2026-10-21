import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/ext/manifest.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/ui/extensions/panel_screen.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('sora-panel-'));
  tearDown(() => dir.delete(recursive: true));

  // Uri on either side would normalize dot segments away, so requests go out raw.
  Future<String> get(Uri base, String path) async {
    final socket = await Socket.connect(base.host, base.port);
    socket.write('GET $path HTTP/1.1\r\nHost: ${base.host}\r\nConnection: close\r\n\r\n');
    return String.fromCharCodes(await socket.expand((b) => b).toList());
  }

  test('the panel entry gets the bridge bootstrap, other pages and files outside do not', () async {
    final root = await Directory('${dir.path}/content/ui').create(recursive: true);
    await File('${root.path}/panel.html').writeAsString('<html><head></head><body>panel</body></html>');
    await File('${root.path}/other.html').writeAsString('<html><head></head><body>other</body></html>');
    await File('${dir.path}/secret.txt').writeAsString('secret');
    final server = LocalPanelServer('${dir.path}/content', entry: 'ui/panel.html', bootstrap: 'window.marker=1;');
    final base = await server.start();
    addTearDown(server.stop);

    final entry = await get(base, '/ui/panel.html');
    expect(entry, startsWith('HTTP/1.1 200'));
    expect(entry, contains('<head><script>window.marker=1;</script>'));
    expect(await get(base, '/ui/other.html'), isNot(contains('window.marker')));
    for (final path in ['/../secret.txt', '/%2e%2e/secret.txt', '/ui/..%2f..%2fsecret.txt']) {
      final answer = await get(base, path);
      expect(answer, isNot(startsWith('HTTP/1.1 200')), reason: path);
      expect(answer, isNot(contains('secret')), reason: path);
    }
  });

  test('disabling an extension keeps its rollback version', () async {
    final manifest = ExtManifest.parse(await File('../examples/theme-midnight/sora-extension.json').readAsString());
    final inst = InstalledExtension(
      manifest: manifest,
      enabled: true,
      source: 'sideload',
      installedAt: DateTime.utc(2026, 10, 21),
      granted: manifest.permissions,
      previous: '0.9.0',
    );
    expect(inst.copyWith(enabled: false).previous, '0.9.0');
  });
}
