import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../sora.dart';
import '../sync.dart';
import '../sync_api.dart';
import '../sync_daemon.dart';
import '../sync_docs.dart';
import 'kit.dart';
import 'qr.dart';

/// End-to-end encrypted device sync without cloud (FEATURE-PLAN.md F9).
///
/// Wired (2026-10-20): the screen drives the sora-sync daemon
/// (`service/sync`) — spawning it on demand, health-checking its localhost
/// HTTP API, and running pairing, peers and sync through it. The daemon is
/// the source of truth for peers; the app keeps no device registry, and
/// "paired" is shown only for peers the daemon reports after a successful
/// Noise_XX handshake.
///
/// Honest states: daemon missing (binary absent) or Android → an
/// "unavailable" notice, never a fake device list; starting → progress;
/// start failure → the error text with a retry; pairing session → the real
/// QR from the daemon with its TTL; peers → `GET /v1/peers` with the
/// daemon's `last_sync`.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  SyncStatusInfo? _status;
  List<SyncPeer>? _peers;
  String? _opError;
  bool _joining = false;
  bool _refreshing = false;
  final _syncing = <String>{};

  /// Whether the post-startup load (legacy migration + first refresh) ran.
  /// The daemon can reach `running` after a retry, not just the first boot,
  /// so the load is driven by the state transition, not by `initState`.
  bool _loaded = false;

  SyncDaemon get _daemon => SoraScope.read(context).syncDaemon;

  @override
  void initState() {
    super.initState();
    _daemon.addListener(_onDaemon);
    unawaited(_boot());
  }

  @override
  void dispose() {
    _daemon.removeListener(_onDaemon);
    super.dispose();
  }

  void _onDaemon() {
    if (!mounted) return;
    if (_daemon.state == SyncDaemonState.running && !_loaded) {
      _loaded = true;
      unawaited(_load());
    }
    if (mounted) setState(() {});
  }

  Future<void> _boot() async {
    await _daemon.ensureRunning();
    if (!mounted) return;
    if (_daemon.state == SyncDaemonState.running && !_loaded) {
      _loaded = true;
      await _load();
    }
  }

  /// Runs once per screen lifetime when the daemon becomes usable: clears
  /// the pre-wiring registry a single time, then loads status and peers.
  Future<void> _load() async {
    await _migrateLegacyRegistry();
    await _refresh();
  }

  /// One-time honest migration of the pre-wiring device list: the old screen
  /// added a registry entry for every scanned code without any handshake, so
  /// those entries were never paired. Keeping them would be theater; they
  /// are cleared with an explanation instead.
  Future<void> _migrateLegacyRegistry() async {
    final sora = SoraScope.read(context);
    if (sora.settings.syncedDevices.isEmpty) return;
    sora.settings.syncedDevices = '';
    if (mounted) _snack(S.of(context).syncLegacyCleared);
  }

  Future<void> _refresh() async {
    final client = _daemon.client;
    if (client == null || _refreshing) return;
    // Keep Sora's document bridge pointed at the daemon's current client
    // (a retry may have created a new one).
    SoraScope.read(context).ensureSyncBridge();
    _refreshing = true;
    try {
      final status = await client.status();
      final peers = await client.peers();
      if (!mounted) return;
      setState(() {
        _status = status;
        _peers = peers;
        _opError = null;
      });
    } on SyncApiException catch (e) {
      if (!mounted) return;
      setState(() => _opError = describeSyncError(S.of(context), e));
    } finally {
      _refreshing = false;
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _scan() async {
    await push<void>(
      context,
      QrScanScreen(
        onScanned: (raw) {
          // Local format check first; the daemon re-decodes canonically.
          if (SyncPairing.decodePairPayload(raw) == null) {
            _snack(S.of(context).qrInvalid);
            return;
          }
          unawaited(_join(raw));
        },
      ),
    );
  }

  /// Joins with a scanned payload: the daemon runs discovery and the
  /// Noise_XX handshake. "Paired" is claimed only when the daemon returns
  /// the peer. The bridge publishes the app's documents first so the
  /// first sync (which runs inside the daemon during join) carries them;
  /// documents that arrived during it are applied afterwards.
  Future<void> _join(String raw) async {
    final client = _daemon.client;
    if (client == null || _joining) return;
    setState(() => _joining = true);
    try {
      final sora = SoraScope.read(context);
      final bridge = SyncDocumentBridge(sora: sora, client: client);
      final before = await client.documents();
      await bridge.publish();
      final peer = await client.joinPairing(raw);
      await bridge.applyPulled(syncDocsDiff(before, await client.documents()));
      if (!mounted) return;
      setState(() => _joining = false);
      await _refresh();
      if (!mounted) return;
      _snack(S.of(context).syncPairedWith(peer.name.isEmpty ? peer.id : peer.name));
    } on SyncApiException catch (e) {
      if (!mounted) return;
      setState(() => _joining = false);
      _snack(describeSyncError(S.of(context), e));
    } on SyncBridgeException catch (e) {
      if (!mounted) return;
      setState(() => _joining = false);
      _snack('${S.of(context).syncError}: ${e.message}');
    }
  }

  Future<void> _showCode() async {
    final paired = await push<bool>(context, _PairingCodeScreen(daemon: _daemon));
    if (paired == true && mounted) {
      await _refresh();
      if (mounted) _snack(S.of(context).syncPaired);
    }
  }

  Future<void> _syncPeer(SyncPeer peer) async {
    final client = _daemon.client;
    if (client == null || !_syncing.add(peer.id)) return;
    if (mounted) setState(() {});
    try {
      final sora = SoraScope.read(context);
      final bridge = SyncDocumentBridge(sora: sora, client: client);
      // Publish first: the sync moves what the daemon holds, so the app's
      // current state must reach the daemon before the peer sync runs.
      await bridge.publish();
      final result = await client.syncPeer(peer.id);
      // Apply exactly what arrived, then show per-document results
      // (kind, name, from, updated_at) instead of bare counters.
      await bridge.applyPulled(result.pulled);
      if (!mounted) return;
      _syncing.remove(peer.id);
      await _refresh();
      if (!mounted) return;
      _snack(S.of(context).syncSyncResult(result.pulled.length, result.pushed.length));
      await _showSyncResult(peer, result);
    } on SyncApiException catch (e) {
      if (!mounted) return;
      _syncing.remove(peer.id);
      setState(() => _opError = describeSyncError(S.of(context), e));
    } on SyncBridgeException catch (e) {
      if (!mounted) return;
      _syncing.remove(peer.id);
      setState(() => _opError = '${S.of(context).syncError}: ${e.message}');
    }
  }

  /// Shows what a sync moved: every pulled and pushed document with its
  /// kind label, name, origin device and update time.
  Future<void> _showSyncResult(SyncPeer peer, SyncResult result) {
    final palette = Palette.of(context);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: palette.scrim,
      transitionDuration: Motion.enabled(context) ? Motion.medium : Duration.zero,
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Motion.curve);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(curved), child: child),
        );
      },
      pageBuilder: (context, _, _) => _SyncResultCard(peer: peer, result: result),
    );
  }

  Future<void> _revoke(SyncPeer peer) async {
    final s = S.of(context);
    final name = peer.name.isEmpty ? peer.id : peer.name;
    if (!await confirm(context, question: s.syncRevokeConfirm(name), action: s.syncRevoke)) return;
    if (!mounted) return;
    final client = _daemon.client;
    if (client == null) return;
    try {
      await client.revokePeer(peer.id);
      if (!mounted) return;
      await _refresh();
    } on SyncApiException catch (e) {
      if (!mounted) return;
      setState(() => _opError = describeSyncError(S.of(context), e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final daemon = SoraScope.of(context).syncDaemon;
    final s = S.of(context);
    return Screen(
      title: s.sync,
      actions: [
        if (daemon.state == SyncDaemonState.running)
          RoundButton(
            icon: Symbols.refresh_rounded,
            label: s.refresh,
            onTap: _refreshing ? null : () => unawaited(_refresh()),
          ),
      ],
      children: switch (daemon.state) {
        SyncDaemonState.idle || SyncDaemonState.starting => [_starting(s)],
        SyncDaemonState.unavailable => [_unavailable(s, daemon.unavailableReason)],
        SyncDaemonState.failed => [_failed(s, daemon)],
        SyncDaemonState.running => _ready(context, s),
      },
    );
  }

  Widget _starting(S s) {
    final palette = Palette.of(context);
    return Group(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(s.syncDaemonStarting, style: Styles.secondary.copyWith(color: palette.ink2)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _unavailable(S s, SyncDaemonUnavailableReason? reason) {
    final palette = Palette.of(context);
    final detail = switch (reason) {
      SyncDaemonUnavailableReason.android => s.syncUnavailableAndroid,
      _ => s.syncDaemonMissing,
    };
    return Group(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Symbols.devices_rounded, size: 40, weight: 400, color: palette.ink3),
              const SizedBox(height: 12),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: Styles.secondary.copyWith(color: palette.ink2, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _failed(S s, SyncDaemon daemon) {
    final palette = Palette.of(context);
    final detail = daemon.errorDetail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Symbols.warning_rounded, size: 40, weight: 400, color: palette.danger),
                  const SizedBox(height: 12),
                  Text(
                    s.syncDaemonFailed,
                    textAlign: TextAlign.center,
                    style: Styles.bodyStrong.copyWith(color: palette.ink),
                  ),
                  if (detail != null && detail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: Styles.caption.copyWith(color: palette.ink2),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: s.syncRetry,
          onTap: () => unawaited(daemon.ensureRunning()),
        ),
      ],
    );
  }

  List<Widget> _ready(BuildContext context, S s) {
    final palette = Palette.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final status = _status;
    final peers = _peers;
    String formatLastSync(DateTime when) =>
        s.syncLastSync(DateFormat.yMMMd(locale).add_Hm().format(when.toLocal()));
    return [
      if (status != null)
        Group(
          children: [
            Tile(
              title: s.syncThisDevice,
              detail: status.deviceName.isEmpty
                  ? status.deviceId
                  : '${status.deviceName} · ${status.deviceId}',
              detailColor: palette.ink2,
            ),
          ],
        ),
      if (status != null) const SizedBox(height: 16),
      if (_opError != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(_opError!, style: Styles.secondary.copyWith(color: palette.danger)),
        ),
      Heading(s.syncDevices),
      if (peers == null)
        const Group(
          children: [
            Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ],
        )
      else if (peers.isEmpty)
        Group(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Symbols.devices_rounded, size: 40, weight: 400, color: palette.ink3),
                  const SizedBox(height: 12),
                  Text(
                    s.syncEmpty,
                    textAlign: TextAlign.center,
                    style: Styles.secondary.copyWith(color: palette.ink2),
                  ),
                ],
              ),
            ),
          ],
        )
      else
        Group(
          children: [
            for (final peer in peers)
              Tile(
                title: peer.name.isEmpty ? peer.id : peer.name,
                detail: peer.lastSync == null ? s.syncNever : formatLastSync(peer.lastSync!),
                detailColor: palette.ink2,
                trailing: _syncing.contains(peer.id)
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RoundButton(
                            icon: Symbols.refresh_rounded,
                            label: s.syncSyncNow,
                            onTap: () => unawaited(_syncPeer(peer)),
                          ),
                          RoundButton(
                            icon: Symbols.link_off_rounded,
                            label: s.syncRevoke,
                            onTap: () => unawaited(_revoke(peer)),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      const SizedBox(height: 16),
      Heading(s.syncPair),
      Group(
        children: [
          LinkTile(
            title: s.syncShowCode,
            onTap: () => unawaited(_showCode()),
          ),
          LinkTile(
            title: s.syncScanCode,
            onTap: () => unawaited(_scan()),
          ),
        ],
      ),
      if (_joining) ...[
        const SizedBox(height: 16),
        Group(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.syncJoining, style: Styles.secondary.copyWith(color: palette.ink2)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 16),
      Group(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.syncSecureNote, style: Styles.secondary.copyWith(color: palette.ink2, height: 1.5)),
                const SizedBox(height: 8),
                Text(s.syncNoLan, style: Styles.secondary.copyWith(color: palette.ink2, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    ];
  }
}

/// Result of one peer sync: every moved document with its kind label,
/// name, origin device and update time — the honest view of what arrived
/// and what left, instead of bare counters.
class _SyncResultCard extends StatelessWidget {
  const _SyncResultCard({required this.peer, required this.result});

  final SyncPeer peer;
  final SyncResult result;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    String when(DateTime t) => DateFormat.yMMMd(locale).add_Hm().format(t.toLocal());
    final peerName = peer.name.isEmpty ? peer.id : peer.name;

    Widget docRow(SyncDocMeta meta, String fromLabel) => Tile(
          title: syncDocKindLabel(s, meta.kind),
          detail: '${meta.name} · ${s.syncFrom(fromLabel)} · ${when(meta.updatedAt)}',
          detailColor: palette.ink2,
        );

    return Center(
      child: Material(
        color: palette.raised,
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.syncResultTitle,
                  textAlign: TextAlign.center,
                  style: Styles.bodyStrong.copyWith(color: palette.ink),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (result.pulled.isEmpty && result.pushed.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              s.syncNoChanges,
                              textAlign: TextAlign.center,
                              style: Styles.secondary.copyWith(color: palette.ink2),
                            ),
                          )
                        else ...[
                          if (result.pulled.isNotEmpty) ...[
                            Heading(s.syncPulled),
                            Group(
                              children: [for (final meta in result.pulled) docRow(meta, peerName)],
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (result.pushed.isNotEmpty) ...[
                            Heading(s.syncPushed),
                            Group(
                              children: [for (final meta in result.pushed) docRow(meta, s.syncThisDevice)],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                Pressable(
                  onTap: () => Navigator.of(context).pop(),
                  radius: 22,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    child: Text(s.close, style: Styles.body.copyWith(color: palette.ink)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows this device's pairing code, generated by the daemon (F9).
///
/// The QR payload comes from `POST /v1/pairing/start` and is shown as-is —
/// the app never invents key material. While the session is open the screen
/// polls the daemon: a fresh peer means the other side paired (the screen
/// pops with success); a closed session without a new peer means the code
/// expired. Closing the screen stops the session.
class _PairingCodeScreen extends StatefulWidget {
  const _PairingCodeScreen({required this.daemon});

  final SyncDaemon daemon;

  @override
  State<_PairingCodeScreen> createState() => _PairingCodeScreenState();
}

class _PairingCodeScreenState extends State<_PairingCodeScreen> {
  String? _payload;
  DateTime? _expiresAt;
  String? _error;
  bool _starting = true;
  bool _stopping = false;
  Set<String> _knownPeers = const {};
  Timer? _ticker;
  Timer? _poller;

  SyncApiClient? get _client => widget.daemon.client;

  @override
  void initState() {
    super.initState();
    widget.daemon.addListener(_onDaemon);
    unawaited(_open());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _poller?.cancel();
    widget.daemon.removeListener(_onDaemon);
    // Best-effort: an abandoned session would otherwise linger until its
    // TTL. Stopping an already-closed session is a no-op on the daemon.
    unawaited(_closeSession());
    super.dispose();
  }

  Future<void> _closeSession() async {
    try {
      await _client?.stopPairing();
    } catch (_) {
      // The daemon is gone; nothing to stop.
    }
  }

  void _onDaemon() {
    if (widget.daemon.state != SyncDaemonState.running && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _open() async {
    final client = _client;
    if (client == null) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    try {
      _knownPeers = {for (final p in await client.peers()) p.id};
      PairingSession session;
      try {
        session = await client.startPairing();
      } on SyncApiException catch (e) {
        // A previous screen died without stopping its session; reclaim it
        // instead of leaving the user stuck behind a 409.
        if (e.statusCode != 409) rethrow;
        await client.stopPairing();
        session = await client.startPairing();
      }
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = null;
        _payload = session.qrPayload;
        _expiresAt = session.expiresAt;
      });
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
      _poller?.cancel();
      _poller = Timer.periodic(const Duration(seconds: 3), (_) => unawaited(_poll()));
      // Show the expiry promptly even if the daemon's TTL already passed.
      unawaited(_poll());
    } on SyncApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = describeSyncError(S.of(context), e);
      });
    }
  }

  /// Watches for the pairing outcome: a fresh peer means the other side
  /// completed the Noise_XX handshake — success is shown immediately, not
  /// after the TTL; a closed session without one means the code expired.
  Future<void> _poll() async {
    final client = _client;
    if (client == null || !mounted || _payload == null) return;
    try {
      final peers = await client.peers();
      if (!mounted || _payload == null) return;
      if (peers.any((p) => !_knownPeers.contains(p.id))) {
        _poller?.cancel();
        _ticker?.cancel();
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      final status = await client.status();
      if (!mounted || _payload == null) return;
      if (status.pairingActive) return;
      _poller?.cancel();
      _ticker?.cancel();
      if (mounted) setState(() => _payload = null);
    } catch (_) {
      // Transient failure: keep polling until the TTL runs out.
    }
  }

  Future<void> _stop() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    await _closeSession();
    if (mounted) Navigator.of(context).pop(false);
  }

  String _countdown(S s) {
    final expires = _expiresAt;
    if (expires == null) return '';
    final left = expires.difference(DateTime.now().toUtc());
    final clamped = left.isNegative ? Duration.zero : left;
    final text =
        '${clamped.inMinutes.toString().padLeft(2, '0')}:${(clamped.inSeconds % 60).toString().padLeft(2, '0')}';
    return s.syncExpiresIn(text);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    return Screen(
      title: s.syncPairingTitle,
      children: [
        if (_starting) ...[
          const SizedBox(height: 64),
          const Center(
            child: SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(s.syncDaemonStarting, style: Styles.secondary.copyWith(color: palette.ink2)),
          ),
        ] else if (_error != null) ...[
          const SizedBox(height: 32),
          Group(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Symbols.warning_rounded, size: 40, weight: 400, color: palette.danger),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Styles.secondary.copyWith(color: palette.ink2, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: s.close, onTap: () => Navigator.of(context).pop(false)),
        ] else if (_payload == null) ...[
          const SizedBox(height: 32),
          Group(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Symbols.devices_rounded, size: 40, weight: 400, color: palette.ink3),
                    const SizedBox(height: 12),
                    Text(
                      s.syncCodeExpired,
                      textAlign: TextAlign.center,
                      style: Styles.bodyStrong.copyWith(color: palette.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: s.syncNewCode,
            onTap: () => setState(() {
              _starting = true;
              _payload = null;
              _expiresAt = null;
              unawaited(_open());
            }),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Center(
            child: DecoratedBox(
              // White quiet zone keeps the code scannable in both themes.
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                // A QR code carries no meaning for screen readers; the
                // payload is single-use and TTL-bound, so the image is
                // hidden from the semantics tree.
                child: ExcludeSemantics(
                  child: QrImageView(
                    data: _payload!,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    size: 260,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _countdown(s),
              style: Styles.secondary.copyWith(color: palette.ink2),
            ),
          ),
          const SizedBox(height: 8),
          Group(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s.syncWaiting, style: Styles.secondary.copyWith(color: palette.ink2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: s.syncStopShowing,
            busy: _stopping,
            onTap: _stopping ? null : () => unawaited(_stop()),
          ),
          const SizedBox(height: 16),
          Group(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Text(s.syncSecureNote, style: Styles.secondary.copyWith(color: palette.ink2, height: 1.5)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
