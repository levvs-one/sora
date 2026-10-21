import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/generated/sora/custom/v1/custom.pbenum.dart';
import 'package:sora/src/ui/addserver.dart';

/// The core stores this document in its vault and reads the same keys back
/// when it plans a connection (core/control applyCredential).
void main() {
  test('each protocol maps its secret to the planner keys', () {
    expect(jsonDecode(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_VLESS, 'id-1')!), {'uuid': 'id-1'});
    expect(jsonDecode(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_VMESS, 'id-2')!), {'uuid': 'id-2'});
    expect(jsonDecode(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_TROJAN, ' pw ')!), {'password': ' pw '});
    expect(jsonDecode(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_SHADOWSOCKS, 'aes-128-gcm:p:w')!), {
      'method': 'aes-128-gcm',
      'password': 'p:w',
    });
  });

  test('an empty secret stores nothing and a malformed one is refused', () {
    expect(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_VLESS, ''), '');
    expect(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_SHADOWSOCKS, 'no-colon'), isNull);
    expect(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_SHADOWSOCKS, ':pw'), isNull);
    expect(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_SHADOWSOCKS, 'aes-128-gcm:'), isNull);
    expect(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_WIREGUARD, 'key'), isNull);
  });

  const key = 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=';
  const wg = (
    addresses: '10.0.0.2/32, fd00::2/128',
    peerKey: key,
    presharedKey: '',
    allowedIps: '0.0.0.0/0, ::/0',
    keepalive: '25',
  );

  test('WireGuard builds the private key, addresses and one peer', () {
    final doc = jsonDecode(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_WIREGUARD, key, wg: wg)!) as Map;
    expect(doc['private_key'], key);
    expect(doc['addresses'], '10.0.0.2/32,fd00::2/128');
    expect(jsonDecode(doc['peers'] as String), [
      {
        'PublicKey': key,
        'AllowedIPs': ['0.0.0.0/0', '::/0'],
        'PersistentKeepalive': 25,
      },
    ]);
  });

  test('WireGuard points at the field that is wrong', () {
    expect(wireGuardProblem('short', wg), 'credentials');
    expect(
      wireGuardProblem(key, (
        addresses: '10.0.0.2',
        peerKey: key,
        presharedKey: '',
        allowedIps: '0.0.0.0/0',
        keepalive: '',
      )),
      'addresses',
    );
    expect(
      wireGuardProblem(key, (
        addresses: '10.0.0.2/32',
        peerKey: 'x',
        presharedKey: '',
        allowedIps: '0.0.0.0/0',
        keepalive: '',
      )),
      'peerKey',
    );
    expect(
      wireGuardProblem(key, (
        addresses: '10.0.0.2/32',
        peerKey: key,
        presharedKey: 'x',
        allowedIps: '0.0.0.0/0',
        keepalive: '',
      )),
      'presharedKey',
    );
    expect(
      wireGuardProblem(key, (
        addresses: '10.0.0.2/32',
        peerKey: key,
        presharedKey: '',
        allowedIps: '0.0.0.0/33',
        keepalive: '',
      )),
      'allowedIps',
    );
    expect(
      wireGuardProblem(key, (
        addresses: '10.0.0.2/32',
        peerKey: key,
        presharedKey: '',
        allowedIps: '::/0',
        keepalive: '70000',
      )),
      'keepalive',
    );
    expect(wireGuardProblem(key, wg), isNull);
  });
}
