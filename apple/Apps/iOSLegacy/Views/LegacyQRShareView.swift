import SwiftUI
import SoraCore
#if canImport(UIKit)
import UIKit
#endif

/// Share one server as a QR code + copyable link, for iOS 13–14 —
/// same honesty contract as the main app's QRShareView: the link comes
/// from the shared `LinkEncoder`; profiles that cannot round-trip get
/// the designed unavailable state instead of a lossy code; the link
/// (which contains the server's secret) stays hidden until revealed,
/// with the same `qrWarning` text. SwiftUI-1 deltas: no
/// `.textSelection` (iOS 15) — the copy button is the access path —
/// and the copy feedback timer uses the legacy task shim.
struct LegacyQRShareView: View {
    let profile: ServerProfile
    @Environment(\.colorScheme) private var scheme
    @State private var showLink = false
    @State private var copied = false

    init(profile: ServerProfile) { self.profile = profile }

    private var link: String? { LinkEncoder.encode(profile) }

    var body: some View {
        NavigationView {
            VStack(spacing: LegacyDesignTokens.space4) {
                Text(profile.name.isEmpty ? profile.address : profile.name)
                    .font(.headline)
                    .foregroundColor(LegacyDesignTokens.ink(for: scheme))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)
                    .accessibility(label: Text(profile.name.isEmpty ? profile.address : profile.name))

                if link != nil {
                    shareContent(link: link!)
                } else {
                    LegacyEmptyStateView(
                        titleKey: "qrShareUnavailableTitle",
                        messageKey: "qrShareUnavailableMessage")
                }
                Spacer()
            }
            .padding(LegacyDesignTokens.space4)
            .background(LegacyDesignTokens.background(for: scheme).edgesIgnoringSafeArea(.all))
            .navigationBarTitle(Text("qrShareTitle"), displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func shareContent(link: String) -> some View {
        VStack(spacing: LegacyDesignTokens.space4) {
            LegacyQRCodeImageView(text: link)
                .frame(width: 220, height: 220)
                .padding(LegacyDesignTokens.space3)
                .background(
                    RoundedRectangle(cornerRadius: LegacyDesignTokens.radiusMedium)
                        .fill(Color.white))
                .accessibility(label: Text("qrShareTitle"))
                .accessibility(hint: Text("qrWarning"))

            HStack(spacing: LegacyDesignTokens.space2) {
                Image(systemName: "exclamationmark.shield")
                Text("qrWarning")
            }
            .font(.footnote)
            .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
            .fixedSize(horizontal: false, vertical: true)

            if showLink {
                Text(link)
                    .font(Font.system(.footnote, design: .monospaced))
                    .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                    .lineLimit(3)
                    .truncationMode(.middle)
                    .accessibility(label: Text("qrShareTitle"))
            }

            HStack(spacing: LegacyDesignTokens.space3) {
                Button(showLink ? "qrHideLink" : "qrShowLink") {
                    withAnimation(LegacyDesignTokens.easeFast) { showLink.toggle() }
                }
                .frame(minHeight: LegacyDesignTokens.hitTarget)
                .accessibility(label: Text(showLink ? "qrHideLink" : "qrShowLink"))
                Button(copied ? "copied" : "qrCopyLink") {
                    copy(link)
                }
                .frame(minHeight: LegacyDesignTokens.hitTarget)
                .accessibility(label: Text("qrCopyLink"))
                .accessibility(hint: Text("qrWarning"))
            }
        }
    }

    private func copy(_ link: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = link
        #endif
        withAnimation(LegacyDesignTokens.easeFast) { copied = true }
        LegacyTask.run {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            copied = false
        }
    }
}

/// QR rendering via CoreImage (`CIQRCodeGenerator`) — identical
/// generator to the main app's QRCodeImageView; failure shows the
/// designed fallback, not a blank square.
struct LegacyQRCodeImageView: View {
    let text: String

    init(text: String) { self.text = text }

    var body: some View {
        Group {
            if Self.makeImage(text: text) != nil {
                Image(uiImage: Self.makeImage(text: text)!)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                LegacyEmptyStateView(titleKey: "qrInvalid",
                                     messageKey: "qrShareUnavailableMessage")
            }
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
