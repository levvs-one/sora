import Foundation

/// Navigation + sheet state for the legacy app — the counterpart of
/// the main app's `AppRouter` (which lives inside its ContentView
/// file and uses iOS 14+ sheet APIs, so it cannot be shared verbatim).
/// Behaviour is identical: a link arriving before the UI is ready is
/// held in `pendingDeepLink`, not dropped; onboarding is a first-run
/// state, shown until the user imports or adds a first server.
///
/// SwiftUI-1 notes: presentation is driven by `@Published` booleans
/// and an optional payload the views observe — there is no
/// `sheet(item:)` dependency here (that API exists on iOS 13, but the
/// boolean + payload pair is what SwiftUI 1 sheets compose reliably).
final class LegacyRouter: ObservableObject {
    enum Tab: Hashable { case servers, stats, settings }

    @Published var selectedTab: Tab = .servers
    @Published var showOnboarding: Bool
    /// Payload for the import sheet (a share link or subscription URL
    /// delivered by a deep link); nil means "no pending import".
    @Published var pendingImportPayload: String?
    @Published var pendingDeepLink: DeepLink?

    /// Set by AppState after init (router is created first so the
    /// scene delegate can route into it before models exist).
    weak var appState: AppState?

    init() {
        showOnboarding = !UserDefaults.standard.bool(forKey: "sora.onboardingDone.v1")
    }

    func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "sora.onboardingDone.v1")
        showOnboarding = false
    }

    func route(_ url: URL) {
        pendingDeepLink = DeepLink.parse(url)
    }

    /// Consumes a held deep link. Called by the root view when it
    /// appears and whenever `pendingDeepLink` changes (SwiftUI 1 has
    /// no `onChange`; the root view polls via `onReceive`).
    func consumePendingDeepLink() {
        guard let link = pendingDeepLink else { return }
        pendingDeepLink = nil
        switch link {
        case .importPayload(let payload), .shareLink(let payload):
            pendingImportPayload = payload
            selectedTab = .servers
        case .connect:
            appState?.connectSelected()
        case .disconnect:
            appState?.disconnect()
        case .unknown:
            break
        }
    }
}
