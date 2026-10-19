import 'dart:convert';
import 'dart:math';

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

  /// 16 cryptographically secure random bytes for the rendezvous token.
  static List<int> newToken() {
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256));
  }

  /// base64url without padding, exactly like Go's `base64.RawURLEncoding`.
  static String _b64raw(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

  /// Decodes base64url without padding; null unless [s] uses only the
  /// URL-safe alphabet and decodes to exactly [length] bytes. Go's
  /// RawURLEncoding rejects padding, so this does too.
  static List<int>? _b64rawDecode(String s, int length) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(s)) return null;
    try {
      final bytes = base64Url.decode(s);
      return bytes.length == length ? bytes : null;
    } on FormatException {
      return null;
    }
  }

  /// Builds the QR payload. Every field comes from the sync service's
  /// invitation; lengths are validated like the Go encoder's inputs, so a
  /// malformed invitation fails here instead of in the scanner.
  static String encodePairPayload({
    required String deviceId,
    required List<int> publicKey,
    required List<int> token,
    required int port,
  }) {
    if (deviceId.isEmpty || deviceId.length > 128) {
      throw ArgumentError.value(deviceId, 'deviceId', 'must be 1..128 chars');
    }
    if (publicKey.length != 32) {
      throw ArgumentError.value(publicKey.length, 'publicKey', 'must be 32 bytes');
    }
    if (token.length != 16) {
      throw ArgumentError.value(token.length, 'token', 'must be 16 bytes');
    }
    if (port <= 0 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'must be 1..65535');
    }
    final query = <String, String>{
      'v': '$syncPairVersion',
      'id': deviceId,
      'pub': _b64raw(publicKey),
      'token': _b64raw(token),
      'port': '$port',
    }
        .entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'sora-sync://pair?$query';
  }

  /// Parses a scanned payload; null when it is not a valid pairing
  /// invitation. Mirrors Go `pairing.Decode`: a wrong scheme, host or
  /// version, and any malformed field, is rejected instead of being
  /// half-accepted.
  static ({String deviceId, List<int> publicKey, List<int> token, int port})? decodePairPayload(
    String raw,
  ) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'sora-sync' || uri.host != 'pair') return null;
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
