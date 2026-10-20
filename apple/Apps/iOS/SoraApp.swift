import SwiftUI
import SoraCore

/// Sora for iOS — entry point.
///
/// Object graph: one `TunnelManager`, one profile store in the App
/// Group container, view models per screen. Deep links (`sora://…` and
/// every LinkParser scheme) arrive via `onOpenURL` and are held by
/// `AppRouter` until the UI is ready, so a cold-start link is not lost.
/// Foregrounding after sleep sends the provider a `.wake` message.
@main
public struct SoraApp: App {
    @StateObject private var tunnel: TunnelManager
    @StateObject private var servers: ServersViewModel
    @StateObject private var settingsModel: SettingsViewModel
    @StateObject private var router = AppRouter()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("sora.theme.v1") private var themeRaw: String = "system"

    public init() {
        let store: ProfilePersisting
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SoraIdentifiers.appGroup) {
            store = JSONFileProfileStore(directory: container)
        } else {
            store = JSONFileProfileStore(directory: FileManager.default.temporaryDirectory)
        }
        _tunnel = StateObject(wrappedValue: TunnelManager(store: store))
        _servers = StateObject(wrappedValue: ServersViewModel(store: store))
        _settingsModel = StateObject(wrappedValue: SettingsViewModel(store: store))
        NotificationService.registerCategories()
    }

    public var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tunnel)
                .environmentObject(servers)
                .environmentObject(settingsModel)
                .environmentObject(router)
                .preferredColorScheme(ThemeChoice.scheme(for: themeRaw))
                .onOpenURL { url in router.route(url) }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL { router.route(url) }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    await tunnel.load()
                    await tunnel.notifyWake()
                }
            }
        }
    }
}
