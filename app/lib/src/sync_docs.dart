import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../l10n/strings.dart';
import 'generated/sora/core/v1/core_control.pbgrpc.dart';
import 'sora.dart';
import 'sync_api.dart';

/// Document kinds the app publishes to the sora-sync daemon (F9).
/// Normative shapes live in `service/sync/F9-SYNC-CONTRACT.md` §4; this
/// file is the app-side implementation of that section.
abstract final class SyncDocKinds {
  static const subscriptions = 'subscriptions';
  static const appSettings = 'app_settings';
  static const overrides = 'overrides';
  static const profiles = 'profiles';
  static const chains = 'chains';

  /// Fixed document name per kind: collections use `list`, singletons
  /// use `main`, so last-write-wins applies to the whole set at once.
  static String nameOf(String kind) => switch (kind) {
    subscriptions => 'list',
    _ => 'main',
  };
}

/// Localized label for a document kind, shown in the sync result.
String syncDocKindLabel(S s, String kind) => switch (kind) {
  SyncDocKinds.subscriptions => s.syncDocKindSubscriptions,
  SyncDocKinds.appSettings => s.syncDocKindSettings,
  SyncDocKinds.overrides => s.syncDocKindOverrides,
  SyncDocKinds.profiles => s.syncDocKindProfiles,
  SyncDocKinds.chains => s.syncDocKindChains,
  _ => kind,
};

/// Documents that arrived after [before]: new ones, or ones with a newer
/// `updated_at`. Used after pairing, where the daemon ran the first sync
/// internally and the app never saw a sync report.
List<SyncDocMeta> syncDocsDiff(List<SyncDocMeta> before, List<SyncDocMeta> after) {
  final prev = <String, DateTime>{};
  for (final meta in before) {
    if (meta.kind.isNotEmpty) prev['${meta.kind}/${meta.name}'] = meta.updatedAt;
  }
  final out = <SyncDocMeta>[];
  for (final meta in after) {
    if (meta.kind.isEmpty) continue;
    final known = prev['${meta.kind}/${meta.name}'];
    if (known == null || meta.updatedAt.isAfter(known)) out.add(meta);
  }
  return out;
}

/// Thrown when the bridge cannot serialize or apply a document. [message]
/// is a technical detail (English); the UI pairs it with a localized
/// headline the same way it does [SyncApiException].
class SyncBridgeException implements Exception {
  SyncBridgeException(this.message);

  final String message;

  @override
  String toString() => 'SyncBridgeException: $message';
}

/// App ⇄ daemon document bridge (F9): serializes app state into the
/// daemon's document store and applies documents pulled from a peer back
/// into the app and the core.
///
/// Publish is a full snapshot per kind: debounced after local changes
/// ([noteChanged]) and forced before every peer sync. A PUT is skipped
/// when the daemon already stores the identical payload (hash match), so
/// unchanged data does not churn `updated_at` and cannot ping-pong
/// between devices.
///
/// Apply is additive and idempotent: running it twice changes nothing the
/// second time. Subscription deletions do not propagate (the doc carries
/// no tombstones — see the contract); unknown kinds are ignored.
class SyncDocumentBridge {
  SyncDocumentBridge({required this.sora, required this.client});

  final Sora sora;
  final SyncApiClient client;

  Timer? _debounce;

  /// Schedules a republish after a local change. Debounced so a burst of
  /// edits (e.g. hiding several servers) publishes once. Failures are
  /// swallowed here: the next manual sync republishes and surfaces errors.
  void noteChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      unawaited(publish().catchError((_) {}));
    });
  }

  /// Serializes every document kind and PUTs the ones that changed.
  Future<void> publish() async {
    final docs = await _buildDocs();
    Map<String, String> storedHashes;
    try {
      storedHashes = {for (final meta in await client.documents()) '${meta.kind}/${meta.name}': meta.hash};
    } on SyncApiException {
      storedHashes = const {}; // unknown state: publish everything
    }
    for (final entry in docs.entries) {
      final kind = entry.key;
      final name = SyncDocKinds.nameOf(kind);
      final payload = entry.value;
      if (storedHashes['$kind/$name'] == _hashOf(payload)) continue;
      await client.putDocument(kind: kind, name: name, payload: payload);
    }
  }

  static String _hashOf(List<int> payload) => sha256.convert(payload).toString();

  Future<Map<String, List<int>>> _buildDocs() async => {
    SyncDocKinds.subscriptions: utf8.encode(await _subscriptionsJson()),
    SyncDocKinds.appSettings: utf8.encode(jsonEncode(sora.settings.exportSyncableSettings())),
    SyncDocKinds.overrides: utf8.encode(sora.settings.subscriptionOverrides),
    SyncDocKinds.profiles: utf8.encode(sora.settings.networkProfiles),
    SyncDocKinds.chains: utf8.encode(sora.settings.proxyChains),
  };

  /// Serializes subscriptions with their URLs. The core keeps bearer URLs
  /// out of state snapshots by design; the dedicated
  /// [Sora.fetchSubscriptionLink] RPC hands one over only for explicit
  /// actions like this. A subscription whose URL cannot be read is skipped
  /// honestly instead of being published URL-less.
  ///
  /// The device-local subscription id is deliberately NOT in the payload:
  /// the core assigns ids per device, so including them would make two
  /// semantically identical snapshots hash differently and ping-pong
  /// between devices forever. Matching is by URL (see [_applySubscriptions]).
  Future<String> _subscriptionsJson() async {
    final items = <Map<String, dynamic>>[];
    for (final sub in sora.subscriptions) {
      final url = await sora.fetchSubscriptionLink(sub.settings.id);
      if (url == null || url.trim().isEmpty) continue;
      items.add({
        'name': sub.settings.name,
        'url': url,
        'auto_update': sub.settings.autoUpdate,
        'user_agent': sub.settings.userAgent,
        'update_interval_seconds': sub.settings.hasUpdateInterval() ? sub.settings.updateInterval.seconds.toInt() : 0,
      });
    }
    return jsonEncode({'v': 1, 'items': items});
  }

  /// Applies documents the peer sent (the `pulled` metas of a sync
  /// report): fetches each payload and merges it into the app and the
  /// core. Unknown kinds are ignored (forward compatibility).
  Future<void> applyPulled(Iterable<SyncDocMeta> metas) async {
    for (final meta in metas) {
      if (meta.kind.isEmpty) continue;
      final doc = await client.getDocument(meta.kind, meta.name);
      await _apply(meta.kind, utf8.decode(doc.payload));
    }
  }

  Future<void> _apply(String kind, String raw) async {
    switch (kind) {
      case SyncDocKinds.subscriptions:
        await _applySubscriptions(raw);
      case SyncDocKinds.appSettings:
        final decoded = _decodeDoc(raw, 'app_settings');
        await sora.settings.importSyncableSettings(decoded);
        sora.notifyListeners();
      case SyncDocKinds.overrides:
        sora.settings.subscriptionOverrides = _requireJson(raw, (d) => d is Map, 'overrides');
        sora.overrides.reload();
      case SyncDocKinds.profiles:
        sora.settings.networkProfiles = _requireJson(raw, (d) => d is List, 'profiles');
        sora.profiles.reload();
      case SyncDocKinds.chains:
        sora.settings.proxyChains = _requireJson(raw, (d) => d is List, 'chains');
        sora.chains.reload();
      default:
        break; // ignore kinds this app version doesn't know
    }
  }

  Map<String, dynamic> _decodeDoc(String raw, String what) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Falls through to the honest error below.
    }
    throw SyncBridgeException('bad $what document from peer');
  }

  /// Validates [raw] parses as JSON satisfying [check] and returns it
  /// unchanged for storage; throws honestly otherwise.
  String _requireJson(String raw, bool Function(dynamic) check, String what) {
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      decoded = null;
    }
    if (!check(decoded)) throw SyncBridgeException('bad $what document from peer');
    return raw;
  }

  /// Additive merge by URL: missing subscriptions are added, present ones
  /// are renamed when the name differs. Deletions intentionally do not
  /// propagate (no tombstones in the doc — see the contract §4).
  Future<void> _applySubscriptions(String raw) async {
    final decoded = _decodeDoc(raw, 'subscriptions');
    final items = decoded['items'];
    if (items is! List) throw SyncBridgeException('bad subscriptions document from peer');
    final byUrl = <String, SubscriptionState>{};
    for (final sub in sora.subscriptions) {
      final url = await sora.fetchSubscriptionLink(sub.settings.id);
      final trimmed = url?.trim() ?? '';
      if (trimmed.isNotEmpty) byUrl[trimmed] = sub;
    }
    final seen = <String>{};
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final url = (item['url'] as String? ?? '').trim();
      if (url.isEmpty || !seen.add(url)) continue; // no URL, or a duplicate entry
      final name = (item['name'] as String? ?? '').trim();
      final existing = byUrl[url];
      if (existing == null) {
        final failure = await sora.addSubscription(url, name: name);
        if (failure != null) throw SyncBridgeException('could not add subscription "$name"');
      } else if (name.isNotEmpty && name != existing.settings.name) {
        final failure = await sora.renameSubscription(existing, name);
        if (failure != null) throw SyncBridgeException('could not rename subscription "$name"');
      }
    }
  }
}
