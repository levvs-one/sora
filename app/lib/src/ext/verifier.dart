/// Minisign signature verification for extensions (mirrors core/ext/sign.go).
///
/// Verifies `.soraext` author signatures and the team catalog signature.
/// Pure Dart: ed25519 via package:cryptography, sha256 via package:crypto.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart' as cry;

/// The team catalog key stays empty until the owner completes the key
/// ceremony, so every team-signature check fails closed, exactly like
/// core/ext TeamPublicKey.
const String teamPublicKey = '';

bool get teamSigningConfigured => teamPublicKey.isNotEmpty;

/// Thrown when a signature, key, or signed payload is invalid. The message is
/// developer-facing; the UI maps failures to localized text.
class SignatureError implements Exception {
  SignatureError(this.message);
  final String message;
  @override
  String toString() => 'SignatureError: $message';
}

/// Parses a minisign public key: the `.pub` file or only its base64 line.
/// Envelope: "Ed" || key_id(8) || pubkey(32).
({Uint8List keyId, Uint8List key}) parsePublicKey(String text) {
  final lines = text.replaceAll('\r\n', '\n').trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) throw SignatureError('public key is empty');
  Uint8List raw;
  try {
    raw = base64Decode(lines.last.trim());
  } catch (e) {
    throw SignatureError('public key is not base64: $e');
  }
  if (raw.length != 42 || raw[0] != 0x45 || raw[1] != 0x64) {
    throw SignatureError('public key has a bad envelope (want 42 bytes starting with "Ed", got ${raw.length})');
  }
  return (keyId: Uint8List.fromList(raw.sublist(2, 10)), key: Uint8List.fromList(raw.sublist(10, 42)));
}

class _ParsedSig {
  _ParsedSig(this.hashed, this.keyId, this.sig, this.trustedComment, this.commentSig);
  final bool hashed;
  final Uint8List keyId;
  final Uint8List sig;
  final Uint8List trustedComment;
  final Uint8List commentSig;
}

const _trustedPrefix = 'trusted comment: ';

/// Parses the standard four-line minisign signature written by
/// aead.dev/minisign (core/ext and the sora-ext CLI): untrusted comment,
/// base64("Ed"|"ED" || key_id(8) || signature(64)), trusted comment, and
/// base64(signature over signature || trusted comment).
_ParsedSig _parseSignature(String text) {
  final lines = text.replaceAll('\r\n', '\n').trim().split('\n');
  if (lines.length != 4) throw SignatureError('signature file must have four lines, got ${lines.length}');
  if (!lines[0].startsWith('untrusted comment:')) {
    throw SignatureError('signature file must start with an "untrusted comment:" line');
  }
  if (!lines[2].startsWith(_trustedPrefix)) {
    throw SignatureError('signature file has no "trusted comment:" line');
  }
  Uint8List raw, global;
  try {
    raw = base64Decode(lines[1].trim());
    global = base64Decode(lines[3].trim());
  } catch (e) {
    throw SignatureError('signature is not base64: $e');
  }
  if (raw.length != 74 || raw[0] != 0x45 || (raw[1] != 0x64 && raw[1] != 0x44)) {
    throw SignatureError('signature has a bad envelope (${raw.length} bytes)');
  }
  if (global.length != 64) throw SignatureError('trusted comment signature is ${global.length} bytes, want 64');
  return _ParsedSig(
    raw[1] == 0x44,
    Uint8List.fromList(raw.sublist(2, 10)),
    Uint8List.fromList(raw.sublist(10, 74)),
    Uint8List.fromList(utf8.encode(lines[2].substring(_trustedPrefix.length))),
    global,
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

/// Verifies that [sigText] is a minisign signature by [pubKeyText] for
/// [payload] in the role named [file] (e.g. "checksums.txt"), with the same
/// checks as core/ext VerifyPayload: role, sha256 of the payload, the
/// payload signature and the trusted comment signature.
Future<void> verifyPayload(String pubKeyText, String sigText, String file, Uint8List payload) async {
  final pub = parsePublicKey(pubKeyText);
  final sig = _parseSignature(sigText);
  if (!_constantTimeBytesEqual(pub.keyId, sig.keyId)) {
    throw SignatureError('signature was made by a different key');
  }
  final tc = _parseTrustedComment(sig.trustedComment);
  if (tc.file != file) {
    throw SignatureError('signature is for "${tc.file}", not "$file"');
  }
  final sum = crypto.sha256.convert(payload).toString();
  if (!_constantTimeHexEqual(sum, tc.shaHex.toLowerCase())) {
    throw SignatureError('payload does not match the signed sha256, the package was modified');
  }
  final key = cry.SimplePublicKey(pub.key, type: cry.KeyPairType.ed25519);
  final ed = cry.Ed25519();
  final message = sig.hashed ? (await cry.Blake2b().hash(payload)).bytes : payload;
  final payloadOk = await ed.verify(message, signature: cry.Signature(sig.sig, publicKey: key));
  final commentOk = await ed.verify(
    [...sig.sig, ...sig.trustedComment],
    signature: cry.Signature(sig.commentSig, publicKey: key),
  );
  if (!payloadOk || !commentOk) throw SignatureError('signature is not valid for this key');
}

bool _constantTimeBytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
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
        'team signing is not configured yet: no team public key is configured. '
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
