import Foundation

/// App Group and provider-configuration contract shared by the iOS app,
/// the Packet Tunnel extension and the Widget extension.
///
/// Bundle-id style follows the repo-wide identifier
/// `io.github.levvs-one.sora` (polkit actions, desktop file, AppStream id).
public enum SoraIdentifiers {
    public static let appGroup = "group.io.github.levvs-one.sora"
    public static let appBundleID = "io.github.levvs-one.sora"
    public static let tunnelBundleID = "io.github.levvs-one.sora.PacketTunnel"
    public static let widgetBundleID = "io.github.levvs-one.sora.Widgets"
    public static let tunnelLocalizedDescription = "Sora"
}

/// Keys for the App Group `UserDefaults` suite. The app writes; the
/// provider and the widget read. Never store secrets anywhere else.
public enum AppGroupKey {
    /// `Data` — JSON-encoded `TunnelConfigExchange`.
    public static let tunnelConfig = "sora.tunnel.config.v1"
    /// `Data` — JSON-encoded `SharedTunnelSnapshot` for the widget.
    public static let tunnelSnapshot = "sora.tunnel.snapshot.v1"
    /// `Bool` — user asked for an always-on connection (on-demand rules).
    public static let onDemandEnabled = "sora.tunnel.onDemand.v1"
    /// `String` — id of the profile the tunnel should run.
    public static let activeProfileID = "sora.tunnel.activeProfile.v1"
}

/// Codable payload the app hands to the provider. It travels twice: as
/// `providerConfiguration` on the `NETunnelProviderProtocol` (the
/// authoritative copy, visible in Settings > VPN) and mirrored into the
/// App Group suite so the provider can re-read it after a system restart
/// where `protocolConfiguration` may be delivered empty.
public struct TunnelConfigExchange: Codable, Equatable, Sendable {
    /// Complete sing-box JSON produced by `LibboxConfigBuilder` (SoraCore).
    public var configJSON: String
    /// Display name of the selected server, for status reporting only.
    public var serverName: String
    /// Profile id, echoed back in status payloads so the app can tell a
    /// stale tunnel (old profile still running) from a fresh one.
    public var profileID: String
    public var tun: TunSettings
    public var updatedAt: Date

    public init(configJSON: String, serverName: String, profileID: String,
                tun: TunSettings, updatedAt: Date = Date()) {
        self.configJSON = configJSON
        self.serverName = serverName
        self.profileID = profileID
        self.tun = tun
        self.updatedAt = updatedAt
    }

    /// Keys inside `NETunnelProviderProtocol.providerConfiguration`.
    public enum ProviderKey {
        public static let configJSON = "configJSON"
        public static let serverName = "serverName"
        public static let profileID = "profileID"
        public static let tun = "tun"
    }

    public var providerDictionary: [String: Any] {
        var tunDict: [String: Any] = [
            "mtu": tun.mtu, "dnsServers": tun.dnsServers,
            "killSwitch": tun.killSwitch,
            "includedRoutes": tun.includedRoutes,
            "excludedRoutes": tun.excludedRoutes,
        ]
        if let ipv6 = tun.ipv6Address { tunDict["ipv6Address"] = ipv6 }
        return [ProviderKey.configJSON: configJSON,
                ProviderKey.serverName: serverName,
                ProviderKey.profileID: profileID,
                ProviderKey.tun: tunDict]
    }

    public init?(providerDictionary dict: [String: Any]?) {
        guard let dict,
              let json = dict[ProviderKey.configJSON] as? String,
              let name = dict[ProviderKey.serverName] as? String,
              let pid = dict[ProviderKey.profileID] as? String,
              let tunDict = dict[ProviderKey.tun] as? [String: Any],
              let mtu = tunDict["mtu"] as? Int else { return nil }
        configJSON = json; serverName = name; profileID = pid
        tun = TunSettings(
            mtu: mtu,
            dnsServers: tunDict["dnsServers"] as? [String] ?? [],
            killSwitch: tunDict["killSwitch"] as? Bool ?? true,
            includedRoutes: tunDict["includedRoutes"] as? [String] ?? [],
            excludedRoutes: tunDict["excludedRoutes"] as? [String] ?? [],
            ipv6Address: tunDict["ipv6Address"] as? String)
        updatedAt = Date()
    }
}

/// The TUN-facing slice of `AppSettings` (SoraCore) the provider needs to
/// build `NEPacketTunnelNetworkSettings`. Kept free of proxy secrets.
public struct TunSettings: Codable, Equatable, Sendable {
    public var mtu: Int
    public var dnsServers: [String]
    /// When true, the app enables on-demand rules so a dropped tunnel
    /// comes back, and no bypass route beyond the proxy endpoint itself
    /// is installed.
    public var killSwitch: Bool
    /// CIDR strings routed *into* the tunnel (split tunnelling).
    /// Empty means "route everything".
    public var includedRoutes: [String]
    /// CIDR strings routed *around* the tunnel.
    public var excludedRoutes: [String]
    public var ipv6Address: String?

    public init(mtu: Int = 1400, dnsServers: [String] = ["1.1.1.1", "8.8.8.8"],
                killSwitch: Bool = true, includedRoutes: [String] = [],
                excludedRoutes: [String] = [], ipv6Address: String? = nil) {
        self.mtu = mtu; self.dnsServers = dnsServers
        self.killSwitch = killSwitch
        self.includedRoutes = includedRoutes
        self.excludedRoutes = excludedRoutes
        self.ipv6Address = ipv6Address
    }
}

/// Snapshot the app publishes into the App Group after every status or
/// stats change. The Widget extension reads *only* this — it never talks
/// to the provider directly, so a widget can never present stale IPC data
/// as if it were live.
public struct SharedTunnelSnapshot: Codable, Equatable, Sendable {
    public enum State: String, Codable, Sendable {
        case disconnected, connecting, connected, reconnecting, disconnecting, unavailable
    }
    public var state: State
    public var serverName: String?
    public var uploadBytes: Int64
    public var downloadBytes: Int64
    public var updatedAt: Date

    public init(state: State, serverName: String? = nil,
                uploadBytes: Int64 = 0, downloadBytes: Int64 = 0,
                updatedAt: Date = Date()) {
        self.state = state; self.serverName = serverName
        self.uploadBytes = uploadBytes; self.downloadBytes = downloadBytes
        self.updatedAt = updatedAt
    }

    public static func load(from defaults: UserDefaults?) -> SharedTunnelSnapshot? {
        guard let data = defaults?.data(forKey: AppGroupKey.tunnelSnapshot) else { return nil }
        return try? JSONDecoder().decode(SharedTunnelSnapshot.self, from: data)
    }
    public func save(to defaults: UserDefaults?) {
        if let data = try? JSONEncoder().encode(self) {
            defaults?.set(data, forKey: AppGroupKey.tunnelSnapshot)
        }
    }
}

// MARK: - App <-> provider messages (handleAppMessage)

/// Command sent from the app through
/// `NETunnelProviderSession.sendProviderMessage`.
public struct TunnelAppMessage: Codable, Equatable, Sendable {
    public enum Command: String, Codable, Sendable {
        case status, stats, wake, sleep, reloadConfig
    }
    public var command: Command
    /// Present only for `.reloadConfig`: a fresh sing-box config JSON the
    /// provider swaps in without a full tunnel restart.
    public var configJSON: String?
    public init(command: Command, configJSON: String? = nil) {
        self.command = command; self.configJSON = configJSON
    }
    public var encoded: Data { (try? JSONEncoder().encode(self)) ?? Data() }
    public init?(data: Data) {
        guard let decoded = try? JSONDecoder().decode(TunnelAppMessage.self, from: data)
        else { return nil }
        self = decoded
    }
}

/// Reply payload for `.status` / `.stats`.
public struct TunnelStatusPayload: Codable, Equatable, Sendable {
    public var running: Bool
    public var serverName: String?
    public var profileID: String?
    /// Cumulative counters from the libbox service, sampled at message
    /// time. See StatsView for how the UI labels their provenance.
    public var uploadBytes: Int64
    public var downloadBytes: Int64
    public var activeConnections: Int
    public var startedAt: Date?
    public init(running: Bool, serverName: String? = nil, profileID: String? = nil,
                uploadBytes: Int64 = 0, downloadBytes: Int64 = 0,
                activeConnections: Int = 0, startedAt: Date? = nil) {
        self.running = running; self.serverName = serverName
        self.profileID = profileID; self.uploadBytes = uploadBytes
        self.downloadBytes = downloadBytes
        self.activeConnections = activeConnections; self.startedAt = startedAt
    }
    public var encoded: Data { (try? JSONEncoder().encode(self)) ?? Data() }
    public init?(data: Data?) {
        guard let data,
              let decoded = try? JSONDecoder().decode(TunnelStatusPayload.self, from: data)
        else { return nil }
        self = decoded
    }
}
