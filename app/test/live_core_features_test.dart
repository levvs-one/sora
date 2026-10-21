// Requires SORA_CORE_BIN (a sora-core built from this tree) and
// SORA_CORE_SOCKET (a fresh socket path). The core runs unprivileged on that
// socket with a private data directory, and the test calls the feature
// services through the same CoreLink the app uses.
@TestOn('linux')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/profiles.dart' as editor;
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';
import 'package:sora/src/generated/sora/custom/v1/custom.pbgrpc.dart';
import 'package:sora/src/ui/addserver.dart';

void main() {
  final binary = Platform.environment['SORA_CORE_BIN'];
  final socket = Platform.environment['SORA_CORE_SOCKET'];
  final enabled = binary != null && socket != null;
  late Directory dir;
  late Process core;
  late CoreLink link;

  setUpAll(() async {
    if (!enabled) return;
    dir = await Directory.systemTemp.createTemp('sora-live-');
    core = await Process.start(binary, [
      '-socket',
      socket,
      '-data-dir',
      '${dir.path}/data',
      '-engines-dir',
      '${dir.path}/none',
      '-allow-file-keys',
    ]);
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
}
