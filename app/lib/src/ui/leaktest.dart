import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart' show GrpcError, ResponseStream, StatusCode;
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../generated/sora/leak/v1/leak.pb.dart';
import '../sora.dart';
import 'kit.dart';

/// Resolves a core-provided check label key such as "dnsLeak.check.tunnelDns".
/// Unknown keys fall through as-is so a newer core never renders a blank row.
String _leakLabel(S s, String key) => switch (key) {
      'dnsLeak.check.tunnelDns' => s.dnsLeakCheckTunnelDns,
      'dnsLeak.check.systemResolvers' => s.dnsLeakCheckSystemResolvers,
      'dnsLeak.check.killSwitchDns' => s.dnsLeakCheckKillSwitchDns,
      _ => key,
    };

/// Resolves a core-provided fix hint key such as "dnsLeak.fix.enableKillSwitch".
String _leakHint(S s, String key) => switch (key) {
      'dnsLeak.fix.configureTunnelDns' => s.dnsLeakFixConfigureTunnelDns,
      'dnsLeak.fix.reviewSystemResolvers' => s.dnsLeakFixReviewSystemResolvers,
      'dnsLeak.fix.enableKillSwitch' => s.dnsLeakFixEnableKillSwitch,
      _ => key,
    };

/// Maps a fix-hint key to the one-tap autofix the UI can apply, or null when
/// the hint is guidance only and has no safe automatic fix.
String? _fixAction(String fixHint) => switch (fixHint) {
      'dnsLeak.fix.enableKillSwitch' => 'killSwitch',
      _ => null,
    };

/// Leak-test screen: runs the core's RunLeakTests stream against the active
/// session and renders one row per test as results arrive.
///
/// States: idle (intro + run button), running (live progress + cancel),
/// done (summary + rows with autofix buttons), error (a neutral localized
/// note via [CoreFailure], never a raw error). A cancelled run keeps its
/// partial results; cancelling is a user action, not a failure.
class LeakTestScreen extends StatefulWidget {
  const LeakTestScreen({super.key});

  @override
  State<LeakTestScreen> createState() => _LeakTestScreenState();
}

class _LeakTestScreenState extends State<LeakTestScreen> {
  bool _running = false;
  bool _needsConnection = false;
  CoreFailure? _failure;

  /// Results collected so far, in arrival order.
  List<LeakTestResult> _results = const [];

  /// Expected test count from the started event; 0 until it arrives.
  int _total = 0;

  /// True once the finished event arrived (as opposed to a cancelled run).
  bool _finished = false;
  bool _allPassed = false;

  /// Check ids the user already fixed: their rows show a confirmation note
  /// instead of the fix button.
  final Set<String> _fixed = {};

  ResponseStream<LeakTestEvent>? _call;

  @override
  void dispose() {
    unawaited(_call?.cancel());
    super.dispose();
  }

  Future<void> _run() async {
    if (_running) return;
    final sora = SoraScope.read(context);
    if (sora.phase != Phase.connected) {
      setState(() {
        _needsConnection = true;
        _failure = null;
        _results = [];
        _total = 0;
        _finished = false;
        _allPassed = false;
        _fixed.clear();
      });
      return;
    }
    final link = sora.link, id = sora.sessionId;
    if (link == null || id == null) {
      setState(() {
        _needsConnection = false;
        _failure = CoreFailure.unavailable;
      });
      return;
    }
    setState(() {
      _running = true;
      _needsConnection = false;
      _failure = null;
      _results = [];
      _total = 0;
      _finished = false;
      _allPassed = false;
      _fixed.clear();
    });
    try {
      final call = _call = link.leak.runLeakTests(
        RunLeakTestsRequest(apiVersion: apiVersion, controlAuthenticator: link.token, sessionId: id),
      );
      await for (final event in call) {
        if (!mounted) break;
        final now = SoraScope.read(context);
        // The session changed mid-run: the results belong to a dead session.
        if (link != now.link || id != now.sessionId) throw CoreFailure.unavailable;
        switch (event.whichPayload()) {
          case LeakTestEvent_Payload.started:
            setState(() => _total = event.started.total);
          case LeakTestEvent_Payload.result:
            setState(() => _results = [..._results, event.result]);
          case LeakTestEvent_Payload.finished:
            final done = event.finished;
            if (done.hasError()) throw CoreFailure(done.error.userMessageKey);
            setState(() {
              _finished = true;
              _allPassed = done.allPassed;
            });
          case LeakTestEvent_Payload.notSet:
            break;
        }
      }
    } catch (error) {
      // Cancelling is a user action, not a failure: partial results stay.
      final cancelled = error is GrpcError && error.code == StatusCode.cancelled;
      if (!cancelled && mounted) {
        setState(() {
          // A core that predates the leak service reports UNIMPLEMENTED;
          // that is a version mismatch, not an internal error.
          _failure = error is GrpcError && error.code == StatusCode.unimplemented
              ? const CoreFailure('core.api.version_mismatch')
              : CoreFailure.from(error);
        });
      }
    } finally {
      _call = null;
      if (mounted) setState(() => _running = false);
    }
  }

  void _cancel() => unawaited(_call?.cancel());

  /// Applies the one-tap autofix for a failed check. Only the kill switch
  /// has a safe automatic fix; everything else stays guidance text.
  Future<void> _fix(LeakTestResult result) async {
    if (_running || _fixed.contains(result.id)) return;
    if (_fixAction(result.fixHint) != 'killSwitch') return;
    final sora = SoraScope.read(context);
    if (sora.settings.killSwitch) return;
    await sora.setKillSwitch(true);
    if (!mounted) return;
    setState(() => _fixed.add(result.id));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Screen(
      title: s.leakTestTitle,
      children: [
        Group(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(s.leakTestIntro, style: Styles.secondary.copyWith(color: Palette.of(context).ink2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: PrimaryButton(
                label: _running ? s.leakTestCancel : s.leakTestRun,
                onTap: _running ? _cancel : _run,
              ),
            ),
          ],
        ),
        if (_running) _progress(context),
        if (_needsConnection) _note(context, Symbols.info_rounded, s.leakTestNeedsConnection),
        if (_failure != null) _note(context, Symbols.info_rounded, describe(s, _failure!)),
        if (_finished || _results.isNotEmpty) _report(context),
      ],
    );
  }

  Widget _progress(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final text = _total > 0 ? s.leakTestProgress(_results.length, _total) : s.leakTestRunning;
    return Group(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CupertinoActivityIndicator(color: palette.ink),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: Styles.secondary.copyWith(color: palette.ink2))),
            ],
          ),
        ),
      ],
    );
  }

  /// A neutral note: info, not an error. Failures are localized through
  /// [describe] and never shown raw or in red.
  Widget _note(BuildContext context, IconData icon, String text) {
    final palette = Palette.of(context);
    return Group(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: palette.ink2),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: Styles.secondary.copyWith(color: palette.ink2))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _report(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final failed = [for (final r in _results) if (!r.passed) r];
    final clean = _finished && failed.isEmpty;
    return Group(
      children: [
        if (_finished)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Icon(
                  clean ? Symbols.check_circle_rounded : Symbols.warning_rounded,
                  size: 22,
                  color: palette.ink,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    clean ? s.leakTestAllClear : s.leakTestFound(failed.length),
                    style: Styles.bodyStrong.copyWith(color: palette.ink),
                  ),
                ),
              ],
            ),
          ),
        for (final result in _results) _resultRow(context, result),
        const SizedBox(height: 8),
      ],
    );
  }

  /// One test: status icon, title, observed values, the fix hint, and the
  /// one-tap fix button where an autofix exists. Pass is a calm accent,
  /// fail is a warning icon in calm ink — never red.
  Widget _resultRow(BuildContext context, LeakTestResult result) {
    final s = S.of(context);
    final sora = SoraScope.of(context);
    final palette = Palette.of(context);
    final failed = !result.passed;
    final canFix = _fixAction(result.fixHint) == 'killSwitch' &&
        !_running &&
        !_fixed.contains(result.id) &&
        !sora.settings.killSwitch;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(44, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                failed ? Symbols.warning_rounded : Symbols.check_circle_rounded,
                size: 16,
                color: palette.ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _leakLabel(s, result.label),
                  style: Styles.body.copyWith(color: palette.ink),
                ),
              ),
            ],
          ),
          if (result.expected.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 2),
              child: Text(
                '${s.leakTestExpected}: ${result.expected}',
                style: Styles.caption.copyWith(color: palette.ink2),
              ),
            ),
          if (result.actual.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 2),
              child: Text(
                '${s.leakTestActual}: ${result.actual}',
                style: Styles.caption.copyWith(color: palette.ink2),
              ),
            ),
          if (result.fixHint.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Symbols.info_rounded, size: 14, color: palette.ink2),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _leakHint(s, result.fixHint),
                      style: Styles.caption.copyWith(color: palette.ink2),
                    ),
                  ),
                ],
              ),
            ),
          if (canFix)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 8),
              child: _FixButton(onTap: () => unawaited(_fix(result))),
            )
          else if (_fixed.contains(result.id))
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Symbols.check_circle_rounded, size: 14, color: palette.ink2),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.leakTestFixedNote,
                      style: Styles.caption.copyWith(color: palette.ink2),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact tonal action button for a row-level autofix, echoing
/// [PrimaryButton] at a smaller size.
class _FixButton extends StatelessWidget {
  const _FixButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    return Pressable(
      onTap: onTap,
      radius: 18,
      wash: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: palette.ink, borderRadius: BorderRadius.circular(18)),
        child: Text(s.leakTestFix, style: Styles.bodyStrong.copyWith(color: palette.surface)),
      ),
    );
  }
}
