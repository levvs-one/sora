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
  bool _booted = false;
  final _syncing = <String>{};

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
    if (mounted) setState(() {});
  }

  Future<void> _boot() async {
    await _daemon.ensureRunning();
    if (!mounted || _booted) return;
    _booted = true;
    if (_daemon.state != SyncDaemonState.running) return;
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
  /// the peer.
  Future<void> _join(String raw) async {
    final client = _daemon.client;
    if (client == null || _joining) return;
    setState(() => _joining = true);
    try {
      final peer = await client.joinPairing(raw);
      if (!mounted) return;
      setState(() => _joining = false);
      await _refresh();
      if (!mounted) return;
      _snack(S.of(context).syncPairedWith(peer.name.isEmpty ? peer.id : peer.name));
    } on SyncApiException catch (e) {
      if (!mounted) return;
      setState(() => _joining = false);
      _snack(describeSyncError(S.of(context), e));
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
      final result = await client.syncPeer(peer.id);
      if (!mounted) return;
      _syncing.remove(peer.id);
      await _refresh();
      if (!mounted) return;
      _snack(S.of(context).syncSyncResult(result.pulled, result.pushed));
    } on SyncApiException catch (e) {
      if (!mounted) return;
      _syncing.remove(peer.id);
      setState(() => _opError = describeSyncError(S.of(context), e));
    }
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
      children: [
        switch (daemon.state) {
          SyncDaemonState.idle || SyncDaemonState.starting => _starting(s),
          SyncDaemonState.unavailable => _unavailable(s, daemon.unavailableReason),
          SyncDaemonState.failed => _failed(s, daemon),
          SyncDaemonState.running => ..._ready(context, s),
        },
      ],
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
      final PairingSession session;
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

  /// Watches for the session's end: a new peer means the other side paired,
  /// a closed session without one means the code expired.
  Future<void> _poll() async {
    final client = _client;
    if (client == null || !mounted || _payload == null) return;
    try {
      final status = await client.status();
      if (!mounted || _payload == null) return;
      if (status.pairingActive) return;
      final peers = await client.peers();
      if (!mounted) return;
      final fresh = peers.any((p) => !_knownPeers.contains(p.id));
      _poller?.cancel();
      _ticker?.cancel();
      if (fresh) {
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
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
