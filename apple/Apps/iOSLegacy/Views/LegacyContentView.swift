import SwiftUI

/// Root tab shell for iOS 13–14 — mirrors the main app's ContentView
/// (Connection / Statistics / Settings), rebuilt on SwiftUI 1:
///  * sheets are boolean-driven (no `sheet(item:)` composition),
///  * held deep links are consumed on appear and via `onReceive`
///    (there is no `onChange` before iOS 14),
///  * initial load happens in `onAppear` (there is no `.task`).
/// Each tab keeps its own `NavigationView` (see the views), the
/// SwiftUI-1 navigation pattern; `StackNavigationViewStyle` keeps
/// iPhone layout single-column.
struct LegacyContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: LegacyRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            LegacyServersView()
                .tabItem {
                    Image(systemName: "server.rack")
                    Text("navServers")
                }
                .tag(LegacyRouter.Tab.servers)
                .accessibility(label: Text("navServers"))
            LegacyStatsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("navStats")
                }
                .tag(LegacyRouter.Tab.stats)
                .accessibility(label: Text("navStats"))
            LegacySettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("settings")
                }
                .tag(LegacyRouter.Tab.settings)
                .accessibility(label: Text("settings"))
        }
        .accentColor(Color("AccentColor"))
        .sheet(isPresented: $router.showOnboarding) {
            LegacyOnboardingView()
                .environmentObject(appState)
                .environmentObject(router)
                .environmentObject(appState.servers)
        }
        .sheet(isPresented: importSheetBinding) {
            LegacyImportView(prefill: router.pendingImportPayload ?? "")
                .environmentObject(appState.servers)
        }
        .onAppear {
            appState.servers.reload()
            LegacyTask.run { await appState.tunnel.load() }
            router.consumePendingDeepLink()
        }
        .onReceive(router.$pendingDeepLink) { _ in
            router.consumePendingDeepLink()
        }
    }

    /// Boolean view of the optional import payload (SwiftUI 1 sheet
    /// presentation is boolean-first; clearing the payload dismisses).
    private var importSheetBinding: Binding<Bool> {
        Binding(get: { router.pendingImportPayload != nil },
                set: { if !$0 { router.pendingImportPayload = nil } })
    }
}
