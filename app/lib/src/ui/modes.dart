import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../sora.dart';
import 'addserver.dart';
import 'extensions/widgets.dart' show setExtensionBypass;
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
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.emptyServersTitle,
                    textAlign: TextAlign.center,
                    style: Styles.heading.copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.emptyServersBody,
                    textAlign: TextAlign.center,
                    style: Styles.secondary.copyWith(color: palette.ink, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(label: s.addSubscription, onTap: () => Navigator.pop(context, 'subscription')),
                  const SizedBox(height: 4),
                  TextButton(
                    key: const ValueKey('connect-own-server'),
                    onPressed: () => Navigator.pop(context, 'own'),
                    child: Text(s.customServerAdd, style: Styles.bodyStrong.copyWith(color: palette.ink)),
                  ),
                  if (sora.serverlessAvailable)
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'bypass'),
                      child: Text(s.serverBypass, style: Styles.bodyStrong.copyWith(color: palette.ink)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!context.mounted) return;
    if (choice == 'subscription') {
      await showSubscriptionSheet(context);
    } else if (choice == 'own') {
      await showAddServerSheet(context);
    }
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

/// One way to connect: icon, name and a one-line consequence, so the choice
/// is understandable without opening the guide.
class _ModeOption extends StatelessWidget {
  const _ModeOption({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $hint',
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        radius: 12,
        give: 0.99,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fast),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? palette.field : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? palette.ink : palette.field,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, fill: 1, color: selected ? palette.surface : palette.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Styles.bodyStrong.copyWith(color: palette.ink)),
                    const SizedBox(height: 1),
                    Text(hint, style: Styles.caption.copyWith(color: palette.ink2, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? palette.ink : palette.ink3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The engine choice as one compact segmented row. Each segment keeps its
/// own key so tests and the tour can address a specific engine.
class _EngineSegments extends StatelessWidget {
  const _EngineSegments({required this.value, required this.choices, required this.onChanged});

  final String value;
  final List<(String, String)> choices;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: palette.field, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (final (key, label) in choices)
            Expanded(
              child: Semantics(
                button: true,
                selected: key == value,
                label: label,
                excludeSemantics: true,
                onTap: () => onChanged(key),
                child: Pressable(
                  key: ValueKey('engine-$key'),
                  onTap: () => onChanged(key),
                  radius: 9,
                  wash: false,
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.fast),
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: key == value ? palette.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: key == value
                          ? [BoxShadow(color: palette.shadow, blurRadius: 4, offset: const Offset(0, 1))]
                          : null,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Styles.secondary.copyWith(
                        color: palette.ink,
                        fontWeight: key == value ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.info, this.sources = const []});
  final String text;
  final String? info;
  final List<InfoSource> sources;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Text(
            text,
            style: Styles.secondary.copyWith(color: palette.ink2, fontWeight: FontWeight.w600),
          ),
          if (info != null) InfoButton(title: text, description: info!, sources: sources, dense: true),
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
    Future<void> mode(String value) async {
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
        _SectionTitle(s.tunnelMode),
        _ModeOption(
          key: const ValueKey('mode-tun'),
          icon: Symbols.public_rounded,
          title: s.tunMode,
          hint: s.modeTunHint,
          selected: current == 'tun',
          onTap: () => unawaited(mode('tun')),
        ),
        _ModeOption(
          key: const ValueKey('mode-proxy'),
          icon: Symbols.travel_explore_rounded,
          title: s.tunnelProxy,
          hint: s.modeProxyHint,
          selected: current == 'proxy',
          onTap: () => unawaited(mode('proxy')),
        ),
        if (sora.serverlessAvailable)
          _ModeOption(
            key: const ValueKey('mode-bypass'),
            icon: Symbols.shield_rounded,
            title: s.serverBypass,
            hint: s.modeBypassHint,
            selected: current == 'bypass',
            onTap: () => unawaited(mode('bypass')),
          ),
      ],
    );
    final engines = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(s.engine, info: s.engineInfo, sources: Sources.engine),
        _EngineSegments(
          value: settings.engine,
          choices: [('', s.engineAuto), ('sing-box', 'sing-box'), ('xray', 'Xray'), ('mihomo', 'mihomo')],
          onChanged: (value) => unawaited(
            sora.change(
              (x) => x
                ..engine = value
                ..controlPort = value == 'sing-box',
            ),
          ),
        ),
      ],
    );
    return Dialog(
      key: const ValueKey('mode-panel'),
      backgroundColor: palette.raised,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: MediaQuery.sizeOf(context).height - 64),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(s.modes, style: Styles.heading.copyWith(color: palette.ink)),
                  ),
                  RoundButton(icon: Symbols.close_rounded, label: s.close, onTap: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              routes,
              const SizedBox(height: 20),
              engines,
              if (current == 'tun' && settings.engine == 'mihomo') ...[
                const SizedBox(height: 8),
                ChoiceTile<String>(
                  key: const ValueKey('mihomo-tun-stack'),
                  title: s.tunStack,
                  info: s.tunStackInfo,
                  sources: Sources.tunStack,
                  value: settings.mihomoTunStack,
                  choices: {'mixed': s.tunStackMixed, 'system': s.tunStackSystem, 'gvisor': 'gVisor', 'mips': 'MIPS'},
                  onChanged: (value) => unawaited(sora.change((x) => x.mihomoTunStack = value)),
                ),
              ],
              if (current == 'tun' && settings.engine == 'xray' && Platform.isLinux) ...[
                const SizedBox(height: 8),
                ChoiceTile<String>(
                  key: const ValueKey('xray-tun-stack'),
                  title: s.tunStack,
                  info: s.tunStackInfo,
                  sources: Sources.tunStack,
                  value: settings.xrayTunStack,
                  choices: {'gvisor': 'gVisor', 'system': s.tunStackSystem, 'mixed': s.tunStackMixed, 'mips': 'MIPS'},
                  onChanged: (value) => unawaited(sora.change((x) => x.xrayTunStack = value)),
                ),
              ],
              const SizedBox(height: 20),
              _SectionTitle(s.protection),
              DecoratedBox(
                decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      SwitchTile(
                        title: s.killSwitch,
                        info: s.killSwitchInfo,
                        sources: Sources.killSwitch,
                        value: settings.killSwitch,
                        onChanged: (v) => unawaited(sora.setKillSwitch(v)),
                      ),
                      if (Platform.isLinux || Platform.isWindows)
                        SwitchTile(
                          key: const ValueKey('strict-kill-switch'),
                          title: s.strictKillSwitch,
                          info: s.strictKillSwitchInfo,
                          sources: Sources.killSwitch,
                          value: settings.strictKillSwitch,
                          onChanged: (v) async {
                            if (v &&
                                !await confirm(
                                  context,
                                  question: s.strictKillSwitchWarning,
                                  action: s.strictKillSwitch,
                                  destructive: false,
                                )) {
                              return;
                            }
                            await sora.setStrictKillSwitch(v);
                          },
                        ),
                      for (final profile in sora.extensions.bypassProfiles)
                        SwitchTile(
                          key: ValueKey('protection-${profile.extensionId}'),
                          title: profile.name,
                          info: s.extensionBypassInfo,
                          sources: Sources.bypass,
                          value:
                              sora.selected == profile.choiceId && sora.phase != Phase.off && sora.phase != Phase.offline,
                          onChanged: (v) => unawaited(setExtensionBypass(context, profile.extensionId, v)),
                        ),
                      if (Platform.isLinux && sora.serverlessAvailable)
                        SwitchTile(
                          title: s.zapretWithVpn,
                          info: s.zapretWithVpnInfo,
                          sources: Sources.bypass,
                          value: settings.zapretWithVpn,
                          onChanged: (v) => unawaited(sora.change((x) => x.zapretWithVpn = v)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
