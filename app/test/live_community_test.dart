@TestOn('linux')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/desktop/links.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';
import 'package:sora/src/ui/servers.dart' show protocolLine;

void main() {
  final binary = Platform.environment['SORA_CORE_BIN'];
  final socket = Platform.environment['SORA_CORE_SOCKET'];
  test('community links persist through the real core without exposing credentials', () async {
    final home = await Directory.systemTemp.createTemp('sora-community-');
    final core = await Process.start(binary!, [
      '-socket',
      socket!,
      '-data-dir',
      home.path,
      '-allow-file-keys',
      '-engines-dir',
      Platform.environment['SORA_ENGINES_DIR'] ?? '${home.path}/engines',
    ]);
    unawaited(core.stdout.drain<void>());
    unawaited(core.stderr.drain<void>());
    CoreLink? link;
    try {
      link = await CoreLink.open().timeout(const Duration(seconds: 20));
      for (final (protocol, raw) in [
        ('mieru', 'mieru://CjoKCUNvbW11bml0eRIZCgVhbGljZRIQcHJpdmF0ZS1wYXNzd29yZBoSCgkxMjcuMC4wLjEaBQi7AxAC'),
        ('mieru', 'mierus://alice:private-password@127.0.0.1?profile=Community&port=4200-4202&protocol=UDP'),
        (
          'naive',
          'naive+https://alice:private-password@127.0.0.1:443/?extra-headers=X-Test%3A%20private-header#Community',
        ),
        ('naive', 'naive+quic://alice:private-password@127.0.0.1:443/#QUIC'),
      ]) {
        final imported = parseImportLink(raw)! as AddSubscription;
        expect(imported.url, raw);
        final parsed = await link.stub.parseImport(
          ParseImportRequest(apiVersion: apiVersion, payload: imported.url.codeUnits),
        );
        expect(parsed.hasError(), isFalse);
        expect(parsed.sessionPlan.outbounds.single.protocol, protocol);
        expect(protocolLine(parsed.sessionPlan.outbounds.single), startsWith(protocol.toUpperCase()));
        expect(parsed.toString(), isNot(contains('private-password')));
        expect(parsed.toString(), isNot(contains('private-header')));
        final saved = await link.stub.saveSubscription(
          SaveSubscriptionRequest(
            apiVersion: apiVersion,
            controlAuthenticator: link.token,
            settings: SubscriptionSettings(url: raw, autoUpdate: true),
          ),
        );
        expect(saved.hasError(), isFalse);
        final refreshed = await link.stub.refreshSubscription(
          RefreshSubscriptionRequest(
            apiVersion: apiVersion,
            controlAuthenticator: link.token,
            id: saved.state.settings.id,
          ),
        );
        expect(refreshed.hasError(), isFalse);
        expect(refreshed.state.settings.autoUpdate, isFalse);
        expect(refreshed.state.outbounds.single.protocol, protocol);
        expect(refreshed.toString(), isNot(contains('private-password')));
      }
    } finally {
      await link?.close();
      core.kill();
      await core.exitCode.timeout(const Duration(seconds: 10));
      await home.delete(recursive: true);
    }
  }, skip: binary == null || socket == null ? 'set SORA_CORE_BIN and a fresh SORA_CORE_SOCKET' : false);
}
