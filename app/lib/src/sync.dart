import 'dart:convert';

/// Pairing payload version. Bump when the QR format changes.
const syncPairVersion = 1;

/// mDNS service type the Go sync service advertises in the LAN.
const syncMdnsService = '_sora-sync._tcp';

/// Pairing handshake data.
///
/// The QR payload is the Go `service/sync/pairing` Invitation, contract for
/// contract: `sora-sync://pair?v=1&id={device}&pub={base64url 32B}`
/// `&token={base64url 16B}&port={1..65535}`. The decoder below mirrors Go's
/// `pairing.Decode` rule for rule, so a code the app accepts is a code the
/// sync service accepts too. Invitations are minted by the sync service
/// (`api.StartPairing`); Dart never invents key material, device ids or
/// ports.
///
/// The app spawns the daemon ([SyncDaemon]), shows the daemon-minted QR and
/// joins through the daemon's HTTP API. The daemon is the source of truth for
/// paired devices.
class SyncPairing {
  SyncPairing._();

  /// Decodes base64url without padding; null unless [s] uses only the
  /// URL-safe alphabet and decodes to exactly [length] bytes. Go's
  /// RawURLEncoding rejects padding, so this does too.
  static List<int>? _b64rawDecode(String s, int length) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(s)) return null;
    try {
      // Go writes RawURLEncoding (no padding); Dart's decoder demands it.
      final bytes = base64Url.decode(base64Url.normalize(s));
      return bytes.length == length ? bytes : null;
    } on FormatException {
      return null;
    }
  }

  /// Parses a scanned payload; null when it is not a valid pairing
  /// invitation. A byte-exact mirror of Go `pairing.Decode`
  /// (service/sync/CONTRACT.md §1): a wrong scheme, host or version, a fragment,
  /// duplicated query keys, and any malformed field, are rejected instead
  /// of being half-accepted. The raw string, not the parsed URI, is
  /// checked for the fragment, the scheme/host case, and duplicates,
  /// because Dart's [Uri] lowercases the host (Go keeps its case), drops a
  /// bare trailing '#', and takes the last of duplicated keys (Go takes
  /// the first, then rejects the payload outright).
  static ({String deviceId, List<int> publicKey, List<int> token, int port})? decodePairPayload(String raw) {
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
    if (deviceId.isEmpty || deviceId.length > 128) return null;
    final publicKey = _b64rawDecode(q['pub'] ?? '', 32);
    if (publicKey == null) return null;
    final token = _b64rawDecode(q['token'] ?? '', 16);
    if (token == null) return null;
    final port = int.tryParse(q['port'] ?? '');
    if (port == null || port <= 0 || port > 65535) return null;
    return (deviceId: deviceId, publicKey: publicKey, token: token, port: port);
  }
}
