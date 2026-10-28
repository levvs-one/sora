import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../generated/sora/core/v1/core_control.pb.dart';
import '../sora.dart';
import 'kit.dart';
import 'leaktest.dart';
import 'subscription_sheet.dart';

/// Fixed resolver lists for the built-in presets. `auto` keeps the core
/// defaults (empty list); `custom` edits [Settings.dns] directly.
///
/// Every preset speaks DoH: the presets used to carry bare IPs, which the
/// core parses as plaintext UDP/53, so picking the "Cloudflare" preset
/// silently *downgraded* the user below the encrypted `auto` default the
/// docs promise (usage.md "DNS по умолчанию"). Cloudflare and Google are
/// IP-addressed, like the core defaults, so they need no bootstrap;
/// Quad9 and AdGuard publish hostname DoH endpoints, which the engines
/// resolve through their bootstrap resolver (user queries still travel
/// encrypted; only the endpoint's own name is resolved plainly).
const _presets = <String, List<String>>{
  'cloudflare': ['https://1.1.1.1/dns-query', 'https://1.0.0.1/dns-query'],
  'google': ['https://8.8.8.8/dns-query', 'https://8.8.4.4/dns-query'],
  'quad9': ['https://dns.quad9.net/dns-query'],
  'adguard': ['https://dns.adguard-dns.com/dns-query'],
};

/// Resolves a core-provided localization key such as "dnsLeak.check.tunnelDns".
/// Unknown keys fall through as-is so a newer core never renders a blank row.
String _checkLabel(S s, String key) => switch (key) {
  'dnsLeak.check.tunnelDns' => s.dnsLeakCheckTunnelDns,
  'dnsLeak.check.systemResolvers' => s.dnsLeakCheckSystemResolvers,
  'dnsLeak.check.encryptedDns' => s.dnsLeakCheckEncryptedDns,
  'dnsLeak.check.killSwitchDns' => s.dnsLeakCheckKillSwitchDns,
  'dnsLeak.check.dnsSpoof' => s.dnsLeakCheckDnsSpoof,
  _ => key,
};

/// Resolves a core-provided fix hint key such as "dnsLeak.fix.enableKillSwitch".
String _checkHint(S s, String key) => switch (key) {
  'dnsLeak.fix.configureTunnelDns' => s.dnsLeakFixConfigureTunnelDns,
  'dnsLeak.fix.reviewSystemResolvers' => s.dnsLeakFixReviewSystemResolvers,
  'dnsLeak.fix.reviewEncryptedDns' => s.dnsLeakFixReviewEncryptedDns,
  'dnsLeak.fix.enableKillSwitch' => s.dnsLeakFixEnableKillSwitch,
  'dnsLeak.fix.useEncryptedDns' => s.dnsLeakFixUseEncryptedDns,
  _ => key,
};

/// DNS manager: resolver presets, custom list and leak checking.
class DnsScreen extends StatefulWidget {
  const DnsScreen({super.key});

  @override
  State<DnsScreen> createState() => _DnsScreenState();
}

class _DnsScreenState extends State<DnsScreen> {
  static final _resolver = RegExp(r'^[A-Za-z0-9\[\]:._/-]+$');

  bool _checking = false;
  List<DnsLeakCheck>? _checks;
  CoreFailure? _failure;
  bool _needsConnection = false;

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
          final parts = [
            for (final p in value.split(RegExp(r'[,\s]+')))
              if (p.isNotEmpty) p,
          ];
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
    final sora = SoraScope.read(context);
    if (sora.phase != Phase.connected) {
      setState(() {
        _checks = null;
        _failure = null;
        _needsConnection = true;
      });
      return;
    }
    setState(() {
      _checking = true;
      _checks = null;
      _failure = null;
      _needsConnection = false;
    });
    final result = await sora.checkDnsLeaks();
    if (!mounted) return;
    if (result.failure == null) {
      sora.settings.dnsLeakLastCheck = DateTime.now().millisecondsSinceEpoch;
    }
    setState(() {
      _checking = false;
      _checks = result.checks;
      _failure = result.failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final settings = sora.settings;
    final s = S.of(context);
    final palette = Palette.of(context);
    final last = settings.dnsLeakLastCheck;
    final locale = Localizations.localeOf(context).languageCode;
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
              Tile(title: s.dns, detail: (_presets[settings.dnsPreset] ?? const []).join(', ')),
          ],
        ),
        Group(
          children: [
            Tile(
              title: s.dnsLastCheck,
              detail: last == 0
                  ? s.dnsNeverChecked
                  : DateFormat.yMMMd(locale).add_Hm().format(DateTime.fromMillisecondsSinceEpoch(last).toLocal()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: PrimaryButton(label: s.dnsCheck, busy: _checking, onTap: _checking ? null : _check),
            ),
            LinkTile(title: s.leakTestTitle, onTap: () => push<void>(context, const LeakTestScreen())),
          ],
        ),
        if (_checking)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                CupertinoActivityIndicator(color: palette.ink),
                const SizedBox(height: 12),
                Text(s.dnsChecking, style: Styles.secondary.copyWith(color: palette.ink)),
              ],
            ),
          )
        else if (_needsConnection)
          _note(context, Symbols.info_rounded, s.dnsCheckNeedsConnection)
        else if (_failure != null)
          _note(context, Symbols.info_rounded, describe(s, _failure!))
        else if (_checks != null)
          _report(context, _checks!),
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
              Expanded(
                child: Text(text, style: Styles.secondary.copyWith(color: palette.ink)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _report(BuildContext context, List<DnsLeakCheck> checks) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final leaked = checks.any((c) => c.leaked);
    return Group(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Icon(leaked ? Symbols.warning_rounded : Symbols.check_circle_rounded, size: 22, color: palette.ink),
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
        for (final check in checks) _checkRow(context, check),
        const SizedBox(height: 8),
      ],
    );
  }

  /// One check: label, observed values, and the fix hint. A hint on a
  /// non-leaking check is a warning (warning icon, calm ink), never an error.
  Widget _checkRow(BuildContext context, DnsLeakCheck check) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final hasHint = check.fixHint.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(44, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                check.leaked || hasHint ? Symbols.warning_rounded : Symbols.check_circle_rounded,
                size: 16,
                color: check.leaked ? palette.ink : palette.ink2,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_checkLabel(s, check.label), style: Styles.body.copyWith(color: palette.ink)),
              ),
            ],
          ),
          if (check.expected.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 2),
              child: Text('${s.dnsExpected}: ${check.expected}', style: Styles.caption.copyWith(color: palette.ink2)),
            ),
          if (check.actual.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 2),
              child: Text('${s.dnsActual}: ${check.actual}', style: Styles.caption.copyWith(color: palette.ink2)),
            ),
          if (hasHint)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Symbols.info_rounded, size: 14, color: palette.ink2),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_checkHint(s, check.fixHint), style: Styles.caption.copyWith(color: palette.ink)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
