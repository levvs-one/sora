import SwiftUI
import SoraCore
#if canImport(UIKit)
import UIKit
#endif

/// Share one server as a QR code + copyable link. The link comes from
/// `LinkEncoder` (app layer, mirroring `LinkParser`); profiles that
/// cannot round-trip hide this screen's content behind an honest state
/// instead of emitting a lossy code. The link contains the server's
/// secret — the screen warns (existing `qrWarning` key) and the link
/// text itself is hidden until the user reveals it (`qrShowLink`).
public struct QRShareView: View {
    public let profile: ServerProfile
    @Environment(\.colorScheme) private var scheme
    @State private var showLink = false
    @State private var copied = false

    public init(profile: ServerProfile) { self.profile = profile }

    private var link: String? { LinkEncoder.encode(profile) }

    public var body: some View {
        VStack(spacing: DesignTokens.space4) {
            Text(profile.name.isEmpty ? profile.address : profile.name)
                .font(.headline)
                .foregroundStyle(DesignTokens.ink(for: scheme))
                .lineLimit(2)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .accessibilityLabel(Text(profile.name.isEmpty ? profile.address : profile.name))

            if let link {
                QRCodeImageView(text: link)
                    .frame(width: 220, height: 220)
                    .padding(DesignTokens.space3)
                    .background(Color.white,
                                in: RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                    .accessibilityLabel(Text("qrShareTitle"))
                    .accessibilityHint(Text("qrWarning"))

                Label("qrWarning", systemImage: "exclamationmark.shield")
                    .font(.footnote)
                    .foregroundStyle(DesignTokens.ink2(for: scheme))
                    .fixedSize(horizontal: false, vertical: true)

                if showLink {
                    Text(link)
                        .font(.footnote.monospaced())
                        .foregroundStyle(DesignTokens.ink2(for: scheme))
                        .lineLimit(3)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                        .accessibilityLabel(Text("qrShareTitle"))
                }

                HStack(spacing: DesignTokens.space3) {
                    Button(showLink ? "qrHideLink" : "qrShowLink") {
                        withAnimation(DesignTokens.easeFast) { showLink.toggle() }
                    }
                    .frame(minHeight: DesignTokens.hitTarget)
                    .accessibilityLabel(Text(showLink ? "qrHideLink" : "qrShowLink"))
                    Button(copied ? "copied" : "qrCopyLink") {
                        copy(link)
                    }
                    .frame(minHeight: DesignTokens.hitTarget)
                    .accessibilityLabel(Text("qrCopyLink"))
                    .accessibilityHint(Text("qrWarning"))
                }
            } else {
                SoraEmptyStateView(
                    titleKey: "qrShareUnavailableTitle",
                    messageKey: "qrShareUnavailableMessage")
            }
            Spacer()
        }
        .padding(DesignTokens.space4)
        .background(DesignTokens.background(for: scheme))
        .navigationTitle(Text("qrShareTitle"))
    }

    private func copy(_ link: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = link
        #endif
        withAnimation(DesignTokens.easeFast) { copied = true }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            copied = false
        }
    }
}

/// QR rendering via CoreImage (`CIQRCodeGenerator`) — no third-party
/// dependency. Generation failure shows the designed fallback, not a
/// blank square.
public struct QRCodeImageView: View {
    public let text: String
    @Environment(\.colorScheme) private var scheme

    public init(text: String) { self.text = text }

    public var body: some View {
        if let image = Self.makeImage(text: text) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            SoraEmptyStateView(titleKey: "qrInvalid", messageKey: "qrShareUnavailableMessage")
        }
    }

    private static func makeImage(text: String) -> UIImage? {
        #if canImport(UIKit)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(text.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
        #else
        return nil
        #endif
    }
}

#if DEBUG
struct QRShareView_Previews: PreviewProvider {
    static var previews: some View {
        let profile = ServerProfile(name: "Preview", protocol: .vless,
                                    address: "example.com", port: 443,
                                    uuid: "00000000-0000-0000-0000-000000000000")
        return Group {
            QRShareView(profile: profile).preferredColorScheme(.dark)
            QRShareView(profile: profile).preferredColorScheme(.light)
        }
    }
}
#endif
