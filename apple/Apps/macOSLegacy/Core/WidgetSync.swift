import Foundation

/// LEGACY REPLACEMENT — macOSLegacy target (deployment target 11.0).
///
/// Replaces: `Apps/macOS/SoraMac/Core/WidgetSync.swift`
/// (same type name, same methods, so `AppState` and `TunnelManager`
/// are reused unchanged).
///
/// Why a replacement exists: the original, after publishing the App
/// Group snapshot, also asks the widget centre to reload timelines.
/// The legacy composition embeds no widget extension (the widget
/// targets are excluded — see TARGET-NOTES.md), so there is no
/// timeline to reload and no reason to link the widget framework into
/// this target at all.
///
/// Everything else is byte-for-byte the original behaviour, and it
/// matters: `publishExchange` is not a widget concern — it is how the
/// tunnel config reaches the provider (App Group suite key plus the
/// `current-config.json` file of ARCHITECTURE.md §3.4) — and
/// `publish(_:)` keeps the snapshot current for Handoff and for any
/// future reader of the same App Group keys. Dropping the file
/// instead of replacing it would have broken the tunnel, not just
/// the widget.
public enum WidgetSync {
    public static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppIdentifiers.appGroupID)
    }

    public static func publish(_ snapshot: SharedTunnelSnapshot) {
        guard let defaults = sharedDefaults,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: AppIdentifiers.AppGroupKey.tunnelSnapshot)
        // No timeline reload: the legacy target embeds no widget.
        // The snapshot itself is still published on every change,
        // exactly as in the main client.
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
