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

/// Resolves a core-provided test label key such as "leakTest.check.directDns".
/// Unknown keys fall through as-is so a newer core never renders a blank row.
String _testLabel(S s, String key) => switch (key) {
      'leakTest.check.directDns' => s.leakTestCheckDirectDns,
      'leakTest.check.ipv6' => s.leakTestCheckIpv6,
      'leakTest.check.icmpEcho' => s.leakTestCheckIcmpEcho,
      'leakTest.check.systemResolvers' => s.leakTestCheckSystemResolvers,
      _ => key,
    };

/// Test ids whose failure the kill switch directly mitigates: the core
/// reports them as "kill switch disarmed, so nothing blocks it". The button
/// is only offered while the kill switch is disarmed; an armed kill switch
/// that still leaks is a firewall failure, not a setting to flip.
bool _killSwitchFixApplies(LeakTestResult result, bool killSwitchOn) =>
    !result.pass && !killSwitchOn && (result.test.id == 'direct-dns' || result.test.id == 'icmp-echo');

/// Leak-test screen: runs the core's RunLeakTests stream against the active
/// session and renders one row per test as results arrive.
///
/// States: idle (intro + run button), running (live progress + cancel),
/// done (summary + rows with the kill-switch autofix where it applies),
/// error (a neutral localized note via [CoreFailure], never a raw error).
/// A cancelled run keeps its partial results; cancelling is a user action,
/// not a failure.
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

  /// True once the stream closed normally (as opposed to a cancelled run).
  bool _finished = false;

  /// Test ids the user already fixed: their rows show a confirmation note
  /// instead of the fix button.
  final Set<String> _fixed = {};

  ResponseStream<LeakTestResult>? _call;

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
        _finished = false;
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
      _finished = false;
      _fixed.clear();
    });
    try {
      final call = _call = link.leak.runLeakTests(
        RunLeakTestsRequest(apiVersion: apiVersion, controlAuthenticator: link.token, sessionId: id),
      );
      await for (final result in call) {
        if (!mounted) break;
        final now = SoraScope.read(context);
        // The session changed mid-run: the results belong to a dead session.
        if (link != now.link || id != now.sessionId) throw CoreFailure.unavailable;
        setState(() => _results = [..._results, result]);
      }
      // The stream closed normally: the suite is done.
      if (mounted) setState(() => _finished = true);
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

  /// Arms the kill switch as the one-tap fix for a failed direct probe.
  Future<void> _fix(LeakTestResult result) async {
    if (_running || _fixed.contains(result.test.id)) return;
    final sora = SoraScope.read(context);
    if (!_killSwitchFixApplies(result, sora.settings.killSwitch)) return;
    await sora.setKillSwitch(true);
    if (!mounted) return;
    setState(() => _fixed.add(result.test.id));
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
        if (_results.isNotEmpty) _report(context),
      ],
    );
  }

  /// Live progress: the core streams bare results with no total, so the
  /// honest progress is the completed count, not a fraction.
  Widget _progress(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    return Group(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CupertinoActivityIndicator(color: palette.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.leakTestProgress(_results.length),
                  style: Styles.secondary.copyWith(color: palette.ink2),
                ),
              ),
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
    final failed = [for (final r in _results) if (!r.pass) r];
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

  /// One test: status icon, title, what the probe observed, and the one-tap
  /// fix where it applies. Pass is a calm accent, fail is a warning icon in
  /// calm ink — never red. A skipped test passes by definition but is marked
  /// so it is never mistaken for a verified pass.
  Widget _resultRow(BuildContext context, LeakTestResult result) {
    final s = S.of(context);
    final sora = SoraScope.of(context);
    final palette = Palette.of(context);
    final failed = !result.pass;
    final canFix = _killSwitchFixApplies(result, sora.settings.killSwitch) &&
        !_running &&
        !_fixed.contains(result.test.id);
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
                  _testLabel(s, result.test.label),
                  style: Styles.body.copyWith(color: palette.ink),
                ),
              ),
            ],
          ),
          if (result.details.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 2),
              child: Text(
                result.details,
                style: Styles.caption.copyWith(color: palette.ink2),
              ),
            ),
          if (result.skipped)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Symbols.info_rounded, size: 14, color: palette.ink2),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.leakTestSkipped,
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
          else if (_fixed.contains(result.test.id))
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
