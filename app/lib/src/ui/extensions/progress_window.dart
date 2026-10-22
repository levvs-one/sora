import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/strings.dart';
import '../../design/theme.dart';

enum InstallStage { download, verify, install }

class InstallProgressWindow extends StatelessWidget {
  const InstallProgressWindow({super.key, required this.stage, this.received = 0, this.total, this.onCancel});

  final InstallStage stage;
  final int received;
  final int? total;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final downloading = stage == InstallStage.download;
    final fraction = downloading && total != null && total! > 0 ? (received / total!).clamp(0.0, 1.0) : null;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final label = switch (stage) {
      InstallStage.download => s.extDownloading,
      InstallStage.verify => s.extVerifying,
      InstallStage.install => s.extInstalling,
    };
    final amount = fraction != null
        ? NumberFormat.percentPattern(locale).format(fraction)
        : s.extReceivedBytes(NumberFormat.decimalPattern(locale).format(received));
    return Dialog(
      constraints: const BoxConstraints(maxWidth: 320),
      backgroundColor: palette.raised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        key: const ValueKey('extension-progress-surface'),
        width: 320,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Motion.of(context, Motion.fast),
                      switchInCurve: Motion.curve,
                      switchOutCurve: Motion.curve,
                      layoutBuilder: (child, previous) =>
                          Stack(alignment: AlignmentDirectional.centerStart, children: [...previous, ?child]),
                      child: Text(
                        label,
                        key: ValueKey(stage),
                        style: Styles.bodyStrong.copyWith(fontSize: 14, color: palette.ink),
                      ),
                    ),
                  ),
                  if (downloading) ...[
                    const SizedBox(width: 12),
                    Text(amount, style: Styles.figures(Styles.bodyStrong).copyWith(fontSize: 13, color: palette.ink)),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TweenAnimationBuilder<double>(
                tween: Tween(end: fraction ?? 0),
                duration: Motion.of(context, Motion.fast),
                curve: Motion.curve,
                builder: (context, value, _) => TickerMode(
                  enabled: Motion.enabled(context),
                  child: LinearProgressIndicator(
                    value: fraction == null ? null : value,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                    color: palette.ink,
                    backgroundColor: palette.raisedField,
                    semanticsLabel: label,
                    semanticsValue: downloading ? amount : null,
                  ),
                ),
              ),
              if (downloading && onCancel != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: palette.ink2, textStyle: Styles.secondary),
                    onPressed: onCancel,
                    child: Text(s.extCancel),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps permission approval on the same route as progress, so neither
/// stage changes nor approval can stack backdrops or pop the caller's page.
class ExtensionInstallDialog {
  ExtensionInstallDialog(BuildContext context, Widget initial)
    : _content = ValueNotifier(initial),
      _navigator = Navigator.of(context, rootNavigator: true) {
    _route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Palette.of(context).scrim,
      builder: (_) => PopScope(
        canPop: false,
        child: ValueListenableBuilder<Widget>(valueListenable: _content, builder: (_, child, _) => child),
      ),
    );
    _navigator.push(_route);
  }

  final ValueNotifier<Widget> _content;
  final NavigatorState _navigator;
  late final DialogRoute<void> _route;
  Future<void>? _closing;

  void show(Widget child) {
    if (_closing == null) _content.value = child;
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    if (_route.isActive) {
      if (_route.isCurrent) {
        _navigator.pop();
      } else {
        _navigator.removeRoute(_route);
      }
    }
    await _route.completed;
    _content.dispose();
  }
}
