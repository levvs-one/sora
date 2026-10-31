/// Shared widgets for the extensions section: cards, star ratings, badges.
///
/// The section follows the app's ink-based design system: surfaces, ink
/// tones and [Palette.danger] for genuine warnings. No decorative colors.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/strings.dart';
import '../../design/theme.dart';
import '../../sora.dart';
import '../kit.dart';
import '../../ext/verifier.dart';
import '../../ext/catalog.dart';
import '../../updates.dart' show appVersion;
import '../../ext/bypass.dart';
import '../../ext/permissions.dart';
import '../../ext/store.dart';
import '../modes.dart' show ensureSystemFilterConsent;

/// Signed catalog requirements are an early gate; package verification and
/// the manifest's own minimum-version check still run after downloading.
String? catalogCompatibilityText(S s, CatalogEntry entry) {
  final requirements = <String>[];
  if (entry.requiresNewerApp(appVersion)) {
    requirements.add(s.extErrMinApp(entry.minAppVersion));
  }
  if (!entry.supportsPlatform(Platform.operatingSystem)) {
    final names = entry.platforms
        .map(
          (os) => switch (os) {
            'linux' => 'Linux',
            'windows' => 'Windows',
            'macos' => 'macOS',
            'android' => 'Android',
            'ios' => 'iOS',
            _ => os,
          },
        )
        .join(', ');
    requirements.add(s.extAvailableOn(names));
  }
  return requirements.isEmpty ? null : requirements.join('\n');
}

/// 5-star rating display with the numeric value.
///
/// The whole row is one semantic node ("Rating 4.5 of 5"): the star icons
/// are decorative and the numeric text is folded into the label, so screen
/// readers announce it once instead of five images plus a number.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 14});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final ratingText = NumberFormat('0.0', Localizations.localeOf(context).toLanguageTag()).format(rating);
    final s = S.of(context);
    return Semantics(
      label: s.extRatingLabel(ratingText),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              rating >= i - 0.25
                  ? Symbols.star_rounded
                  : (rating >= i - 0.75 ? Symbols.star_half_rounded : Symbols.star_outline_rounded),
              size: size,
              color: palette.ink,
            ),
          const SizedBox(width: 4),
          Text(ratingText, style: Styles.caption.copyWith(color: palette.ink2)),
        ],
      ),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: S.of(context).extVerifiedSora,
    child: Icon(Symbols.verified_rounded, fill: 1, size: size, color: Palette.of(context).verified),
  );
}

bool isTeamExtension(InstalledExtension extension) =>
    (extension.authorKey ?? extension.manifest.author.publicKey).trim() == teamPublicKey;

bool isTeamEntry(CatalogEntry entry) => entry.authorKey.trim() == teamPublicKey;

/// Extension name with the verified mark after it.
class ExtensionName extends StatelessWidget {
  const ExtensionName({super.key, required this.name, required this.verified, this.list = false});
  final String name;
  final bool verified;
  final bool list;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Styles.bodyStrong.copyWith(fontSize: list ? 15 : 20, color: Palette.of(context).ink),
        ),
      ),
      if (verified) ...[const SizedBox(width: 5), VerifiedBadge(size: list ? 15 : 18)],
    ],
  );
}

/// What the Sora team's own extensions do, in the user's language. Other
/// authors' descriptions come from their signed manifest as written.
String extensionBlurb(S s, {required String id, required bool team, required String fallback}) {
  if (team) {
    switch (id) {
      case 'org.sora.hello-panel':
        return s.extAboutHello;
      case 'org.sora.zapret':
        return s.extAboutZapret;
      case 'org.sora.byedpi':
        return s.extAboutByedpi;
    }
  }
  final text = fallback.trim();
  final end = text.indexOf('. ');
  return end > 0 ? text.substring(0, end + 1) : text;
}

/// The extension's mark: a glyph for what it does on a quiet tile.
class ExtensionIcon extends StatelessWidget {
  const ExtensionIcon({super.key, required this.capabilities, this.size = 40});
  final List<String> capabilities;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final glyph = capabilities.contains('network-hook')
        ? Symbols.shield_rounded
        : capabilities.contains('ui-panel')
        ? Symbols.dashboard_rounded
        : capabilities.contains('routing')
        ? Symbols.alt_route_rounded
        : capabilities.contains('theme')
        ? Symbols.palette_rounded
        : Symbols.extension_rounded;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: palette.field, borderRadius: BorderRadius.circular(size * 0.28)),
      child: Icon(glyph, size: size * 0.5, fill: 1, color: palette.ink),
    );
  }
}

/// One catalog/install row. One tap opens the detail; the trailing action is
/// install / open / update depending on state.
///
/// The action sits beside the tappable body, never inside it: a button
/// nested in a button gives screen readers one node with two tap actions.
class ExtensionCard extends StatelessWidget {
  const ExtensionCard({
    super.key,
    required this.title,
    required this.author,
    this.description = '',
    this.rating,
    this.installs,
    this.verified = false,
    this.sideload = false,
    this.trailing,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.capabilities = const [],
    this.permissions = const [],
    this.networkHosts = const [],
  });

  final String title;
  final String author;

  /// One or two lines on what the extension does.
  final String description;
  final double? rating;
  final int? installs;
  final bool verified;
  final bool sideload;
  final Widget? trailing;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  /// Manifest capabilities, which pick the icon and the capability lines.
  final List<String> capabilities;

  /// Granted (installed) or requested (catalog) permission ids.
  final List<String> permissions;

  /// Host allowlist for the network permission (manifest `network_hosts`).
  final List<String> networkHosts;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final s = S.of(context);
    final label = [
      title,
      if (verified) s.extVerifiedSora,
      if (sideload) s.extSideloadWarning,
      if (description.isNotEmpty) description,
      ?subtitle,
    ].join('. ');
    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExtensionIcon(capabilities: capabilities),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: ExtensionName(name: title, verified: verified, list: true),
                  ),
                  if (sideload) ...[
                    const SizedBox(width: 6),
                    Icon(Symbols.warning_rounded, size: 15, color: palette.danger),
                  ],
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Styles.secondary.copyWith(color: palette.ink, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: Styles.caption.copyWith(color: palette.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if ((rating ?? 0) > 0 || (installs ?? 0) > 0) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (rating != null && rating! > 0) StarRating(rating: rating!),
                    if (installs != null && installs! > 0)
                      Text(
                        installs! == 1 ? s.extInstallOne : s.extInstallsCount(_compact(context, installs!)),
                        style: Styles.caption.copyWith(color: palette.ink2),
                      ),
                  ],
                ),
              ],
              ...capabilityLines(
                context,
                capabilities: capabilities,
                permissions: permissions,
                networkHosts: networkHosts,
              ),
            ],
          ),
        ),
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: onTap != null,
                label: label,
                excludeSemantics: true,
                onTap: onTap,
                child: Pressable(
                  onTap: onTap,
                  radius: 16,
                  give: 0.99,
                  child: Padding(padding: const EdgeInsets.all(12), child: body),
                ),
              ),
            ),
            if (trailing != null) Padding(padding: const EdgeInsetsDirectional.only(end: 12), child: trailing),
          ],
        ),
      ),
    );
  }

  static String _compact(BuildContext context, int n) {
    return NumberFormat.compact(locale: Localizations.localeOf(context).toLanguageTag()).format(n);
  }
}

/// Permission row for the install prompt and the detail screen.
///
/// The risk tier is visible at a glance: normal permissions get a plain check,
/// sensitive ones a stronger info mark, dangerous ones the warning icon in
/// the semantic danger color. The tier is also part of the screen-reader
/// label, so it is never color- or icon-only information.
class PermissionRow extends StatelessWidget {
  const PermissionRow({super.key, required this.blurb, required this.risk});
  final String blurb;
  final ExtRisk risk;

  String _tierLabel(BuildContext context) {
    final s = S.of(context);
    return switch (risk) {
      ExtRisk.normal => s.extRiskNormal,
      ExtRisk.sensitive => s.extRiskSensitive,
      ExtRisk.dangerous => s.extRiskDangerous,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final (icon, color) = switch (risk) {
      ExtRisk.normal => (Symbols.check_circle_rounded, palette.ink2),
      ExtRisk.sensitive => (Symbols.info_rounded, palette.ink),
      ExtRisk.dangerous => (Symbols.warning_rounded, palette.danger),
    };
    return Semantics(
      label: '${_tierLabel(context)}: $blurb',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(blurb, style: Styles.body.copyWith(fontSize: 14, color: palette.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Human-language capability lines for an extension card: background mode
/// and network access with the allowed hosts.
///
/// [capabilities] are manifest capabilities (installed extensions),
/// [permissions] the granted/requested permission ids, [networkHosts] the
/// manifest `network_hosts` allowlist. Returns an empty list when the
/// extension declares neither, and the card stays exactly as before.
List<Widget> capabilityLines(
  BuildContext context, {
  required List<String> capabilities,
  required List<String> permissions,
  required List<String> networkHosts,
}) {
  final s = S.of(context);
  final out = <Widget>[];
  if (capabilities.contains('background') || permissions.contains('background')) {
    out.add(_CapabilityLine(icon: Symbols.schedule_rounded, text: s.extCapBackground));
  }
  if (permissions.any(isNetworkPermission)) {
    out.add(
      _CapabilityLine(
        icon: Symbols.public_rounded,
        text: networkHosts.isEmpty ? s.extCapNetwork : s.extCapNetworkHosts(networkHosts.join(', ')),
      ),
    );
  }
  return out;
}

class _CapabilityLine extends StatelessWidget {
  const _CapabilityLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: palette.ink2),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Styles.caption.copyWith(color: palette.ink),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// The host allowlist for the network permission, one row per host.
/// Callers add the surrounding padding/indentation.
class NetworkHostsList extends StatelessWidget {
  const NetworkHostsList({super.key, required this.hosts});
  final List<String> hosts;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final h in hosts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(Symbols.dns_rounded, size: 14, color: palette.ink3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(h, style: Styles.caption.copyWith(color: palette.ink2)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Turns an extension's blocking bypass on the way the host's own controls
/// do: consent for system-wide filters, then TUN, the extension's profile and
/// a connection. Throws [ExtAssetError] when the profile cannot run here.
Future<void> connectExtensionBypass(BuildContext context, String id) async {
  final sora = SoraScope.read(context);
  final choice = '$extensionBypassPrefix$id';
  if (!await ensureSystemFilterConsent(context, choice) || !context.mounted) return;
  final profile = sora.extensions.bypassProfile(choice);
  if (profile == null) throw ExtAssetError('bypass profile is unavailable');
  sora.rememberServer();
  await sora.change((settings) => settings.tunnel = 'tun', replan: false);
  await sora.select(profile.choiceId);
  sora.applyConnectionChanges();
  if (sora.selected == profile.choiceId && (sora.phase == Phase.off || sora.phase == Phase.offline)) {
    await sora.connect();
  }
}

/// Turns an extension's bypass on or off. Off goes back to the server it
/// replaced and never stops a session another choice started.
Future<void> setExtensionBypass(BuildContext context, String id, bool active) async {
  if (active) return connectExtensionBypass(context, id);
  await SoraScope.read(context).leaveBypass('$extensionBypassPrefix$id');
}

/// Localized text for store refusals the user can act on.
String extStoreErrorText(S s, ExtStoreError e) {
  if (e is ExtAssetError) return s.extAssetRejected;
  if (e.message.contains('was revoked')) return s.extErrRevoked;
  if (e.message.contains('revocation list expired')) return s.extErrRevocationsExpired;
  return s.extErrGeneric;
}

/// Enables or disables an extension, explaining a refusal (for example a
/// revoked version) instead of failing silently.
Future<void> toggleExtension(BuildContext context, ExtensionStore store, String id, bool enabled) async {
  final sora = context.getInheritedWidgetOfExactType<SoraScope>()?.notifier;
  try {
    await store.setEnabled(id, enabled);
    sora?.applyConnectionChanges();
  } on ExtStoreError catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extStoreErrorText(S.of(context), e))));
  }
}
