@TestOn('linux')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';
import 'package:sora/src/ui/servers.dart' show protocolLine;

void main() {
  final binary = Platform.environment['SORA_CORE_BIN'];
  final socket = Platform.environment['SORA_CORE_SOCKET'];
  final enabled = binary != null && socket != null;
  test('olcrtc imports through the real core and exposes only a credential reference', () async {
    final home = await Directory.systemTemp.createTemp('sora-olc-');
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
      const key = 'd823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799';
      const raw =
          'olcrtc://jitsi?vp8channel<vp8-fps=60&vp8-batch=64>@https://meet.example.org/room#'
          '$key\$Community';
      final parsed = await link.stub.parseImport(ParseImportRequest(apiVersion: apiVersion, payload: raw.codeUnits));
      expect(parsed.hasError(), isFalse);
      expect(parsed.sessionPlan.outbounds.single.protocol, 'olcrtc');
      expect(protocolLine(parsed.sessionPlan.outbounds.single), startsWith('OLCRTC'));
      expect(parsed.toString(), isNot(contains(key)));
      expect(parsed.sessionPlan.outbounds.single.credentials.reference, isNotEmpty);
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
      expect(refreshed.state.outbounds.single.displayName, 'Community');
      expect(refreshed.state.settings.autoUpdate, isFalse);
      expect(refreshed.toString(), isNot(contains(key)));
      final malformed = await link.stub.parseImport(
        ParseImportRequest(apiVersion: apiVersion, payload: 'olcrtc://broken'.codeUnits),
      );
      expect(malformed.sessionPlan.outbounds, isEmpty);
    } finally {
      await link?.close();
      core.kill();
      await core.exitCode.timeout(const Duration(seconds: 10));
      await home.delete(recursive: true);
    }
  }, skip: enabled ? false : 'set SORA_CORE_BIN and a fresh SORA_CORE_SOCKET');
}
