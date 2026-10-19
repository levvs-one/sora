import 'dart:convert';

import 'package:flutter/foundation.dart';

/// User edits layered over a subscription: server renames and hidden servers.
///
/// Stored locally in settings (`subscriptionOverrides`) until the core
/// implements the SaveSubscriptionOverride/GetSubscriptionOverride RPCs
/// (FEATURE-PLAN.md F6). The JSON shape mirrors the planned core format
/// (`{renames: {id: name}, hidden: [id]}`) so the migration is a drop-in:
/// the store below just needs to delegate to the RPCs.
class SubscriptionOverride {
  const SubscriptionOverride({this.renames = const {}, this.hidden = const {}});

  final Map<String, String> renames;
  final Set<String> hidden;

  bool get isEmpty => renames.isEmpty && hidden.isEmpty;

  factory SubscriptionOverride.fromJson(Map<String, dynamic> json) {
    final renames = <String, String>{};
    final rawRenames = json['renames'];
    if (rawRenames is Map) {
      for (final entry in rawRenames.entries) {
        if (entry.key is String && entry.value is String) {
          renames[entry.key as String] = entry.value as String;
        }
      }
    }
    final hidden = <String>{};
    final rawHidden = json['hidden'];
    if (rawHidden is List) {
      for (final value in rawHidden) {
        if (value is String) hidden.add(value);
      }
    }
    return SubscriptionOverride(renames: renames, hidden: hidden);
  }

  Map<String, dynamic> toJson() => {
    'renames': renames,
    'hidden': hidden.toList(),
  };

  SubscriptionOverride copyWith({Map<String, String>? renames, Set<String>? hidden}) =>
      SubscriptionOverride(renames: renames ?? this.renames, hidden: hidden ?? this.hidden);
}

/// Loads, caches and persists per-subscription overrides.
class OverrideStore {
  OverrideStore(this._load, this._save);

  final String Function() _load;
  final void Function(String) _save;

  /// Called after every mutation so the UI can rebuild.
  VoidCallback? onChanged;

  Map<String, SubscriptionOverride>? _cache;

  Map<String, SubscriptionOverride> get all {
    final cached = _cache;
    if (cached != null) return cached;
    final parsed = <String, SubscriptionOverride>{};
    try {
      final raw = jsonDecode(_load());
      if (raw is Map<String, dynamic>) {
        for (final entry in raw.entries) {
          if (entry.value is Map<String, dynamic>) {
            parsed[entry.key] = SubscriptionOverride.fromJson(entry.value as Map<String, dynamic>);
          }
        }
      }
    } on FormatException {
      // Corrupt store: start empty rather than break the UI.
    }
    return _cache = parsed;
  }

  SubscriptionOverride of(String subscriptionId) => all[subscriptionId] ?? const SubscriptionOverride();

  void put(String subscriptionId, SubscriptionOverride override) {
    final next = Map<String, SubscriptionOverride>.of(all);
    if (override.isEmpty) {
      next.remove(subscriptionId);
    } else {
      next[subscriptionId] = override;
    }
    _cache = next;
    _save(jsonEncode({for (final entry in next.entries) entry.key: entry.value.toJson()}));
    onChanged?.call();
  }

  /// Drops all edits for a subscription (called when it is deleted).
  void drop(String subscriptionId) => put(subscriptionId, const SubscriptionOverride());

  /// Hidden server IDs across all subscriptions.
  Set<String> get hiddenIds => {for (final o in all.values) ...o.hidden};

  /// Renames across all subscriptions: server ID -> display name.
  Map<String, String> get renames => {for (final o in all.values) ...o.renames};
}
