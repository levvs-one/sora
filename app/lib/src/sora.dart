import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart' hide ConnectionState;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/io_client.dart';
import 'package:grpc/grpc.dart' show CallOptions, ResponseStream, GrpcError, StatusCode;
import 'package:retry/retry.dart';

import '../l10n/strings.dart';

import 'core/link.dart';
import 'browser_diagnostics.dart';
import 'chains.dart';
import 'generated/sora/core/v1/core_control.pbgrpc.dart';
import 'groups.dart';
import 'overrides.dart';
import 'profiles.dart';
import 'rules.dart';
import 'settings.dart';
import 'notifications.dart';
import 'sync.dart';
import 'updates.dart';
import 'ui/kit.dart' show describe;

/// Connection phases exposed to the UI.
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

/// App state and core operations. Screens access it through [SoraScope] and
/// rebuild on notifications.
class Sora extends ChangeNotifier {
  Sora(this.settings)
    : history = settings.notificationHistory,
      overrides = OverrideStore(() => settings.subscriptionOverrides, (v) => settings.subscriptionOverrides = v),
      profiles = ProfilesStore(() => settings.networkProfiles, (v) => settings.networkProfiles = v),
      chains = ChainsStore(() => settings.proxyChains, (v) => settings.proxyChains = v),
      syncDevices = SyncDevices(() => settings.syncedDevices, (v) => settings.syncedDevices = v) {
    overrides.onChanged = () {
      notifyListeners();
      // Hiding a server changes the plan; renaming does not (IDs are stable).
      unawaited(_replan());
    };
    profiles.addListener(notifyListeners);
    chains.addListener(notifyListeners);
    syncDevices.addListener(notifyListeners);
    _loadBandwidth();
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

  bool get updateBlocked => updates.busy;

  final _messages = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get messages => _messages.stream;
  final _reported = <String, String>{};
  bool serverlessAvailable = false;
  Set<String> coreCapabilities = {};

  S get strings {
    final chosen = settings.locale ?? WidgetsBinding.instance.platformDispatcher.locale;
    return lookupS(S.delegate.isSupported(chosen) ? chosen : const Locale('en'));
  }

  void reportFailure(Object error, {String source = 'request', String action = 'logs', String argument = ''}) {
    if (_disposed) return;
    final failed = CoreFailure.from(error);
    if (_reported[source] == failed.key) return;
    _reported[source] = failed.key;
    unawaited(
      recordNotification(
        AppNotification(
          time: DateTime.now(),
          title: strings.errGeneric,
          body: describe(strings, failed),
          action: action,
          argument: argument,
        ),
      ),
    );
  }

  void recovered(String source) => _reported.remove(source);

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
      final id => nameOf(id),
    };
    final (title, body, action) = switch (notice) {
      ConnectionLost() => (s.noticeLost, s.noticeLostBody, 'logs'),
      ConnectionRestored() => (s.noticeRestored, server, ''),
      ConnectionFailed(:final failure) => (s.noticeFailed, describe(s, failure), 'connect'),
      ServerSwitched(:final entry, :final backup) => (entry, backup ? s.noticeBackup : s.noticeNext, 'logs'),
      ServerReturned(:final entry) => (entry, s.noticeMainBack, ''),
    };
    return AppNotification(time: DateTime.now(), title: title, body: body, action: action);
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
  SessionPlan? _activePlan;
  Future<void> _locationWork = Future.value();
  int _selectionRevision = 0;
  int? _pendingSelection;
  bool needsReconnect = false;
  bool cleanupPending = false;

  /// Tracks a reported drop so restoration also emits a notice.
  bool _lostAnnounced = false;

  final _notices = StreamController<Notice>.broadcast();

  /// Unsolicited connection events for notification subscribers.
  Stream<Notice> get notices => _notices.stream;

  /// Notice count used to avoid reporting a failure already announced by state
  /// handling.
  int _emitted = 0;

  void _emit(Notice notice) {
    if (_disposed) return;
    _emitted++;
    unawaited(recordNotification(notificationFor(notice)));
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
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
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
      reportFailure(error, source: 'stats');
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
    try {
      final answer = await link.stub.checkDnsLeaks(
        CheckDnsLeaksRequest(apiVersion: apiVersion, controlAuthenticator: link.token, sessionId: id),
      );
      if (id != sessionId || link != _link) {
        // The session changed mid-check: the results belong to a dead session.
        return (checks: const <DnsLeakCheck>[], failure: CoreFailure.unavailable);
      }
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      recovered('request');
      return (checks: answer.checks, failure: null);
    } catch (error) {
      final failure = CoreFailure.from(error);
      reportFailure(error, source: 'request');
      return (checks: const <DnsLeakCheck>[], failure: failure);
    }
  }

  /// Last displayed failure, cleared by the next action.
  CoreFailure? failure;

  final Map<String, SubscriptionState> _subscriptions = {};
  List<SubscriptionState> get subscriptions => _subscriptions.values.toList();

  /// Server latency in milliseconds; null means the server did not respond.
  final Map<String, int?> latency = {};

  /// User edits layered over subscriptions (FEATURE-PLAN.md F6).
  final OverrideStore overrides;

  /// Network profiles with auto-apply triggers (FEATURE-PLAN.md F5).
  final ProfilesStore profiles;

  /// Named proxy chains (FEATURE-PLAN.md F8).
  final ChainsStore chains;

  /// Devices paired for E2E sync (FEATURE-PLAN.md F9).
  final SyncDevices syncDevices;

  /// Fingerprint of the currently joined network. Unknown until the core
  /// RPC GetNetworkFingerprint lands (F5).
  NetworkFingerprint networkFingerprint = const NetworkFingerprint.unknown();

  /// True when the core advertises proxy-chain support for the active
  /// engine. The engine registry sets the [chainCapability] flag per engine
  /// (F8).
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
    final seen = <String>{};
    final hidden = hiddenServerIds;
    return [
      for (final s in _subscriptions.values)
        for (final o in s.outbounds)
          if (seen.add(o.id) && !hidden.contains(o.id)) o,
    ];
  }

  /// Current selection; falls back to auto if the selected server or group is
  /// no longer present.
  String get selected {
    final chosen = settings.server;
    if (chosen == 'auto') return chosen;
    if (chosen == 'bypass') return serverlessAvailable ? chosen : 'auto';
    if (chosen.startsWith(groupPrefix)) return entryOf(chosen, _subscriptions.values) != null ? chosen : 'auto';
    return servers.any((o) => o.id == chosen) ? chosen : 'auto';
  }

  String nameOf(String id) => id.startsWith(groupPrefix)
      ? entryOf(id, _subscriptions.values)?.name ?? id
      : servers.firstWhere((o) => o.id == id, orElse: () => OutboundSpec(displayName: id)).displayName;

  bool get busy => _connectionWork != null || phase == Phase.connecting || phase == Phase.disconnecting;

  SessionPlan get currentPlan => buildPlan(
    servers: servers,
    choice: selected,
    settings: settings,
    latency: latency,
    bandwidth: bandwidth,
    entry: selected.startsWith(groupPrefix) ? entryOf(selected, _subscriptions.values) : null,
  );

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  /// Maintains the core connection and watches subscriptions and session state,
  /// reopening the connection after a drop until disposal.
  Future<void> run() async {
    checkCrashIntent();
    while (!_disposed) {
      final opening = Stopwatch()..start();
      final CoreLink link;
      try {
        link = await CoreLink.open(
          onRetry: (error) {
            if (_disposed || !_startedOnce && opening.elapsed < const Duration(seconds: 5)) return;
            failure = CoreFailure.from(error);
            reportFailure(error, source: 'core');
            notifyListeners();
          },
          canceled: () => _disposed,
        );
      } catch (error) {
        failure = CoreFailure.from(error);
        reportFailure(error, source: 'core');
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
        reportFailure(error, source: 'core');
        if (!dropped.isCompleted && CoreFailure.from(error).key == CoreFailure.unavailable.key) dropped.complete();
      };
      try {
        await _readStatus(report: false);
        final about = await link.stub.getAbout(GetAboutRequest(apiVersion: apiVersion));
        if (about.hasError()) throw CoreFailure(about.error.userMessageKey);
        coreCapabilities = about.about.contract.capabilities.toSet();
        serverlessAvailable = coreCapabilities.contains('serverless');
        localProxy = about.about.hasLocalProxy() ? about.about.localProxy : null;
        if (failure?.key == CoreFailure.unavailable.key) failure = null;
        recovered('core');
        _watchSubscriptions();
        _watchSession();
        notifyListeners();
        if (_pendingSelection != null) unawaited(_applySelection());
        if ((settings.connectOnStart || settings.resumeAfterUpdate) && !_startedOnce && phase == Phase.off) {
          // Auto-connect only once per launch so core reconnection cannot undo
          // an explicit disconnect.
          _startedOnce = true;
          // Allow time for the initial server list to arrive through the
          // subscription watch.
          await Future<void>.delayed(const Duration(milliseconds: 600));
          if (phase == Phase.off) {
            await settings.saveResumeAfterUpdate(false);
            unawaited(connect());
          }
        }
        if (phase == Phase.connected && settings.resumeAfterUpdate) await settings.saveResumeAfterUpdate(false);
        _startedOnce = true;
        await dropped.future;
      } catch (error) {
        failure = CoreFailure.from(error);
        reportFailure(error, source: 'core');
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
    if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
    _applyState(answer.status.connection, report: report);
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
    if (phase == Phase.connecting || phase == Phase.reconnecting) unawaited(_probeCall?.cancel());
    // Session events may omit the ID. Retain the known ID until the session
    // ends.
    if (phase == Phase.off) {
      sessionId = null;
      _activePlan = null;
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
      unawaited((_connectionWork?.future ?? Future.value()).then((_) => connect(retry: true)));
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
      _emit(ConnectionFailed(failure ?? CoreFailure(_keyOfCode(state.reason))));
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
    _subscriptionWatch = stream.listen((state) {
      final id = state.settings.id;
      if (state.deleted) {
        _subscriptions.remove(id);
      } else {
        _subscriptions[id] = state;
      }
      final key = state.hasLastError() ? state.lastError.userMessageKey : '';
      if (key.isNotEmpty) {
        reportFailure(CoreFailure(key), source: 'subscription:$id', action: 'subscription', argument: id);
      } else {
        recovered('subscription:$id');
      }
      notifyListeners();
    }, onError: _drop);
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
        // A healthy event resets the watchdog streak (FEATURE-PLAN.md F7).
        if (_watchFailures != 0) {
          _watchFailures = 0;
          if (failure?.key == 'app.core_watch_unstable') failure = null;
        }
        _seenSession = id;
        _seenSequence = event.sequence;
        final fresh = !event.hasEmittedAt() || event.emittedAt.toDateTime().isAfter(opened);
        if (event.hasStateChanged()) {
          _applyState(event.stateChanged.state, report: fresh);
          notifyListeners();
        } else if (event.hasGroupSwitched() && fresh) {
          _fallbackMoved(event.groupSwitched);
        }
      },
      onError: (Object error) {
        _drop(error);
        _watchFailures++;
        if (_watchFailures == 1) {
          // First break in the streak: show the recovery attempt instead of
          // retrying silently.
          unawaited(recordNotification(AppNotification(time: DateTime.now(), title: strings.coreRestoringLink, body: '')));
        }
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
  /// and asks the user to repair the link (FEATURE-PLAN.md F7).
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

  /// Server choice saved before connecting; offered for restore when the app
  /// restarts after a crash (FEATURE-PLAN.md F7).
  String? _pendingRestore;

  /// A crashed session is waiting for the user's restore decision.
  String? get pendingRestore => _pendingRestore;

  void _writeSessionIntent(String choice) {
    if (!settings.restoreOnCrash) return;
    settings.sessionIntent = jsonEncode({'server': choice, 'at': DateTime.now().millisecondsSinceEpoch});
  }

  void _clearSessionIntent() {
    _pendingRestore = null;
    if (settings.sessionIntent.isNotEmpty) settings.sessionIntent = '';
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
    if (choice != null && choice != 'auto' && choice != 'bypass') settings.server = choice;
    notifyListeners();
    await connect();
  }

  /// Dismisses the crash-restore offer without connecting.
  void dismissCrashRestore() {
    _clearSessionIntent();
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

  /// Applies a network profile's settings snapshot (F5). Only snapshot
  /// fields the profile captured are touched; the rest stays as-is.
  Future<void> applyProfile(NetworkProfile profile) async {
    await change((x) {
      if (profile.tunnel != null) x.tunnel = profile.tunnel!;
      if (profile.preset != null) x.preset = profile.preset!;
      if (profile.dns != null) x.dns = profile.dns!;
      if (profile.dnsPreset != null) x.dnsPreset = profile.dnsPreset!;
      if (profile.engine != null) x.engine = profile.engine!;
      if (profile.serverId != null && profile.serverId!.isNotEmpty) x.server = profile.serverId!;
    });
  }

  /// Handles a core ProfileMatched event (F5): marks the profile active and
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
  /// are one tap away (F5).
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

  /// Restores the settings snapshot saved by [applyProfileWithUndo] (F5).
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
    } catch (_) {
      // A corrupt snapshot must not break the UI; there is nothing sane to
      // restore, so the current settings simply stay.
    }
  }

  /// Refreshes the current network fingerprint (F5).
  ///
  /// TODO(core): wire to the GetNetworkFingerprint RPC and the
  /// ProfileMatched core event once the Go agent lands
  /// `core/profiles/profiles.go`. Until then the fingerprint stays unknown
  /// and the UI says so instead of guessing.
  Future<void> refreshFingerprint() async {
    networkFingerprint = const NetworkFingerprint.unknown();
    final matched = profiles.match(networkFingerprint);
    if (matched != null && matched.id != profiles.activeId) {
      await handleProfileMatched(matched.id);
    } else {
      notifyListeners();
    }
  }

  /// Connects through a proxy chain (F8).
  ///
  /// The Go plan builder does not accept chains yet (F8 backend pending), so
  /// connecting reports an honest, localized failure for now instead of a
  /// raw error. Chain building, validation and management are fully usable.
  Future<void> connectChain(ProxyChain chain) async {
    throw const CoreFailure('chainUnsupported');
  }

  Future<void> toggle() async {
    if (cleanupPending) {
      await disconnect();
    } else if (phase == Phase.off) {
      await connect();
    } else if (phase == Phase.disconnecting) {
      _connectQueued = true;
    } else if (phase == Phase.connected || phase == Phase.reconnecting || phase == Phase.connecting) {
      await disconnect();
    }
  }

  /// Connects using the current selection and settings. [retry] preserves the
  /// remaining attempt count during profile-group failover.
  Future<void> connect({bool retry = false}) async {
    if (_disposed || updateBlocked || busy || _stopping) return;
    if (cleanupPending) {
      await disconnect();
      if (cleanupPending || _disposed) return;
    }
    final link = _link;
    if (link == null) {
      // The core is not up (e.g. "retry" tapped in a notification): say so
      // instead of silently doing nothing (audit L23).
      failure = CoreFailure.unavailable;
      notifyListeners();
      return;
    }
    failure = null;
    if (selected != 'bypass' && servers.isEmpty) {
      failure = const CoreFailure('app.no_servers');
      _emit(ConnectionFailed(failure!));
      notifyListeners();
      return;
    }
    final choice = selected;
    final entry = choice.startsWith(groupPrefix) ? entryOf(choice, _subscriptions.values) : null;
    final plan = currentPlan;
    if (plan.tunStack.isNotEmpty && link.minor < 7) {
      failure = const CoreFailure('core.api.version_mismatch');
      _emit(ConnectionFailed(failure!));
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
    final armed = settings.killSwitch;
    // Track the active profile because profile groups fail over in the client.
    _member = entry != null && entry.members.any(isProfile) ? plan.outbounds.single.id : null;
    if (!retry) _memberSpare = entry == null ? 0 : entry.members.length - 1;
    final work = _connectionWork = Completer<void>();
    phase = Phase.connecting;
    // Remember the intent so a crash can offer to restore the session (F7).
    _writeSessionIntent(choice);
    notifyListeners();
    // Include events emitted during these requests, before the watch opens.
    final started = DateTime.now();
    var connected = false;
    try {
      await _probeCall?.cancel();
      final answer = await link.stub.connect(
        // The core arms the kill switch before the engine starts, so nothing
        // leaves outside the tunnel while it comes up.
        ConnectRequest(apiVersion: apiVersion, sessionPlan: plan, controlAuthenticator: link.token, killSwitch: armed),
        options: CallOptions(timeout: const Duration(seconds: 35)),
      );
      if (_disposed || link != _link) return;
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      _applyState(answer.status.connection);
      _activePlan = plan;
      needsReconnect = currentPlan != plan;
      connected = true;
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
      if (!_stopping && _emitted == before) _emit(ConnectionFailed(failure!));
    } finally {
      _connectionWork = null;
      work.complete();
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
    // A clean disconnect is not a crash: drop the restore intent (F7).
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
            if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
            return answer;
          }, retryIf: (error) => error is CoreFailure && error.key == 'core.session.busy');
      cleanupPending = false;
      _applyState(answer.status.connection);
    } catch (error) {
      failure = CoreFailure.from(error);
      reportFailure(error, source: 'disconnect');
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
    if (phase == Phase.connected || phase == Phase.reconnecting || _connectionWork != null) {
      needsReconnect = _activePlan == null || currentPlan != _activePlan;
      notifyListeners();
    }
  }

  Future<void> select(String server) async {
    if (settings.server == server) return;
    settings.server = server;
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
    recovered('kill-switch');
    settings.killSwitch = value;
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
            if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
          } catch (error) {
            reportFailure(error, source: 'kill-switch');
          }
        }
        return;
      }
      try {
        final answer = await link.stub.setKillSwitch(
          SetKillSwitchRequest(apiVersion: apiVersion, sessionId: id, enabled: value),
        );
        if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      } catch (error) {
        failure = CoreFailure.from(error);
        reportFailure(error, source: 'kill-switch');
        notifyListeners();
      }
    });
  }

  /// Saves a subscription; the core fetches it and streams its servers. Returns
  /// null on success; failures are reported through the notification stream.
  Future<CoreFailure?> addSubscription(String url, {String name = ''}) async {
    recovered('request');
    final link = _link;
    if (link == null) {
      reportFailure(CoreFailure.unavailable);
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
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      _subscriptions[answer.state.settings.id] = answer.state;
      notifyListeners();
      return null;
    } catch (error) {
      reportFailure(error);
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
    if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
  });

  /// Saves subscription settings without replacing the stored URL.
  Future<CoreFailure?> saveSubscription(SubscriptionSettings chosen) => _call(() async {
    final link = _link!;
    final answer = await link.stub.saveSubscription(
      SaveSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, settings: chosen..url = ''),
    );
    if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
  });

  /// Fetches the bearer link only for this action, without retaining it in state.
  Future<String?> fetchSubscriptionLink(String id) async {
    final link = _link;
    if (link == null) {
      reportFailure(CoreFailure.unavailable);
      return null;
    }
    try {
      final answer = await link.stub.getSubscriptionLink(
        GetSubscriptionLinkRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: id),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      recovered('request');
      return answer.url;
    } catch (error) {
      reportFailure(error, source: 'request');
      return null;
    }
  }

  /// Fetches the bearer link only for this action, without retaining it in state.
  Future<CoreFailure?> openSubscriptionPage(String id) => _call(() async {
    final link = _link!;
    final answer = await link.stub.getSubscriptionLink(
      GetSubscriptionLinkRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: id),
    );
    if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
    if (!await launchUrl(Uri.parse(answer.url), mode: LaunchMode.externalApplication)) {
      throw const CoreFailure('core.internal.unexpected');
    }
  });

  Future<CoreFailure?> refreshSubscription(String id) => _call(() async {
    final link = _link!;
    final answer = await link.stub.refreshSubscription(
      RefreshSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: id),
    );
    if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
  });

  Future<CoreFailure?> deleteSubscription(String id) => _call(() async {
    final link = _link!;
    final answer = await link.stub.deleteSubscription(
      DeleteSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: id),
    );
    if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
    _subscriptions.remove(id);
    overrides.drop(id);
    notifyListeners();
  });

  /// Runs a core request; returns null on success or stores and returns its
  /// failure.
  Future<CoreFailure?> _call(Future<void> Function() body) async {
    recovered('request');
    if (_link == null) {
      reportFailure(CoreFailure.unavailable);
      return CoreFailure.unavailable;
    }
    failure = null;
    try {
      await body();
      return null;
    } catch (error) {
      failure = CoreFailure.from(error);
      reportFailure(error);
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

  Future<void> probe({String? subscriptionId}) async {
    final link = _link;
    final all = subscriptionId == null ? servers : _subscriptions[subscriptionId]?.outbounds.toList() ?? [];
    if (!canProbe || link == null || all.isEmpty) return;
    probing = true;
    probingSubscription = subscriptionId;
    recovered('probe');
    try {
      final call = _probeCall = link.stub.probeServers(
        ProbeServersRequest(
          apiVersion: apiVersion,
          outbounds: all,
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
      notifyListeners();
      var lastNotify = DateTime.now();
      await for (final r in call) {
        if (_disposed || link != _link || busy || (phase != Phase.off && phase != Phase.connected)) break;
        latency[r.serverId] = r.reachable ? r.latencyMs : null;
        final now = DateTime.now();
        if (now.difference(lastNotify) >= _probeNotifyInterval) {
          lastNotify = now;
          notifyListeners();
        }
      }
    } catch (error) {
      if (!_disposed && link == _link && !(error is GrpcError && error.code == StatusCode.cancelled)) {
        reportFailure(error, source: 'probe');
      }
      // Keep partial results; unmeasured servers remain unknown instead of
      // being marked unreachable.
    } finally {
      _probeCall = null;
      probing = false;
      probingSubscription = null;
      notifyListeners();
    }
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
  /// The BenchmarkServers RPC is hand-wired per FEATURE-PLAN.md F2 while the
  /// Go side is pending: a core without the RPC answers UNIMPLEMENTED and the
  /// UI reports a friendly version message instead of a raw error.
  /// Notifications are throttled like [probe]; cancel with [cancelBenchmark].
  Future<void> benchmarkServers({List<String>? serverIds}) async {
    final link = _link;
    final ids = serverIds ?? [for (final o in servers) o.id];
    if (!canBenchmark || link == null || ids.isEmpty) return;
    benchmarking = true;
    benchmarkProgress = (done: 0, total: ids.length);
    benchmarkPct.clear();
    recovered('benchmark');
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
      await for (final sample in call) {
        if (_disposed || link != _link) break;
        if (sample.hasError()) throw CoreFailure(sample.error.userMessageKey);
        if (!sample.done) {
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
      _saveBandwidth();
    } catch (error) {
      if (!_disposed && link == _link && !(error is GrpcError && error.code == StatusCode.cancelled)) {
        if (error is GrpcError && error.code == StatusCode.unimplemented) {
          reportFailure(const CoreFailure('app.benchmark_unsupported'), source: 'benchmark');
        } else {
          reportFailure(error, source: 'benchmark');
        }
      }
      // Keep partial results; unmeasured servers stay unknown.
    } finally {
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
    return compareAutoSelect(a, b, mode, latency, bandwidth);
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
    browserDiagnostics.clear();
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
    for (final rule in settings.rules.map(UserRule.parse).nonNulls) {
      final target = switch (rule.target) {
        RuleTarget.direct => 'direct',
        RuleTarget.block => 'reject',
        RuleTarget.proxy => proxy,
      };
      plan.routes.add(RoutingRule(destination: rule.destination, outboundId: target));
    }
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
    // Profiles cannot share an engine. Select one reachable member by role
    // priority or latency.
    choice = pickMember(entry, latency).id;
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
    final profile = picked ?? _fastest(profiles, latency, bandwidth: bandwidth, autoSelect: settings.autoSelectMode);
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
    ]..sort((a, b) => (latency[a.id] ?? 1 << 30).compareTo(latency[b.id] ?? 1 << 30));
    plan.groups.add(
      GroupSpec(
        name: Sora.failoverGroup,
        type: GroupType.GROUP_TYPE_FALLBACK,
        members: [choice, for (final o in others) o.id],
      ),
    );
    plan.routing.proxyTarget = Sora.failoverGroup;
  } else {
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
}) {
  bool down(OutboundSpec o) => latency.containsKey(o.id) && latency[o.id] == null;
  if (entry.ordered) return entry.byRole.firstWhere((o) => !down(o), orElse: () => entry.byRole.first);
  final up = [
    for (final o in entry.members)
      if (!down(o)) o,
  ];
  return _fastest(up.isEmpty ? entry.members : up, latency, bandwidth: bandwidth, autoSelect: autoSelect);
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

/// Smart score in [0, 1] (higher is better): ping 40%, speed 40%,
/// measurement freshness 20%.
double smartScoreOf(String id, Map<String, int?> latency, Map<String, ({int bps, DateTime at})> bandwidth) {
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
  return score;
}

/// Compares two servers for auto-selection. [mode] is ping, speed or smart;
/// unknown modes fall back to ping. Ties break by ping.
int compareAutoSelect(
  String a,
  String b,
  String mode,
  Map<String, int?> latency,
  Map<String, ({int bps, DateTime at})> bandwidth,
) {
  int byPing() => (latency[a] ?? 1 << 30).compareTo(latency[b] ?? 1 << 30);
  switch (mode) {
    case 'speed':
      final x = freshBandwidthOf(bandwidth, a), y = freshBandwidthOf(bandwidth, b);
      if (x != null || y != null) {
        if (x == null) return 1;
        if (y == null) return -1;
        final bySpeed = y.compareTo(x);
        if (bySpeed != 0) return bySpeed;
      }
      return byPing();
    case 'smart':
      final bySmart = smartScoreOf(b, latency, bandwidth).compareTo(smartScoreOf(a, latency, bandwidth));
      return bySmart != 0 ? bySmart : byPing();
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
}) {
  var best = profiles.first;
  for (final o in profiles) {
    if (compareAutoSelect(o.id, best.id, autoSelect, latency, bandwidth) < 0) best = o;
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
