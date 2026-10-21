import Foundation
import UIKit
import SoraCore

/// The legacy target's object-graph wrapper — the role `@StateObject`
/// plays in the main app (`SoraApp`), rebuilt for iOS 13, where
/// `@StateObject` does not exist: models are created once here, owned
/// by the `AppDelegate`, and handed to SwiftUI as `@ObservedObject` /
/// environment objects by the scene delegate.
///
/// The view models themselves are the main app's (`TunnelManager`,
/// `ServersViewModel`, `SettingsViewModel` — shared sources, see
/// TARGET-NOTES.md): their API surface (ObservableObject + @Published +
/// async methods) is SwiftUI-1 compatible, so the legacy app reuses
/// them unchanged instead of forking state logic that would drift.
final class AppState: ObservableObject {

    let tunnel: TunnelManager
    let servers: ServersViewModel
    let settingsModel: SettingsViewModel
    let router = LegacyRouter()

    /// Theme choice, persisted under the same key the main app uses
    /// for `@AppStorage` (iOS 14+, unavailable here), so a user moving
    /// between targets keeps the choice. Values: system/dark/light —
    /// the `themeSystem/themeDark/themeLight` glossary values.
    @Published var themeRaw: String {
        didSet {
            UserDefaults.standard.set(themeRaw, forKey: Self.themeKey)
            applyInterfaceStyle()
        }
    }
    private static let themeKey = "sora.theme.v1"

    init() {
        let store: ProfilePersisting
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SoraIdentifiers.appGroup) {
            store = JSONFileProfileStore(directory: container)
        } else {
            store = JSONFileProfileStore(directory: FileManager.default.temporaryDirectory)
        }
        tunnel = TunnelManager(store: store)
        servers = ServersViewModel(store: store)
        settingsModel = SettingsViewModel(store: store)
        themeRaw = UserDefaults.standard.string(forKey: Self.themeKey) ?? "system"
        router.appState = self
    }

    /// `UIUserInterfaceStyle` is the iOS 13 mechanism for the same
    /// choice the main app expresses as `preferredColorScheme`.
    var interfaceStyle: UIUserInterfaceStyle {
        switch themeRaw {
        case "dark": return .dark
        case "light": return .light
        default: return .unspecified
        }
    }

    private func applyInterfaceStyle() {
        for scene in UIApplication.shared.connectedScenes {
            (scene.delegate as? SceneDelegate)?.window?.overrideUserInterfaceStyle = interfaceStyle
        }
    }

    // MARK: Connect flow (preflight through the tier adapter)

    /// Connect entry point for every legacy screen and shortcut.
    /// The config is first built through `LegacyEngineConfig` — the
    /// legacy tier's single config-construction call site — so a
    /// config the lx.15 engine would reject fails here, in the app,
    /// with the honest `alert.configBuildFailed` state, before any
    /// VPN profile is touched. `TunnelManager.connect` then performs
    /// the profile save + tunnel start. (Integration note for the
    /// coordinator: once `LibboxConfigBuilder` accepts the tier
    /// parameter, route TunnelManager's internal build through the
    /// injected adapter — see TARGET-NOTES.md §4.)
    func connectSelected() {
        guard let profile = servers.profiles.first else {
            servers.alertKey = SoraAppError.noProfileSelected.localizationKey
            return
        }
        connect(profile: profile)
    }

    func connect(profile: ServerProfile) {
        let settings = settingsModel.settings
        do {
            _ = try LegacyEngineConfig.buildConfig(profile: profile, settings: settings)
        } catch {
            servers.alertKey = SoraAppError.configBuildFailed.localizationKey
            return
        }
        LegacyTask.run { [tunnel] in
            try? await tunnel.connect(profile: profile, settings: settings)
        }
    }

    func disconnect() {
        tunnel.disconnect()
    }

    func switchServer(to profile: ServerProfile) {
        let settings = settingsModel.settings
        do {
            _ = try LegacyEngineConfig.buildConfig(profile: profile, settings: settings)
        } catch {
            servers.alertKey = SoraAppError.configBuildFailed.localizationKey
            return
        }
        LegacyTask.run { [tunnel] in
            try? await tunnel.switchServer(to: profile, settings: settings)
        }
    }

    // MARK: Shortcuts / quick actions (limited mode, ARCHITECTURE §5.2)

    /// Handles both donated Siri activities and Home-screen quick
    /// actions. Actions go through the same approval-respecting path
    /// as a manual tap — never around `TunnelManager`.
    @discardableResult
    func handleQuickAction(_ type: String) -> Bool {
        handleShortcutAction(type)
    }

    @discardableResult
    func handleShortcutAction(_ action: String) -> Bool {
        switch action {
        case LegacyShortcuts.connectAction:
            connectSelected()
            return true
        case LegacyShortcuts.disconnectAction:
            disconnect()
            return true
        case LegacyShortcuts.statusAction:
            router.selectedTab = .servers
            return true
        default:
            return false
        }
    }
}
