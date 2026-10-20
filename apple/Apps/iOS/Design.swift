import SwiftUI

/// Palette parity with the Flutter app (`app/lib/src/design/theme.dart`):
/// the same cool neutrals, dark theme as the primary one, and the
/// Apple-Intelligence-style spectrum reserved for the connection glow.
/// Hex values are copied 1:1 from `Palette.light` / `Palette.dark`.
public enum SoraPalette {
    public static let darkBackground = Color(red: 0x0B / 255, green: 0x0B / 255, blue: 0x0C / 255)
    public static let darkSurface = Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255)
    public static let darkField = Color(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2E / 255)
    public static let darkInk = Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255)
    public static let darkInk2 = Color(red: 0x98 / 255, green: 0x98 / 255, blue: 0x9F / 255)
    public static let lightBackground = Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255)
    public static let lightSurface = Color.white
    public static let lightField = Color(red: 0xEB / 255, green: 0xEB / 255, blue: 0xEF / 255)
    public static let lightInk = Color(red: 0x1D / 255, green: 0x1D / 255, blue: 0x1F / 255)
    public static let lightInk2 = Color(red: 0x63 / 255, green: 0x66 / 255, blue: 0x6C / 255)
    /// Danger is for destructive *actions* (delete), never for status
    /// text: connection problems render as neutral state rows, matching
    /// the Flutter app's "no red errors in the UI" rule.
    public static let danger = Color(red: 0xFF / 255, green: 0x5D / 255, blue: 0x52 / 255)

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

/// The Sora mark: a geometric "S" drawn as two 180-degree-rotated halves,
/// mirroring `SoraMark` in `app/lib/src/design/logo.dart` (same 1254-unit
/// master space, simplified to the outer silhouette for small sizes).
public struct SoraMarkView: View {
    public var size: CGFloat = 44
    public var color: Color = SoraPalette.darkInk
    public init(size: CGFloat = 44, color: Color = SoraPalette.darkInk) {
        self.size = size; self.color = color
    }
    public var body: some View {
        Canvas { context, canvasSize in
            let scale = canvasSize.width / 1254
            var path = Path()
            // Upper half silhouette (master coordinates, logo.dart).
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
            // Lower half: the same path rotated 180 degrees about the centre.
            let centre = CGPoint(x: 643, y: 615)
            var transform = CGAffineTransform(translationX: centre.x, y: centre.y)
                .rotated(by: .pi)
                .translatedBy(x: -centre.x, y: -centre.y)
            let lower = path.applying(transform)
            path.addPath(lower)
            context.scaleBy(x: scale, y: scale)
            context.fill(path, with: .color(color))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Byte formatting shared by StatsView and the widget ("1.2 MB").
public enum ByteFormat {
    public static func string(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}
