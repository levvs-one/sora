import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../sora.dart';
import 'kit.dart';
import 'subscription_sheet.dart';

Future<void> showModes(BuildContext context) async {
  final navigator = Navigator.of(context);
  final info = await showDialog<bool>(context: context, builder: (_) => const _Modes());
  if (info == true && navigator.mounted) await push<void>(navigator.context, const ModesGuideScreen());
}

/// Consent belongs to the host UI and this app launch, not extension settings.
Future<bool> ensureSystemFilterConsent(BuildContext context, String choice) async {
  final sora = SoraScope.read(context);
  final profile = sora.extensions.bypassProfile(choice);
  if (profile == null || !profile.systemWide) return true;
  final available = sora.bypassProfileAvailable(profile);
  if (available && !sora.needsSystemFilterConsent(choice)) return true;
  final key = sora.systemFilterConsentKey(choice);
  final s = S.of(context), palette = Palette.of(context);
  final accepted = await showDialog<bool>(
    context: context,
    barrierColor: palette.scrim,
    animationStyle: AnimationStyle(
      duration: Motion.of(context, Motion.medium),
      reverseDuration: Motion.of(context, Motion.medium),
    ),
    builder: (context) => AlertDialog(
      key: const ValueKey('system-filter-consent'),
      scrollable: true,
      backgroundColor: palette.raised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      constraints: const BoxConstraints(maxWidth: 420),
      insetPadding: const EdgeInsets.all(24),
      title: Text(profile.name, style: Styles.heading.copyWith(color: palette.ink)),
      content: Text(
        available ? s.winwsScopeWarning : s.winwsRequirements,
        style: Styles.body.copyWith(color: palette.ink, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(available ? s.cancel : s.close, style: Styles.bodyStrong.copyWith(color: palette.ink)),
        ),
        if (available)
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.chooseEngine(profile.name), style: Styles.bodyStrong.copyWith(color: palette.ink)),
          ),
      ],
    ),
  );
  return accepted == true && context.mounted && key != null && sora.approveSystemFilter(choice, key);
}

Future<void> connectFromHome(BuildContext context) async {
  final sora = SoraScope.read(context);
  if (sora.phase == Phase.off && !sora.cleanupPending && sora.servers.isEmpty && !sora.bypassSelected) {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) {
        final s = S.of(context), palette = Palette.of(context);
        return Dialog(
          backgroundColor: palette.raised,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(label: s.addSubscription, onTap: () => Navigator.pop(context, 'subscription')),
                  if (sora.serverlessAvailable) ...[
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => Navigator.pop(context, 'bypass'), child: Text(s.serverBypass)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!context.mounted) return;
    if (choice == 'subscription') await showSubscriptionSheet(context);
    if (choice == 'bypass') {
      await sora.change(
        (x) => x
          ..server = 'bypass'
          ..tunnel = 'tun',
      );
      await sora.connect();
    }
    return;
  }
  if (sora.phase == Phase.off && !await ensureSystemFilterConsent(context, sora.selected)) return;
  await sora.toggle();
}

class ModeButton extends StatelessWidget {
  const ModeButton({super.key});
  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context), s = S.of(context), palette = Palette.of(context);
    final label = sora.bypassSelected
        ? (sora.selected == 'bypass' ? s.serverBypass : sora.displayNameOf(sora.selected))
        : sora.settings.tunnel == 'tun'
        ? 'TUN'
        : s.proxyShort;
    return OutlinedButton(
      key: const ValueKey('mode-button'),
      onPressed: () => showModes(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.ink,
        side: BorderSide(color: palette.ink3.withValues(alpha: .35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(0, 44),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Styles.bodyStrong.copyWith(color: palette.ink),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Symbols.expand_more_rounded, size: 20, weight: 600, color: palette.ink),
        ],
      ),
    );
  }
}

class _Modes extends StatelessWidget {
  const _Modes();
  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context), s = S.of(context), palette = Palette.of(context);
    final settings = sora.settings;
    final current = sora.bypassSelected ? sora.selected : settings.tunnel;
    Widget choice(String key, String title, bool selected, VoidCallback choose, {String? info}) => ListTile(
      key: ValueKey(key),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minTileHeight: 52,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selected: selected,
      selectedTileColor: palette.field,
      title: Row(
        children: [
          Flexible(
            child: Text(title, style: Styles.bodyStrong.copyWith(color: palette.ink)),
          ),
          if (info != null) InfoButton(title: title, description: info),
        ],
      ),
      onTap: choose,
      trailing: SizedBox(
        width: 24,
        child: selected ? Icon(Symbols.check_rounded, size: 22, weight: 700, color: palette.ink) : null,
      ),
    );
    Future<void> mode(String value) async {
      if (sora.extensions.bypassProfile(value) != null) {
        if (!await ensureSystemFilterConsent(context, value) || !context.mounted) return;
        await sora.change((settings) => settings.tunnel = 'tun', replan: false);
        await sora.select(value);
        return;
      }
      await sora.change((x) {
        if (value == 'bypass') {
          x.server = 'bypass';
          x.tunnel = 'tun';
        } else {
          if (sora.bypassSelected) x.server = 'auto';
          x.tunnel = value;
        }
      });
    }

    final routes = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(s.tunnelMode, style: Styles.bodyStrong.copyWith(color: palette.ink)),
        ),
        for (final (value, title) in [
          ('tun', s.tunMode),
          ('proxy', s.tunnelProxy),
          if (sora.serverlessAvailable) ('bypass', s.serverBypass),
          for (final profile in sora.extensions.bypassProfiles) (profile.choiceId, profile.name),
        ])
          choice(
            'mode-$value',
            title,
            current == value,
            () => unawaited(mode(value)),
            info: sora.extensions.bypassProfile(value)?.systemWide == true ? s.winwsScopeWarning : null,
          ),
      ],
    );
    final engines = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(s.engine, style: Styles.bodyStrong.copyWith(color: palette.ink)),
        ),
        for (final (value, title) in [
          ('', s.engineAuto),
          ('sing-box', 'sing-box'),
          ('xray', 'Xray'),
          ('mihomo', 'mihomo'),
        ])
          choice('engine-$value', title, settings.engine == value, () async {
            if (value == 'sing-box' && !settings.controlPort) {
              if (!await confirm(
                context,
                question: s.controlPortQuestion('sing-box'),
                action: s.chooseEngine('sing-box'),
                destructive: false,
              )) {
                return;
              }
              if (!context.mounted) return;
            }
            await sora.change(
              (x) => x
                ..engine = value
                ..controlPort = value == 'sing-box',
            );
          }),
      ],
    );
    return Dialog(
      key: const ValueKey('mode-panel'),
      backgroundColor: palette.raised,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.sizeOf(context).height - 64),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(s.modes, style: Styles.heading.copyWith(color: palette.ink)),
                  ),
                  RoundButton(icon: Symbols.close_rounded, label: s.close, onTap: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (_, constraints) => constraints.maxWidth >= 540
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: routes),
                          const SizedBox(width: 24),
                          Expanded(child: engines),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [routes, const SizedBox(height: 24), engines],
                      ),
              ),
              const SizedBox(height: 20),
              if (current == 'tun' && settings.engine == 'mihomo') ...[
                ChoiceTile<String>(
                  key: const ValueKey('mihomo-tun-stack'),
                  title: s.tunStack,
                  value: settings.mihomoTunStack,
                  choices: {'mixed': s.tunStackMixed, 'system': s.tunStackSystem, 'gvisor': 'gVisor', 'mips': 'MIPS'},
                  onChanged: (value) => unawaited(sora.change((x) => x.mihomoTunStack = value)),
                ),
                const SizedBox(height: 12),
              ],
              if (current == 'tun' && settings.engine == 'xray' && Platform.isLinux) ...[
                ChoiceTile<String>(
                  key: const ValueKey('xray-tun-stack'),
                  title: s.tunStack,
                  value: settings.xrayTunStack,
                  choices: {'gvisor': 'gVisor', 'system': s.tunStackSystem, 'mixed': s.tunStackMixed, 'mips': 'MIPS'},
                  onChanged: (value) => unawaited(sora.change((x) => x.xrayTunStack = value)),
                ),
                const SizedBox(height: 12),
              ],
              Divider(height: 1, color: palette.field),
              const SizedBox(height: 8),
              SwitchTile(
                title: s.killSwitch,
                value: settings.killSwitch,
                onChanged: (v) => unawaited(sora.setKillSwitch(v)),
              ),
              if (Platform.isLinux || Platform.isWindows)
                ExpansionTile(
                  key: const ValueKey('advanced-protection'),
                  title: Text(s.more, style: Styles.bodyStrong.copyWith(color: palette.ink)),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  iconColor: palette.ink2,
                  collapsedIconColor: palette.ink2,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  children: [
                    SwitchTile(
                      key: const ValueKey('strict-kill-switch'),
                      title: s.strictKillSwitch,
                      info: s.strictKillSwitchWarning,
                      value: settings.strictKillSwitch,
                      onChanged: (v) => unawaited(sora.setStrictKillSwitch(v)),
                    ),
                  ],
                ),
              if (Platform.isLinux && sora.serverlessAvailable) ...[
                const SizedBox(height: 12),
                SwitchTile(
                  title: s.zapretWithVpn,
                  info: s.zapretWithVpnHint,
                  value: settings.zapretWithVpn,
                  onChanged: (v) => unawaited(sora.change((x) => x.zapretWithVpn = v)),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const ValueKey('modes-info'),
                  onPressed: () => Navigator.pop(context, true),
                  icon: Icon(Symbols.info_rounded, size: 20, weight: 600, color: palette.ink),
                  label: Text(s.modesInfo, style: Styles.secondary.copyWith(color: palette.ink)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModesGuideScreen extends StatelessWidget {
  const ModesGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    return Screen(
      key: const ValueKey('modes-guide'),
      title: s.modesGuideTitle,
      children: [
        MarkdownBody(
          data: s.modesGuide,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: Styles.body.copyWith(color: palette.ink, height: 1.6),
            h2: Styles.heading.copyWith(color: palette.ink),
            h3: Styles.bodyStrong.copyWith(color: palette.ink),
            h2Padding: const EdgeInsets.only(top: 24, bottom: 8),
            h3Padding: const EdgeInsets.only(top: 16, bottom: 4),
            a: Styles.body.copyWith(color: palette.ink, decoration: TextDecoration.underline),
            listBullet: Styles.body.copyWith(color: palette.ink),
            tableBody: Styles.secondary.copyWith(color: palette.ink),
            tableHead: Styles.bodyStrong.copyWith(color: palette.ink),
            tableCellsPadding: const EdgeInsets.all(10),
            tableBorder: TableBorder(horizontalInside: BorderSide(color: palette.field)),
          ),
          onTapLink: (_, href, _) {
            if (href != null) unawaited(openLink(context, href));
          },
        ),
      ],
    );
  }
}
