import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart' hide ConnectionState;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/io_client.dart';
import 'package:grpc/grpc.dart' show CallOptions, ResponseStream, GrpcError, StatusCode;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:retry/retry.dart';

import '../l10n/strings.dart';

import 'core/link.dart';
import 'browser_diagnostics.dart';
import 'chains.dart';
// The proto messages NetworkProfile/NetworkFingerprint collide with the
// app-side model classes in profiles.dart, which are the ones this file
// uses; hide the proto names so the references stay unambiguous. The
// fingerprint RPC answer is consumed through its fields, never by naming
// the proto type.
import 'generated/sora/core/v1/core_control.pbgrpc.dart' hide NetworkFingerprint, NetworkProfile;
import 'generated/sora/custom/v1/custom.pbgrpc.dart';
import 'groups.dart';
import 'overrides.dart';
import 'profiles.dart';
import 'rules.dart';
import 'ext/store.dart';
import 'ext/workers.dart';
import 'settings.dart';
import 'notifications.dart';
import 'sync_daemon.dart';
import 'sync_docs.dart';
import 'updates.dart';
import 'ui/kit.dart' show describe;

/// Connection phases exposed to the UI.
enum FailureMode { action, background }

enum Phase { offline, off, connecting, connected, reconnecting, disconnecting }

/// An unsolicited connection event for background notifications.
sealed class Notice {
  const Notice();
}

/// A connection drop while the core attempts reconnection.
final class ConnectionLost extends Notice {
  const ConnectionLost();
}

/// A connection restored after a drop.
final class ConnectionRestored extends Notice {
  const ConnectionRestored();
}

/// A connection that ended or failed to start with [failure].
final class ConnectionFailed extends Notice {
  const ConnectionFailed(this.failure);

  final CoreFailure failure;
}

/// A failover within group [entry]. [backup] indicates role-based failover to a
/// backup server.
final class ServerSwitched extends Notice {
  const ServerSwitched(this.entry, {required this.backup});

  final String entry;
  final bool backup;
}

/// A core fallback group back on its first server [entry] after that server
/// answered again.
final class ServerReturned extends Notice {
  const ServerReturned(this.entry);

  final String entry;
}

/// The pinned server degraded while auto-switch was on, so the app moved to
/// the best measured alternative.
final class ServerDegraded extends Notice {
  const ServerDegraded(this.entry);

  final String entry;
}

/// App state and core operations. Screens access it through [SoraScope] and
/// rebuild on notifications.
class Sora extends ChangeNotifier {
  Sora(this.settings, {ExtensionStore? extensions})
    : extensions = extensions ?? ExtensionStore(),
      history = settings.notificationHistory,
      overrides = OverrideStore(() => settings.subscriptionOverrides, (v) => settings.subscriptionOverrides = v),
      profiles = ProfilesStore(() => settings.networkProfiles, (v) => settings.networkProfiles = v),
      chains = ChainsStore(() => settings.proxyChains, (v) => settings.proxyChains = v) {
    overrides.onChanged = () {
      notifyListeners();
      // Hiding a server changes the plan; renaming does not (IDs are stable).
      unawaited(_replan());
      _noteSyncChanged();
    };
    profiles.addListener(notifyListeners);
    profiles.addListener(_noteSyncChanged);
    profiles.addListener(_profilesChanged);
    chains.addListener(notifyListeners);
    chains.addListener(_noteSyncChanged);
    this.extensions.addListener(_extensionsChanged);
    _loadBandwidth();
  }
  final ExtensionStore extensions;
  ExtensionWorkers? _extensionWorkers;

  final _extensionErrorsReported = <String, String>{};
  void _extensionsChanged() {
    for (final e in extensions.runtimeErrors.entries) {
      if (_extensionErrorsReported[e.key] == e.value) continue;
      _extensionErrorsReported[e.key] = e.value;
      reportFailure(
        const CoreFailure('app.extension_asset'),
        mode: FailureMode.background,
        source: 'extension:${e.key}',
        action: '',
      );
    }
    for (final id in _extensionErrorsReported.keys.where((id) => !extensions.runtimeErrors.containsKey(id)).toList()) {
      _extensionErrorsReported.remove(id);
      recovered('extension:$id');
    }
    notifyListeners();
    unawaited(_replan());
    if (phase == Phase.connected || phase == Phase.reconnecting || _connectionWork != null) {
      _pendingSelection = ++_selectionRevision;
      unawaited(_applySelection());
    }
  }

  final browserDiagnostics = BrowserDiagnostics();

  AppUpdater get updates => _updates;
  late final _updates = AppUpdater(
    settings,
    connection: () => switch (phase) {
      Phase.off => UpdateConnection.idle,
      Phase.connected => UpdateConnection.connected,
      Phase.offline => UpdateConnection.unknown,
      _ => UpdateConnection.changing,
    },
    client: () => IOClient(
      HttpClient()
        ..findProxy = (uri) {
          final proxy = localProxy;
          if (settings.tunnel == 'proxy' &&
              proxy != null &&
              (phase == Phase.connected || phase == Phase.reconnecting)) {
            return 'PROXY ${proxy.host}:${proxy.port}';
          }
          return HttpClient.findProxyFromEnvironment(uri);
        },
    ),
    available: (release) => recordNotification(
      AppNotification(
        time: DateTime.now(),
        title: strings.updateAvailable(release.version),
        body: strings.updateOpenAbout,
        action: 'update',
      ),
    ),
  )..addListener(notifyListeners);

  bool get updateBlocked => updates.busy || updates.rollbackBusy;

  final _messages = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get messages => _messages.stream;
  final _reported = <String, String>{};
  final _failureTimers = <String, Timer>{};
  final _backgroundFailures = <String, ({CoreFailure failure, DateTime since})>{};

  CoreFailure? backgroundFailure(String source) => _backgroundFailures[source]?.failure;

  Map<String, dynamic> get _subscriptionFailures {
    try {
      return jsonDecode(settings.subscriptionFailures) as Map<String, dynamic>;
    } on FormatException {
      return {};
    } on TypeError {
      return {};
    }
  }

  bool serverlessAvailable = false;

  /// Set once the core answers the control channel (the getStatus/getAbout
  /// handshake in [run]); the post-update health signal.
  bool coreHandshakeDone = false;
  Set<String> coreCapabilities = {};

  Locale get locale => basicLocaleListResolution(
    settings.locale == null ? WidgetsBinding.instance.platformDispatcher.locales : [settings.locale!],
    [const Locale('en'), ...S.supportedLocales],
  );

  S get strings => lookupS(locale);

  void reportFailure(
    Object error, {
    required FailureMode mode,
    String source = 'request',
    String action = 'logs',
    String argument = '',
    DateTime? since,
  }) {
    if (_disposed) return;
    final failed = CoreFailure.from(error);
    if (failed.key == 'core.request.cancelled') return;
    // All streams share the control socket. Its outage has one owner.
    if (failed.key == CoreFailure.unavailable.key && source != 'core') {
      _drop(error);
      source = 'core';
    }
    final previous = _backgroundFailures[source];
    final stored = source.startsWith('subscription:') ? _subscriptionFailures[source] : null;
    final started =
        since ?? previous?.since ?? (stored is Map ? DateTime.tryParse('${stored['since']}') : null) ?? DateTime.now();
    _backgroundFailures[source] = (failure: failed, since: started);
    if (stored is Map && stored['reported'] is String) {
      _reported.putIfAbsent(source, () => stored['reported'] as String);
    }
    if (previous?.failure.identity != failed.identity) _failureTimers.remove(source)?.cancel();

    void publish() {
      if (_disposed || _backgroundFailures[source]?.failure.identity != failed.identity) return;
      if (mode == FailureMode.background && _reported[source] == failed.identity) return;
      final repeated = _reported[source] == failed.identity;
      _reported[source] = failed.identity;
      _saveSubscriptionFailure(source);
      final message = describe(strings, failed);
      final notice = AppNotification(
        time: DateTime.now(),
        title: message,
        body: '',
        action: action,
        argument: argument,
        failureKey: failed.key,
      );
      if (repeated) {
        // Retrying still gets feedback, without filling history with one cause.
        _messages.add(notice);
      } else {
        unawaited(recordNotification(notice));
      }
    }

    if (mode == FailureMode.action) {
      publish();
    } else if (_reported[source] != failed.identity && !_failureTimers.containsKey(source)) {
      final threshold = source == 'core' || source == 'session'
          ? const Duration(seconds: 15)
          : source.startsWith('subscription:')
          ? const Duration(hours: 24)
          : const Duration(minutes: 15);
      final remaining = threshold - DateTime.now().difference(started);
      if (remaining <= Duration.zero) {
        publish();
      } else if (source == 'core' ||
          source == 'session' ||
          source.startsWith('subscription:') ||
          source.startsWith('extension')) {
        _failureTimers[source] = Timer(remaining, () {
          _failureTimers.remove(source);
          publish();
        });
      }
    }
    _saveSubscriptionFailure(source);
    if (previous?.failure.identity != failed.identity) notifyListeners();
  }

  void _saveSubscriptionFailure(String source) {
    if (!source.startsWith('subscription:')) return;
    final stored = _subscriptionFailures;
    final state = _backgroundFailures[source];
    if (state == null) {
      stored.remove(source);
    } else {
      stored[source] = {'since': state.since.toIso8601String(), 'reported': _reported[source]};
    }
    settings.subscriptionFailures = jsonEncode(stored);
  }

  void recovered(String source, {bool notify = true}) {
    _failureTimers.remove(source)?.cancel();
    _reported.remove(source);
    final removed = _backgroundFailures.remove(source);
    _saveSubscriptionFailure(source);
    if (removed != null && notify) notifyListeners();
  }

  final Settings settings;
  List<AppNotification> history;
  int get unreadCount => history.where((n) => !n.read).length;
  Future<void> _historyWork = Future.value();
  Future<void> _killSwitchWork = Future.value();

  Future<void> recordNotification(AppNotification notice) {
    if (_disposed) return Future.value();
    history = [notice, ...history].take(100).toList();
    _messages.add(notice);
    notifyListeners();
    return _saveHistory();
  }

  Future<void> markNotificationsRead() {
    history = history.map((n) => n.markRead()).toList();
    notifyListeners();
    return _saveHistory();
  }

  Future<void> clearNotifications() {
    history = [];
    notifyListeners();
    return _saveHistory();
  }

  Future<void> _saveHistory() {
    final snapshot = [...history];
    // A failed write must not poison the chain for all subsequent saves
    // (audit L25): swallow the error and keep the chain usable.
    return _historyWork = _historyWork
        .then((_) => settings.saveNotificationHistory(snapshot))
        .catchError((Object _) {});
  }

  AppNotification notificationFor(Notice notice) {
    final s = strings;
    final server = switch (selected) {
      'auto' => s.serverAuto,
      'bypass' => s.serverBypass,
      final id => displayNameOf(id),
    };
    final (title, body, action) = switch (notice) {
      ConnectionLost() => (s.noticeLost, s.noticeLostBody, 'logs'),
      ConnectionRestored() => (s.noticeRestored, server, ''),
      ConnectionFailed(:final failure) => (s.noticeFailed, describe(s, failure), 'connect'),
      ServerSwitched(:final entry, :final backup) => (entry, backup ? s.noticeBackup : s.noticeNext, 'logs'),
      ServerReturned(:final entry) => (entry, s.noticeMainBack, ''),
      ServerDegraded(:final entry) => (entry, s.noticeDegraded, 'logs'),
    };
    return AppNotification(
      time: DateTime.now(),
      title: title,
      body: body,
      action: action,
      failureKey: notice is ConnectionFailed ? notice.failure.key : '',
    );
  }

  /// App group IDs use "sora:", which never prefixes core-generated server IDs.
  static const autoGroup = 'sora:auto';
  static const bypassId = 'sora:bypass';
  static const failoverGroup = 'sora:failover';
  static const entryGroup = 'sora:group';

  CoreLink? _link;
  bool _disposed = false;
  bool _startedOnce = false;

  /// Active profile in a named group, followed by the remaining retry count.
  String? _member;
  int _memberSpare = 0;
  StreamSubscription<SubscriptionState>? _subscriptionWatch;
  StreamSubscription<CoreEvent>? _sessionWatch;

  /// Fallback groups of the watched session by name: members in the order the
  /// core tries them, the main ones, and the name notices give the group.
  Map<String, ({List<String> order, Set<String> mains, String title, bool ordered})> _fallbacks = {};

  /// Last event seen, so a watch reopened on the same session resumes after it
  /// instead of replaying history.
  String? _seenSession;
  Int64 _seenSequence = Int64.ZERO;

  /// Drops the core connection when a request detects it is unavailable.
  void Function(Object error) _drop = (_) {};

  /// Suppresses failure notices during an explicit disconnect.
  bool _stopping = false;
  Completer<void>? _connectionWork;
  FailureMode _connectionMode = FailureMode.action;
  SessionPlan? _activePlan;

  /// Chain the active session runs through; null for a direct session.
  /// Included in [currentPlan] so that, while chain-connected, the settings
  /// comparison sees the real session plan: the "pending changes" banner no
  /// longer lies, and reconnecting keeps the chain instead of silently
  /// dropping it.
  ProxyChain? _activeChain;
  Future<void> _locationWork = Future.value();
  int _selectionRevision = 0;
  int? _pendingSelection;
  bool needsReconnect = false;
  bool cleanupPending = false;
  bool strictBlocked = false;

  /// Tracks a reported drop so restoration also emits a notice.
  bool _lostAnnounced = false;

  final _notices = StreamController<Notice>.broadcast();

  /// Unsolicited connection events for notification subscribers.
  Stream<Notice> get notices => _notices.stream;

  /// Notice count used to avoid reporting a failure already announced by state
  /// handling.
  int _emitted = 0;

  void _emit(Notice notice, {FailureMode mode = FailureMode.action}) {
    if (_disposed) return;
    _emitted++;
    if (notice is ConnectionLost) {
      reportFailure(
        const CoreFailure('core.network.failed'),
        mode: FailureMode.background,
        source: 'session',
        action: 'connect',
      );
      return;
    }
    if (notice is ConnectionRestored) {
      final announced = _reported.containsKey('session');
      recovered('session');
      if (!announced) return;
    }
    if (notice is ConnectionFailed) {
      if (mode == FailureMode.action) recovered('session', notify: false);
      reportFailure(
        notice.failure,
        mode: mode,
        source: mode == FailureMode.action ? 'connect' : 'session',
        action: 'connect',
      );
      if (mode == FailureMode.background) return;
    } else {
      unawaited(recordNotification(notificationFor(notice)));
    }
    _notices.add(notice);
  }

  /// The core's local proxy endpoint, used by system proxy mode. Null until
  /// reported by the core.
  Endpoint? localProxy;

  Phase phase = Phase.offline;
  DateTime? since;
  String? sessionId;

  StatsTick? stats;
  double? speedUp, speedDown;
  DateTime? _statsAt;
  bool _readingStats = false;

  /// Reads core traffic statistics on demand. There is intentionally no
  /// periodic polling: the UI currently has no consumer for these numbers
  /// (audit M17), so a 1s timer would only burn IPC traffic and battery.
  Future<void> readStats() async {
    final link = _link, id = sessionId;
    if (link == null || id == null || _readingStats) return;
    _readingStats = true;
    try {
      final answer = await link.stub.getStats(GetStatsRequest(apiVersion: apiVersion, sessionId: id));
      if (id != sessionId || link != _link) return;
      if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
      if (!answer.hasStats()) throw const CoreFailure('core.internal.unexpected');
      final now = DateTime.now(), before = stats, at = _statsAt;
      if (before != null && at != null) {
        final seconds = now.difference(at).inMicroseconds / 1e6;
        if (seconds > 0) {
          speedUp = (answer.stats.bytesUp - before.bytesUp).toDouble().clamp(0, double.infinity) / seconds;
          speedDown = (answer.stats.bytesDown - before.bytesDown).toDouble().clamp(0, double.infinity) / seconds;
        }
      }
      stats = answer.stats;
      _statsAt = now;
      recovered('stats');
    } catch (error) {
      reportFailure(error, source: 'stats', mode: FailureMode.background);
      stats = null;
      speedUp = speedDown = null;
      _statsAt = null;
    } finally {
      _readingStats = false;
    }
  }

  /// Runs the DNS leak diagnostics on the core (API 1.8). Needs an active
  /// session; without one it returns [CoreFailure.unavailable], which the UI
  /// renders as a friendly note, never a raw error.
  Future<({List<DnsLeakCheck> checks, CoreFailure? failure})> checkDnsLeaks() async {
    final link = _link, id = sessionId;
    if (link == null || id == null) {
      return (checks: const <DnsLeakCheck>[], failure: CoreFailure.unavailable);
    }
    // DNS leak diagnostics landed with API 1.8: an older core would answer
    // UNIMPLEMENTED and the UI would show a misleading internal error.
    if (link.minor < 8) {
      return (checks: const <DnsLeakCheck>[], failure: const CoreFailure('core.api.version_mismatch'));
    }
    try {
      final answer = await link.stub.checkDnsLeaks(
        CheckDnsLeaksRequest(apiVersion: apiVersion, controlAuthenticator: link.token, sessionId: id),
      );
      if (id != sessionId || link != _link) {
        // The session changed mid-check: the results belong to a dead session.
        return (checks: const <DnsLeakCheck>[], failure: CoreFailure.unavailable);
      }
      if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
      recovered('request');
      return (checks: answer.checks, failure: null);
    } catch (error) {
      final failure = CoreFailure.from(error);
      reportFailure(error, source: 'request', mode: FailureMode.action);
      return (checks: const <DnsLeakCheck>[], failure: failure);
    }
  }

  /// Last displayed failure, cleared by the next action.
  CoreFailure? failure;

  final Map<String, SubscriptionState> _subscriptions = {};
  List<SubscriptionState> get subscriptions => _subscriptions.values.toList();

  /// Server latency in milliseconds; null means the server did not respond.
  final Map<String, int?> latency = {};

  /// User edits layered over subscriptions.
  final OverrideStore overrides;

  /// Network profiles with auto-apply triggers.
  final ProfilesStore profiles;

  /// Named proxy chains.
  final ChainsStore chains;

  /// Lifecycle manager for the sora-sync device-sync daemon. The daemon
  /// is spawned on demand (first opened sync screen) and stopped on app exit;
  /// it is the source of truth for paired devices; the app keeps no device
  /// registry of its own.
  final SyncDaemon syncDaemon = SyncDaemon();

  /// App ⇄ daemon document bridge. Wired to the daemon's current API
  /// client by [ensureSyncBridge]; null while the daemon is unavailable.
  SyncDocumentBridge? _syncBridge;

  /// Wires (or rewires) the document bridge to the daemon's current API
  /// client. Safe to call repeatedly; a no-op without a client.
  void ensureSyncBridge() {
    final client = syncDaemon.client;
    if (client == null) return;
    if (_syncBridge?.client != client) {
      _syncBridge = SyncDocumentBridge(sora: this, client: client);
    }
  }

  /// Fire-and-forget republish hint after local data changes (subscriptions,
  /// servers, settings stores). Debounced inside the bridge; a no-op when
  /// sync is unavailable. The forced publish before every manual sync is
  /// what guarantees nothing is missed.
  void _noteSyncChanged() => _syncBridge?.noteChanged();

  /// Fingerprint of the currently joined network, filled by
  /// [refreshFingerprint] from the core's GetNetworkFingerprint RPC.
  /// Unknown until the first successful refresh.
  NetworkFingerprint networkFingerprint = const NetworkFingerprint.unknown();

  /// True when the core advertises proxy-chain support for the active
  /// engine. The engine registry sets the [chainCapability] flag per engine.
  bool get chainsSupported => coreCapabilities.contains(chainCapability);

  /// Server IDs hidden by subscription overrides.
  Set<String> get hiddenServerIds => overrides.hiddenIds;

  /// Display name with the user's rename applied, if any.
  String displayNameOf(String id) => overrides.renames[id] ?? nameOf(id);
  bool probing = false;
  String? probingSubscription;
  ResponseStream<ProbeResult>? _probeCall;

  bool get canProbe =>
      !_disposed && _link != null && !probing && !busy && (phase == Phase.off || phase == Phase.connected);

  /// All subscription servers in list order, deduplicated by ID.
  List<OutboundSpec> get servers {
    final cached = _serversCache;
    if (cached != null) return cached;
    final seen = <String>{};
    final hidden = hiddenServerIds;
    return _serversCache = [
      for (final s in _subscriptions.values)
        for (final o in s.outbounds)
          if (seen.add(o.id) && !hidden.contains(o.id)) o,
      for (final server in customServers)
        if (server.hasOutbound() && seen.add(server.outbound.id)) server.outbound,
    ];
  }

  /// Memo for [servers], dropped by [notifyListeners]. A single build pass
  /// reads [servers] from the connection pane, from every server row (via
  /// [selected]) and from the plan builder, and each read used to rebuild
  /// the whole deduped list: O(reads × servers) allocations on the first
  /// builds and on every probe tick. Every write to the inputs
  /// (_subscriptions, subscription overrides) already ends in
  /// [notifyListeners], so the memo can never outlive a mutation; it is
  /// replaced rather than mutated, so a held reference keeps the snapshot
  /// semantics the fresh-list-per-call version had.
  List<OutboundSpec>? _serversCache;

  /// Current selection; falls back to auto if the selected server or group is
  /// no longer present. Always the canonical outbound id: custom servers are
  /// stored with plain ids, but the core merges them into subscription
  /// outbound lists as `custom/<id>`, so the plain form is mapped on
  /// read (and on write by [select]), keeping the plan builder, latency
  /// keys and selection comparisons in one namespace.
  String get selected {
    final chosen = settings.server;
    if (chosen == 'auto') return chosen;
    if (chosen == 'bypass') return serverlessAvailable ? chosen : 'auto';
    if (chosen.startsWith(groupPrefix)) {
      // A group whose members are all hidden no longer exists: fall back to
      // auto instead of building a plan the core would reject.
      return entryOf(chosen, _subscriptions.values)?.withoutHidden(hiddenServerIds) == null ? 'auto' : chosen;
    }
    // Legacy plain custom ids (stored before custom ids were canonicalized) resolve
    // here; everything else already lives in the outbound namespace.
    final canonical = canonicalServerId(chosen);
    return servers.any((o) => o.id == canonical) ? canonical : 'auto';
  }

  /// Maps a selection to the core's outbound id namespace:
  /// `custom/<id>` for custom servers, everything else unchanged. See
  /// [canonicalCustomId].
  String canonicalServerId(String id) => canonicalCustomId(id, [for (final s in customServers) s.id]);

  String nameOf(String id) {
    if (id.startsWith(groupPrefix)) return entryOf(id, _subscriptions.values)?.name ?? id;
    // Custom servers are keyed by plain id in _customServers but selected by
    // their canonical `custom/<id>` outbound id.
    final plain = id.startsWith(customServerPrefix) ? id.substring(customServerPrefix.length) : id;
    for (final s in _customServers) {
      if (s.id == plain) return s.name;
    }
    return servers.firstWhere((o) => o.id == id, orElse: () => OutboundSpec(displayName: id)).displayName;
  }

  bool get busy => _connectionWork != null || phase == Phase.connecting || phase == Phase.disconnecting;

  SessionPlan get currentPlan {
    // Hops that vanished (a server was deleted mid-session) are dropped
    // instead of throwing inside a getter the UI calls on every rebuild;
    // the mismatch then reports as pending changes.
    final chain = _activeChain;
    final hops = chain == null
        ? const <String>[]
        : [
            for (final id in chain.hops)
              if (servers.any((o) => o.id == id)) id,
          ];
    return buildPlan(
      servers: servers,
      choice: selected,
      settings: settings,
      extensionRules: [for (final r in extensions.routingRules) r.rule],
      latency: latency,
      bandwidth: bandwidth,
      entry: selected.startsWith(groupPrefix)
          // Hidden members must not reach the plan: the core rejects a group
          // that names a server absent from the outbounds.
          ? entryOf(selected, _subscriptions.values)?.withoutHidden(hiddenServerIds)
          : null,
      chain: hops,
      zapretWithVpn: settings.zapretWithVpn && Platform.isLinux && serverlessAvailable,
      reliabilityOf: reliabilityOf,
    );
  }

  @override
  void notifyListeners() {
    // State just changed, so the memoized server list may be stale; the
    // next [servers] read rebuilds it (see [_serversCache]).
    _serversCache = null;
    if (!_disposed) super.notifyListeners();
  }

  /// Maintains the core connection and watches subscriptions and session state,
  /// reopening the connection after a drop until disposal.
  Future<void> run() async {
    try {
      await extensions.load();
    } catch (error) {
      reportFailure(error, source: 'extensions', mode: FailureMode.background);
    }
    if (_disposed) return;
    _extensionWorkers = ExtensionWorkers(this);
    checkCrashIntent();
    while (!_disposed) {
      final CoreLink link;
      try {
        link = await CoreLink.open(
          onRetry: (error) {
            if (_disposed) return;
            failure = CoreFailure.from(error);
            reportFailure(error, source: 'core', mode: FailureMode.background);
            notifyListeners();
          },
          canceled: () => _disposed,
        );
      } catch (error) {
        failure = CoreFailure.from(error);
        reportFailure(error, source: 'core', mode: FailureMode.background);
        notifyListeners();
        return;
      }
      if (_disposed) {
        await link.close();
        return;
      }
      _link = link;
      final dropped = Completer<void>();
      _drop = (error) {
        reportFailure(error, source: 'core', mode: FailureMode.background);
        if (!dropped.isCompleted && CoreFailure.from(error).key == CoreFailure.unavailable.key) dropped.complete();
      };
      try {
        await _readStatus(report: false);
        final about = await link.stub.getAbout(GetAboutRequest(apiVersion: apiVersion));
        if (about.hasError()) throw CoreFailure.fromWire(about.error);
        coreCapabilities = about.about.contract.capabilities.toSet();
        serverlessAvailable = coreCapabilities.contains('serverless');
        localProxy = about.about.hasLocalProxy() ? about.about.localProxy : null;
        if (failure?.key == CoreFailure.unavailable.key) failure = null;
        recovered('core');
        // GetStatus + getAbout answered: the post-update
        // health signal. The updater clears its pending-update marker here;
        // the 60-second rollback window never fires on a healthy core.
        coreHandshakeDone = true;
        unawaited(_updates.noteCoreHealthy());
        await syncProfiles();
        _watchSubscriptions();
        _watchSession();
        unawaited(loadCustomServers());
        notifyListeners();
        if (_pendingSelection != null) unawaited(_applySelection());
        if ((settings.connectOnStart || settings.resumeAfterUpdate) && !_startedOnce && phase == Phase.off) {
          // Auto-connect only once per launch so core reconnection cannot undo
          // an explicit disconnect.
          _startedOnce = true;
          // Allow time for the initial server list to arrive through the
          // subscription watch.
          await Future<void>.delayed(const Duration(milliseconds: 600));
          // A pending crash-restore offer owns the connection decision: wait
          // for it instead of connecting underneath the banner.
          // An explicit dismiss stands the auto-connect down for this launch.
          // A dropped core link ends the wait: the run loop must recover the
          // transport below instead of stalling on the banner; the offer
          // still stands, because the gate below requires _pendingRestore to
          // be null before any auto-connect.
          while (_pendingRestore != null && !_disposed && phase == Phase.off && !dropped.isCompleted) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
          if (phase == Phase.off && _pendingRestore == null && !_restoreDeclined) {
            await settings.saveResumeAfterUpdate(false);
            unawaited(connect(mode: FailureMode.background));
          }
        }
        if (phase == Phase.connected && settings.resumeAfterUpdate) await settings.saveResumeAfterUpdate(false);
        _startedOnce = true;
        await dropped.future;
      } catch (error) {
        failure = CoreFailure.from(error);
        reportFailure(error, source: 'core', mode: FailureMode.background);
        notifyListeners();
        // Delay retries after post-handshake failures to avoid a tight loop.
        await Future<void>.delayed(const Duration(seconds: 3));
      }
      await _cancelWatches();
      _link = null;
      serverlessAvailable = false;
      coreCapabilities = {};
      await link.close();
      phase = Phase.offline;
      stats = null;
      speedUp = speedDown = null;
      _statsAt = null;
      notifyListeners();
    }
  }

  Future<void> _cancelWatches() async {
    await _subscriptionWatch?.cancel();
    await _sessionWatch?.cancel();
    _subscriptionWatch = _sessionWatch = null;
  }

  /// Reads session state. [report] enables failure reporting; startup disables
  /// it to suppress failures predating the current UI session.
  Future<void> _readStatus({bool report = true}) async {
    final link = _link!, expected = sessionId;
    final answer = await link.stub.getStatus(GetStatusRequest(apiVersion: apiVersion));
    if (_disposed || link != _link || expected != sessionId) return;
    if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
    _applyState(answer.status.connection, report: report);
    if (link.minor >= 12) {
      strictBlocked = answer.status.strictKillSwitch;
      if (strictBlocked) {
        settings.strictKillSwitch = true;
        settings.killSwitch = true;
      }
      if (phase == Phase.off && strictBlocked) cleanupPending = true;
    }
  }

  void _applyState(ConnectionState state, {bool report = true}) {
    final before = phase;
    if (state.sessionId.isNotEmpty && state.sessionId != sessionId ||
        state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED ||
        state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED) {
      stats = null;
      speedUp = speedDown = null;
      _statsAt = null;
    }
    phase = switch (state.value) {
      ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTING => Phase.connecting,
      ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTED => Phase.connected,
      ConnectionStateValue.CONNECTION_STATE_VALUE_RECONNECTING => Phase.reconnecting,
      _ => Phase.off,
    };
    if (phase == Phase.off && strictBlocked) cleanupPending = true;
    if (phase == Phase.connecting || phase == Phase.reconnecting) unawaited(_probeCall?.cancel());
    // Session events may omit the ID. Retain the known ID until the session
    // ends.
    if (phase == Phase.off) {
      sessionId = null;
      _activePlan = null;
      _activeChain = null;
      needsReconnect = false;
    } else if (state.sessionId.isNotEmpty) {
      sessionId = state.sessionId;
    }
    since = state.hasChangedAt() ? state.changedAt.toDateTime() : null;
    if (_stopping && (phase != Phase.off || _connectionWork != null)) phase = Phase.disconnecting;
    if (report &&
        state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED &&
        _member != null &&
        _memberSpare > 0) {
      // Profiles need client-side failover because they cannot share a core
      // fallback group.
      latency[_member!] = null;
      _memberSpare--;
      final entry = entryOf(settings.server, _subscriptions.values);
      if (entry != null) _emit(ServerSwitched(entry.name, backup: entry.ordered));
      final mode = _connectionWork == null ? FailureMode.background : _connectionMode;
      unawaited((_connectionWork?.future ?? Future.value()).then((_) => connect(retry: true, mode: mode)));
      return;
    }
    if (report &&
        state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED &&
        state.reason != SoraErrorCode.SORA_ERROR_CODE_UNSPECIFIED) {
      // Preserve the request's detailed error over the less specific state
      // reason.
      failure ??= CoreFailure(_keyOfCode(state.reason));
    }
    if (report) _announce(before, state);
  }

  /// Emits notices for unsolicited drops, restorations and failures.
  void _announce(Phase before, ConnectionState state) {
    if (before == Phase.connected && phase == Phase.reconnecting) {
      _lostAnnounced = true;
      _emit(const ConnectionLost());
    } else if (phase == Phase.connected && _lostAnnounced) {
      _lostAnnounced = false;
      _emit(const ConnectionRestored());
    } else if (before != Phase.off &&
        phase == Phase.off &&
        state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED &&
        !_stopping) {
      _lostAnnounced = false;
      _emit(
        ConnectionFailed(failure ?? CoreFailure(_keyOfCode(state.reason))),
        mode: _connectionWork == null ? FailureMode.background : _connectionMode,
      );
    }
  }

  static String _keyOfCode(SoraErrorCode code) => switch (code) {
    SoraErrorCode.SORA_ERROR_CODE_DEADLINE_EXCEEDED => 'core.network.timeout',
    SoraErrorCode.SORA_ERROR_CODE_UNAVAILABLE => 'core.network.failed',
    SoraErrorCode.SORA_ERROR_CODE_PERMISSION_DENIED => 'core.plan.tunnel_unsupported',
    _ => 'core.engine.stopped',
  };

  void _watchSubscriptions() {
    final link = _link!;
    final stream = link.stub.watchSubscriptions(
      WatchSubscriptionsRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
    );
    _subscriptionWatch = stream.listen(
      (state) {
        final id = state.settings.id;
        if (state.deleted) {
          _subscriptions.remove(id);
        } else {
          _subscriptions[id] = state;
        }
        final key = state.hasLastError() ? state.lastError.userMessageKey : '';
        if (state.deleted) {
          recovered('subscription:$id');
        } else if (key.isNotEmpty) {
          reportFailure(
            CoreFailure.fromWire(state.lastError),
            source: 'subscription:$id',
            action: 'subscription',
            argument: id,
            since: state.hasFailureSince() ? state.failureSince.toDateTime() : null,
            mode: FailureMode.background,
          );
        } else {
          recovered('subscription:$id');
        }
        notifyListeners();
      },
      onError: (Object error) {
        if (!_disposed && link == _link) _drop(error);
      },
      onDone: () {
        if (!_disposed && link == _link) _drop(CoreFailure.unavailable);
      },
    );
  }

  /// Replaces the current session watch. Events before [since] update state
  /// without triggering notices or failover.
  void _watchSession({DateTime? since, bool resetFailures = true}) {
    unawaited(_sessionWatch?.cancel());
    _sessionWatch = null;
    final link = _link, id = sessionId;
    if (link == null || id == null) return;
    if (resetFailures) _watchFailures = 0;
    // Refresh status because a closed watch may mean the session ended or was
    // replaced.
    void resync() {
      if (_link == link) unawaited(_readStatus().then((_) => notifyListeners(), onError: _drop));
    }

    // The stream replays history; old events must not trigger notices or repeat
    // failover.
    final opened = (since ?? DateTime.now()).subtract(const Duration(seconds: 1));
    final stream = link.stub.watchEvents(
      WatchEventsRequest(
        apiVersion: apiVersion,
        sessionId: id,
        afterSequence: id == _seenSession ? _seenSequence : null,
      ),
    );
    _sessionWatch = stream.listen(
      (event) {
        if (link != _link || id != sessionId) return;
        if (event.sessionId.isNotEmpty && event.sessionId != id) return;
        if (event.hasStateChanged() &&
            event.stateChanged.state.sessionId.isNotEmpty &&
            event.stateChanged.state.sessionId != id) {
          return;
        }
        // A healthy event resets the watchdog streak.
        if (_watchFailures != 0) {
          _watchFailures = 0;
          if (failure?.key == 'app.core_watch_unstable') failure = null;
          recovered('core');
        }
        _seenSession = id;
        _seenSequence = event.sequence;
        final fresh = !event.hasEmittedAt() || event.emittedAt.toDateTime().isAfter(opened);
        if (event.hasStateChanged()) {
          _applyState(event.stateChanged.state, report: fresh);
          notifyListeners();
        } else if (event.hasGroupSwitched() && fresh) {
          _fallbackMoved(event.groupSwitched);
        } else if (event.hasProfileMatched() && fresh) {
          // The core auto-matched a network profile (1.10+): apply it when
          // auto-apply is on, otherwise ask the user. handleProfileMatched
          // ignores unknown profile ids, so a stale core/client profile set
          // cannot break the watch.
          unawaited(handleProfileMatched(event.profileMatched.profileId));
        }
      },
      onError: (Object error) {
        if (_disposed || link != _link || id != sessionId) return;
        _drop(error);
        _watchFailures++;
        if (_watchFailures >= _maxWatchFailures) {
          // Stop auto-recovery and surface a visible error with a repair
          // action instead of looping forever.
          failure = const CoreFailure('app.core_watch_unstable');
          notifyListeners();
          return;
        }
        // Reopen the watch after a short pause; resync covers the gap.
        unawaited(
          Future<void>.delayed(const Duration(seconds: 2)).then((_) {
            if (!_disposed && link == _link && id == sessionId && !watchUnstable) {
              _watchSession(since: DateTime.now(), resetFailures: false);
            }
          }),
        );
        resync();
      },
      onDone: resync,
    );
  }

  /// Consecutive WatchEvents failures; reset by any healthy event.
  int _watchFailures = 0;

  /// After this many consecutive watch failures the app stops silent retries
  /// and asks the user to repair the link.
  static const _maxWatchFailures = 5;

  /// Whether the session watch gave up auto-recovery.
  bool get watchUnstable => _watchFailures >= _maxWatchFailures;

  /// Re-establishes the session watch after [watchUnstable].
  Future<void> repairWatch() async {
    _watchFailures = 0;
    if (failure?.key == 'app.core_watch_unstable') failure = null;
    _watchSession();
    notifyListeners();
  }

  /// How long a session intent stays restorable. An offer older than this
  /// refers to a session the user has long forgotten, so the stored `at`
  /// timestamp is read and stale intents are silently dropped.
  static const _sessionIntentTtl = Duration(hours: 24);

  /// Server choice saved after a successful connect; offered for restore when
  /// the app restarts after a crash.
  String? _pendingRestore;

  /// A crashed session is waiting for the user's restore decision.
  String? get pendingRestore => _pendingRestore;

  /// Set when the user explicitly dismisses the crash-restore offer: the
  /// pending auto-connect stands down for this launch instead of connecting
  /// right after the user's "not now".
  bool _restoreDeclined = false;

  void _writeSessionIntent(String choice) {
    if (!settings.restoreOnCrash) return;
    settings.sessionIntent = jsonEncode({'server': choice, 'at': DateTime.now().millisecondsSinceEpoch});
  }

  void _clearSessionIntent() {
    _pendingRestore = null;
    if (settings.sessionIntent.isNotEmpty) settings.sessionIntent = '';
  }

  /// Marks a clean shutdown. A quit that reaches this point is not a crash,
  /// so no restore may be offered for this run's session on next launch,
  /// even when the core session is intentionally left running
  /// (`quit(disconnect: false)`) or the disconnect is skipped because the
  /// core is offline.
  void noteCleanShutdown() {
    if (settings.strictKillSwitch || strictBlocked) return;
    _clearSessionIntent();
  }

  /// Checks for a session intent left by a crashed run; call once at startup.
  void checkCrashIntent() {
    if (!settings.restoreOnCrash) {
      _clearSessionIntent();
      return;
    }
    final raw = settings.sessionIntent;
    if (raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && decoded['server'] is String) {
        final at = decoded['at'];
        final age = at is int ? DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(at)) : Duration.zero;
        if (age > _sessionIntentTtl) {
          // Too old to be a session worth restoring: drop it instead of
          // offering to resurrect a choice the user made days ago.
          _clearSessionIntent();
          return;
        }
        _pendingRestore = decoded['server'] as String;
        notifyListeners();
      } else {
        settings.sessionIntent = '';
      }
    } on FormatException {
      settings.sessionIntent = '';
    }
  }

  /// Restores the crashed session: applies the saved choice and connects.
  Future<void> restoreCrashedSession() async {
    final choice = _pendingRestore;
    _clearSessionIntent();
    if (choice != null && choice.startsWith('chain:')) {
      final chain = chains.chains.where((c) => c.id == choice.substring(6)).firstOrNull;
      notifyListeners();
      if (chain != null) {
        // Chain preconditions (engine capability, hop validity) throw: surface
        // them as a visible failure instead of an unhandled async error from
        // the unawaited UI call.
        try {
          await connectChain(chain);
        } on CoreFailure catch (error) {
          failure = error;
          reportFailure(error, source: 'restore', mode: FailureMode.action);
          notifyListeners();
        }
        return;
      }
      // The chain is gone (deleted after the crash): fall through and restore
      // a plain session instead of silently doing nothing.
    }
    if (choice != null && choice != 'auto' && choice != 'bypass') settings.server = choice;
    notifyListeners();
    await connect();
  }

  /// Dismisses the crash-restore offer without connecting.
  void dismissCrashRestore() {
    // The explicit "not now" wins: a pending auto-connect stands down for
    // this launch, and a stale resume-after-update flag is consumed so the
    // next launch does not reconnect behind the user's back.
    _restoreDeclined = true;
    _clearSessionIntent();
    unawaited(settings.saveResumeAfterUpdate(false));
    notifyListeners();
  }

  /// Tells the user that a fallback group of the core moved. The core tries
  /// members in order, so a move down the list means a server stopped
  /// answering, and a move up means an earlier one answers again. A move up
  /// to a backup stays quiet: no notice text fits it without naming a main
  /// server that is not there.
  void _fallbackMoved(GroupSwitched moved) {
    final group = _fallbacks[moved.group];
    if (group == null) return;
    final isMain = group.mains.contains(moved.selected);
    if (group.order.indexOf(moved.selected) > group.order.indexOf(moved.previous)) {
      _emit(ServerSwitched(group.title, backup: group.ordered && !isMain));
    } else if (isMain && !group.mains.contains(moved.previous)) {
      _emit(ServerReturned(group.title));
    }
  }

  /// The main members of fallback group [g]: those named main in a group with
  /// roles, otherwise the server the user picked.
  static Set<String> _mainsOf(GroupSpec g, Entry? entry) => entry != null && entry.ordered
      ? {
          for (final m in g.members)
            if (entry.roles[m] == Role.main) m,
        }
      : {g.members.first};

  /// Connects when off; disconnects an active or connecting session.
  ///
  /// A tap during [Phase.disconnecting] is queued: [connect] runs once the
  /// in-flight disconnect lands, instead of being swallowed (audit L24).
  bool _connectQueued = false;

  Future<void> _profileWork = Future.value();

  void _profilesChanged() => unawaited(syncProfiles(mode: FailureMode.action));

  /// Reconciles the runtime mirror after edits, imports and core reconnects.
  /// Serialized sends prevent an older save from restoring a deleted profile.
  Future<void> syncProfiles({FailureMode mode = FailureMode.background}) {
    final link = _link;
    return _profileWork = _profileWork.then((_) async {
      if (_disposed || link == null || link != _link) return;
      try {
        if (link.minor < 10) {
          if (profiles.profiles.isNotEmpty) throw const CoreFailure('core.api.version_mismatch');
          return;
        }
        final desired = [for (final profile in profiles.profiles) profile.toWire()];
        final listed = await link.stub.listProfiles(
          ListProfilesRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
          options: CallOptions(timeout: const Duration(seconds: 10)),
        );
        if (listed.hasError()) throw CoreFailure.fromWire(listed.error);
        final ids = desired.map((p) => p.id).toSet();
        final retained = listed.profiles.where((p) => ids.contains(p.id)).map((p) => p.id).toList();
        final expected = desired.take(retained.length).map((p) => p.id).toList();
        // Match priority follows editor order, including imported reorderings.
        final reorder = !listEquals(retained, expected);
        for (final old in listed.profiles) {
          if (_disposed || link != _link) return;
          if (!ids.contains(old.id) || reorder) {
            final deleted = await link.stub.deleteProfile(
              DeleteProfileRequest(apiVersion: apiVersion, controlAuthenticator: link.token, profileId: old.id),
              options: CallOptions(timeout: const Duration(seconds: 10)),
            );
            if (deleted.hasError()) throw CoreFailure.fromWire(deleted.error);
          }
        }
        for (final profile in desired) {
          if (_disposed || link != _link) return;
          if (!reorder && listed.profiles.any((old) => old == profile)) continue;
          final saved = await link.stub.saveProfile(
            SaveProfileRequest(apiVersion: apiVersion, controlAuthenticator: link.token, profile: profile),
            options: CallOptions(timeout: const Duration(seconds: 10)),
          );
          if (saved.hasError()) throw CoreFailure.fromWire(saved.error);
        }
        recovered('profiles');
      } catch (error) {
        if (_disposed || link != _link) return;
        reportFailure(error, source: 'profiles', mode: mode);
        if (CoreFailure.from(error).key == CoreFailure.unavailable.key) _drop(error);
      }
    });
  }

  /// Applies a network profile's settings snapshot. Only snapshot
  /// fields the profile captured are touched; the rest stays as-is.
  Future<void> applyProfile(NetworkProfile profile) async {
    await change((x) {
      if (profile.tunnel != null) x.tunnel = profile.tunnel!;
      if (profile.preset != null) x.preset = profile.preset!;
      if (profile.dns != null) x.dns = profile.dns!;
      if (profile.dnsPreset != null) x.dnsPreset = profile.dnsPreset!;
      if (profile.engine != null) x.engine = profile.engine!;
      if (profile.serverId != null) x.server = profile.serverId!;
    });
    if (phase == Phase.connected || phase == Phase.reconnecting || _connectionWork != null) {
      _pendingSelection = ++_selectionRevision;
      await _applySelection();
    }
  }

  /// Handles a core ProfileMatched event: marks the profile active and
  /// either applies it (auto-apply) or asks first. Applying posts an undo
  /// snapshot so the previous settings are one tap away.
  Future<void> handleProfileMatched(String profileId) async {
    final profile = profiles.byId(profileId);
    if (profile == null) return;
    profiles.activeId = profileId;
    if (profile.autoApply) {
      await applyProfileWithUndo(profile);
    } else {
      await recordNotification(
        AppNotification(
          time: DateTime.now(),
          title: strings.profileApplyAsk(profile.name),
          body: '',
          action: 'apply-profile',
          argument: profileId,
        ),
      );
    }
    notifyListeners();
  }

  /// Applies a profile and posts an undo snapshot so the previous settings
  /// are one tap away.
  Future<void> applyProfileWithUndo(NetworkProfile profile) async {
    final before = jsonEncode({
      'tunnel': settings.tunnel,
      'preset': settings.preset,
      'dns': settings.dns,
      'dnsPreset': settings.dnsPreset,
      'server': settings.server,
      'engine': settings.engine,
    });
    await applyProfile(profile);
    await recordNotification(
      AppNotification(
        time: DateTime.now(),
        title: strings.profileApplied(profile.name),
        body: '',
        action: 'undo-profile',
        argument: before,
      ),
    );
  }

  /// Restores the settings snapshot saved by [applyProfileWithUndo].
  Future<void> undoProfileApply(String snapshotJson) async {
    try {
      final before = jsonDecode(snapshotJson) as Map<String, dynamic>;
      await change((x) {
        final tunnel = before['tunnel'];
        if (tunnel is String) x.tunnel = tunnel;
        final preset = before['preset'];
        if (preset is String) x.preset = preset;
        final dns = before['dns'];
        if (dns is List) x.dns = [for (final v in dns) v.toString()];
        final dnsPreset = before['dnsPreset'];
        if (dnsPreset is String) x.dnsPreset = dnsPreset;
        final server = before['server'];
        if (server is String) x.server = server;
        final engine = before['engine'];
        if (engine is String) x.engine = engine;
      });
      if (phase == Phase.connected || phase == Phase.reconnecting || _connectionWork != null) {
        _pendingSelection = ++_selectionRevision;
        await _applySelection();
      }
    } catch (_) {
      // A corrupt snapshot must not break the UI; there is nothing sane to
      // restore, so the current settings simply stay.
    }
  }

  /// Refreshes the fingerprint for the editor display. Runtime matching is
  /// owned by the core and arrives through ProfileMatched events, independent
  /// of this screen. A failed lookup leaves the display unknown.
  Future<void> refreshFingerprint() async {
    var fingerprint = const NetworkFingerprint.unknown();
    final link = _link;
    if (link != null && link.minor >= 10) {
      try {
        final answer = await link.stub.getNetworkFingerprint(
          GetNetworkFingerprintRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
          options: CallOptions(timeout: const Duration(seconds: 10)),
        );
        if (!_disposed && link == _link && !answer.hasError() && answer.hasFingerprint()) {
          String? nonEmpty(String value) => value.isEmpty ? null : value;
          fingerprint = NetworkFingerprint(
            ssid: nonEmpty(answer.fingerprint.ssid),
            gateway: nonEmpty(answer.fingerprint.gateway),
            asn: nonEmpty(answer.fingerprint.asn),
          );
        }
      } catch (_) {
        // A failed lookup must not break the UI; the fingerprint stays
        // unknown and the profiles screen shows the unavailable state.
      }
    }
    networkFingerprint = fingerprint;
    notifyListeners();
  }

  /// Connects through a proxy chain. The chain backend landed with core
  /// API 1.10; older cores and engines without the chains capability get an
  /// localized failure instead of a silent misconnect.
  Future<void> connectChain(ProxyChain chain) async {
    if (!chainsSupported) {
      throw const CoreFailure('chainUnsupported');
    }
    final error = ChainsStore.validateHops(chain.hops);
    if (error != null) throw CoreFailure(error);
    final missing = [
      for (final id in chain.hops)
        if (!servers.any((o) => o.id == id)) id,
    ];
    if (missing.isNotEmpty) {
      throw const CoreFailure('chainHopMissing');
    }
    await connect(via: chain);
  }

  Future<void> toggle() async {
    if (cleanupPending) {
      await disconnect();
    } else if (phase == Phase.off || phase == Phase.offline) {
      // Offline means the core link is down: connect() then reports
      // app.core_unavailable instead of silently ignoring the tap.
      await connect();
    } else if (phase == Phase.disconnecting) {
      _connectQueued = true;
    } else if (phase == Phase.connected || phase == Phase.reconnecting || phase == Phase.connecting) {
      await disconnect();
    }
  }

  /// Connects using the current selection and settings. [retry] preserves the
  /// remaining attempt count during profile-group failover.
  Future<void> connect({bool retry = false, ProxyChain? via, FailureMode mode = FailureMode.action}) async {
    if (_disposed || updateBlocked || busy || _stopping) return;
    if (cleanupPending && !strictBlocked) {
      await disconnect();
      if (cleanupPending || _disposed) return;
    }
    final link = _link;
    if (link == null) {
      // The core is not up (e.g. "retry" tapped in a notification): say so
      // instead of silently doing nothing (audit L23).
      failure = CoreFailure.unavailable;
      reportFailure(failure!, mode: mode, source: 'connect', action: 'connect');
      notifyListeners();
      return;
    }
    failure = null;
    if (selected != 'bypass' && servers.isEmpty) {
      failure = const CoreFailure('app.no_servers');
      _emit(ConnectionFailed(failure!), mode: mode);
      notifyListeners();
      return;
    }
    final choice = selected;
    final entry = choice.startsWith(groupPrefix) ? entryOf(choice, _subscriptions.values) : null;
    // A plain reconnect during a chain session keeps the chain: via is
    // only set for a fresh chain connect, while select()/disconnect() clear
    // the tracked chain explicitly. A hop deleted mid-session breaks the
    // chain: fail loudly with chainHopMissing instead of silently connecting
    // a single server the user did not ask for, or crashing the plan builder
    // on firstWhere.
    final keepChain = via ?? _activeChain;
    if (keepChain != null) {
      final broken =
          ChainsStore.validateHops(keepChain.hops) != null ||
          keepChain.hops.any((id) => !servers.any((o) => o.id == id));
      if (broken) {
        failure = const CoreFailure('chainHopMissing');
        _emit(ConnectionFailed(failure!), mode: mode);
        notifyListeners();
        return;
      }
    }
    final plan = via == null
        ? currentPlan
        : buildPlan(
            servers: servers,
            choice: 'auto',
            settings: settings,
            extensionRules: [for (final r in extensions.routingRules) r.rule],
            latency: latency,
            bandwidth: bandwidth,
            chain: via.hops,
            zapretWithVpn: settings.zapretWithVpn && Platform.isLinux && serverlessAvailable,
            reliabilityOf: reliabilityOf,
          );
    if (plan.tunStack.isNotEmpty && link.minor < 7) {
      failure = const CoreFailure('core.api.version_mismatch');
      _emit(ConnectionFailed(failure!), mode: mode);
      notifyListeners();
      return;
    }
    // Chains and zapret-with-VPN need core API 1.10; an older core would
    // silently ignore the fields and connect without them.
    if ((plan.chain.isNotEmpty || plan.zapretWithVpn) && link.minor < 10) {
      failure = const CoreFailure('core.api.version_mismatch');
      _emit(ConnectionFailed(failure!), mode: mode);
      notifyListeners();
      return;
    }
    final fallbacks = {
      for (final g in plan.groups)
        if (g.type == GroupType.GROUP_TYPE_FALLBACK && g.members.isNotEmpty)
          g.name: (
            order: g.members,
            mains: _mainsOf(g, entry),
            title: entry?.name ?? nameOf(g.members.first),
            ordered: entry?.ordered ?? false,
          ),
    };
    final strict = settings.strictKillSwitch;
    if (strict && (link.minor < 12 || !coreCapabilities.contains('strict-kill-switch'))) {
      failure = const CoreFailure('core.api.version_mismatch');
      _emit(ConnectionFailed(failure!), mode: mode);
      notifyListeners();
      return;
    }
    final armed = settings.killSwitch || strict;
    // Track the active profile because profile groups fail over in the client.
    _member = entry != null && entry.members.any(isProfile) ? plan.outbounds.single.id : null;
    if (!retry) _memberSpare = entry == null ? 0 : entry.members.length - 1;
    final work = _connectionWork = Completer<void>();
    _connectionMode = mode;
    phase = Phase.connecting;
    notifyListeners();
    // Include events emitted during these requests, before the watch opens.
    final started = DateTime.now();
    var connected = false;
    try {
      await _probeCall?.cancel();
      final answer = await link.stub.connect(
        // The core arms the kill switch before the engine starts, so nothing
        // leaves outside the tunnel while it comes up.
        ConnectRequest(
          apiVersion: apiVersion,
          sessionPlan: plan,
          controlAuthenticator: link.token,
          killSwitch: armed,
          strictKillSwitch: strict,
          reconnect: settings.connectOnStart,
        ),
        options: CallOptions(timeout: const Duration(seconds: 35)),
      );
      if (_disposed || link != _link) return;
      if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
      _applyState(answer.status.connection);
      _activePlan = plan;
      // via == null on a plain reconnect keeps the tracked chain.
      _activeChain = keepChain;
      needsReconnect = currentPlan != plan;
      connected = true;
      recovered('connect');
      recovered('session');
      strictBlocked = strict;
      // Remember the intent only once the session is truly up: writing
      // it before the RPC would offer to "restore" a session that never
      // existed if the connect failed. Chain connects are recorded by chain
      // id and restored through connectChain rather than the server
      // selector; a plain reconnect during a chain session keeps the chain
      // id too.
      _writeSessionIntent(keepChain == null ? choice : 'chain:${keepChain.id}');
      // Swapped together with the watch, so events of the previous session
      // never meet the groups of this one.
      _fallbacks = fallbacks;
      _watchSession(since: started);
    } catch (error) {
      if (_disposed || link != _link) return;
      failure = CoreFailure.from(error);
      if (failure!.key == 'core.guard.restore_failed') cleanupPending = true;
      // Read state to trigger profile failover or report a final failure
      // without duplicating notices.
      final before = _emitted;
      await _readStatus().catchError((Object _) {});
      if (phase == Phase.connecting) phase = Phase.off;
      if (!_stopping && _emitted == before) _emit(ConnectionFailed(failure!), mode: mode);
      // The session never came up: this was a failed connect, not a crash,
      // so no restore intent may linger for the next startup.
      // Profile-group failover re-runs connect() and re-writes its intent.
      _clearSessionIntent();
    } finally {
      _connectionWork = null;
      work.complete();
    }
    if (connected && !_disposed && !_stopping && settings.strictKillSwitch != strict) {
      await setStrictKillSwitch(settings.strictKillSwitch);
    }
    if (connected && !_disposed && !_stopping && settings.killSwitch != armed && sessionId != null) {
      await setKillSwitch(settings.killSwitch);
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    _selectionRevision++;
    _pendingSelection = null;
    final link = _link;
    if (link == null) return;
    if (_stopping) {
      // A redundant disconnect while one is in flight: the latest explicit
      // intent is to stay disconnected, so drop any queued reconnect.
      _connectQueued = false;
      return;
    }
    failure = null;
    recovered('disconnect');
    phase = Phase.disconnecting;
    _stopping = true;
    cleanupPending = true;
    _lostAnnounced = false;
    // A clean disconnect is not a crash: drop the restore intent.
    _clearSessionIntent();
    notifyListeners();
    try {
      await _probeCall?.cancel();
      await _connectionWork?.future;
      if (_disposed || link != _link) return;
      final answer =
          await const RetryOptions(
            maxAttempts: 10,
            delayFactor: Duration(milliseconds: 100),
            maxDelay: Duration(seconds: 1),
          ).retry(() async {
            final answer = await link.stub.disconnect(
              DisconnectRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
              options: CallOptions(timeout: const Duration(seconds: 20)),
            );
            if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
            return answer;
          }, retryIf: (error) => error is CoreFailure && error.key == 'core.session.busy');
      cleanupPending = false;
      strictBlocked = false;
      _applyState(answer.status.connection);
    } catch (error) {
      failure = CoreFailure.from(error);
      reportFailure(error, source: 'disconnect', mode: FailureMode.action);
      await _readStatus().catchError((Object _) {});
    } finally {
      _stopping = false;
    }
    notifyListeners();
    // A toggle tap during disconnecting queues a reconnect (audit L24).
    if (_connectQueued) {
      _connectQueued = false;
      if (!_disposed && phase == Phase.off) unawaited(connect());
    }
  }

  /// Defers connection changes until the user explicitly reconnects.
  Future<void> _replan() async {
    extensions.logRoutingOverlaps(settings.rules.map(UserRule.parse).nonNulls.map((r) => r.destination).toList());
    if (phase == Phase.connected || phase == Phase.reconnecting || _connectionWork != null) {
      needsReconnect = _activePlan == null || currentPlan != _activePlan;
      notifyListeners();
    }
  }

  Future<void> select(String server) async {
    // Persist the canonical outbound id: the plan builder, latency
    // keys and selection checks all speak the core's `custom/<id>` namespace
    // for custom servers, so the plain card id is mapped once, here.
    final canonical = canonicalServerId(server);
    if (settings.server == canonical) return;
    settings.server = canonical;
    if (_activeChain != null) {
      // A manual server pick ends the chain session: the next plan is
      // direct, so the comparison below reconnects to the chosen server
      // instead of silently keeping the chain.
      _activeChain = null;
    }
    notifyListeners();
    await _replan();
    if (_stopping ||
        _disposed ||
        (phase != Phase.connected && phase != Phase.reconnecting && _connectionWork == null && sessionId == null)) {
      return;
    }
    _pendingSelection = ++_selectionRevision;
    await _applySelection();
  }

  Future<void> _applySelection() {
    final revision = _pendingSelection;
    final link = _link;
    // Collapse queued clicks to the last selection. Core Connect validates
    // the replacement before stopping the old session.
    return _locationWork = _locationWork.then((_) async {
      await _connectionWork?.future;
      if (_disposed ||
          _stopping ||
          link == null ||
          link != _link ||
          revision == null ||
          revision != _selectionRevision) {
        return;
      }
      if ((phase == Phase.connected || phase == Phase.reconnecting) && currentPlan != _activePlan) {
        await connect();
      }
      if (link == _link && revision == _selectionRevision && failure?.key != CoreFailure.unavailable.key) {
        _pendingSelection = null;
      }
    });
  }

  /// Applies settings and stages connection changes. Disable [replan] for
  /// appearance-only changes.
  Future<void> change(void Function(Settings) apply, {bool replan = true}) async {
    final checks = settings.checkUpdates;
    apply(settings);
    if (checks != settings.checkUpdates) await updates.setChecking(settings.checkUpdates);
    notifyListeners();
    if (replan) await _replan();
  }

  /// Resets settings to defaults and reapplies the active connection plan.
  Future<void> reset() async {
    await settings.reset();
    await updates.setChecking(settings.checkUpdates);
    notifyListeners();
    await _replan();
  }

  Future<void> setKillSwitch(bool value) {
    if (!value && (settings.strictKillSwitch || strictBlocked)) return setStrictKillSwitch(false);
    recovered('kill-switch');
    settings.killSwitch = value;
    if (!value) settings.strictKillSwitch = false;
    notifyListeners();
    if (_stopping || _connectionWork != null) return Future.value();
    return _killSwitchWork = _killSwitchWork.then((_) async {
      if (_disposed || _stopping || value != settings.killSwitch) return;
      final link = _link, id = sessionId;
      if (link == null) return;
      if (id == null) {
        // A session still connecting takes the new value when Connect returns.
        // A failed session may retain the kill switch after its ID is cleared;
        // disconnecting it releases the block.
        if (!value && phase != Phase.connecting) {
          try {
            final answer = await link.stub.disconnect(
              DisconnectRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
            );
            if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
          } catch (error) {
            reportFailure(error, source: 'kill-switch', mode: FailureMode.action);
          }
        }
        return;
      }
      try {
        final answer = await link.stub.setKillSwitch(
          SetKillSwitchRequest(apiVersion: apiVersion, sessionId: id, enabled: value),
        );
        if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
        strictBlocked = answer.strict;
      } catch (error) {
        failure = CoreFailure.from(error);
        reportFailure(error, source: 'kill-switch', mode: FailureMode.action);
        notifyListeners();
      }
    });
  }

  Future<void> setStrictKillSwitch(bool value) {
    recovered('strict-kill-switch');
    final previous = settings.strictKillSwitch;
    final previousKill = settings.killSwitch;
    settings.strictKillSwitch = value;
    if (value) settings.killSwitch = true;
    notifyListeners();
    return _killSwitchWork = _killSwitchWork.then((_) async {
      await _connectionWork?.future;
      if (_disposed || _stopping || settings.strictKillSwitch != value) return;
      final link = _link;
      try {
        if (link == null) {
          if (!value) throw CoreFailure.unavailable;
          return;
        }
        if (link.minor < 12) throw const CoreFailure('core.api.version_mismatch');
        if (value && sessionId == null && !strictBlocked) return;
        final answer = await link.stub.setKillSwitch(
          SetKillSwitchRequest(apiVersion: apiVersion, enabled: value, strict: value),
          options: CallOptions(timeout: const Duration(seconds: 15)),
        );
        if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
        strictBlocked = answer.strict;
        settings.killSwitch = answer.enabled;
        if (!strictBlocked && phase == Phase.off) cleanupPending = false;
      } catch (error) {
        settings.strictKillSwitch = previous;
        settings.killSwitch = previousKill;
        reportFailure(error, source: 'strict-kill-switch', mode: FailureMode.action);
      }
      notifyListeners();
    });
  }

  /// Saves a subscription; the core fetches it and streams its servers. Returns
  /// null on success; failures are reported through the notification stream.
  Future<CoreFailure?> addSubscription(String url, {String name = ''}) async {
    recovered('request');
    final link = _link;
    if (link == null) {
      reportFailure(CoreFailure.unavailable, mode: FailureMode.action);
      return CoreFailure.unavailable;
    }
    try {
      final answer = await link.stub.saveSubscription(
        SaveSubscriptionRequest(
          apiVersion: apiVersion,
          controlAuthenticator: link.token,
          settings: SubscriptionSettings(url: url.trim(), name: name.trim(), autoUpdate: true),
        ),
      );
      if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
      // The watch owns insertion order, including when a save response
      // races the initial snapshot. Inserting here could overtake it.
      _noteSyncChanged();
      return null;
    } catch (error) {
      reportFailure(error, mode: FailureMode.action);
      return CoreFailure.from(error);
    }
  }

  Future<CoreFailure?> renameSubscription(SubscriptionState state, String name) => _call(() async {
    final link = _link!;
    final settings = state.settings.deepCopy()
      ..name = name.trim()
      ..url = '';
    final answer = await link.stub.saveSubscription(
      SaveSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, settings: settings),
    );
    if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
    _noteSyncChanged();
  });

  /// Saves subscription settings without replacing the stored URL.
  Future<CoreFailure?> saveSubscription(SubscriptionSettings chosen) => _call(() async {
    final link = _link!;
    final answer = await link.stub.saveSubscription(
      SaveSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, settings: chosen..url = ''),
    );
    if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
    _noteSyncChanged();
  });

  /// Fetches the bearer link only for this action, without retaining it in state.
  Future<String?> fetchSubscriptionLink(String id) async {
    final link = _link;
    if (link == null) {
      reportFailure(CoreFailure.unavailable, mode: FailureMode.action);
      return null;
    }
    try {
      final answer = await link.stub.getSubscriptionLink(
        GetSubscriptionLinkRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: id),
      );
      if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
      recovered('request');
      return answer.url;
    } catch (error) {
      reportFailure(error, source: 'request', mode: FailureMode.action);
      return null;
    }
  }

  /// Fetches the bearer link only for this action, without retaining it in state.
  Future<CoreFailure?> openSubscriptionPage(String id) => _call(() async {
    final link = _link!;
    final answer = await link.stub.getSubscriptionLink(
      GetSubscriptionLinkRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: id),
    );
    if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
    if (!await launchUrl(Uri.parse(answer.url), mode: LaunchMode.externalApplication)) {
      throw const CoreFailure('app.browser_unavailable');
    }
  });

  Future<CoreFailure?> refreshSubscription(String id) => _call(
    () async {
      final link = _link!;
      final answer = await link.stub.refreshSubscription(
        RefreshSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: id),
      );
      if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
    },
    source: 'subscription:$id',
    action: 'subscription',
    argument: id,
  );

  Future<CoreFailure?> deleteSubscription(String id) => _call(() async {
    final link = _link!;
    final answer = await link.stub.deleteSubscription(
      DeleteSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: id),
    );
    if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
    _subscriptions.remove(id);
    recovered('subscription:$id');
    overrides.drop(id);
    notifyListeners();
    _noteSyncChanged();
  });

  /// User-added servers, stored by the core outside subscriptions.
  final List<CustomServer> _customServers = [];
  List<CustomServer> get customServers => List.unmodifiable(_customServers);
  List<String> customProtocols = [
    for (final p in CustomProtocol.values)
      if (p != CustomProtocol.CUSTOM_PROTOCOL_UNSPECIFIED) p.name.replaceFirst('CUSTOM_PROTOCOL_', '').toLowerCase(),
  ];

  /// Uses the same parser as subscriptions, without persisting the draft.
  Future<PreviewCustomServerResponse> previewCustomServer(String text) async {
    final link = _link;
    if (link == null) throw CoreFailure.unavailable;
    try {
      final answer = await link.custom.previewCustomServer(
        PreviewCustomServerRequest(apiVersion: apiVersion, controlAuthenticator: link.token, link: text),
        options: CallOptions(timeout: const Duration(seconds: 10)),
      );
      if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
      return answer;
    } on GrpcError catch (error) {
      if (error.code == StatusCode.unimplemented) throw const CoreFailure('core.api.version_mismatch');
      rethrow;
    }
  }

  /// Loads custom servers after the core link opens. The service lands with
  /// the core update; until then the section simply stays empty.
  Future<void> loadCustomServers() async {
    final link = _link;
    // CustomServers exists since API 1.11; an older core has nothing to list.
    if (link == null || link.minor < 11) return;
    try {
      final answer = await link.custom.listCustomServers(
        ListCustomServersRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
      );
      if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
      _customServers
        ..clear()
        ..addAll(answer.servers);
      if (answer.protocols.isNotEmpty) customProtocols = answer.protocols.toList();
      recovered('custom-servers');
      notifyListeners();
    } catch (error) {
      if (error is GrpcError && error.code == StatusCode.unimplemented) return;
      reportFailure(error, source: 'custom-servers', mode: FailureMode.background);
    }
  }

  /// Saves a new custom server; the core assigns its id (an empty id creates,
  /// a set id updates). Returns null on success; failures are reported
  /// through the notification stream.
  Future<CoreFailure?> addCustomServer(CustomServer server, {bool replaceCredentials = false}) => _call(() async {
    final link = _link!;
    final answer = await link.custom.saveCustomServer(
      SaveCustomServerRequest(
        apiVersion: apiVersion,
        controlAuthenticator: link.token,
        server: server,
        replaceCredentials: replaceCredentials,
      ),
    );
    if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
    // Upsert, not append: the sync bridge re-saves known ids (update path),
    // and appending would duplicate the entry in the list.
    final index = _customServers.indexWhere((s) => s.id == answer.server.id);
    if (index < 0) {
      _customServers.add(answer.server);
    } else {
      _customServers[index] = answer.server;
    }
    notifyListeners();
    _noteSyncChanged();
  });

  Future<CoreFailure?> deleteCustomServer(String id) => _call(() async {
    final link = _link!;
    final answer = await link.custom.deleteCustomServer(
      DeleteCustomServerRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: id),
    );
    if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
    _customServers.removeWhere((s) => s.id == id);
    notifyListeners();
    _noteSyncChanged();
  });

  /// Tests reachability of a saved custom server by id; the core API has no
  /// draft test, so the only path is save-then-test. On success the outcome
  /// lands in [latency] (null when unreachable) and listeners are notified;
  /// failures are reported through the notification stream.
  Future<({bool reachable, int latencyMs, CoreFailure? failure})> testCustomServer(String id) async {
    recovered('request');
    final link = _link;
    if (link == null) {
      reportFailure(CoreFailure.unavailable, mode: FailureMode.action);
      return (reachable: false, latencyMs: 0, failure: CoreFailure.unavailable);
    }
    try {
      // The core API takes the plain custom id; the latency map lives in the
      // outbound namespace, where passive probes already key custom results
      // by `custom/<id>`: one key for both, or the card never shows a manual
      // test result.
      final plain = id.startsWith(customServerPrefix) ? id.substring(customServerPrefix.length) : id;
      final key = '$customServerPrefix$plain';
      final answer = await link.custom.testCustomServer(
        TestCustomServerRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: plain, timeoutMs: 5000),
      );
      if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
      final ms = answer.latencyMs.toInt();
      latency[key] = answer.reachable ? ms : null;
      notifyListeners();
      return (reachable: answer.reachable, latencyMs: ms, failure: null);
    } catch (error) {
      final failure = CoreFailure.from(error);
      reportFailure(error, mode: FailureMode.action);
      return (reachable: false, latencyMs: 0, failure: failure);
    }
  }

  /// Runs a core request; returns null on success or stores and returns its
  /// failure.
  Future<CoreFailure?> _call(
    Future<void> Function() body, {
    String source = 'request',
    String action = 'logs',
    String argument = '',
  }) async {
    if (_link == null) {
      reportFailure(
        CoreFailure.unavailable,
        mode: FailureMode.action,
        source: source,
        action: action,
        argument: argument,
      );
      return CoreFailure.unavailable;
    }
    failure = null;
    try {
      await body();
      recovered(source);
      return null;
    } catch (error) {
      failure = CoreFailure.from(error);
      reportFailure(error, mode: FailureMode.action, source: source, action: action, argument: argument);
      notifyListeners();
      return failure;
    }
  }

  /// Probes a subscription or all servers and publishes results as they arrive.
  ///
  /// Listener notifications are throttled: with hundreds of servers, one
  /// [notifyListeners] per result rebuilds the whole UI and the tray tooltip
  /// hundreds of times (audit M20).
  static const _probeNotifyInterval = Duration(milliseconds: 300);

  /// Maximum servers in one probe request. Mirrors the core's ProbeChunkSize
  /// (core/control/plan.go): the core processes probes in chunks of this
  /// size, so every chunk stays far inside the per-request limit, keeps the
  /// request message small and the stream short and cancellable. Keep in
  /// sync with the core.
  static const _probeChunkSize = 128;

  Future<void> probe({String? subscriptionId}) async {
    final link = _link;
    final all = subscriptionId == null ? servers : _subscriptions[subscriptionId]?.outbounds.toList() ?? [];
    if (!canProbe || link == null || all.isEmpty) return;
    probing = true;
    probingSubscription = subscriptionId;
    notifyListeners();
    // The first chunk failure is reported once below; every chunk's results
    // are kept independently, so one bad chunk never sinks the whole probe.
    Object? firstError;
    try {
      var lastNotify = DateTime.now();
      for (var i = 0; i < all.length; i += _probeChunkSize) {
        if (_disposed || link != _link || busy || (phase != Phase.off && phase != Phase.connected)) break;
        final chunk = all.sublist(i, min(i + _probeChunkSize, all.length));
        try {
          final call = _probeCall = link.stub.probeServers(
            ProbeServersRequest(
              apiVersion: apiVersion,
              outbounds: chunk,
              options: ProbeOptions(
                method: switch (settings.probeMethod) {
                  'engine' => ProbeMethod.PROBE_METHOD_ENGINE,
                  'connect' => ProbeMethod.PROBE_METHOD_CONNECT,
                  _ => ProbeMethod.PROBE_METHOD_UNSPECIFIED,
                },
                url: settings.probeUrl,
                timeoutMs: settings.probeTimeout,
              ),
            ),
          );
          await for (final r in call) {
            if (_disposed || link != _link || busy || (phase != Phase.off && phase != Phase.connected)) break;
            latency[r.serverId] = r.reachable ? r.latencyMs : null;
            _recordProbe(r.serverId, r.reachable);
            final now = DateTime.now();
            if (now.difference(lastNotify) >= _probeNotifyInterval) {
              lastNotify = now;
              notifyListeners();
            }
          }
        } catch (error) {
          // A cancelled chunk is a user-initiated stop (connect, disconnect,
          // dispose): end the probe quietly instead of failing it.
          if (error is GrpcError && error.code == StatusCode.cancelled) break;
          // A failed chunk leaves its servers unknown; the rest are still
          // measured.
          firstError ??= error;
        }
      }
      if (firstError != null && !_disposed && link == _link) {
        reportFailure(firstError, source: 'probe', mode: FailureMode.background);
      }
      if (firstError == null) recovered('probe');
      // Keep partial results; unmeasured servers remain unknown instead of
      // being marked unreachable.
    } finally {
      _probeCall = null;
      probing = false;
      probingSubscription = null;
      _maybeAutoSwitch();
      notifyListeners();
    }
  }

  /// Auto-switch on degradation fires at most this often. Switching servers
  /// reconnects the tunnel, so flapping would hurt more than help; the
  /// settings text promises this bound, keep them in sync.
  static const autoSwitchCooldown = Duration(minutes: 10);

  /// Last degradation-driven switch; the cooldown above throttles switches,
  /// not probes.
  DateTime? _lastAutoSwitch;

  /// Moves the pinned selection to the best measured alternative when the
  /// selected server degrades. Runs after each probe; throttled by
  /// [autoSwitchCooldown]. Never touches 'auto' (the core's url-test group
  /// already switches there), groups, profiles or bypass.
  void _maybeAutoSwitch() {
    if (_disposed || !settings.autoSwitchOnDegrade) return;
    if (phase != Phase.connected || _link == null) return;
    final current = selected;
    if (current == 'auto' || current == 'bypass' || current.startsWith(groupPrefix)) return;
    final spec = servers.where((o) => o.id == current).firstOrNull;
    if (spec == null || isProfile(spec)) return;
    final now = DateTime.now();
    if (_lastAutoSwitch != null && now.difference(_lastAutoSwitch!) < autoSwitchCooldown) return;
    final candidates = [
      for (final o in servers)
        if (!isProfile(o) && o.id != current) o,
    ];
    if (candidates.isEmpty) return;
    final best = _fastest(
      candidates,
      latency,
      bandwidth: bandwidth,
      autoSelect: settings.autoSelectMode,
      reliabilityOf: reliabilityOf,
    );
    if (!_degraded(current, best.id)) return;
    _lastAutoSwitch = now;
    _emit(ServerDegraded(displayNameOf(best.id)));
    unawaited(select(best.id));
  }

  /// True when [current] stopped answering or is clearly slower than [best]:
  /// at least twice the ping and 100 ms behind. Unknown measurements never
  /// trigger a switch: no blind moves.
  bool _degraded(String current, String best) {
    if (best == current) return false;
    final curMs = latency[current];
    final bestMs = latency[best];
    // The pinned server stopped answering: move only to a server with real
    // measurements. Hopping to an unprobed candidate would trade a known-bad
    // server for an unknown one, and a needless reconnect.
    if (latency.containsKey(current) && curMs == null) return bestMs != null;
    if (curMs == null || bestMs == null) return false;
    return bestMs * 2 <= curMs && curMs - bestMs >= 100;
  }

  /// Core client and authentication token for direct screen requests, such as
  /// logs. Null while the core is unavailable.
  CoreLink? get link => _link;

  /// Measured throughput per server: server ID -> (bytes/sec, measured at).
  /// Fed by [benchmarkServers]; persisted across restarts.
  final Map<String, ({int bps, DateTime at})> bandwidth = {};

  /// Bandwidth measurements older than this are shown as stale and ignored by
  /// speed-based auto-selection.
  static const bandwidthTtl = Duration(hours: 24);

  void _loadBandwidth() {
    try {
      final raw = jsonDecode(settings.benchmarkHistory);
      if (raw is Map<String, dynamic>) {
        for (final entry in raw.entries) {
          final value = entry.value;
          if (value is Map<String, dynamic> && value['bps'] is int && value['at'] is int) {
            bandwidth[entry.key] = (
              bps: value['bps'] as int,
              at: DateTime.fromMillisecondsSinceEpoch(value['at'] as int),
            );
          }
        }
      }
    } on FormatException {
      // Corrupt history: start empty rather than break startup.
    }
  }

  void _saveBandwidth() {
    settings.benchmarkHistory = jsonEncode({
      for (final entry in bandwidth.entries)
        entry.key: {'bps': entry.value.bps, 'at': entry.value.at.millisecondsSinceEpoch},
    });
  }

  /// Fresh (non-stale) throughput for [id], or null when unknown or outdated.
  int? freshBandwidth(String id) => freshBandwidthOf(bandwidth, id);

  /// Recent probe outcomes per server: answered vs missed probes. In-memory
  /// only: probes are cheap, so reliability always reflects fresh data and
  /// needs no migration or persistence.
  final Map<String, ({int ok, int fail})> probeStats = {};

  /// How many recent probe outcomes bound each server's reliability.
  static const probeHistoryDepth = 20;

  /// Share of recent probes the server answered (0..1), or null when it has
  /// no probe history yet. Feeds the smart score and the list indicator.
  double? reliabilityOf(String id) {
    final stats = probeStats[id];
    if (stats == null) return null;
    final total = stats.ok + stats.fail;
    if (total == 0) return null;
    return stats.ok / total;
  }

  /// Records one probe outcome, decaying old history instead of a hard
  /// window so recent probes rule without cliff effects.
  void _recordProbe(String id, bool ok) {
    final stats = probeStats[id] ?? (ok: 0, fail: 0);
    var good = stats.ok, bad = stats.fail;
    if (good + bad >= probeHistoryDepth) {
      good ~/= 2;
      bad ~/= 2;
    }
    probeStats[id] = ok ? (ok: good + 1, fail: bad) : (ok: good, fail: bad + 1);
  }

  bool benchmarking = false;
  ResponseStream<BandwidthSample>? _benchmarkCall;

  /// Benchmark progress as (measured, total); null when idle.
  ({int done, int total})? benchmarkProgress;

  /// Per-server progress percent (0..100) while benchmarking.
  final Map<String, int> benchmarkPct = {};

  /// Whether a benchmark can run right now.
  bool get canBenchmark =>
      !_disposed && _link != null && !benchmarking && (phase == Phase.off || phase == Phase.connected);

  /// Streams real-throughput measurements for [serverIds] (all servers when
  /// null) and records them in [bandwidth].
  ///
  /// A failed server fails only itself: the core reports it as a done sample
  /// with an error and keeps measuring the rest. A core without the RPC
  /// answers UNIMPLEMENTED and the UI reports a friendly version message
  /// instead of a raw error. Notifications are throttled like [probe];
  /// cancel with [cancelBenchmark].
  Future<void> benchmarkServers({List<String>? serverIds}) async {
    final link = _link;
    final ids = serverIds ?? [for (final o in servers) o.id];
    if (!canBenchmark || link == null || ids.isEmpty) return;
    benchmarking = true;
    benchmarkProgress = (done: 0, total: ids.length);
    benchmarkPct.clear();
    notifyListeners();
    try {
      final call = _benchmarkCall = link.stub.benchmarkServers(
        BenchmarkServersRequest(
          apiVersion: apiVersion,
          controlAuthenticator: link.token,
          serverIds: ids,
          durationS: 10,
          concurrency: 2,
        ),
      );
      var lastNotify = DateTime.now();
      var done = 0;
      var failed = 0;
      CoreFailure? firstFailure;
      await for (final sample in call) {
        if (_disposed || link != _link) break;
        if (sample.hasError()) {
          // One failed server fails only itself, never the batch: the core
          // sends a per-server error sample and keeps measuring the rest.
          // Failed servers simply show no result (a dash).
          firstFailure ??= CoreFailure.fromWire(sample.error);
          failed++;
          done++;
          benchmarkPct[sample.serverId] = 100;
        } else if (!sample.done) {
          final pct = sample.progressPct;
          benchmarkPct[sample.serverId] = pct < 0 ? 0 : (pct > 100 ? 100 : pct);
        } else {
          done++;
          benchmarkPct[sample.serverId] = 100;
          final bps = sample.bytesPerSec.toInt();
          if (bps > 0) bandwidth[sample.serverId] = (bps: bps, at: DateTime.now());
        }
        benchmarkProgress = (done: done, total: ids.length);
        final now = DateTime.now();
        if (now.difference(lastNotify) >= _probeNotifyInterval) {
          lastNotify = now;
          notifyListeners();
        }
      }
      if (failed == 0 && done > 0) recovered('benchmark');
      if (!_disposed && link == _link && done > 0 && failed >= done) {
        // Every server failed: the run measured nothing, so it says so
        // instead of finishing in silence.
        reportFailure(
          firstFailure ?? const CoreFailure('app.benchmark_unsupported'),
          source: 'benchmark',
          mode: FailureMode.background,
        );
      }
    } catch (error) {
      if (!_disposed && link == _link && !(error is GrpcError && error.code == StatusCode.cancelled)) {
        if (error is GrpcError && error.code == StatusCode.unimplemented) {
          reportFailure(
            const CoreFailure('app.benchmark_unsupported'),
            source: 'benchmark',
            mode: FailureMode.background,
          );
        } else {
          reportFailure(error, source: 'benchmark', mode: FailureMode.background);
        }
      }
      // Keep partial results; unmeasured servers stay unknown.
    } finally {
      // Persist even on cancel or error: partial results are kept, so they
      // must survive a restart too.
      _saveBandwidth();
      _benchmarkCall = null;
      benchmarking = false;
      benchmarkProgress = null;
      benchmarkPct.clear();
      notifyListeners();
    }
  }

  /// Cancels an in-flight benchmark; partial results are kept.
  Future<void> cancelBenchmark() => _benchmarkCall?.cancel() ?? Future.value();

  /// Compares two servers for list sorting: ping, speed, smart or name.
  int compareServers(String a, String b, String mode) {
    if (mode == 'name') {
      return displayNameOf(a).toLowerCase().compareTo(displayNameOf(b).toLowerCase());
    }
    return compareAutoSelect(a, b, mode, latency, bandwidth, reliabilityOf: reliabilityOf);
  }

  /// The server the smart auto-select ranks first right now, with the metrics
  /// behind the choice. Null when there is nothing to rank or nothing
  /// measured yet; the UI shows no "why" badge then.
  ({String id, int? ms, int? bps})? smartPick() {
    final ordinary = [
      for (final o in servers)
        if (!isProfile(o)) o,
    ];
    if (ordinary.isEmpty) return null;
    final anyMeasured = ordinary.any(
      (o) => latency.containsKey(o.id) || bandwidth.containsKey(o.id) || probeStats.containsKey(o.id),
    );
    if (!anyMeasured) return null;
    final best = _fastest(ordinary, latency, bandwidth: bandwidth, autoSelect: 'smart', reliabilityOf: reliabilityOf);
    return (id: best.id, ms: latency[best.id], bps: freshBandwidth(best.id));
  }

  /// Scales bytes by powers of 1024, returning the value and unit index (B to
  /// TB).
  static (double, int) scaleBytes(Int64 bytes) {
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < 4) {
      value /= 1024;
      unit++;
    }
    return (value, unit);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _failureTimers.values) {
      timer.cancel();
    }
    profiles.removeListener(_profilesChanged);
    profiles.removeListener(_noteSyncChanged);
    profiles.removeListener(notifyListeners);
    profiles.dispose();
    _extensionWorkers?.dispose();
    extensions.removeListener(_extensionsChanged);
    extensions.dispose();
    browserDiagnostics.clear();
    unawaited(syncDaemon.stop());
    unawaited(_probeCall?.cancel());
    _drop(CoreFailure.unavailable);
    updates.dispose();
    unawaited(_notices.close());
    unawaited(_messages.close());
    unawaited(_cancelWatches());
    unawaited(_link?.close());
    super.dispose();
  }
}

/// Builds routing for [choice]: auto selects the fastest ordinary server,
/// bypass uses no server, or an ID selects one. A provider Xray profile runs as
/// the sole outbound; profile-only auto selection uses [latency].
SessionPlan buildPlan({
  required List<OutboundSpec> servers,
  required String choice,
  required Settings settings,
  Map<String, int?> latency = const {},
  Map<String, ({int bps, DateTime at})> bandwidth = const {},
  Entry? entry,
  List<UserRule> extensionRules = const [],
  List<String> chain = const [],
  bool zapretWithVpn = false,
  double? Function(String id)? reliabilityOf,
}) {
  final plan = SessionPlan(
    tunnelMode: settings.tunnel == 'proxy' ? TunnelMode.TUNNEL_MODE_APPLICATION : TunnelMode.TUNNEL_MODE_SYSTEM,
    tunStack: settings.tunnel == 'tun' && choice != 'bypass'
        ? switch (settings.engine) {
            'mihomo' => settings.mihomoTunStack,
            'xray' when Platform.isWindows || settings.xrayTunStack != 'gvisor' => settings.xrayTunStack,
            _ => '',
          }
        : '',
    engines: [if (settings.engine.isNotEmpty) settings.engine],
    networkControlAllowed: settings.controlPort,
    routing: RoutingOptions(preset: settings.preset, blockAds: settings.blockAds),
    ipv6: settings.ipv6,
    dnsPolicy: DnsPolicy(servers: settings.dns),
    antiCensorship: AntiCensorship(
      tlsFragment: settings.fragment,
      fragmentPackets: settings.fragmentPackets,
      fragmentLength: settings.fragmentLength,
      fragmentInterval: settings.fragmentInterval,
    ),
  );
  // User rules take precedence over the preset; resolve proxy rules after the
  // default traffic target is known.
  void addRules(String proxy) {
    for (final rule in [...settings.rules.map(UserRule.parse).nonNulls, ...extensionRules]) {
      final target = switch (rule.target) {
        RuleTarget.direct => 'direct',
        RuleTarget.block => 'reject',
        RuleTarget.proxy => proxy,
      };
      plan.routes.add(RoutingRule(destination: rule.destination, outboundId: target));
    }
  }

  // Zapret's tpws alongside the VPN tunnel (Linux only, needs tpws in
  // the engines directory); never in serverless bypass mode.
  if (zapretWithVpn && choice != 'bypass') {
    plan.zapretWithVpn = true;
    // Carry the tuned handshake strategy with it: without it the core falls
    // back to its own defaults and silently ignores the zapret settings
    // (splitPos, disorder, tlsRecord, hostCase) the user configured for the
    // bypass outbound.
    plan.zapretStrategy = BypassStrategy(
      splitPos: settings.splitPos,
      disorder: settings.disorder,
      tlsRecord: settings.tlsRecord,
      hostCase: settings.hostCase,
    );
  }

  // A proxy chain carries its hop outbounds and the ordered hop ids; the
  // core renders each hop to dial through the next one. Traffic enters the
  // first hop, so it becomes the routing target.
  if (chain.isNotEmpty) {
    final hops = [for (final id in chain) servers.firstWhere((o) => o.id == id)];
    plan.outbounds.addAll(hops);
    plan.chain.addAll(chain);
    plan.routing.proxyTarget = chain.first;
    addRules(chain.first);
    return plan;
  }

  if (choice == 'bypass') {
    plan.outbounds.add(
      OutboundSpec(
        id: Sora.bypassId,
        displayName: 'zapret',
        protocol: 'bypass',
        bypass: BypassStrategy(
          splitPos: settings.splitPos,
          disorder: settings.disorder,
          tlsRecord: settings.tlsRecord,
          hostCase: settings.hostCase,
        ),
      ),
    );
    plan.routing.proxyTarget = Sora.bypassId;
    addRules(Sora.bypassId);
    return plan;
  }
  final profiles = [
    for (final o in servers)
      if (isProfile(o)) o,
  ];
  final ordinary = [
    for (final o in servers)
      if (!isProfile(o)) o,
  ];
  if (entry != null && entry.members.any(isProfile)) {
    // Profiles cannot share an engine. Select one reachable member using the
    // same auto-select mode as every other pick, not a hardcoded 'ping'.
    choice = pickMember(
      entry,
      latency,
      bandwidth: bandwidth,
      autoSelect: settings.autoSelectMode,
      reliabilityOf: reliabilityOf,
    ).id;
  } else if (entry != null) {
    // mihomo supports role-ordered fallback groups. Other engines compare only
    // main members by latency; unlabelled groups compare all members.
    final fallback = entry.ordered && (settings.engine.isEmpty || settings.engine == 'mihomo');
    final members = fallback
        ? entry.byRole
        : entry.ordered
        ? [
            for (final o in entry.members)
              if (entry.roles[o.id] == Role.main) o,
          ]
        : entry.members;
    plan.outbounds.addAll(ordinary);
    plan.groups.add(
      GroupSpec(
        name: Sora.entryGroup,
        type: fallback ? GroupType.GROUP_TYPE_FALLBACK : GroupType.GROUP_TYPE_URL_TEST,
        members: [for (final o in members.isEmpty ? entry.members : members) o.id],
        toleranceMs: fallback ? 0 : 50,
      ),
    );
    plan.routing.proxyTarget = Sora.entryGroup;
    addRules(Sora.entryGroup);
    return plan;
  }
  final picked = profiles.where((o) => o.id == choice).firstOrNull;
  if (picked != null || (choice == 'auto' && ordinary.isEmpty && profiles.isNotEmpty)) {
    final profile =
        picked ??
        _fastest(
          profiles,
          latency,
          bandwidth: bandwidth,
          autoSelect: settings.autoSelectMode,
          reliabilityOf: reliabilityOf,
        );
    plan.outbounds.add(profile);
    plan.routing.proxyTarget = profile.id;
    addRules(profile.id);
    return plan;
  }
  plan.outbounds.addAll(ordinary);
  if (choice == 'auto') {
    plan.groups.add(
      GroupSpec(
        name: Sora.autoGroup,
        type: GroupType.GROUP_TYPE_URL_TEST,
        members: [for (final o in ordinary) o.id],
        toleranceMs: 50,
      ),
    );
    plan.routing.proxyTarget = Sora.autoGroup;
  } else if (settings.failover && ordinary.length > 1 && (settings.engine.isEmpty || settings.engine == 'mihomo')) {
    // Only mihomo supports fallback groups; pinned sing-box or Xray uses the
    // selected server alone. Try it first, then alternatives by latency, and
    // return to it when reachable.
    final others = [
      for (final o in ordinary)
        if (o.id != choice) o,
    ];
    final order = {for (var i = 0; i < ordinary.length; i++) ordinary[i].id: i};
    others.sort((a, b) => compareAutoSelect(a.id, b.id, 'ping', latency, bandwidth, providerOrder: order));
    plan.groups.add(
      GroupSpec(
        name: Sora.failoverGroup,
        type: GroupType.GROUP_TYPE_FALLBACK,
        members: [choice, for (final o in others) o.id],
      ),
    );
    plan.routing.proxyTarget = Sora.failoverGroup;
  } else {
    // An unrelated imported server must not invalidate a pinned connection.
    plan.outbounds.removeWhere((outbound) => outbound.id != choice);
    plan.routing.proxyTarget = choice;
  }
  addRules(plan.routing.proxyTarget);
  return plan;
}

/// Picks a member not measured as unreachable: first by role priority,
/// otherwise by latency. If all are down, uses the first by role or the fastest
/// measured member.
OutboundSpec pickMember(
  Entry entry,
  Map<String, int?> latency, {
  Map<String, ({int bps, DateTime at})> bandwidth = const {},
  String autoSelect = 'ping',
  double? Function(String id)? reliabilityOf,
}) {
  bool down(OutboundSpec o) => latency.containsKey(o.id) && latency[o.id] == null;
  if (entry.ordered) return entry.byRole.firstWhere((o) => !down(o), orElse: () => entry.byRole.first);
  final up = [
    for (final o in entry.members)
      if (!down(o)) o,
  ];
  return _fastest(
    up.isEmpty ? entry.members : up,
    latency,
    bandwidth: bandwidth,
    autoSelect: autoSelect,
    reliabilityOf: reliabilityOf,
  );
}

/// Checks whether a server is a full Xray profile from a JSON subscription.
bool isProfile(OutboundSpec o) => o.protocol == 'xray-profile';

/// Fresh (non-stale) throughput for [id] in [bandwidth], or null.
int? freshBandwidthOf(Map<String, ({int bps, DateTime at})> bandwidth, String id) {
  final measurement = bandwidth[id];
  if (measurement == null) return null;
  if (DateTime.now().difference(measurement.at) > Sora.bandwidthTtl) return null;
  return measurement.bps;
}

/// Benchmark goodput is stored in bytes per second; the UI labels it
/// megabits per second, so the bytes-to-bits scaling lives here instead of
/// at every call site.
double mbpsOf(int bytesPerSec) => bytesPerSec * 8 / 1000000;

/// Smart score in [0, 1] (higher is better): ping 40%, speed 40%,
/// measurement freshness 20%, scaled by [reliability] when known: a server
/// answering half of its recent probes keeps three quarters of its score.
double smartScoreOf(
  String id,
  Map<String, int?> latency,
  Map<String, ({int bps, DateTime at})> bandwidth, {
  double? reliability,
}) {
  var score = 0.0;
  var measured = false;
  final ms = latency[id];
  if (ms != null) {
    measured = true;
    // Map 20ms..2000ms to 1..0.
    score += 0.4 * (1.0 - ((ms - 20) / 1980).clamp(0.0, 1.0));
  }
  final bps = freshBandwidthOf(bandwidth, id);
  if (bps != null) {
    measured = true;
    // Map 1..100 Mbps to 0..1 (sqrt softens the top end).
    score += 0.4 * (sqrt(bps / 125000) / 10).clamp(0.0, 1.0);
  }
  if (measured) {
    final at = bandwidth[id]?.at;
    if (at != null) {
      final ageHours = DateTime.now().difference(at).inHours;
      score += 0.2 * (1.0 - (ageHours / Sora.bandwidthTtl.inHours).clamp(0.0, 1.0));
    } else {
      // Ping-only data: half freshness credit.
      score += 0.1;
    }
  }
  if (reliability != null) {
    // Flaky servers rank lower even with a good ping; unknown reliability
    // keeps the score untouched rather than punished.
    score *= 0.5 + 0.5 * reliability.clamp(0.0, 1.0);
  }
  return score;
}

/// Compares two servers for auto-selection. [mode] is ping, speed or smart;
/// unknown modes and missing speed measurements fall back to ping.
/// Equal ranking keys retain the provider order.
int compareAutoSelect(
  String a,
  String b,
  String mode,
  Map<String, int?> latency,
  Map<String, ({int bps, DateTime at})> bandwidth, {
  double? Function(String id)? reliabilityOf,
  Map<String, int> providerOrder = const {},
}) {
  int byProvider() => (providerOrder[a] ?? 1 << 30).compareTo(providerOrder[b] ?? 1 << 30);
  int byPing() {
    final compared = (latency[a] ?? 1 << 30).compareTo(latency[b] ?? 1 << 30);
    return compared != 0 ? compared : byProvider();
  }

  switch (mode) {
    case 'speed':
      final x = freshBandwidthOf(bandwidth, a), y = freshBandwidthOf(bandwidth, b);
      if (x != null || y != null) {
        if (x == null) return 1;
        if (y == null) return -1;
        final bySpeed = y.compareTo(x);
        return bySpeed != 0 ? bySpeed : byProvider();
      }
      return byPing();
    case 'smart':
      final bySmart = smartScoreOf(
        b,
        latency,
        bandwidth,
        reliability: reliabilityOf?.call(b),
      ).compareTo(smartScoreOf(a, latency, bandwidth, reliability: reliabilityOf?.call(a)));
      return bySmart != 0 ? bySmart : byProvider();
    default:
      return byPing();
  }
}

/// Returns the best profile by auto-selection mode, or the first if the list
/// has a single entry. Requires a nonempty list.
OutboundSpec _fastest(
  List<OutboundSpec> profiles,
  Map<String, int?> latency, {
  Map<String, ({int bps, DateTime at})> bandwidth = const {},
  String autoSelect = 'ping',
  double? Function(String id)? reliabilityOf,
}) {
  final order = {for (var i = 0; i < profiles.length; i++) profiles[i].id: i};
  var best = profiles.first;
  for (final o in profiles) {
    if (compareAutoSelect(
          o.id,
          best.id,
          autoSelect,
          latency,
          bandwidth,
          reliabilityOf: reliabilityOf,
          providerOrder: order,
        ) <
        0) {
      best = o;
    }
  }
  return best;
}

/// Provides [Sora] to descendants and rebuilds dependents when state changes.
class SoraScope extends InheritedNotifier<Sora> {
  const SoraScope({super.key, required Sora sora, required super.child}) : super(notifier: sora);

  static Sora of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SoraScope>()!.notifier!;

  /// Reads [Sora] without subscribing, for use in callbacks.
  static Sora read(BuildContext context) => context.getInheritedWidgetOfExactType<SoraScope>()!.notifier!;
}
