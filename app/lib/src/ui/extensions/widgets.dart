/// Shared widgets for the extensions section: cards, star ratings, badges.
///
/// The section follows the app's ink-based design system: surfaces, ink
/// tones and [Palette.danger] for genuine warnings. No decorative colors.
library;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../kit.dart';
import '../../ext/catalog.dart';

/// 5-star rating display with the numeric value.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 14});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final s = S.of(context);
    return Row(
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
        Text(rating.toStringAsFixed(1), style: Styles.caption.copyWith(color: palette.ink2)),
        // Screen-reader text; visual users see the stars.
        Semantics(
          label: s.extRatingLabel(rating.toStringAsFixed(1)),
          child: const SizedBox.shrink(),
        ),
      ],
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
        color: tone == ExtBadgeTone.warn
            ? palette.danger.withValues(alpha: 0.1)
            : palette.field.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: Styles.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
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
                    Text(title,
                        style: Styles.title.copyWith(color: palette.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(s.extByAuthor(author),
                        style: Styles.caption.copyWith(color: palette.ink2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: Styles.caption.copyWith(color: palette.ink2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
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
                          Text(s.extInstallsCount(_compact(installs!)),
                              style: Styles.caption.copyWith(color: palette.ink2)),
                      ],
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

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

/// Permission row for the install prompt and the detail screen.
class PermissionRow extends StatelessWidget {
  const PermissionRow({
    super.key,
    required this.blurb,
    required this.dangerous,
  });
  final String blurb;
  final bool dangerous;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            dangerous ? Symbols.warning_rounded : Symbols.check_circle_rounded,
            size: 18,
            color: dangerous ? palette.danger : palette.ink2,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(blurb, style: Styles.body.copyWith(color: palette.ink)),
          ),
        ],
      ),
    );
  }
}
