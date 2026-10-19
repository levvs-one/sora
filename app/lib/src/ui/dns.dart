import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../sora.dart';
import 'kit.dart';
import 'subscription_sheet.dart';

/// Fixed resolver lists for the built-in presets. `auto` keeps the core
/// defaults (empty list); `custom` edits [Settings.dns] directly.
const _presets = <String, List<String>>{
  'cloudflare': ['1.1.1.1', '1.0.0.1'],
  'google': ['8.8.8.8', '8.8.4.4'],
  'quad9': ['9.9.9.9', '149.112.112.112'],
  'adguard': ['94.140.14.14', '94.140.15.15'],
};

/// One leak check result. [detail] is a human-readable, non-technical note.
class DnsLeakCheck {
  const DnsLeakCheck({required this.label, required this.leaked, this.detail = ''});

  final String label;
  final bool leaked;
  final String detail;
}

/// Outcome of a leak check run. [available] is false while the core does not
/// expose the check yet; the UI shows a friendly note instead of an error.
class DnsLeakReport {
  const DnsLeakReport.unavailable() : checks = const [], available = false;
  const DnsLeakReport(this.checks) : available = true;

  final bool available;
  final List<DnsLeakCheck> checks;

  bool get leaked => checks.any((c) => c.leaked);
}

/// Runs the DNS leak check.
///
/// Backend note: wire this to the `CheckDnsLeaks` core RPC once it exists;
/// the screen is built against this interface so only this function changes.
Future<DnsLeakReport> checkDnsLeaks(Sora sora) async {
  // Core RPC not implemented yet — report unavailability, never a raw error.
  return const DnsLeakReport.unavailable();
}

/// DNS manager: resolver presets, custom list and leak checking.
class DnsScreen extends StatefulWidget {
  const DnsScreen({super.key});

  @override
  State<DnsScreen> createState() => _DnsScreenState();
}

class _DnsScreenState extends State<DnsScreen> {
  static final _resolver = RegExp(r'^[A-Za-z0-9\[\]:._/-]+$');

  bool _checking = false;
  DnsLeakReport? _report;

  Future<void> _applyPreset(String id) async {
    final sora = SoraScope.read(context);
    await sora.change((x) {
      x.dnsPreset = id;
      x.dns = switch (id) {
        'auto' => const [],
        'custom' => x.dns,
        _ => _presets[id] ?? const [],
      };
    });
  }

  void _editCustom() {
    final s = S.of(context);
    final sora = SoraScope.read(context);
    unawaited(
      showFieldSheet(
        context,
        title: s.dns,
        hint: s.dnsHint,
        action: s.save,
        initial: sora.settings.dns.join(', '),
        allowEmpty: true,
        submit: (value) async {
          final parts = [for (final p in value.split(RegExp(r'[,\s]+'))) if (p.isNotEmpty) p];
          if (parts.any((p) => !_resolver.hasMatch(p))) return s.invalidValue;
          await sora.change((x) {
            x.dnsPreset = 'custom';
            x.dns = parts;
          });
          return null;
        },
      ),
    );
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _report = null;
    });
    final report = await checkDnsLeaks(SoraScope.read(context));
    if (!mounted) return;
    if (report.available) {
      SoraScope.read(context).settings.dnsLeakLastCheck = DateTime.now().millisecondsSinceEpoch;
    }
    setState(() {
      _checking = false;
      _report = report;
    });
  }

  /// Applies the tunnel DNS again and re-runs the check.
  Future<void> _fix() async {
    final sora = SoraScope.read(context);
    final preset = sora.settings.dnsPreset;
    await sora.change((x) {
      x.dns = preset == 'auto' ? const [] : preset == 'custom' ? x.dns : _presets[preset] ?? const [];
    });
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final settings = sora.settings;
    final s = S.of(context);
    final palette = Palette.of(context);
    final last = settings.dnsLeakLastCheck;
    return Screen(
      title: s.dns,
      children: [
        Group(
          children: [
            ChoiceTile<String>(
              title: s.dnsPreset,
              value: settings.dnsPreset,
              choices: {
                'auto': s.dnsAuto,
                'cloudflare': s.dnsPresetCloudflare,
                'google': s.dnsPresetGoogle,
                'quad9': s.dnsPresetQuad9,
                'adguard': s.dnsPresetAdGuard,
                'custom': s.dnsPresetCustom,
              },
              onChanged: _applyPreset,
            ),
            if (settings.dnsPreset == 'custom')
              LinkTile(
                title: s.dns,
                value: settings.dns.isEmpty ? s.dnsAuto : settings.dns.join(', '),
                onTap: _editCustom,
              )
            else if (settings.dnsPreset != 'auto')
              Tile(
                title: s.dns,
                detail: (_presets[settings.dnsPreset] ?? const []).join(', '),
              ),
          ],
        ),
        Group(
          children: [
            Tile(
              title: s.dnsLastCheck,
              detail: last == 0 ? s.dnsNeverChecked : DateTime.fromMillisecondsSinceEpoch(last).toLocal().toString(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: PrimaryButton(
                label: s.dnsCheck,
                busy: _checking,
                onTap: _checking ? null : _check,
              ),
            ),
          ],
        ),
        if (_checking)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                CupertinoActivityIndicator(color: palette.ink),
                const SizedBox(height: 12),
                Text(s.dnsChecking, style: Styles.secondary.copyWith(color: palette.ink2)),
              ],
            ),
          )
        else if (_report != null)
          _result(context, _report!),
      ],
    );
  }

  Widget _result(BuildContext context, DnsLeakReport report) {
    final s = S.of(context);
    final palette = Palette.of(context);
    if (!report.available) {
      return Group(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Symbols.info_rounded, size: 18, color: palette.ink2),
                const SizedBox(width: 10),
                Expanded(child: Text(s.dnsCheckPending, style: Styles.secondary.copyWith(color: palette.ink2))),
              ],
            ),
          ),
        ],
      );
    }
    final leaked = report.leaked;
    return Group(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Icon(
                leaked ? Symbols.warning_rounded : Symbols.check_circle_rounded,
                size: 22,
                color: palette.ink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  leaked ? s.dnsLeakFound : s.dnsNoLeak,
                  style: Styles.bodyStrong.copyWith(color: palette.ink),
                ),
              ),
            ],
          ),
        ),
        for (final check in report.checks)
          Padding(
            padding: const EdgeInsets.fromLTRB(44, 6, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      check.leaked ? Symbols.warning_rounded : Symbols.check_circle_rounded,
                      size: 16,
                      color: palette.ink2,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(check.label, style: Styles.body.copyWith(color: palette.ink))),
                  ],
                ),
                if (check.detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Text(check.detail, style: Styles.caption.copyWith(color: palette.ink2)),
                  ),
              ],
            ),
          ),
        if (leaked)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: PrimaryButton(label: s.dnsFix, onTap: _fix),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }
}
