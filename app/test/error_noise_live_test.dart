@TestOn('linux')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final binary = Platform.environment['SORA_CORE_BIN'];
  final socket = Platform.environment['SORA_CORE_SOCKET'];
  final engines = Platform.environment['SORA_ENGINES_DIR'];
  test(
    'real core: plan errors, subscription failure and service restart',
    () async {
      final dir = await Directory.systemTemp.createTemp('sora-noise-');
      final certificate = await Process.run('openssl', [
        'req',
        '-x509',
        '-newkey',
        'rsa:2048',
        '-nodes',
        '-days',
        '1',
        '-subj',
        '/CN=127.0.0.1',
        '-addext',
        'subjectAltName=IP:127.0.0.1',
        '-keyout',
        '${dir.path}/key.pem',
        '-out',
        '${dir.path}/cert.pem',
      ]);
      expect(certificate.exitCode, 0);
      final tls = SecurityContext()
        ..useCertificateChain('${dir.path}/cert.pem')
        ..usePrivateKey('${dir.path}/key.pem');
      final provider = await HttpServer.bindSecure(InternetAddress.anyIPv4, 0, tls);
      var mode = 'good';
      final stalled = Completer<void>();
      final serving = provider.listen((request) async {
        if (mode == 'timeout') {
          await stalled.future;
          return;
        } else if (mode == 'status') {
          request.response.statusCode = HttpStatus.forbidden;
        } else if (mode == 'good') {
          request.response.write('trojan://test-password@127.0.0.1:443#Test');
        } else if (mode == 'empty-list') {
          request.response.write('{"outbounds":[]}');
        }
        await request.response.close();
      }, onError: (Object error) => expect(error, isA<HandshakeException>()));
      Future<Process> launch() => Process.start(
        binary!,
        [
          '-socket',
          socket!,
          '-data-dir',
          '${dir.path}/data',
          '-engines-dir',
          engines ?? '${dir.path}/engines',
          '-allow-file-keys',
        ],
        environment: {'SSL_CERT_FILE': '${dir.path}/cert.pem'},
      );
      var core = await launch();
      void drain(Process process) {
        unawaited(process.stdout.drain<void>());
        unawaited(process.stderr.drain<void>());
      }

      drain(core);
      debugPrint('live: core launched');
      final link = await CoreLink.open().timeout(const Duration(seconds: 20));
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final settings = await Settings.load();
      settings.language = 'ru';
      final sora = Sora(settings, extensions: ExtensionStore(dir: '${dir.path}/extensions'));
      debugPrint('live: handshake answered');
      final running = sora.run();
      Future<void> until(bool Function() ready) async {
        final deadline = DateTime.now().add(const Duration(seconds: 25));
        while (!ready()) {
          if (DateTime.now().isAfter(deadline)) fail('Timed out waiting for real core');
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      }

      try {
        Future<String> connect(SessionPlan plan) async {
          final answer = await link.stub.connect(
            ConnectRequest(apiVersion: apiVersion, controlAuthenticator: link.token, sessionPlan: plan),
          );
          return answer.error.userMessageKey;
        }

        debugPrint('live: validating plans');
        expect(await connect(SessionPlan()), 'core.plan.empty');
        final malformed = SessionPlan(
          tunnelMode: TunnelMode.TUNNEL_MODE_APPLICATION,
          outbounds: [
            OutboundSpec(
              id: 'test',
              protocol: 'unknown',
              endpoint: Endpoint(host: '127.0.0.1', port: 443),
            ),
          ],
        );
        expect(await connect(malformed), 'core.plan.outbounds_invalid');
        if (engines != null) {
          final unsupported = SessionPlan(
            tunnelMode: TunnelMode.TUNNEL_MODE_APPLICATION,
            engines: ['xray'],
            outbounds: [
              OutboundSpec(
                id: 'tuic',
                protocol: 'tuic',
                transport: 'udp',
                endpoint: Endpoint(host: '127.0.0.1', port: 443),
              ),
            ],
          );
          expect(await connect(unsupported), 'core.plan.engine_unsupported');
          debugPrint('live: TUIC pinned to Xray => core.plan.engine_unsupported');
        }
        final missing = await link.stub.refreshSubscription(
          RefreshSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: 'missing'),
        );
        expect(missing.error.userMessageKey, 'core.subscription.not_found');
        final connections = await link.stub.listConnections(
          ListConnectionsRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
        );
        expect(connections.error.userMessageKey, 'core.connections.unavailable');
        debugPrint('live: waiting for app handshake');
        await until(() => sora.coreHandshakeDone);
        debugPrint('live: app handshake answered');
        final tlsFailure = await link.stub.fetchSubscription(
          FetchSubscriptionRequest(apiVersion: apiVersion, reference: 'https://127.0.0.2:${provider.port}/test'),
        );
        expect(tlsFailure.error.userMessageKey, 'core.tls.certificate');
        expect(await sora.addSubscription('https://127.0.0.1:${provider.port}/test'), isNull);
        await until(() => sora.subscriptions.isNotEmpty && sora.subscriptions.single.outbounds.isNotEmpty);
        debugPrint('live: subscription loaded');
        final id = sora.subscriptions.single.settings.id;
        final original = sora.subscriptions.single.outbounds.single;
        for (final pair in [
          ('status', 'core.subscription.status'),
          ('empty', 'core.subscription.empty'),
          ('empty-list', 'core.subscription.no_servers'),
          ('timeout', 'core.request.deadline_exceeded'),
        ]) {
          mode = pair.$1;
          final before = sora.history.length;
          expect((await sora.refreshSubscription(id))?.key, pair.$2);
          await until(() => sora.subscriptions.single.hasLastError());
          await Future<void>.delayed(const Duration(milliseconds: 100));
          expect(sora.history.length, before + 1, reason: 'RPC and watch must share one notification');
          expect(sora.history.first.action, 'subscription');
          expect(sora.history.first.failureKey, pair.$2);
          debugPrint('live: ${pair.$1} => ${pair.$2}, one notification, previous servers kept');
          if (pair.$1 == 'status') expect(sora.history.first.title, sora.strings.errHttpStatus(403));
          expect(sora.subscriptions.single.outbounds.single, original);
          if (pair.$1 == 'timeout') stalled.complete();
          mode = 'good';
          expect(await sora.refreshSubscription(id), isNull);
          await until(() => !sora.subscriptions.single.hasLastError());
          expect(sora.subscriptions.single.hasFailureSince(), isFalse);
          expect(sora.backgroundFailure('subscription:$id'), isNull);
        }
        debugPrint('live: subscription recovery verified');
        await sora.clearNotifications();
        debugPrint('live: stopping core');
        core.kill();
        await core.exitCode;
        await until(() => sora.phase == Phase.offline);
        core = await launch();
        drain(core);
        await until(() => sora.phase != Phase.offline);
        expect(sora.history, isEmpty, reason: 'short service restart must be silent');
        debugPrint('live: stopping core');
        core.kill();
        await core.exitCode;
        await until(() => sora.phase == Phase.offline);
        await until(() => sora.history.isNotEmpty);
        expect(sora.history, hasLength(1));
        expect(sora.history.single.failureKey, 'app.core_unavailable');
        core = await launch();
        drain(core);
        await until(() => sora.phase != Phase.offline);
        expect(sora.backgroundFailure('core'), isNull);
      } finally {
        if (!stalled.isCompleted) stalled.complete();
        sora.dispose();
        await running.timeout(const Duration(seconds: 10));
        await link.close();
        debugPrint('live: stopping core');
        core.kill();
        await core.exitCode;
        await provider.close(force: true);
        await serving.cancel();
        await dir.delete(recursive: true);
      }
    },
    skip: binary == null || socket == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
