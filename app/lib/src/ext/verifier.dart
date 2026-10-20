/// Minisign signature verification for extensions (mirrors core/ext/sign.go).
///
/// Verifies `.soraext` author signatures and the team catalog signature.
/// Pure Dart: ed25519 via package:cryptography, sha256 via package:crypto.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart' as cry;

/// The team catalog key. Placeholder until the owner completes the key
/// ceremony — every team-signature check fails closed until then, exactly
/// like packaging/install/install.sh and core/ext.
const String teamPublicKey =
    'UNTRUSTED COMMENT: Sora team catalog key — PLACEHOLDER, key ceremony pending\n'
    'RWRPLACEHOLDERPLACEHOLDERPLACEHOLDERPLACEHOLDERPLACEHOLDER00';

bool get teamSigningConfigured => !teamPublicKey.contains('PLACEHOLDER');

/// Thrown when a signature, key, or signed payload is invalid. The message is
/// developer-facing; the UI maps failures to localized text.
class SignatureError implements Exception {
  SignatureError(this.message);
  final String message;
  @override
  String toString() => 'SignatureError: $message';
}

/// Parses the `<base64>` line of a minisign .pub file into 32 key bytes.
/// Envelope: "Ed" || key_id(8) || pubkey(32).
Uint8List parsePublicKey(String line) {
  Uint8List raw;
  try {
    raw = base64Decode(line.trim());
  } catch (e) {
    throw SignatureError('public key is not base64: $e');
  }
  if (raw.length != 42 || raw[0] != 0x45 || raw[1] != 0x64) {
    throw SignatureError(
        'public key has a bad envelope (want 42 bytes starting with "Ed", got ${raw.length})');
  }
  return Uint8List.fromList(raw.sublist(10, 42));
}

class _ParsedSig {
  _ParsedSig(this.sig, this.trustedComment);
  final Uint8List sig;
  final Uint8List trustedComment;
}

_ParsedSig _parseSignature(String text) {
  final lines = text.replaceAll('\r\n', '\n').trim().split('\n');
  if (lines.length < 2) throw SignatureError('signature file is truncated');
  if (!lines[0].startsWith('untrusted comment:')) {
    throw SignatureError('signature file must start with an "untrusted comment:" line');
  }
  Uint8List raw;
  try {
    raw = base64Decode(lines[1].trim());
  } catch (e) {
    throw SignatureError('signature is not base64: $e');
  }
  if (raw.length < 65) throw SignatureError('signature blob is truncated (${raw.length} bytes)');
  return _ParsedSig(
    Uint8List.fromList(raw.sublist(0, 64)),
    Uint8List.fromList(raw.sublist(64)),
  );
}

class _TrustedComment {
  _TrustedComment(this.timestamp, this.file, this.shaHex);
  final int timestamp;
  final String file;
  final String shaHex;
}

_TrustedComment _parseTrustedComment(Uint8List tc) {
  final parts = utf8.decode(tc).split('\t');
  if (parts.length != 3 ||
      !parts[0].startsWith('timestamp:') ||
      !parts[1].startsWith('file:') ||
      !parts[2].startsWith('sha256:')) {
    throw SignatureError('trusted comment has a bad shape');
  }
  final ts = int.tryParse(parts[0].substring('timestamp:'.length));
  final file = parts[1].substring('file:'.length);
  final shaHex = parts[2].substring('sha256:'.length);
  if (ts == null || ts <= 0) throw SignatureError('trusted comment has a bad timestamp');
  if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(shaHex)) {
    throw SignatureError('trusted comment sha256 is not hex');
  }
  return _TrustedComment(ts, file, shaHex);
}

/// Verifies that [sigText] is a minisign signature by [pubKeyLine] for
/// [payload] in the role named [file] (e.g. "checksums.txt").
Future<void> verifyPayload(
    String pubKeyLine, String sigText, String file, Uint8List payload) async {
  final pub = parsePublicKey(pubKeyLine);
  final sig = _parseSignature(sigText);
  final tc = _parseTrustedComment(sig.trustedComment);
  if (tc.file != file) {
    throw SignatureError('signature is for "${tc.file}", not "$file"');
  }
  final sum = crypto.sha256.convert(payload).toString();
  if (!_constantTimeHexEqual(sum, tc.shaHex.toLowerCase())) {
    throw SignatureError('payload does not match the signed sha256 — the package was modified');
  }
  final ed = cry.Ed25519();
  final ok = await ed.verify(
    sig.trustedComment,
    signature: cry.Signature(
      sig.sig,
      publicKey: cry.SimplePublicKey(pub, type: cry.KeyPairType.ed25519),
    ),
  );
  if (!ok) throw SignatureError('signature is not valid for this key');
}

/// Verifies a .soraext's signature.minisig against the author's key and the
/// checksums.txt bytes.
Future<void> verifyPackageSignature(
        String authorKeyLine, String sigText, Uint8List checksums) =>
    verifyPayload(authorKeyLine, sigText, 'checksums.txt', checksums);

/// Verifies a catalog.json.minisig with the team key. Fails closed while the
/// key ceremony is pending.
Future<void> verifyCatalogSignature(String sigText, Uint8List catalogJson) {
  if (!teamSigningConfigured) {
    throw SignatureError(
        'team signing is not configured yet: the minisign public key is still a placeholder. '
        'The owner must complete the key ceremony before team-signed artifacts can be trusted.');
  }
  return verifyPayload(teamPublicKey, sigText, 'catalog.json', catalogJson);
}

bool _constantTimeHexEqual(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
