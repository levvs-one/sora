import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// Design tokens for the macOS app (detail standard §1: no magic
/// numbers in screens). Mirrors the desktop sora design system:
///  * spacing/radii — the 4/8 grid used by the Flutter UI kit;
///  * colours — `Palette.light` / `Palette.dark` from
///    `app/lib/src/design/theme.dart`, copied 1:1 (same values as the
///    iOS `SoraPalette` in `apple/Apps/iOS/Design.swift`);
///  * motion — the three tiers of the Flutter `Motion` tokens
///    (`app/lib/src/design/theme.dart`, ARCHITECTURE.md §8 correction):
///    fast 160 ms, medium 180 ms, slow 220 ms, curve
///    `Cubic(0.2, 0.9, 0.25, 1)`. NOT 0.20/0.30 — those were a draft
///    guess and were explicitly superseded by the Motion tokens.
public enum DesignTokens {

    // MARK: Spacing (4/8 grid)

    public enum Space {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        /// Sidebar width and menu-bar popover width.
        public static let sidebarWidth: CGFloat = 220
        public static let menuPopoverWidth: CGFloat = 320
        /// Fixed row heights keep long server names from reflowing the
        /// table (detail standard §4, together with truncation rules).
        public static let serverRowHeight: CGFloat = 44
        public static let menuRowHeight: CGFloat = 28
    }

    // MARK: Radii

    public enum Radius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let pill: CGFloat = 999
    }

    // MARK: Motion (Flutter `Motion`, theme.dart:168-174)

    public enum Motion {
        public static let fast: TimeInterval = 0.160
        public static let medium: TimeInterval = 0.180
        public static let slow: TimeInterval = 0.220
        /// `Cubic(0.2, 0.9, 0.25, 1)` from the Flutter tokens.
        public static var curve: Animation {
            .timingCurve(0.2, 0.9, 0.25, 1)
        }
        public static var fastAnimation: Animation { .timingCurve(0.2, 0.9, 0.25, 1, duration: fast) }
        public static var mediumAnimation: Animation { .timingCurve(0.2, 0.9, 0.25, 1, duration: medium) }
        public static var slowAnimation: Animation { .timingCurve(0.2, 0.9, 0.25, 1, duration: slow) }

        /// Honours Reduce Motion: mirrors Flutter `Motion.of`, which
        /// collapses durations to zero when motion is disabled.
        public static func respectingSystem(_ animation: Animation) -> Animation? {
            #if canImport(AppKit)
            if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion { return nil }
            #endif
            return animation
        }
    }

    // MARK: Colours (Flutter Palette, theme.dart — dark is primary)

    public enum Palette {
        // Dark (primary theme of the desktop app)
        public static let darkBackground = Color(red: 0x0B / 255, green: 0x0B / 255, blue: 0x0C / 255)
        public static let darkSurface = Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255)
        public static let darkField = Color(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2E / 255)
        public static let darkInk = Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255)
        public static let darkInk2 = Color(red: 0x98 / 255, green: 0x98 / 255, blue: 0x9F / 255)
        public static let darkInk3 = Color(red: 0x92 / 255, green: 0x94 / 255, blue: 0x9C / 255)
        public static let darkRaised = Color(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2E / 255)
        // Light (full parity — every screen is built from these
        // semantic colours only, never from a fixed dark value)
        public static let lightBackground = Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255)
        public static let lightSurface = Color.white
        public static let lightField = Color(red: 0xEB / 255, green: 0xEB / 255, blue: 0xEF / 255)
        public static let lightInk = Color(red: 0x1D / 255, green: 0x1D / 255, blue: 0x1F / 255)
        public static let lightInk2 = Color(red: 0x63 / 255, green: 0x66 / 255, blue: 0x6C / 255)
        public static let lightInk3 = Color(red: 0x66 / 255, green: 0x6B / 255, blue: 0x73 / 255)
        public static let lightRaised = Color.white
        /// Destructive actions only. Status/error text is NEVER danger
        /// coloured — the house rule (no raw red errors in the UI).
        public static let dangerDark = Color(red: 0xFF / 255, green: 0x5D / 255, blue: 0x52 / 255)
        public static let dangerLight = Color(red: 0xD0 / 255, green: 0x2A / 255, blue: 0x22 / 255)

        /// Connection-glow spectrum (theme.dart `Palette.spectrum`).
        public static let spectrum: [Color] = [
            Color(red: 0xBC / 255, green: 0x82 / 255, blue: 0xF3 / 255),
            Color(red: 0xF5 / 255, green: 0xB9 / 255, blue: 0xEA / 255),
            Color(red: 0x8D / 255, green: 0x9F / 255, blue: 0xFF / 255),
            Color(red: 0xFF / 255, green: 0x67 / 255, blue: 0x78 / 255),
            Color(red: 0xFF / 255, green: 0xBA / 255, blue: 0x71 / 255),
            Color(red: 0xC6 / 255, green: 0x86 / 255, blue: 0xFF / 255),
        ]
    }

    // MARK: Semantic colours (resolve per appearance — §5 parity)

    public static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Palette.darkBackground : Palette.lightBackground
    }
    public static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Palette.darkSurface : Palette.lightSurface
    }
    public static func field(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Palette.darkField : Palette.lightField
    }
    public static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Palette.darkInk : Palette.lightInk
    }
    public static func ink2(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Palette.darkInk2 : Palette.lightInk2
    }
    public static func ink3(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Palette.darkInk3 : Palette.lightInk3
    }
    public static func danger(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Palette.dangerDark : Palette.dangerLight
    }

    // MARK: Status-item icon (detail standard §5)

    /// The menu-bar icon is a TEMPLATE image: macOS renders it in the
    /// correct colour for light/dark menu bars and for the tinted /
    /// translucent menu-bar styles automatically. Never ship a coloured
    /// bitmap here. Connection state is conveyed by the menu content
    /// and the VoiceOver label, not by tinting the template.
    public static var statusItemIconName: String { "sora-status-template" }
}

/// Localisation helper: resolves a key from the shared
/// `apple/Localizations/Localizable.xcstrings` table, falling back to a
/// supplied default (English glossary term) when the key is a new
/// macOS proposal not yet merged by the localisation sub-department.
/// Glossary terms come from the main app (Servers / Subscriptions /
/// Settings / Statistics / About, Connect / Disconnect, …).
public func tr(_ key: String, _ fallback: String) -> String {
    Bundle.main.localizedString(forKey: key, value: fallback, table: nil)
}
