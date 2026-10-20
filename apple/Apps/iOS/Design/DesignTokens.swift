import SwiftUI

/// The only source of spacing, radius, animation and colour values for
/// the iOS app screens. Screens must not contain magic numbers: layout
/// lives on the 4/8 grid defined here, motion durations are the two
/// shared values, colours are semantic (they resolve per appearance —
/// dark is the primary theme, light is a first-class parity target).
public enum DesignTokens {
    // MARK: Spacing — 4/8 grid only.
    public static let space1: CGFloat = 4
    public static let space2: CGFloat = 8
    public static let space3: CGFloat = 12
    public static let space4: CGFloat = 16
    public static let space5: CGFloat = 24
    public static let space6: CGFloat = 32
    public static let space7: CGFloat = 48

    /// Horizontal page margin on compact screens.
    public static let pageMargin: CGFloat = 16
    /// Minimum hit target (HIG 44pt).
    public static let hitTarget: CGFloat = 44
    public static let rowMinHeight: CGFloat = 52
    public static let iconSize: CGFloat = 24
    public static let markSize: CGFloat = 56

    // MARK: Corner radius.
    public static let radiusSmall: CGFloat = 8
    public static let radiusMedium: CGFloat = 12
    public static let radiusLarge: CGFloat = 16
    public static let radiusCard: CGFloat = 20

    // MARK: Motion — the desktop app's `Motion` tokens, verbatim
    // (ARCHITECTURE.md §8 / Flutter `Motion`): three tiers, 160/180/220 ms,
    // so Apple and desktop feel like the same product. Do not invent
    // local durations; pick a tier by the meaning of the transition:
    // fast = micro-feedback (row highlight, badge), standard = state
    // change (connect header, tab content), slow = sheet/large surface.
    public static let durationFast: Double = 0.16
    public static let durationStandard: Double = 0.18
    public static let durationSlow: Double = 0.22
    public static var easeFast: Animation { .easeInOut(duration: durationFast) }
    public static var easeStandard: Animation { .easeInOut(duration: durationStandard) }
    public static var easeSlow: Animation { .easeInOut(duration: durationSlow) }
    public static var springToggle: Animation {
        .spring(response: durationStandard, dampingFraction: 0.85)
    }

    // MARK: Semantic colours (resolve per colour scheme; values mirror
    // the Flutter Palette — see Design.swift for the raw hex table).
    public static var background: Color { Color("SoraBackground") }
    public static var surface: Color { Color("SoraSurface") }
    public static var field: Color { Color("SoraField") }
    public static var ink: Color { Color.primary }
    public static var ink2: Color { Color.secondary }
    public static var separator: Color { Color(UIColor.separator) }
    /// Destructive actions only (delete) — never status/error text.
    public static var danger: Color { SoraPalette.danger }
    /// Positive status dot (connected). Not an error channel.
    public static var statusOn: Color { Color(red: 0.20, green: 0.78, blue: 0.35) }
    /// Neutral transitional status dot (connecting/reconnecting).
    public static var statusBusy: Color { Color(red: 0.95, green: 0.65, blue: 0.15) }
    public static var statusOff: Color { Color.secondary }
}

/// Asset-catalog colour fallbacks. The Xcode project defines
/// `SoraBackground`/`SoraSurface`/`SoraField` as Any/Dark appearance
/// colours with exactly the Palette hex values (README lists them); this
/// helper lets previews and unbundled contexts resolve the same values
/// from the scheme instead.
public extension DesignTokens {
    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? SoraPalette.darkBackground : SoraPalette.lightBackground
    }
    static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? SoraPalette.darkSurface : SoraPalette.lightSurface
    }
    static func field(for scheme: ColorScheme) -> Color {
        scheme == .dark ? SoraPalette.darkField : SoraPalette.lightField
    }
    static func ink(for scheme: ColorScheme) -> Color {
        scheme == .dark ? SoraPalette.darkInk : SoraPalette.lightInk
    }
    static func ink2(for scheme: ColorScheme) -> Color {
        scheme == .dark ? SoraPalette.darkInk2 : SoraPalette.lightInk2
    }
}

/// Standard empty / state block used by every list and screen: a title in
/// plain language, one explanatory line and (when possible) the action
/// that resolves the state. Never a bare "No data".
public struct SoraEmptyStateView: View {
    public let titleKey: LocalizedStringKey
    public let messageKey: LocalizedStringKey
    public var actionTitleKey: LocalizedStringKey?
    public var action: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(titleKey: LocalizedStringKey, messageKey: LocalizedStringKey,
                actionTitleKey: LocalizedStringKey? = nil, action: (() -> Void)? = nil) {
        self.titleKey = titleKey
        self.messageKey = messageKey
        self.actionTitleKey = actionTitleKey
        self.action = action
    }

    public var body: some View {
        VStack(spacing: DesignTokens.space3) {
            SoraMarkView(size: DesignTokens.markSize,
                         color: DesignTokens.ink2(for: scheme))
            Text(titleKey)
                .font(.headline)
                .foregroundStyle(DesignTokens.ink(for: scheme))
                .multilineTextAlignment(.center)
            Text(messageKey)
                .font(.subheadline)
                .foregroundStyle(DesignTokens.ink2(for: scheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitleKey, let action {
                Button(actionTitleKey, action: action)
                    .buttonStyle(.borderedProminent)
                    .frame(minHeight: DesignTokens.hitTarget)
                    .accessibilityHint(Text("state.emptyStateActionHint"))
            }
        }
        .padding(DesignTokens.space5)
        .frame(maxWidth: .infinity)
    }
}
