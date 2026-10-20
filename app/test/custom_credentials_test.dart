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
    expect(
      jsonDecode(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_SHADOWSOCKS, 'aes-128-gcm:p:w')!),
      {'method': 'aes-128-gcm', 'password': 'p:w'},
    );
  });

  test('an empty secret stores nothing and a malformed one is refused', () {
    expect(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_VLESS, ''), '');
    expect(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_SHADOWSOCKS, 'no-colon'), isNull);
    expect(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_SHADOWSOCKS, ':pw'), isNull);
    expect(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_SHADOWSOCKS, 'aes-128-gcm:'), isNull);
    expect(customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_WIREGUARD, 'key'), isNull);
  });
}
