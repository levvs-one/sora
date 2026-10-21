/// Shared widgets for the extensions section: cards, star ratings, badges.
///
/// The section follows the app's ink-based design system: surfaces, ink
/// tones and [Palette.danger] for genuine warnings. No decorative colors.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/strings.dart';
import '../../design/theme.dart';
import '../kit.dart';
import '../../ext/catalog.dart';
import '../../ext/permissions.dart';

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

enum ExtBadgeTone { calm, warn }

/// Small badge chip: verified / top / new / staff, or the sideload warning.
class ExtBadge extends StatelessWidget {
  const ExtBadge({super.key, required this.label, this.tone = ExtBadgeTone.calm, this.icon});
  final String label;
  final ExtBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final fg = tone == ExtBadgeTone.warn ? palette.danger : palette.ink2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone == ExtBadgeTone.warn ? palette.danger.withValues(alpha: 0.1) : palette.field.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Text(
            label,
            style: Styles.caption.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Badges for a catalog entry: verified/top/new/staff.
List<Widget> catalogBadges(BuildContext context, CatalogEntry e) {
  final s = S.of(context);
  final out = <Widget>[];
  for (final b in e.badges) {
    switch (b) {
      case 'verified':
        out.add(ExtBadge(label: s.extBadgeVerified, icon: Symbols.verified_rounded));
      case 'top':
        out.add(ExtBadge(label: s.extBadgeTop, icon: Symbols.trending_up_rounded));
      case 'new':
        out.add(ExtBadge(label: s.extBadgeNew, icon: Symbols.fiber_new_rounded));
      case 'staff':
        out.add(ExtBadge(label: s.extBadgeStaff, icon: Symbols.shield_rounded));
    }
  }
  return out;
}

/// One catalog/install row. One tap opens the detail; the trailing action is
/// install / open / update depending on state.
class ExtensionCard extends StatelessWidget {
  const ExtensionCard({
    super.key,
    required this.title,
    required this.author,
    this.rating,
    this.installs,
    required this.badges,
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
  final double? rating;
  final int? installs;
  final List<Widget> badges;
  final Widget? trailing;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  /// Manifest capabilities (installed) — used for the human-language
  /// capability lines below the badges.
  final List<String> capabilities;

  /// Granted (installed) or requested (catalog) permission ids.
  final List<String> permissions;

  /// Host allowlist for the network permission (manifest `network_hosts`).
  final List<String> networkHosts;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final s = S.of(context);
    return Pressable(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.field),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.field.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Symbols.extension_rounded, color: palette.ink2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Styles.title.copyWith(color: palette.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.extByAuthor(author),
                      style: Styles.caption.copyWith(color: palette.ink2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Styles.caption.copyWith(color: palette.ink2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (rating != null && rating! > 0) StarRating(rating: rating!),
                        ...badges,
                        if (installs != null && installs! > 0)
                          Text(
                            installs! == 1 ? s.extInstallOne : s.extInstallsCount(_compact(context, installs!)),
                            style: Styles.caption.copyWith(color: palette.ink2),
                          ),
                      ],
                    ),
                    ...capabilityLines(
                      context,
                      capabilities: capabilities,
                      permissions: permissions,
                      networkHosts: networkHosts,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
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
/// The risk tier is visually honest: normal permissions get a plain check,
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(blurb, style: Styles.body.copyWith(color: palette.ink)),
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
/// extension declares neither — the card stays exactly as before.
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
              style: Styles.caption.copyWith(color: palette.ink2),
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

/// "How ratings work" dialog: the published rating methodology in plain
/// language (extRatingHowBody). Opened from the rating row on the extension
/// detail page. The formula lives in core/ext/ratings.go and the normative
/// spec; this dialog is its user-facing summary.
Future<void> showRatingHowDialog(BuildContext context) {
  final s = S.of(context), palette = Palette.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: palette.raised,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.extRatingHow, style: Styles.title.copyWith(color: palette.ink)),
              const SizedBox(height: 10),
              Text(s.extRatingHowBody, style: Styles.body.copyWith(color: palette.ink2)),
              const SizedBox(height: 16),
              PrimaryButton(label: s.extOk, onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    ),
  );
}
