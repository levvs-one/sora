import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Maximum hops in a chain (FEATURE-PLAN.md F8).
const maxChainHops = 3;

/// Minimum hops: a chain of one is just a server.
const minChainHops = 2;

/// Core capability flag advertising chain support. The Go engine registry
/// sets it per engine (sing-box native chained outbounds, mihomo likewise,
/// Xray via dialerProxy where supported).
const chainCapability = 'chains';

/// A named proxy chain: traffic enters at the first hop and exits at the
/// last (F8).
class ProxyChain {
  ProxyChain({required this.id, required this.name, required List<String> hops})
      : hops = List.unmodifiable(hops);

  final String id;
  String name;
  final List<String> hops;

  /// Estimated end-to-end latency: the sum of hop pings, shown before
  /// connecting. Hops without a measurement are skipped; null when none
  /// were measured.
  int? estimatedLatency(Map<String, int?> latency) {
    var sum = 0;
    var measured = 0;
    for (final hop in hops) {
      final ms = latency[hop];
      if (ms != null) {
        sum += ms;
        measured++;
      }
    }
    return measured == 0 ? null : sum;
  }

  factory ProxyChain.fromJson(Map<String, dynamic> json) => ProxyChain(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        hops: [for (final v in (json['hops'] as List? ?? [])) v.toString()],
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'hops': hops};
}

/// App-side chain store, persisted as JSON in settings (F8).
class ChainsStore extends ChangeNotifier {
  ChainsStore(this._read, this._write) {
    _load();
  }

  final String Function() _read;
  final void Function(String) _write;

  final List<ProxyChain> _chains = [];
  List<ProxyChain> get chains => List.unmodifiable(_chains);

  void _load() {
    final raw = _read();
    if (raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic> && (item['id'] as String? ?? '').isNotEmpty) {
            final chain = ProxyChain.fromJson(item);
            if (_validHops(chain.hops)) _chains.add(chain);
          }
        }
      }
    } catch (_) {
      // Corrupt JSON starts the list empty; the next save overwrites it.
    }
  }

  static bool _validHops(List<String> hops) =>
      hops.length >= minChainHops &&
      hops.length <= maxChainHops &&
      hops.toSet().length == hops.length &&
      hops.every((h) => h.isNotEmpty);

  void _save() {
    _write(jsonEncode([for (final c in _chains) c.toJson()]));
    notifyListeners();
  }

  /// Adds a chain; returns an error key when the hops are invalid.
  String? add(ProxyChain chain) {
    final error = validateHops(chain.hops);
    if (error != null) return error;
    _chains.add(chain);
    _save();
    return null;
  }

  /// Replaces a chain; returns an error key when the hops are invalid.
  String? update(ProxyChain chain) {
    final error = validateHops(chain.hops);
    if (error != null) return error;
    final index = _chains.indexWhere((c) => c.id == chain.id);
    if (index < 0) return null;
    _chains[index] = chain;
    _save();
    return null;
  }

  void remove(String id) {
    _chains.removeWhere((c) => c.id == id);
    _save();
  }

  ProxyChain? byId(String id) {
    for (final c in _chains) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Validates hop selection for the builder UI; null means valid.
  static String? validateHops(List<String> hops) {
    if (hops.length < minChainHops) return 'chainTooFew';
    if (hops.length > maxChainHops) return 'chainTooMany';
    if (hops.toSet().length != hops.length) return 'chainDuplicate';
    return null;
  }
}
