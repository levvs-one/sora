import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Pairing payload version. Bump when the QR format changes.
const syncPairVersion = 1;

/// mDNS service type the Go sync service advertises in the LAN (F9).
const syncMdnsService = '_sora-sync._tcp';

/// A device paired for end-to-end encrypted sync (F9).
///
/// Design: secrets sync too, but only inside the Noise_XX-encrypted channel
/// owned by the Go sync service (`service/sync`, a separate service — not a
/// control RPC). The threat model lives in `docs/sync-threat-model.md`.
/// Status (2026-10-19): the Go service is implemented and tested, but the
/// app neither launches it nor talks to its local API yet — nothing syncs
/// from the app side; the sync screen is currently a local device registry.
class SyncedDevice {
  SyncedDevice({required this.id, required this.name, this.lastSync});

  final String id;
  String name;
  DateTime? lastSync;

  factory SyncedDevice.fromJson(Map<String, dynamic> json) => SyncedDevice(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        lastSync: switch (json['lastSync']) {
          final String s => DateTime.tryParse(s),
          _ => null,
        },
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (lastSync != null) 'lastSync': lastSync!.toUtc().toIso8601String(),
      };
}

/// Pairing handshake data (F9).
///
/// The QR payload is the Go `service/sync/pairing` Invitation, contract for
/// contract: `sora-sync://pair?v=1&id=<device>&pub=<base64url 32B>
/// &token=<base64url 16B>&port=<1..65535>`. The decoder below mirrors Go's
/// `pairing.Decode` rule for rule, so a code the app accepts is a code the
/// sync service accepts too. Invitations are minted by the sync service
/// (`api.StartPairing`); Dart never invents key material, device ids or
/// ports.
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

/// App-side device registry, persisted as JSON in settings (F9).
class SyncDevices extends ChangeNotifier {
  SyncDevices(this._read, this._write) {
    _load();
  }

  final String Function() _read;
  final void Function(String) _write;

  final List<SyncedDevice> _devices = [];
  List<SyncedDevice> get devices => List.unmodifiable(_devices);

  void _load() {
    final raw = _read();
    if (raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic> && (item['id'] as String? ?? '').isNotEmpty) {
            _devices.add(SyncedDevice.fromJson(item));
          }
        }
      }
    } catch (_) {
      // Corrupt JSON starts empty; the next save overwrites it.
    }
  }

  void _save() {
    _write(jsonEncode([for (final d in _devices) d.toJson()]));
    notifyListeners();
  }

  void add(SyncedDevice device) {
    if (_devices.any((d) => d.id == device.id)) return;
    _devices.add(device);
    _save();
  }

  void revoke(String id) {
    _devices.removeWhere((d) => d.id == id);
    _save();
  }

  void markSynced(String id, DateTime when) {
    for (final d in _devices) {
      if (d.id == id) {
        d.lastSync = when;
        _save();
        return;
      }
    }
  }
}
