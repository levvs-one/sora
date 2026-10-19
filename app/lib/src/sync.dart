import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Pairing payload version. Bump when the QR format changes.
const syncPairVersion = 1;

/// mDNS service type the Go sync service advertises in the LAN (F9).
const syncMdnsService = '_sora-sync._tcp';

/// A device paired for end-to-end encrypted sync (F9).
///
/// Secrets sync too, but only inside the Noise_XX-encrypted channel owned by
/// the Go sync service (`core/sync/sync.go`, a separate service — not a
/// control RPC). The threat model lives in `docs/sync-threat-model.md`.
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
/// The QR shown by "Show my code" carries the rendezvous token; the
/// ephemeral X25519 public key is attached by the Go sync service once it
/// lands (the Dart `crypto` package has no X25519, and inventing key
/// material here would be dishonest). Scanning side parses the payload with
/// [decodePairPayload].
class SyncPairing {
  SyncPairing._();

  /// Cryptographically secure rendezvous token, hex-encoded.
  static String newToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Builds the QR payload. [ephemeralPub] is base64 X25519 public key bytes
  /// when the sync service supplies them, null while it is pending.
  static String encodePairPayload({required String token, String? ephemeralPub}) {
    final params = <String, String>{'v': '$syncPairVersion', 'token': token};
    if (ephemeralPub != null && ephemeralPub.isNotEmpty) params['key'] = ephemeralPub;
    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'sora-sync://pair?$query';
  }

  /// Parses a scanned payload; null when it is not a sync pairing code.
  /// Returns the rendezvous token and the ephemeral key (null while the
  /// other side's sync service has not attached one yet).
  static ({String token, String? key})? decodePairPayload(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'sora-sync' || uri.host != 'pair') return null;
    final token = uri.queryParameters['token'] ?? '';
    if (token.isEmpty) return null;
    return (token: token, key: uri.queryParameters['key']);
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
