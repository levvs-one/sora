import SwiftUI

/// First-run screen for iOS 13–14 — identical copy and discipline to
/// the main app's OnboardingView: what Sora is in three short lines,
/// the one action that makes the app useful (import), and NO
/// permission requests here. SwiftUI-1 deltas: icon+text rows are
/// manual HStacks (no `Label`), dismissal flows through the router
/// flag that presented the sheet.
struct LegacyOnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: LegacyRouter
    @EnvironmentObject private var servers: ServersViewModel
    @Environment(\.colorScheme) private var scheme
    @State private var showImport = false

    init() {}

    var body: some View {
        VStack(spacing: LegacyDesignTokens.space5) {
            Spacer(minLength: LegacyDesignTokens.space6)
            LegacyMarkView(size: LegacyDesignTokens.markSize * 2,
                           color: LegacyDesignTokens.ink(for: scheme))
            Text("onboardingTitle")
                .font(Font.largeTitle.weight(.semibold))
                .foregroundColor(LegacyDesignTokens.ink(for: scheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: LegacyDesignTokens.space3) {
                pointRow("onboardingPointServers", systemImage: "server.rack")
                pointRow("onboardingPointPrivacy", systemImage: "lock.shield")
                pointRow("onboardingPointControl", systemImage: "slider.horizontal.3")
            }
            .font(.body)
            .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
            .frame(maxWidth: CGFloat.infinity, alignment: .leading)
            .padding(.horizontal, LegacyDesignTokens.space2)
            Spacer(minLength: LegacyDesignTokens.space4)
            Button(action: { showImport = true }) {
                Text("importTitle")
                    .frame(maxWidth: CGFloat.infinity,
                           minHeight: LegacyDesignTokens.hitTarget)
            }
            .buttonStyle(LegacyProminentButtonStyle())
            .accessibility(label: Text("importTitle"))
            .accessibility(hint: Text("onboardingImportHint"))
            Button(action: { router.finishOnboarding() }) {
                Text("onboardingLater")
                    .frame(maxWidth: CGFloat.infinity,
                           minHeight: LegacyDesignTokens.hitTarget)
            }
            .accessibility(label: Text("onboardingLater"))
            .accessibility(hint: Text("onboardingLaterHint"))
        }
        .padding(LegacyDesignTokens.space5)
        .background(LegacyDesignTokens.background(for: scheme).edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showImport, onDismiss: { router.finishOnboarding() }) {
            LegacyImportView(prefill: "")
                .environmentObject(servers)
        }
    }

    private func pointRow(_ key: LocalizedStringKey, systemImage: String) -> some View {
        HStack(spacing: LegacyDesignTokens.space3) {
            Image(systemName: systemImage)
                .accessibility(hidden: true)
            Text(key)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
