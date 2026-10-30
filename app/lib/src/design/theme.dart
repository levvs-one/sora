import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Cool neutral UI colours, red for failures and an Apple Intelligence-style
/// spectrum for the connection glow.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.background,
    required this.surface,
    required this.field,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.danger,
    required this.onDanger,
    required this.shadow,
    required this.raised,
    required this.raisedField,
    required this.scrim,
    this.accent,
    this.verified = const Color(0xFF007AFF),
  });

  final Color verified;
  final Color? accent;
  List<Color> get glowColors => accent == null ? spectrum : List.filled(spectrum.length, accent!);

  final Color background;
  final Color surface;
  final Color field;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color danger;

  /// Label colour on a filled [danger] background. White in light mode, black
  /// in dark mode: no single light label reaches WCAG AA on the bright dark
  /// red, and no single dark label works on the deep light red.
  final Color onDanger;

  final Color shadow;

  /// Elevated sheet and menu surfaces, lighter than the page in dark mode.
  final Color raised;
  final Color raisedField;

  /// The backdrop colour used to dim content behind a sheet.
  final Color scrim;

  Color get hover => ink.withValues(alpha: 0.05);
  Color get pressed => ink.withValues(alpha: 0.09);

  static const light = Palette(
    background: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    field: Color(0xFFEBEBEF),
    ink: Color(0xFF1D1D1F),
    ink2: Color(0xFF4A4D53),
    ink3: Color(0xFF5C6068),
    danger: Color(0xFFD02A22),
    onDanger: Color(0xFFFFFFFF),
    shadow: Color(0x14000000),
    raised: Color(0xFFFFFFFF),
    raisedField: Color(0xFFEBEBEF),
    scrim: Color(0x38000000),
  );

  static const dark = Palette(
    verified: Color(0xFF0A84FF),
    background: Color(0xFF0B0B0C),
    surface: Color(0xFF1C1C1E),
    field: Color(0xFF2C2C2E),
    ink: Color(0xFFF5F5F7),
    ink2: Color(0xFFB4B4BB),
    ink3: Color(0xFFA2A4AC),
    danger: Color(0xFFFF5D52),
    onDanger: Color(0xFF000000),
    shadow: Color(0x66000000),
    raised: Color(0xFF2C2C2E),
    raisedField: Color(0xFF3A3A3C),
    scrim: Color(0x8C000000),
  );

  /// Colours for the Apple Intelligence-style connection glow.
  static const spectrum = <Color>[
    Color(0xFFBC82F3),
    Color(0xFFF5B9EA),
    Color(0xFF8D9FFF),
    Color(0xFFFF6778),
    Color(0xFFFFBA71),
    Color(0xFFC686FF),
  ];

  static Palette of(BuildContext context) => Theme.of(context).extension<Palette>()!;

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    return Palette(
      accent: Color.lerp(accent, other.accent, t),
      verified: Color.lerp(verified, other.verified, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      field: Color.lerp(field, other.field, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      raisedField: Color.lerp(raisedField, other.raisedField, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

/// Inter text styles with optical sizing and tighter tracking at larger sizes.
abstract final class Styles {
  /// Bundled script fonts keep localization readable without optional OS packs.
  static const _fallback = [
    'Noto Sans Arabic',
    'Noto Sans Bengali',
    'Noto Sans Devanagari',
    'Noto Sans Thai',
    'Noto Sans Armenian',
    'Noto Sans Georgian',
    'Sora CJK',
    'Noto Color Emoji',
    'Segoe UI Emoji',
    'Apple Color Emoji',
  ];

  static TextStyle _inter(double size, double weight, double tracking, double height) => TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fallback,
    fontSize: size,
    fontWeight: weight == 400
        ? FontWeight.w400
        : weight == 500
        ? FontWeight.w500
        : FontWeight.w600,
    height: height,
    letterSpacing: tracking,
    fontVariations: [FontVariation('wght', weight), FontVariation('opsz', size.clamp(14, 32))],
  );

  /// Uses tabular figures for latency, timers and log timestamps. Apply
  /// selectively because this feature also widens hyphens and punctuation.
  static TextStyle figures(TextStyle style) => style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static final status = _inter(28, 600, -0.6, 1.14);
  static final title = _inter(28, 600, -0.6, 1.14);
  static final heading = _inter(20, 600, -0.3, 1.2);
  static final body = _inter(15, 400, -0.1, 1.33);
  static final bodyStrong = _inter(15, 600, -0.1, 1.33);
  static final row = _inter(15, 500, -0.1, 1.2);
  static final secondary = _inter(13, 400, 0, 1.3);
  static final caption = _inter(12, 400, 0, 1.3);
  static final timestamp = figures(_inter(12, 600, 0, 4 / 3));

  /// Destructive action labels; validation uses field borders and notifications.
  static TextStyle dangerSecondary(BuildContext context) => secondary.copyWith(color: Palette.of(context).danger);
}

/// Shared animation durations and curves that respect the motion setting.
abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 180);
  static const slow = Duration(milliseconds: 220);

  /// Navigation curve approximating an Apple critically damped spring.
  static const curve = Cubic(0.2, 0.9, 0.25, 1);

  static Duration of(BuildContext context, Duration d) => enabled(context) ? d : Duration.zero;

  static bool enabled(BuildContext context) => MotionScope.of(context);
}

/// Enables motion only when allowed by both app and system settings.
class MotionScope extends InheritedWidget {
  const MotionScope({super.key, required this.enabled, required super.child});

  final bool enabled;

  static bool of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MotionScope>();
    final system = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return (scope?.enabled ?? true) && !system;
  }

  @override
  bool updateShouldNotify(MotionScope oldWidget) => enabled != oldWidget.enabled;
}

ThemeData buildTheme(Brightness brightness, {Palette? colors}) {
  final palette = colors ?? (brightness == Brightness.dark ? Palette.dark : Palette.light);
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    fontFamily: 'Inter',
    fontFamilyFallback: Styles._fallback,
    scaffoldBackgroundColor: palette.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.ink,
      brightness: brightness,
      surface: palette.surface,
      onSurface: palette.ink,
      primary: palette.ink,
      onPrimary: palette.surface,
      error: palette.danger,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: palette.hover,
    focusColor: palette.hover,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.ink,
      selectionColor: palette.ink.withValues(alpha: 0.18),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(palette.raised),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(2),
        shadowColor: WidgetStatePropertyAll(palette.shadow),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    ),
    cupertinoOverrideTheme: CupertinoThemeData(brightness: brightness, primaryColor: palette.ink),
    extensions: [palette],
  );
  return base;
}
