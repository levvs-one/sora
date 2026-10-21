import SwiftUI
import UIKit

/// Design tokens for the legacy target — an ADAPTER over the main
/// app's token layer, per ARCHITECTURE §8 ("values live in one place;
/// a screen hardcoding a number/colour/string around the tokens does
/// not pass review").
///
/// Why an adapter file exists at all: the main app's
/// `Design/DesignTokens.swift` + `Design.swift` cannot compile for
/// iOS 13 as written — `SoraEmptyStateView` uses the iOS 15
/// `.borderedProminent` button style and `SoraMarkView` draws with
/// `Canvas` (iOS 15). The VALUES below are copied 1:1 from those
/// files (spacing grid, motion tiers, palette hexes from
/// `SoraPalette`, which itself mirrors the Flutter `Palette`), so the
/// two targets look and move identically; only the *rendering* of the
/// shared components is re-implemented with SwiftUI-1 APIs in this
/// file. Coordinator note (TARGET-NOTES.md): the durable fix is to
/// split the main token file into an iOS-13-clean values part both
/// targets share — until then this mirror is kept honest by naming
/// its source for every group.
enum LegacyDesignTokens {
    // Spacing — 4/8 grid. Mirror of DesignTokens.space1…space7.
    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space5: CGFloat = 24
    static let space6: CGFloat = 32
    static let space7: CGFloat = 48

    static let pageMargin: CGFloat = 16   // DesignTokens.pageMargin
    static let hitTarget: CGFloat = 44   // HIG minimum, DesignTokens.hitTarget
    static let rowMinHeight: CGFloat = 52
    static let markSize: CGFloat = 56

    // Corner radius. Mirror of DesignTokens.radius*.
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusCard: CGFloat = 20

    // Motion — same three tiers as DesignTokens (0.16/0.18/0.22,
    // easeInOut; spring for toggles). No local durations anywhere.
    static let durationFast: Double = 0.16
    static let durationStandard: Double = 0.18
    static let durationSlow: Double = 0.22
    static var easeFast: Animation { Animation.easeInOut(duration: durationFast) }
    static var easeStandard: Animation { Animation.easeInOut(duration: durationStandard) }
    static var easeSlow: Animation { Animation.easeInOut(duration: durationSlow) }
    static var springToggle: Animation {
        Animation.spring(response: durationStandard, dampingFraction: 0.85)
    }

    // Semantic colours resolved per scheme. Hex values are
    // SoraPalette's (Design.swift), which are the Flutter Palette's.
    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x0B / 255, green: 0x0B / 255, blue: 0x0C / 255)
            : Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255)
    }
    static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255)
            : Color.white
    }
    static func field(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2E / 255)
            : Color(red: 0xEB / 255, green: 0xEB / 255, blue: 0xEF / 255)
    }
    static func ink(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255)
            : Color(red: 0x1D / 255, green: 0x1D / 255, blue: 0x1F / 255)
    }
    static func ink2(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x98 / 255, green: 0x98 / 255, blue: 0x9F / 255)
            : Color(red: 0x63 / 255, green: 0x66 / 255, blue: 0x6C / 255)
    }
    /// Destructive actions only — mirror of SoraPalette.danger.
    static var danger: Color { Color(red: 0xFF / 255, green: 0x5D / 255, blue: 0x52 / 255) }
    static var statusOn: Color { Color(red: 0.20, green: 0.78, blue: 0.35) }
    static var statusBusy: Color { Color(red: 0.95, green: 0.65, blue: 0.15) }
    static var statusOff: Color { Color.secondary }
}

/// The Sora mark without `Canvas` (iOS 15): the same two-half
/// silhouette as `SoraMarkView` (master space 1254, logo.dart),
/// expressed as a SwiftUI `Shape` — Shapes exist since SwiftUI 1.
struct LegacyMarkView: View {
    var size: CGFloat = 44
    var color: Color = Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255)

    var body: some View {
        LegacyMarkShape()
            .fill(color)
            .frame(width: size, height: size)
            .accessibility(hidden: true)
    }
}

struct LegacyMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 1254
        var path = Path()
        // Upper half silhouette (master coordinates, logo.dart) —
        // identical point list to SoraMarkView.
        path.move(to: CGPoint(x: 493, y: 154))
        path.addLine(to: CGPoint(x: 1090, y: 154))
        path.addLine(to: CGPoint(x: 880, y: 357))
        path.addLine(to: CGPoint(x: 512, y: 357))
        path.addCurve(to: CGPoint(x: 462, y: 470),
                      control1: CGPoint(x: 440, y: 357), control2: CGPoint(x: 410, y: 420))
        path.addLine(to: CGPoint(x: 706, y: 716))
        path.addLine(to: CGPoint(x: 465, y: 716))
        path.addQuadCurve(to: CGPoint(x: 420, y: 702), control: CGPoint(x: 434, y: 716))
        path.addLine(to: CGPoint(x: 250, y: 532))
        path.addQuadCurve(to: CGPoint(x: 250, y: 397), control: CGPoint(x: 182, y: 464))
        path.closeSubpath()
        let centre = CGPoint(x: 643, y: 615)
        var transform = CGAffineTransform(translationX: centre.x, y: centre.y)
            .rotated(by: CGFloat.pi)
            .translatedBy(x: -centre.x, y: -centre.y)
        path.addPath(path.applying(transform))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

/// The standard empty/state block (mirror of `SoraEmptyStateView`):
/// a plain-language title, one explanatory line, and the resolving
/// action when one exists. Never a bare "No data".
struct LegacyEmptyStateView: View {
    let titleKey: LocalizedStringKey
    let messageKey: LocalizedStringKey
    var actionTitleKey: LocalizedStringKey?
    var action: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: LegacyDesignTokens.space3) {
            LegacyMarkView(size: LegacyDesignTokens.markSize,
                           color: LegacyDesignTokens.ink2(for: scheme))
            Text(titleKey)
                .font(.headline)
                .foregroundColor(LegacyDesignTokens.ink(for: scheme))
                .multilineTextAlignment(.center)
            Text(messageKey)
                .font(.subheadline)
                .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if actionTitleKey != nil && action != nil {
                Button(action: { action?() }) {
                    Text(actionTitleKey ?? "")
                        .padding(.horizontal, LegacyDesignTokens.space4)
                        .frame(minHeight: LegacyDesignTokens.hitTarget)
                }
                .background(LegacyDesignTokens.field(for: scheme))
                .cornerRadius(LegacyDesignTokens.radiusMedium)
                .accessibility(hint: Text("state.emptyStateActionHint"))
            }
        }
        .padding(LegacyDesignTokens.space5)
        .frame(maxWidth: CGFloat.infinity)
    }
}

/// Icon + text row label: `Label` is SwiftUI 2 (iOS 14); this is the
/// SwiftUI-1 equivalent used by legacy screens wherever the main app
/// uses `Label(_:systemImage:)`.
struct LegacyLabel: View {
    let titleKey: LocalizedStringKey
    let systemImage: String

    var body: some View {
        HStack(spacing: LegacyDesignTokens.space2) {
            Image(systemName: systemImage)
            Text(titleKey)
        }
    }
}

/// Activity indicator: `ProgressView` is SwiftUI 2 (iOS 14).
struct LegacyActivityIndicator: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: .medium)
        view.startAnimating()
        return view
    }
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {}
}

/// Multiline text editor: `TextEditor` is SwiftUI 2 (iOS 14). This
/// UITextView wrapper is the era's standard replacement and is used
/// for the paste field, DNS and split-tunnel route editors.
struct LegacyMultilineTextField: UIViewRepresentable {
    @Binding var text: String
    @Environment(\.colorScheme) private var scheme

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.backgroundColor = UIColor.clear
        view.text = text
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: LegacyMultilineTextField
        init(_ parent: LegacyMultilineTextField) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text ?? ""
        }
    }
}

/// Byte formatting — mirror of the shared `ByteFormat` (Design.swift),
/// which the legacy target cannot include: that file also carries
/// `SoraMarkView`, drawn with `Canvas` (iOS 15). Same formatter and
/// count style, so numbers read identically across targets.
enum LegacyByteFormat {
    static func string(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

/// Prominent button look without the iOS 15 button styles: accent
/// background from the asset colour, token radius, HIG hit target.
/// Used for the primary action of a screen (connect, onboarding CTA).
struct LegacyProminentButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.white)
            .background(Color.accentColor)
            .cornerRadius(LegacyDesignTokens.radiusMedium)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

/// Bordered button look (companion to the prominent style).
struct LegacyBorderedButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(LegacyDesignTokens.ink(for: scheme))
            .background(
                RoundedRectangle(cornerRadius: LegacyDesignTokens.radiusMedium)
                    .stroke(LegacyDesignTokens.ink2(for: scheme), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
