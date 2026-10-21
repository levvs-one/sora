// Requires SORA_CORE_BIN (a sora-core built from this tree) and
// SORA_CORE_SOCKET (a fresh socket path). The core runs unprivileged on that
// socket with a private data directory, and the test calls the feature
// services through the same CoreLink the app uses.
@TestOn('linux')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, StatusCode;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/profiles.dart' as editor;
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';
import 'package:sora/src/generated/sora/custom/v1/custom.pbgrpc.dart';
import 'package:sora/src/generated/sora/ext/v1/ext_host.pbgrpc.dart';
import 'package:sora/src/ui/addserver.dart';

void main() {
  final binary = Platform.environment['SORA_CORE_BIN'];
  final socket = Platform.environment['SORA_CORE_SOCKET'];
  final enabled = binary != null && socket != null;
  final engines = Platform.environment['SORA_ENGINES_DIR'];
  final fetchEnabled = enabled && engines != null && Platform.environment['SORA_LIVE_EXTENSION_FETCH'] == '1';
  late Directory dir;
  late Process core;
  late CoreLink link;

  setUpAll(() async {
    if (!enabled) return;
    dir = await Directory.systemTemp.createTemp('sora-live-');
    if (fetchEnabled) {
      final certificate = await Process.run('openssl', [
        'req',
        '-x509',
        '-newkey',
        'rsa:2048',
        '-nodes',
        '-days',
        '1',
        '-subj',
        '/CN=example.com',
        '-addext',
        'subjectAltName=DNS:example.com',
        '-keyout',
        '${dir.path}/key.pem',
        '-out',
        '${dir.path}/cert.pem',
      ]);
      expect(certificate.exitCode, 0, reason: certificate.stderr.toString());
    }
    core = await Process.start(binary, [
      '-socket',
      socket,
      '-data-dir',
      '${dir.path}/data',
      '-engines-dir',
      engines ?? '${dir.path}/none',
      '-allow-file-keys',
    ], environment: fetchEnabled ? {'SSL_CERT_FILE': '${dir.path}/cert.pem'} : null);
    unawaited(core.stdout.drain<void>());
    unawaited(core.stderr.drain<void>());
    link = await CoreLink.open().timeout(const Duration(seconds: 20));
  });

  tearDownAll(() async {
    if (!enabled) return;
    await link.close();
    core.kill();
    await core.exitCode;
    await dir.delete(recursive: true);
  });

  final skip = enabled ? false : 'set SORA_CORE_BIN to a sora-core built from this tree and SORA_CORE_SOCKET';

  test('the core negotiates the feature contract', () {
    expect(link.minor, apiVersion.minor);
  }, skip: skip);

  test('workers use the app control token without a service extension registry', () async {
    final denied = link.extensions.runWorker(Stream.value(WorkerClientMessage(controlToken: [0])));
    await expectLater(
      denied.first,
      throwsA(isA<GrpcError>().having((e) => e.code, 'code', StatusCode.unauthenticated)),
    );

    final input = StreamController<WorkerClientMessage>();
    final stream = link.extensions.runWorker(input.stream);
    input.add(
      WorkerClientMessage(
        controlToken: link.token,
        manifestJson:
            '{"manifest_version":1,"id":"com.example.live-worker","name":"Live Worker",'
            '"version":"1.0.0","min_app_version":"1.0.0",'
            '"author":{"name":"Test","identity":"github:example",'
            '"public_key":"RWQAAAAAAAAAAHd26HC5M1TyoLJMI/KjbMToDiIyGMG5eSb90Bg5aiub"},'
            '"permissions":["background"],"capabilities":["background"],'
            '"background_task":{"interval_minutes":15,"entry":"worker.js"}}',
        source: "console.log('live worker');",
        configJson: '{"enabled":true,"interval_minutes":15}',
      ),
    );
    try {
      expect((await stream.first.timeout(const Duration(seconds: 5))).log, 'background worker scheduled');
      expect(await Directory('${dir.path}/data/extensions').exists(), isFalse);
    } finally {
      await stream.cancel();
      await input.close();
    }
  }, skip: skip);

  test('a hand added server round-trips without exposing its secret', () async {
    final saved = await link.custom.saveCustomServer(
      SaveCustomServerRequest(
        apiVersion: apiVersion,
        controlAuthenticator: link.token,
        server: CustomServer(
          name: 'Manual',
          protocol: CustomProtocol.CUSTOM_PROTOCOL_VLESS,
          address: 'vpn.example.com',
          port: 443,
          credentials: customCredentialDocument(
            CustomProtocol.CUSTOM_PROTOCOL_VLESS,
            '11111111-2222-3333-4444-555555555555',
          ),
        ),
      ),
    );
    expect(saved.hasError(), isFalse, reason: saved.error.toString());
    final listed = await link.custom.listCustomServers(
      ListCustomServersRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
    );
    final server = listed.servers.singleWhere((s) => s.id == saved.server.id);
    // has_credentials clashes with the presence check of credentials in Dart.
    expect(server.hasCredentials_7, isTrue);
    expect(server.credentials, isEmpty);
    final bare = await link.custom.saveCustomServer(
      SaveCustomServerRequest(
        apiVersion: apiVersion,
        controlAuthenticator: link.token,
        server: CustomServer(
          name: 'Bare',
          protocol: CustomProtocol.CUSTOM_PROTOCOL_VLESS,
          address: 'vpn.example.com',
          port: 443,
          credentials: 'not-a-document',
        ),
      ),
    );
    expect(bare.hasError(), isTrue);
    final deleted = await link.custom.deleteCustomServer(
      DeleteCustomServerRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: server.id),
    );
    expect(deleted.hasError(), isFalse);
  }, skip: skip);

  test('a hand added WireGuard server is accepted and a broken one refused', () async {
    const key = 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=';
    Future<SaveCustomServerResponse> save(String credentials) => link.custom.saveCustomServer(
      SaveCustomServerRequest(
        apiVersion: apiVersion,
        controlAuthenticator: link.token,
        server: CustomServer(
          name: 'WG',
          protocol: CustomProtocol.CUSTOM_PROTOCOL_WIREGUARD,
          address: '198.51.100.7',
          port: 51820,
          credentials: credentials,
        ),
      ),
    );
    final good = customCredentialDocument(
      CustomProtocol.CUSTOM_PROTOCOL_WIREGUARD,
      key,
      wg: (addresses: '10.0.0.2/32', peerKey: key, presharedKey: '', allowedIps: '0.0.0.0/0', keepalive: ''),
    )!;
    final saved = await save(good);
    expect(saved.hasError(), isFalse, reason: saved.error.toString());
    expect((await save('{"private_key":"$key"}')).hasError(), isTrue);
  }, skip: skip);

  test('network profiles save, list and delete', () async {
    final saved = await link.stub.saveProfile(
      SaveProfileRequest(
        apiVersion: apiVersion,
        controlAuthenticator: link.token,
        profile: NetworkProfile(
          name: 'Home',
          triggers: ProfileTriggers(ssids: ['Home Wi-Fi']),
          apply: ProfileApply(mode: 'tun'),
        ),
      ),
    );
    expect(saved.hasError(), isFalse, reason: saved.error.toString());
    final listed = await link.stub.listProfiles(
      ListProfilesRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
    );
    expect(listed.profiles.map((p) => p.name), contains('Home'));
    final deleted = await link.stub.deleteProfile(
      DeleteProfileRequest(apiVersion: apiVersion, controlAuthenticator: link.token, profileId: saved.profile.id),
    );
    expect(deleted.hasError(), isFalse);
    final fingerprint = await link.stub.getNetworkFingerprint(
      GetNetworkFingerprintRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
    );
    expect(fingerprint.hasError(), isFalse, reason: fingerprint.error.toString());
  }, skip: skip);

  test('editor auto-apply profile reaches the real core on startup and every edit', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final settings = await Settings.load();
    final sora = Sora(settings);
    final profile = editor.NetworkProfile(
      id: 'editor-home',
      name: 'Editor home',
      ssids: ['Home'],
      gateways: ['192.168.1.1'],
      asns: ['64500'],
      autoApply: true,
      tunnel: 'proxy',
      preset: '',
      engine: '',
      dns: ['https://dns.example.com/dns-query'],
      dnsPreset: 'custom',
      serverId: 'auto',
    );
    sora.profiles.add(profile);
    final running = sora.run();
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (!sora.coreHandshakeDone) {
        if (DateTime.now().isAfter(deadline)) fail('Core handshake timed out');
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await sora.syncProfiles();
      Future<ListProfilesResponse> list() =>
          link.stub.listProfiles(ListProfilesRequest(apiVersion: apiVersion, controlAuthenticator: link.token));
      var listed = await list();
      expect(listed.hasError(), isFalse);
      expect(editor.NetworkProfile.fromWire(listed.profiles.single).toJson(), profile.toJson());
      profile.name = 'Edited home';
      profile.dns = [];
      sora.profiles.update(profile);
      await sora.syncProfiles();
      listed = await list();
      expect(editor.NetworkProfile.fromWire(listed.profiles.single).toJson(), profile.toJson());
      sora.profiles.remove(profile.id);
      await sora.syncProfiles();
      expect((await list()).profiles, isEmpty);
    } finally {
      sora.dispose();
      await running.timeout(const Duration(seconds: 10));
    }
  }, skip: skip);

  // The production scheduler intentionally waits at least fifteen minutes.
  // Opt in separately so ordinary test runs never shorten that boundary.
  test(
    'extension fetch and its DNS use the VPN despite matching direct rules',
    () async {
      final tls = SecurityContext()
        ..useCertificateChain('${dir.path}/cert.pem')
        ..usePrivateKey('${dir.path}/key.pem');
      final origin = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, tls);
      var requests = 0;
      final serving = origin.listen((request) async {
        requests++;
        expect(request.headers.value('proxy-authorization'), isNull);
        request.response.write('through-private-vpn');
        await request.response.close();
      });
      Future<int> freePort() async {
        final reservation = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final port = reservation.port;
        await reservation.close();
        return port;
      }

      // Xray's dns outbound forwards queries upstream, which this namespace
      // cannot reach, so the VPN exit hands port 53 to mihomo's resolver.
      final dnsPort = await freePort();
      final resolver = await Process.start('$engines/mihomo', ['-d', '${dir.path}/resolver', '-f', '-']);
      unawaited(resolver.stdout.drain<void>());
      unawaited(resolver.stderr.drain<void>());
      resolver.stdin.write(
        jsonEncode({
          'log-level': 'warning',
          'hosts': {
            'example.com': ['127.0.0.2', '::1'],
          },
          'dns': {
            'enable': true,
            'listen': '127.0.0.1:$dnsPort',
            'use-hosts': true,
            'ipv6': true,
            'nameserver': ['127.0.0.1:1'],
          },
          'rules': ['MATCH,DIRECT'],
        }),
      );
      await resolver.stdin.close();
      final vpnPort = await freePort();
      final config = {
        'log': {'loglevel': 'warning'},
        'inbounds': [
          {
            'listen': '127.0.0.1',
            'port': vpnPort,
            'protocol': 'shadowsocks',
            'settings': {'method': 'aes-256-gcm', 'password': 'live-extension-vpn-password'},
          },
        ],
        'routing': {
          'rules': [
            {'port': '53', 'outboundTag': 'resolver'},
          ],
        },
        'outbounds': [
          {
            'tag': 'origin',
            'protocol': 'freedom',
            'settings': {'redirect': '127.0.0.1:${origin.port}'},
          },
          {
            'tag': 'resolver',
            'protocol': 'freedom',
            'settings': {'redirect': '127.0.0.1:$dnsPort'},
          },
        ],
      };
      final vpn = await Process.start('$engines/xray', ['run', '-c', 'stdin:']);
      unawaited(vpn.stdout.drain<void>());
      unawaited(vpn.stderr.drain<void>());
      vpn.stdin.write(jsonEncode(config));
      await vpn.stdin.close();
      final input = StreamController<WorkerClientMessage>();
      final output = link.extensions.runWorker(input.stream);
      try {
        final stored = await link.stub.putSecret(
          PutSecretRequest(
            apiVersion: apiVersion,
            credentials: CredentialsRef(reference: 'fetch_vpn'),
            material: utf8.encode('{"method":"aes-256-gcm","password":"live-extension-vpn-password"}'),
          ),
        );
        expect(stored.hasError(), isFalse, reason: stored.error.toString());
        for (final kind in ['sing-box', 'xray', 'mihomo']) {
          final connected = await link.stub.connect(
            ConnectRequest(
              apiVersion: apiVersion,
              controlAuthenticator: link.token,
              sessionPlan: SessionPlan(
                tunnelMode: TunnelMode.TUNNEL_MODE_APPLICATION,
                engines: [kind],
                networkControlAllowed: true,
                outbounds: [
                  OutboundSpec(
                    id: 'vpn',
                    displayName: 'VPN',
                    protocol: 'shadowsocks',
                    security: 'none',
                    endpoint: Endpoint(host: '127.0.0.1', port: vpnPort),
                    credentials: CredentialsRef(reference: 'fetch_vpn'),
                  ),
                ],
                routes: [
                  RoutingRule(destination: 'full:example.com', outboundId: 'direct'),
                  RoutingRule(destination: '127.0.0.0/8', outboundId: 'direct'),
                  RoutingRule(destination: '53', outboundId: 'direct'),
                ],
                routing: RoutingOptions(proxyTarget: 'vpn'),
              ),
            ),
          );
          expect(connected.hasError(), isFalse, reason: connected.error.toString());
          if (kind != 'mihomo') continue;
          input.add(
            WorkerClientMessage(
              controlToken: link.token,
              manifestJson: jsonEncode({
                'manifest_version': 1,
                'id': 'com.example.live-fetch',
                'name': 'Live Fetch',
                'version': '1.0.0',
                'min_app_version': '1.0.0',
                'author': {
                  'name': 'Test',
                  'identity': 'github:example',
                  'public_key': 'RWQAAAAAAAAAAHd26HC5M1TyoLJMI/KjbMToDiIyGMG5eSb90Bg5aiub',
                },
                'permissions': ['background', 'net.fetch'],
                'capabilities': ['background'],
                'background_task': {'interval_minutes': 15, 'entry': 'worker.js'},
                'network_hosts': ['example.com'],
              }),
              source:
                  "const r = await window.soraExt.call('net.fetch', {url:'https://example.com/'}); "
                  "if(r.status !== 200 || r.body !== 'through-private-vpn') throw new Error('wrong VPN origin'); "
                  "console.log('fetch-vpn-verified');",
              configJson: '{"enabled":true,"interval_minutes":15}',
            ),
          );
        }
        final logs = <String>[];
        final result = await output
            .firstWhere((message) {
              logs.add(message.log);
              return message.failed || message.log == 'fetch-vpn-verified';
            })
            .timeout(const Duration(minutes: 17));
        expect(result.failed, isFalse, reason: logs.join('\n'));
        expect(result.log, 'fetch-vpn-verified');
        expect(requests, 1);
      } finally {
        await output.cancel();
        await input.close();
        await link.stub.disconnect(DisconnectRequest(apiVersion: apiVersion, controlAuthenticator: link.token));
        vpn.kill();
        await vpn.exitCode;
        resolver.kill();
        await resolver.exitCode;
        await origin.close(force: true);
        await serving.cancel();
      }
    },
    skip: fetchEnabled
        ? false
        : 'set SORA_LIVE_EXTENSION_FETCH=1 with SORA_CORE_BIN, SORA_CORE_SOCKET and SORA_ENGINES_DIR',
    timeout: const Timeout(Duration(minutes: 18)),
  );
}
