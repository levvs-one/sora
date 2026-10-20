import SwiftUI

/// First-run screen: what Sora is, in three short lines, and the one
/// action that makes the app useful — import a server or subscription.
/// No permission requests here (VPN approval happens on first connect,
/// notifications from Settings): asking early is a dark pattern.
public struct OnboardingView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.colorScheme) private var scheme
    @State private var showImport = false

    public init() {}

    public var body: some View {
        VStack(spacing: DesignTokens.space5) {
            Spacer(minLength: DesignTokens.space6)
            SoraMarkView(size: DesignTokens.markSize * 2,
                         color: DesignTokens.ink(for: scheme))
                .accessibilityHidden(true)
            Text("onboardingTitle")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(DesignTokens.ink(for: scheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: DesignTokens.space3) {
                Label("onboardingPointServers", systemImage: "server.rack")
                Label("onboardingPointPrivacy", systemImage: "lock.shield")
                Label("onboardingPointControl", systemImage: "slider.horizontal.3")
            }
            .font(.body)
            .foregroundStyle(DesignTokens.ink2(for: scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.space2)
            Spacer(minLength: DesignTokens.space4)
            Button {
                showImport = true
            } label: {
                Text("importTitle")
                    .frame(maxWidth: .infinity, minHeight: DesignTokens.hitTarget)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(Text("importTitle"))
            .accessibilityHint(Text("onboardingImportHint"))
            Button {
                router.finishOnboarding()
            } label: {
                Text("onboardingLater")
                    .frame(maxWidth: .infinity, minHeight: DesignTokens.hitTarget)
            }
            .accessibilityLabel(Text("onboardingLater"))
            .accessibilityHint(Text("onboardingLaterHint"))
        }
        .padding(DesignTokens.space5)
        .background(DesignTokens.background(for: scheme))
        .sheet(isPresented: $showImport, onDismiss: { router.finishOnboarding() }) {
            ImportView(prefill: "")
        }
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingView().preferredColorScheme(.dark)
            OnboardingView().preferredColorScheme(.light)
        }
        .environmentObject(AppRouter())
    }
}
#endif
