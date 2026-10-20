import SwiftUI

/// App entry point (task §1).
///
/// Scenes:
///  * the main window (always);
///  * the menu bar — installed through the capability ladder
///    (`FeatureAvailability.menuBarBackend`): `MenuBarExtra` on
///    macOS 13+, otherwise the `StatusItemController` created by
///    `AppDelegate`. SwiftUI cannot conditionally declare a Scene,
///    so the modern scene is installed via the `@available` wrapper
///    type and the body picks it only when the probe says so; on
///    11–12 the body contains just the window and the AppKit status
///    item does the job — same content model, same behaviour.
@main
public struct SoraMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState.shared

    public init() {}

    public var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(state)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(tr("mac.servers.import", "Import…")) {
                    NotificationCenter.default.post(name: .soraOpenImport, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                .accessibilityLabel(tr("mac.servers.import", "Import servers"))
            }
            CommandMenu(tr("mac.menu.connection", "Connection")) {
                Button(TunnelManager.shared.phase.isConnected
                       ? tr("mac.disconnect", "Disconnect") : tr("mac.connect", "Connect")) {
                    Task { await TunnelManager.shared.toggle() }
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                .accessibilityLabel(TunnelManager.shared.phase.isConnected
                                     ? tr("mac.disconnect", "Disconnect") : tr("mac.connect", "Connect"))
            }
        }

        // Modern menu-bar backend (13+). On 11–12 this scene is not
        // installed; AppDelegate's StatusItemController is used.
        if FeatureAvailability.menuBarBackend == .menuBarExtra {
            if #available(macOS 13.0, *) {
                SoraMenuBarScene()
            }
        }
    }
}
