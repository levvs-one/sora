import Foundation
#if canImport(AppIntents)
import AppIntents
#endif

/// Shortcuts / AppIntents (mandate §4): Connect, Disconnect, Status —
/// plus SwitchServer, which ARCHITECTURE.md §4.4 names in the same
/// surface. Available on macOS 13+ (`@available`); on macOS 11–12
/// AppIntents does not exist and there is no honest equivalent —
/// Settings reports the capability as unavailable rather than
/// shipping a half-working SiriKit port (see README).
///
/// Intents route through `TunnelManager` exactly like a tap in the
/// UI: the same extension-approval and profile gates apply, and a
/// blocked connect returns the designed `state.*` text, never a raw
/// error.
#if canImport(AppIntents)
@available(macOS 13.0, *)
public struct ConnectIntent: AppIntent {
    public static var title: LocalizedStringResource = "mac.intent.connect.title"
    public static var description = IntentDescription("mac.intent.connect.description")
    public init() {}
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let server = await AppState.shared.selectedServer else {
            return .result(dialog: IntentDialog(stringLiteral:
                tr("alert.noProfileSelected", "No server is selected. Pick a server first, then connect.")))
        }
        await TunnelManager.shared.connect(to: server)
        let phase = await TunnelManager.shared.phase
        return .result(dialog: IntentDialog(stringLiteral: phase.localizedTitle))
    }
}

@available(macOS 13.0, *)
public struct DisconnectIntent: AppIntent {
    public static var title: LocalizedStringResource = "mac.intent.disconnect.title"
    public static var description = IntentDescription("mac.intent.disconnect.description")
    public init() {}
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        await TunnelManager.shared.disconnect()
        return .result(dialog: IntentDialog(stringLiteral: tr("state.disconnected", "Disconnected")))
    }
}

@available(macOS 13.0, *)
public struct StatusIntent: AppIntent {
    public static var title: LocalizedStringResource = "mac.intent.status.title"
    public static var description = IntentDescription("mac.intent.status.description")
    public init() {}
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let tunnel = TunnelManager.shared
        let phase = await tunnel.phase
        let server = await tunnel.currentServer
        var text = phase.localizedTitle
        if let server, phase.isConnected { text += " — \(server.name)" }
        return .result(dialog: IntentDialog(stringLiteral: text))
    }
}

@available(macOS 13.0, *)
public struct SwitchServerIntent: AppIntent {
    public static var title: LocalizedStringResource = "mac.intent.switch.title"
    public static var description = IntentDescription("mac.intent.switch.description")
    @Parameter(title: "mac.intent.switch.server")
    public var serverName: String
    public init() {}
    public init(serverName: String) { self.serverName = serverName }
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let state = AppState.shared
        guard let server = await state.servers.first(where: {
            $0.name.localizedCaseInsensitiveCompare(serverName) == .orderedSame
        }) else {
            return .result(dialog: IntentDialog(stringLiteral:
                tr("mac.intent.switch.notFound", "No server with that name was found.")))
        }
        await MainActor.run { state.select(server) }
        await TunnelManager.shared.connect(to: server)
        return .result(dialog: IntentDialog(stringLiteral:
            String(format: tr("mac.a11y.connectTo", "Connect to %@"), server.name)))
    }
}

@available(macOS 13.0, *)
public struct SoraShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: ConnectIntent(),
                    phrases: ["Connect with \(.applicationName)"],
                    shortTitle: "mac.intent.connect.title",
                    systemImageName: "shield")
        AppShortcut(intent: DisconnectIntent(),
                    phrases: ["Disconnect \(.applicationName)"],
                    shortTitle: "mac.intent.disconnect.title",
                    systemImageName: "shield.slash")
        AppShortcut(intent: StatusIntent(),
                    phrases: ["\(.applicationName) status"],
                    shortTitle: "mac.intent.status.title",
                    systemImageName: "info.circle")
    }
}
#endif
