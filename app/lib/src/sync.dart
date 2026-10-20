import 'dart:convert';

/// Pairing payload version. Bump when the QR format changes.
const syncPairVersion = 1;

/// mDNS service type the Go sync service advertises in the LAN (F9).
const syncMdnsService = '_sora-sync._tcp';

/// Pairing handshake data (F9).
///
/// The QR payload is the Go `service/sync/pairing` Invitation, contract for
/// contract: `sora-sync://pair?v=1&id=<device>&pub=<base64url 32B>
/// &token=<base64url 16B>&port=<1..65535>`. The decoder below mirrors Go's
/// `pairing.Decode` rule for rule, so a code the app accepts is a code the
/// sync service accepts too. Invitations are minted by the sync service
/// (`api.StartPairing`); Dart never invents key material, device ids or
/// ports.
///
/// Status (2026-10-20): wired — the app spawns the daemon ([SyncDaemon]),
/// shows the daemon-minted QR, and joins through the daemon's HTTP API. The
/// daemon is the source of truth for paired devices; the old app-side
/// device registry is gone.
class SyncPairing {
  SyncPairing._();

  /// Decodes base64url without padding; null unless [s] uses only the
  /// URL-safe alphabet and decodes to exactly [length] bytes. Go's
  /// RawURLEncoding rejects padding, so this does too.
  static List<int>? _b64rawDecode(String s, int length) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(s)) return null;
    // Hand-rolled, because neither stock decoder matches Go's
    // RawURLEncoding exactly: base64Url.decode demands a padded length
    // (multiple of 4) and throws on the raw form Go emits (43 chars for
    // 32 bytes, 22 for 16), and even after normalize() it rejects the
    // non-canonical trailing bits Go silently discards. Go's rules are:
    // alphabet chars only (the regex above), a length mod 4 of 1 is an
    // error, and leftover sub-byte bits at the end are ignored.
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    final out = <int>[];
    var acc = 0;
    var bits = 0;
    for (var i = 0; i < s.length; i++) {
      acc = (acc << 6) | alphabet.indexOf(s[i]);
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        out.add((acc >> bits) & 0xff);
      }
    }
    if (bits >= 6) return null; // length mod 4 == 1: Go rejects this too
    return out.length == length ? out : null;
  }

  /// Parses a scanned payload; null when it is not a valid pairing
  /// invitation. A byte-exact mirror of Go `pairing.Decode`
  /// (F9-SYNC-CONTRACT.md §1): a wrong scheme, host or version, a fragment,
  /// duplicated query keys, and any malformed field, are rejected instead
  /// of being half-accepted. The raw string — not the parsed URI — is
  /// checked for the fragment, the scheme/host case, and duplicates,
  /// because Dart's [Uri] lowercases the host (Go keeps its case), drops a
  /// bare trailing '#', and takes the last of duplicated keys (Go takes
  /// the first, then rejects the payload outright).
  static ({String deviceId, List<int> publicKey, List<int> token, int port})? decodePairPayload(
    String raw,
  ) {
    final text = raw.trim();
    // No fragment, not even an empty one: the canonical form never
    // contains '#'.
    if (text.contains('#')) return null;
    // Scheme is matched case-insensitively (Go's url.Parse lowercases it),
    // the host case-sensitively on the raw authority with userinfo
    // stripped (Go keeps the host's case and drops userinfo; Dart's Uri
    // would lowercase the host and silently drop a bare trailing '#').
    final schemeEnd = text.indexOf('://');
    if (schemeEnd < 0) return null;
    if (text.substring(0, schemeEnd).toLowerCase() != 'sora-sync') return null;
    final authStart = schemeEnd + 3;
    var authEnd = text.length;
    for (var i = authStart; i < text.length; i++) {
      final c = text[i];
      if (c == '/' || c == '?') {
        authEnd = i;
        break;
      }
    }
    final authority = text.substring(authStart, authEnd);
    final atSign = authority.lastIndexOf('@');
    final host = atSign >= 0 ? authority.substring(atSign + 1) : authority;
    if (host != 'pair') return null;
    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    // Duplicate keys are rejected: Go's Values.Get takes the first value,
    // Dart's queryParameters the last, so a duplicated key could make the
    // two sides disagree on the public key or token.
    final all = uri.queryParametersAll;
    if (all.values.any((values) => values.length != 1)) return null;
    final q = uri.queryParameters;
    if (q['v'] != '$syncPairVersion') return null;
    final deviceId = q['id'] ?? '';
    // Go measures the id in bytes (len(id) > 128); a UTF-16 code-unit
    // count would let multi-byte ids through that the daemon rejects.
    if (deviceId.isEmpty || utf8.encode(deviceId).length > 128) return null;
    final publicKey = _b64rawDecode(q['pub'] ?? '', 32);
    if (publicKey == null) return null;
    final token = _b64rawDecode(q['token'] ?? '', 16);
    if (token == null) return null;
    // Go's strconv.Atoi grammar: an optional sign and digits, nothing
    // else — in particular no whitespace, which a '+' or %20 in the
    // query decodes to and int.tryParse would silently trim away.
    final portText = q['port'] ?? '';
    if (!RegExp(r'^[+-]?[0-9]+$').hasMatch(portText)) return null;
    final port = int.tryParse(portText);
    if (port == null || port <= 0 || port > 65535) return null;
    return (deviceId: deviceId, publicKey: publicKey, token: token, port: port);
  }
}
