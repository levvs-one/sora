import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../l10n/strings.dart';

/// Error from the sora-sync HTTP API: the daemon answered with a non-2xx
/// status or was unreachable. [message] is the daemon's own `{"error"}`
/// text (English, from the Go service); the UI pairs it with a localized
/// headline via [describeSyncError] and may show the raw text as detail.
class SyncApiException implements Exception {
  SyncApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'SyncApiException${statusCode == null ? '' : '($statusCode)'}: $message';
}

/// A device paired through the daemon (F9). The daemon is the source of
/// truth; the app keeps no registry of its own.
class SyncPeer {
  SyncPeer({
    required this.id,
    required this.name,
    required this.identityKey,
    required this.pairedAt,
    this.lastSync,
  });

  final String id;
  final String name;

  /// Base64url-encoded X25519 identity key of the peer.
  final String identityKey;
  final DateTime pairedAt;

  /// Last completed document sync, null when never.
  final DateTime? lastSync;

  static DateTime? _unixSeconds(dynamic v) =>
      v is int && v > 0 ? DateTime.fromMillisecondsSinceEpoch(v * 1000, isUtc: true) : null;

  factory SyncPeer.fromJson(Map<String, dynamic> json) => SyncPeer(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        identityKey: json['identity_key'] as String? ?? '',
        pairedAt: _unixSeconds(json['paired_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        lastSync: _unixSeconds(json['last_sync']),
      );
}

/// `GET /v1/status` response (F9).
class SyncStatusInfo {
  SyncStatusInfo({
    required this.deviceId,
    required this.deviceName,
    required this.pairingActive,
    this.pairingExpiresAt,
    required this.peerCount,
  });

  final String deviceId;
  final String deviceName;
  final bool pairingActive;
  final DateTime? pairingExpiresAt;
  final int peerCount;

  factory SyncStatusInfo.fromJson(Map<String, dynamic> json) {
    final expires = json['pairing_expires_at'];
    return SyncStatusInfo(
      deviceId: json['device_id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      pairingActive: json['pairing_active'] as bool? ?? false,
      pairingExpiresAt:
          expires is int && expires > 0 ? DateTime.fromMillisecondsSinceEpoch(expires * 1000, isUtc: true) : null,
      peerCount: json['peers'] as int? ?? 0,
    );
  }
}

/// An open pairing session from `POST /v1/pairing/start` (F9). The daemon is
/// the only generator of the QR payload; the app shows it as-is.
class PairingSession {
  PairingSession({required this.qrPayload, required this.expiresAt});

  final String qrPayload;
  final DateTime expiresAt;

  factory PairingSession.fromJson(Map<String, dynamic> json) {
    final expires = json['expires_at'];
    return PairingSession(
      qrPayload: json['qr_payload'] as String? ?? '',
      expiresAt: expires is int && expires > 0
          ? DateTime.fromMillisecondsSinceEpoch(expires * 1000, isUtc: true)
          : DateTime.now().toUtc(),
    );
  }
}

/// Result of `POST /v1/peers/{id}/sync` (F9).
class SyncResult {
  SyncResult({required this.pulled, required this.pushed});

  final int pulled;
  final int pushed;

  factory SyncResult.fromJson(Map<String, dynamic> json) => SyncResult(
        pulled: json['pulled'] as int? ?? 0,
        pushed: json['pushed'] as int? ?? 0,
      );
}

/// Token-authenticated client for the sora-sync localhost HTTP API
/// (contract §3). Every request carries `Authorization: Bearer <token>`;
/// non-2xx responses surface the daemon's `{"error"}` text as
/// [SyncApiException].
class SyncApiClient {
  SyncApiClient({required String baseUrl, required String token, http.Client? httpClient})
      : _base = baseUrl,
        _token = token,
        _http = httpClient ?? http.Client();

  final String _base;
  final String _token;
  final http.Client _http;

  void close() => _http.close();

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>> _call(
    String method,
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final http.Response res;
    try {
      final request = http.Request(method, Uri.parse('$_base$path'))..headers.addAll(_headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _http.send(request).timeout(timeout);
      res = await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw SyncApiException('request timed out');
    } on SocketException catch (e) {
      throw SyncApiException('cannot reach the sync service: ${e.message}');
    } on http.ClientException catch (e) {
      throw SyncApiException('cannot reach the sync service: ${e.message}');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw SyncApiException(_errorText(res), statusCode: res.statusCode);
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw SyncApiException('bad response from the sync service');
    }
    return decoded;
  }

  static String _errorText(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['error'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
      // Fall through to the status line.
    }
    return 'HTTP ${res.statusCode}';
  }

  Future<SyncStatusInfo> status() async =>
      SyncStatusInfo.fromJson(await _call('GET', '/v1/status'));

  /// Opens a pairing session. Throws with [SyncApiException.statusCode] 409
  /// when a session is already open.
  Future<PairingSession> startPairing() async =>
      PairingSession.fromJson(await _call('POST', '/v1/pairing/start'));

  /// Closes the pairing session; a no-op when none is open.
  Future<void> stopPairing() async {
    await _call('POST', '/v1/pairing/stop');
  }

  /// Joins with a scanned QR payload (the raw string; the daemon decodes it
  /// canonically). May take a while: mDNS discovery plus the Noise_XX
  /// handshake run inside the daemon.
  Future<SyncPeer> joinPairing(String qrPayload) async {
    final json = await _call(
      'POST',
      '/v1/pairing/join',
      body: {'qr_payload': qrPayload},
      timeout: const Duration(seconds: 90),
    );
    final peer = json['peer'];
    if (peer is! Map<String, dynamic>) throw SyncApiException('bad response from the sync service');
    return SyncPeer.fromJson(peer);
  }

  Future<List<SyncPeer>> peers() async {
    final json = await _call('GET', '/v1/peers');
    final list = json['peers'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic> && (item['id'] as String? ?? '').isNotEmpty)
          SyncPeer.fromJson(item),
    ];
  }

  Future<void> revokePeer(String id) async {
    await _call('DELETE', '/v1/peers/${Uri.encodeComponent(id)}');
  }

  Future<SyncResult> syncPeer(String id) async => SyncResult.fromJson(
        await _call(
          'POST',
          '/v1/peers/${Uri.encodeComponent(id)}/sync',
          timeout: const Duration(seconds: 60),
        ),
      );
}

/// Localized headline for a sync failure. The daemon's raw message
/// ([SyncApiException.message]) stays available as the error detail.
String describeSyncError(S s, Object error) {
  if (error is SyncApiException) {
    final headline = switch (error.statusCode) {
      401 => s.syncErrAuth,
      404 => s.syncErrNotFound,
      409 => s.syncErrPairingActive,
      502 || 504 => s.syncErrUnreachable,
      _ => null,
    };
    if (headline != null) return headline;
    return error.message.isNotEmpty ? '${s.syncError}: ${error.message}' : s.syncError;
  }
  return s.syncError;
}
