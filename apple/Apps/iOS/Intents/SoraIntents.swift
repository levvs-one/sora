import Foundation
#if canImport(AppIntents)
import AppIntents
#endif
import SoraCore

/// Shortcuts / Siri intents: Connect, Disconnect, Status.
///
/// AppIntents requires iOS 16 — the whole file is gated on availability,
/// a capability branch (the framework does not exist before 16), not a
/// bare version check in feature code. On iOS 15 the designed fallback
/// is SiriKit `INIntent` handlers: DESIGNED, NOT IMPLEMENTED in this
/// pass — the Info.plist still declares the AppIntents surface, and the
/// fallback is recorded in Apps/iOS/README.md. Older systems keep full
/// functionality in-app; nothing is faked.
///
/// Intents act through the same store + a short-lived
/// NETunnelProviderManager session as the UI, and they respect the
/// approval state: without an approved VPN profile they answer with the
/// localized `state.intentNeedsAppApproval` text (existing key) instead
/// of failing silently.
#if canImport(AppIntents)
@available(iOS 16.0, *)
public struct ConnectIntent: AppIntent {
    public static var title: LocalizedStringResource = "intentConnectTitle"
    public static var description = IntentDescription("intentConnectDescription")
    public static var openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = JSONFileProfileStore.sharedContainer()
        let profiles = (try? store.load()) ?? []
        guard let first = profiles.first else {
            return .result(dialog: IntentDialog(
                stringLiteral: NSLocalizedString("intentNoServer", comment: "")))
        }
        let manager = TunnelManager(store: store)
        await manager.load()
        do {
            let settings = (try? store.loadSettings()) ?? AppSettings()
            try await manager.connect(profile: first, settings: settings)
            return .result(dialog: IntentDialog(
                stringLiteral: NSLocalizedString("intentConnected", comment: "")))
        } catch {
            return .result(dialog: IntentDialog(
                stringLiteral: NSLocalizedString("state.intentNeedsAppApproval", comment: "")))
        }
    }
}

@available(iOS 16.0, *)
public struct DisconnectIntent: AppIntent {
    public static var title: LocalizedStringResource = "intentDisconnectTitle"
    public static var description = IntentDescription("intentDisconnectDescription")
    public static var openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = TunnelManager(store: JSONFileProfileStore.sharedContainer())
        await manager.load()
        manager.disconnect()
        return .result(dialog: IntentDialog(
            stringLiteral: NSLocalizedString("intentDisconnected", comment: "")))
    }
}

@available(iOS 16.0, *)
public struct StatusIntent: AppIntent {
    public static var title: LocalizedStringResource = "intentStatusTitle"
    public static var description = IntentDescription("intentStatusDescription")
    public static var openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = TunnelManager(store: JSONFileProfileStore.sharedContainer())
        await manager.load()
        let key = manager.state.localizationKey
        var text = NSLocalizedString(key, comment: "")
        if manager.state.isConnected, let name = manager.activeServerName {
            text += " — \(name)"
        }
        return .result(dialog: IntentDialog(stringLiteral: text))
    }
}

@available(iOS 16.0, *)
public struct SoraShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: ConnectIntent(),
                    phrases: ["intentConnectPhrase"],
                    shortTitle: "intentConnectTitle",
                    systemImageName: "lock.shield")
        AppShortcut(intent: DisconnectIntent(),
                    phrases: ["intentDisconnectPhrase"],
                    shortTitle: "intentDisconnectTitle",
                    systemImageName: "shield.slash")
        AppShortcut(intent: StatusIntent(),
                    phrases: ["intentStatusPhrase"],
                    shortTitle: "intentStatusTitle",
                    systemImageName: "info.circle")
    }
}
#endif
