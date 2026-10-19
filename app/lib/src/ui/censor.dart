import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/censor.dart';
import '../design/theme.dart';
import '../profiles.dart';
import '../sora.dart';
import 'kit.dart';

/// Explains a detector reason code in human language. Unknown codes fall
/// through to the core-provided detail so a newer core never renders a
/// blank row.
String _reasonText(S s, CensorReason reason) => switch (reason.code) {
  'tls.reset' => s.censorReasonTlsReset,
  'dns.spoofed' => s.censorReasonDnsSpoofed,
  'http.block' => s.censorReasonHttpBlock,
  'connect.timeout' => s.censorReasonConnectTimeout,
  _ => reason.detail.isNotEmpty ? reason.detail : reason.code,
};

String _kindLabel(S s, CensorVerdictKind kind) => switch (kind) {
  CensorVerdictKind.blocked => s.censorKindBlocked,
  CensorVerdictKind.likelyBlocked => s.censorKindLikely,
  CensorVerdictKind.notBlocked => s.censorKindClear,
  CensorVerdictKind.unknown => s.censorKindUnknown,
};

/// "Blocking diagnostics": detector verdict history, human-readable reasons
/// and one-tap application of the recommended masking profile.
///
/// Calm by design: neutral ink tones, no alarming colours.
class CensorScreen extends StatelessWidget {
  const CensorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    return ListenableBuilder(
      listenable: sora.censor,
      builder: (context, _) {
        final history = sora.censor.history;
        return Screen(
          title: s.censorTitle,
          children: [
            if (history.isEmpty)
              const _EmptyState()
            else ...[
              _VerdictCard(verdict: history.first),
              if (history.length > 1) ...[
                Heading(s.censorHistory),
                Group(children: [for (final verdict in history.skip(1)) _HistoryRow(verdict: verdict)]),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(Symbols.shield_rounded, size: 40, color: palette.ink3),
          const SizedBox(height: 16),
          Text(s.censorEmpty, textAlign: TextAlign.center, style: Styles.secondary.copyWith(color: palette.ink2)),
        ],
      ),
    );
  }
}

/// The latest verdict: kind, confidence, human-readable reasons and the
/// recommended profile action.
class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.verdict});

  final CensorVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final sora = SoraScope.of(context);
    final actionable = verdict.actionable;
    final profile = verdict.recommendedProfileId.isEmpty ? null : sora.profiles.byId(verdict.recommendedProfileId);
    return Group(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              // A warning here is informational, never an error: calm ink,
              // no red anywhere on this screen.
              Icon(
                actionable ? Symbols.warning_rounded : Symbols.check_circle_rounded,
                size: 22,
                color: palette.ink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_kindLabel(s, verdict.kind), style: Styles.bodyStrong.copyWith(color: palette.ink)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.censorConfidence(verdict.confidence), style: Styles.secondary.copyWith(color: palette.ink2)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: verdict.confidence / 100,
                  minHeight: 6,
                  backgroundColor: palette.field,
                  valueColor: AlwaysStoppedAnimation<Color>(palette.ink2),
                ),
              ),
            ],
          ),
        ),
        for (final reason in verdict.reasons)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Symbols.info_rounded, size: 16, color: palette.ink3),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_reasonText(s, reason), style: Styles.body.copyWith(color: palette.ink))),
              ],
            ),
          ),
        if (actionable)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(s.censorExplainer, style: Styles.secondary.copyWith(color: palette.ink2)),
          ),
        if (actionable)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: profile == null
                ? Text(s.censorNoProfile, style: Styles.secondary.copyWith(color: palette.ink2))
                : _ApplyButton(profile: profile),
          ),
      ],
    );
  }
}

class _ApplyButton extends StatefulWidget {
  const _ApplyButton({required this.profile});

  final NetworkProfile profile;

  @override
  State<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends State<_ApplyButton> {
  bool _busy = false;

  Future<void> _apply() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sora = SoraScope.read(context);
      // Posts its own notification with an undo action.
      await sora.applyProfileWithUndo(widget.profile);
      sora.censor.dismissPrompt();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    return FilledButton.icon(
      onPressed: _busy ? null : () => unawaited(_apply()),
      icon: _busy
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: palette.surface),
            )
          : const Icon(Symbols.shield_rounded, size: 18),
      label: Text(s.censorApplyProfile),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: palette.ink,
        foregroundColor: palette.surface,
        textStyle: Styles.secondary.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.verdict});

  final CensorVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Icon(
            verdict.actionable ? Symbols.warning_rounded : Symbols.check_circle_rounded,
            size: 18,
            color: palette.ink2,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_kindLabel(s, verdict.kind), style: Styles.body.copyWith(color: palette.ink)),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('dd.MM.yyyy  HH:mm').format(verdict.detectedAt.toLocal())} · ${s.censorConfidence(verdict.confidence)}',
                  style: Styles.caption.copyWith(color: palette.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The friendly verdict prompt: "looks like the provider is blocking…
/// try masking?" with Enable / Details / Not now.
///
/// A calm centered dialog following the app's [confirm] idiom — no alarming
/// colours, no exclamation.
Future<void> showCensorPrompt(BuildContext context, Sora sora, CensorVerdict verdict) async {
  final profile =
      verdict.recommendedProfileId.isEmpty ? null : sora.profiles.byId(verdict.recommendedProfileId);
  final action = await _promptDialog(context, verdict: verdict, profile: profile);
  if (action == 'enable' && profile != null) {
    // Posts its own notification with an undo action; the prompt itself is
    // dismissed by the host.
    await sora.applyProfileWithUndo(profile);
  } else if (action == 'details' && context.mounted) {
    unawaited(push<void>(context, const CensorScreen()));
  }
}

Future<String?> _promptDialog(BuildContext context, {required CensorVerdict verdict, NetworkProfile? profile}) {
  final s = S.of(context);
  final palette = Palette.of(context);
  return showGeneralDialog<String>(
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
    pageBuilder: (dialogContext, _, _) => Center(
      child: Material(
        color: palette.raised,
        elevation: 0,
        shadowColor: palette.shadow,
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          width: 340,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Symbols.warning_rounded, size: 28, color: palette.ink),
                const SizedBox(height: 12),
                Text(
                  s.censorPromptTitle,
                  textAlign: TextAlign.center,
                  style: Styles.bodyStrong.copyWith(color: palette.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  s.censorPromptBody(verdict.confidence),
                  textAlign: TextAlign.center,
                  style: Styles.secondary.copyWith(color: palette.ink2),
                ),
                const SizedBox(height: 20),
                if (profile != null)
                  _DialogAction(label: s.censorEnable, primary: true, onTap: () => Navigator.of(dialogContext).pop('enable'))
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      s.censorNoProfile,
                      textAlign: TextAlign.center,
                      style: Styles.secondary.copyWith(color: palette.ink2),
                    ),
                  ),
                _DialogAction(label: s.censorDetails, onTap: () => Navigator.of(dialogContext).pop('details')),
                _DialogAction(label: s.censorNotNow, onTap: () => Navigator.of(dialogContext).pop()),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({required this.label, required this.onTap, this.primary = false});

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Pressable(
      onTap: onTap,
      radius: 26,
      wash: false,
      child: Container(
        // minHeight keeps large text scales from clipping the label.
        constraints: const BoxConstraints(minHeight: 52),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? palette.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: (primary ? Styles.bodyStrong : Styles.body).copyWith(color: primary ? palette.raised : palette.ink),
        ),
      ),
    );
  }
}

/// App-wide host for the verdict prompt: shows [showCensorPrompt] when
/// [CensorDetector.prompt] appears. Mounted once, next to [NotificationToasts]
/// in main.dart.
class CensorPromptHost extends StatefulWidget {
  const CensorPromptHost({super.key, required this.sora, required this.navigator, required this.child});

  final Sora sora;
  final GlobalKey<NavigatorState> navigator;
  final Widget child;

  @override
  State<CensorPromptHost> createState() => _CensorPromptHostState();
}

class _CensorPromptHostState extends State<CensorPromptHost> {
  bool _showing = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    widget.sora.censor.addListener(_maybeShow);
  }

  @override
  void dispose() {
    widget.sora.censor.removeListener(_maybeShow);
    super.dispose();
  }

  /// Schedules the prompt for the next frame: verdicts arrive from async
  /// event handlers, but never assume this isn't a build.
  void _maybeShow() {
    if (_showing || _scheduled || widget.sora.censor.prompt == null) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _showNow();
    });
  }

  void _showNow() {
    if (_showing) return;
    final prompt = widget.sora.censor.prompt;
    final context = widget.navigator.currentState?.overlay?.context;
    if (prompt == null || context == null) return;
    _showing = true;
    unawaited(
      showCensorPrompt(context, widget.sora, prompt).whenComplete(() {
        _showing = false;
        // Only clear if nothing newer arrived while the dialog was open.
        if (widget.sora.censor.prompt?.id == prompt.id) widget.sora.censor.dismissPrompt();
        _maybeShow();
      }),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
