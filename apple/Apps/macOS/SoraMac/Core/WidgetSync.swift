import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Publishes the tunnel snapshot to the App Group so the WidgetKit
/// widget (and only it — no network, no provider IPC) can render
/// status, and mirrors the exchange/config for the provider
/// (ARCHITECTURE.md §3.4, §4.3).
public enum WidgetSync {
    public static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppIdentifiers.appGroupID)
    }

    public static func publish(_ snapshot: SharedTunnelSnapshot) {
        guard let defaults = sharedDefaults,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: AppIdentifiers.AppGroupKey.tunnelSnapshot)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "SoraStatusWidget")
        #endif
    }

    public static func currentSnapshot() -> SharedTunnelSnapshot {
        guard let data = sharedDefaults?.data(forKey: AppIdentifiers.AppGroupKey.tunnelSnapshot),
              let snap = try? JSONDecoder().decode(SharedTunnelSnapshot.self, from: data)
        else { return .disconnected }
        return snap
    }

    public static func publishSelectedServer(id: String?) {
        sharedDefaults?.set(id, forKey: AppIdentifiers.AppGroupKey.activeProfileID)
    }

    public static func publishOnDemand(_ enabled: Bool) {
        sharedDefaults?.set(enabled, forKey: AppIdentifiers.AppGroupKey.onDemandEnabled)
    }

    /// Writes the exchange twice, as the shared contract prescribes:
    /// into the App Group suite (`sora.tunnel.config.v1`) and as the
    /// `current-config.json` file in the App Group container (§3.4).
    public static func publishExchange(_ exchange: MacTunnelConfigExchange) {
        if let data = try? JSONEncoder().encode(exchange) {
            sharedDefaults?.set(data, forKey: AppIdentifiers.AppGroupKey.tunnelConfig)
            if let dir = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppIdentifiers.appGroupID) {
                try? data.write(to: dir.appendingPathComponent(AppIdentifiers.configFileName),
                                options: [.atomic])
            }
        }
    }
}
