import SwiftUI
import SoraCore

/// Root tab shell: Connection (servers + connect), Statistics,
/// Settings. Import lives inside the Servers tab toolbar and as a sheet
/// from onboarding and deep links.
public struct ContentView: View {
    @EnvironmentObject private var tunnel: TunnelManager
    @EnvironmentObject private var servers: ServersViewModel
    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var router: AppRouter
    @Environment(\.colorScheme) private var scheme

    public init() {}

    public var body: some View {
        TabView(selection: $router.selectedTab) {
            ServersView()
                .tabItem { Label("navServers", systemImage: "server.rack") }
                .tag(AppRouter.Tab.servers)
                .accessibilityLabel(Text("navServers"))
            StatsView()
                .tabItem { Label("navStats", systemImage: "chart.bar") }
                .tag(AppRouter.Tab.stats)
                .accessibilityLabel(Text("navStats"))
            SettingsView()
                .tabItem { Label("settings", systemImage: "gearshape") }
                .tag(AppRouter.Tab.settings)
                .accessibilityLabel(Text("settings"))
        }
        .tint(DesignTokens.ink(for: scheme))
        .sheet(isPresented: $router.showOnboarding) {
            OnboardingView()
        }
        .sheet(item: $router.pendingImport) { payload in
            ImportView(prefill: payload.value)
        }
        .task {
            await tunnel.load()
            servers.reload()
        }
        .onChange(of: router.pendingDeepLink) { _, link in
            handle(link)
        }
    }

    private func handle(_ link: DeepLink?) {
        guard let link else { return }
        switch link {
        case .importPayload(let payload), .shareLink(let payload):
            router.pendingImport = IdentifiedString(value: payload)
            router.selectedTab = .servers
        case .connect:
            if let profile = servers.profiles.first {
                Task { try? await tunnel.connect(profile: profile, settings: settings.settings) }
            }
        case .disconnect:
            tunnel.disconnect()
        case .unknown, .none:
            break
        }
        router.pendingDeepLink = nil
    }
}

/// Navigation + sheet state shared by the app entry, deep links and
/// intents. Kept out of the views so a link arriving before the UI is
/// ready is held, not dropped.
@MainActor
public final class AppRouter: ObservableObject {
    public enum Tab: Hashable { case servers, stats, settings }
    @Published public var selectedTab: Tab = .servers
    @Published public var showOnboarding: Bool
    @Published public var pendingImport: IdentifiedString?
    @Published public var pendingDeepLink: DeepLink?

    public init() {
        // Onboarding is a first-run state, not a timer: it shows until
        // the user imports or adds a first server, then never again.
        showOnboarding = !UserDefaults.standard.bool(forKey: "sora.onboardingDone.v1")
    }

    public func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "sora.onboardingDone.v1")
        showOnboarding = false
    }

    public func route(_ url: URL) {
        pendingDeepLink = DeepLink.parse(url)
    }
}

public struct IdentifiedString: Identifiable, Equatable {
    public let id = UUID()
    public let value: String
    public init(value: String) { self.value = value }
}
