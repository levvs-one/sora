import SwiftUI

/// LEGACY REPLACEMENT — macOSLegacy target (deployment target 11.0).
///
/// Replaces: `Apps/macOS/SoraMac/SoraMacApp.swift`
/// (same type name, same window scene, same menu commands).
///
/// Why a replacement exists: the original declares a second scene —
/// the SwiftUI menu-bar scene that only exists from macOS 13 — and
/// installs it conditionally through the capability ladder. On
/// macOS 11–12 that scene type does not exist, so the legacy entry
/// point declares exactly one scene: the main window. The menu bar
/// is not missing; it is the `NSStatusItem` installed by
/// `AppDelegate` (reused unchanged — its backend choice goes through
/// the legacy `FeatureAvailability`, which always answers the
/// status-item backend here). Same content model, same behaviour,
/// no conditional scene machinery.
///
/// The SwiftUI app lifecycle itself is original to macOS 11, so
/// `@main`, `WindowGroup`, the delegate adaptor and `commands` are
/// all floor-clean and kept from the original verbatim.
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
    }
}
