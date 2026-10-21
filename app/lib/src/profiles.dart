import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'generated/sora/core/v1/core_control.pb.dart' as wire;

/// A network profile: triggers identifying a network plus a snapshot of the
/// connection settings to apply when that network is joined.
///
/// Settings are the editor's source of truth. Sora mirrors every change and
/// each core reconnection through the profile RPCs. The core alone matches
/// network changes and sends ProfileMatched; opening the editor only reads
/// the fingerprint for display.
class NetworkProfile {
  NetworkProfile({
    required this.id,
    required this.name,
    this.ssids = const [],
    this.gateways = const [],
    this.asns = const [],
    this.autoApply = false,
    this.tunnel,
    this.preset,
    this.dns,
    this.dnsPreset,
    this.serverId,
    this.engine,
  });

  final String id;
  String name;
  List<String> ssids;
  List<String> gateways;
  List<String> asns;
  bool autoApply;

  // Settings snapshot, captured with "remember current settings".
  String? tunnel;
  String? preset;
  List<String>? dns;
  String? dnsPreset;
  String? serverId;
  String? engine;

  /// True when at least one trigger can identify a network.
  bool get hasTriggers => ssids.isNotEmpty || gateways.isNotEmpty || asns.isNotEmpty;

  factory NetworkProfile.fromWire(wire.NetworkProfile profile) {
    final apply = profile.apply;
    return NetworkProfile(
      id: profile.id,
      name: profile.name,
      ssids: List.of(profile.triggers.ssids),
      gateways: List.of(profile.triggers.gateways),
      asns: List.of(profile.triggers.asns),
      autoApply: profile.autoApply,
      tunnel: apply.hasMode() ? apply.mode : null,
      preset: apply.hasRulesPreset() ? apply.rulesPreset : null,
      dns: apply.dnsSet || apply.dns.isNotEmpty ? List.of(apply.dns) : null,
      dnsPreset: apply.hasDnsPreset() ? apply.dnsPreset : null,
      serverId: apply.hasServerId() ? apply.serverId : null,
      engine: apply.hasEngine() ? apply.engine : null,
    );
  }

  wire.NetworkProfile toWire() => wire.NetworkProfile(
    id: id,
    name: name,
    triggers: wire.ProfileTriggers(ssids: ssids, gateways: gateways, asns: asns),
    autoApply: autoApply,
    apply: wire.ProfileApply(
      mode: tunnel,
      rulesPreset: preset,
      dns: dns,
      dnsSet: dns != null,
      dnsPreset: dnsPreset,
      serverId: serverId,
      engine: engine,
    ),
  );

  factory NetworkProfile.fromJson(Map<String, dynamic> json) {
    final dnsJson = json['dns'] as List?;
    return NetworkProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ssids: [for (final v in (json['ssids'] as List? ?? [])) v.toString()],
      gateways: [for (final v in (json['gateways'] as List? ?? [])) v.toString()],
      asns: [for (final v in (json['asns'] as List? ?? [])) v.toString()],
      autoApply: json['autoApply'] as bool? ?? false,
      tunnel: json['tunnel'] as String?,
      preset: json['preset'] as String?,
      dns: dnsJson == null ? null : [for (final v in dnsJson) v.toString()],
      dnsPreset: json['dnsPreset'] as String?,
      serverId: json['serverId'] as String?,
      engine: json['engine'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ssids': ssids,
    'gateways': gateways,
    'asns': asns,
    'autoApply': autoApply,
    if (tunnel != null) 'tunnel': tunnel,
    if (preset != null) 'preset': preset,
    if (dns != null) 'dns': dns,
    if (dnsPreset != null) 'dnsPreset': dnsPreset,
    if (serverId != null) 'serverId': serverId,
    if (engine != null) 'engine': engine,
  };
}

/// Fingerprint of the currently joined network.
///
/// Filled by `Sora.refreshFingerprint` from the core RPC
/// `GetNetworkFingerprint` (the Go side lives in `core/profiles/`). When
/// the core cannot be asked, the fingerprint stays unknown and the app
/// shows the "unavailable" state instead of guessing.
class NetworkFingerprint {
  const NetworkFingerprint({this.ssid, this.gateway, this.asn});

  const NetworkFingerprint.unknown() : this();

  final String? ssid;
  final String? gateway;
  final String? asn;

  bool get known => ssid != null || gateway != null || asn != null;
}

/// App-side profile store, persisted as JSON in settings.
class ProfilesStore extends ChangeNotifier {
  ProfilesStore(this._read, this._write) {
    _load();
  }

  final String Function() _read;
  final void Function(String) _write;

  final List<NetworkProfile> _profiles = [];
  List<NetworkProfile> get profiles => List.unmodifiable(_profiles);

  /// Profile whose triggers matched the current network, if any.
  String? activeId;

  void _load() {
    final raw = _read();
    if (raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic> && (item['id'] as String? ?? '').isNotEmpty) {
            _profiles.add(NetworkProfile.fromJson(item));
          }
        }
      }
    } catch (_) {
      // A corrupt store must not wipe the editor; it just starts empty and
      // gets overwritten on the next save.
    }
  }

  void _save() {
    _write(jsonEncode([for (final p in _profiles) p.toJson()]));
    notifyListeners();
  }

  /// Re-reads the store from settings (e.g. after a sync import replaced
  /// the underlying JSON) and notifies listeners. The network match is
  /// dropped: imported profiles are new data, not a live match.
  void reload() {
    _profiles.clear();
    activeId = null;
    _load();
    notifyListeners();
  }

  void add(NetworkProfile profile) {
    _profiles.add(profile);
    _save();
  }

  void update(NetworkProfile profile) {
    final index = _profiles.indexWhere((p) => p.id == profile.id);
    if (index < 0) return;
    _profiles[index] = profile;
    _save();
  }

  void remove(String id) {
    _profiles.removeWhere((p) => p.id == id);
    if (activeId == id) activeId = null;
    _save();
  }

  NetworkProfile? byId(String id) {
    for (final p in _profiles) {
      if (p.id == id) return p;
    }
    return null;
  }
}
