import Foundation
#if canImport(NetworkExtension)
import NetworkExtension
#endif

/// Honest, user-facing tunnel states (mandate: designed states, no raw
/// system text). Every case renders through a `state.*` localisation
/// key from the shared `apple/Localizations/Localizable.xcstrings`
/// (the same namespace the iOS app uses); raw `NEVPNStatus` / system
/// extension errors are logged, never shown.
public enum TunnelPhase: String, Codable, Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case reconnecting
    /// Extension installed but not approved in System Settings yet.
    case extensionNotApproved
    /// Extension was replaced and must restart (or the Mac reboot).
    case extensionNeedsRestart
    /// No VPN configuration created yet (first run).
    case profileNotCreated
    /// Extension bundle not embedded (dev build) — nothing to run.
    case extensionMissing
    /// App Group container unavailable — app/extension cannot exchange
    /// the config (`state.appGroupUnavailable`, existing key).
    case appGroupUnavailable
    case failed

    public var localizationKey: String {
        switch self {
        case .profileNotCreated: return "state.profileNotCreated"
        case .extensionNotApproved: return "state.extensionNotApproved"
        case .extensionNeedsRestart: return "state.extensionNeedsRestart"
        case .extensionMissing: return "state.extensionMissing"
        case .appGroupUnavailable: return "state.appGroupUnavailable"
        case .failed: return "state.failed"
        default: return "state.\(rawValue)"
        }
    }
    public var localizedTitle: String { tr(localizationKey, rawValue) }

    public var isTransitional: Bool {
        switch self { case .connecting, .disconnecting, .reconnecting: return true; default: return false }
    }
    public var isConnected: Bool { self == .connected }
    /// States that get a designed banner with a call to action.
    public var needsAttention: Bool {
        switch self {
        case .extensionNotApproved, .extensionNeedsRestart, .profileNotCreated,
             .extensionMissing, .appGroupUnavailable, .failed:
            return true
        default: return false
        }
    }

    #if canImport(NetworkExtension)
    static func from(_ status: NEVPNStatus) -> TunnelPhase {
        switch status {
        case .invalid: return .profileNotCreated
        case .disconnected: return .disconnected
        case .connecting: return .connecting
        case .connected: return .connected
        case .reasserting: return .reconnecting
        case .disconnecting: return .disconnecting
        @unknown default: return .failed
        }
    }
    #endif
}

/// Mirror of `SharedTunnelSnapshot` in
/// `apple/PacketTunnel/TunnelConfigExchange.swift` — IDENTICAL Codable
/// shape and App Group key (`sora.tunnel.snapshot.v1`), because the
/// widget and the provider decode the same bytes. The app target does
/// not compile the PacketTunnel file, hence the mirror; if the shape
/// changes there, change it here in the same commit.
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

    public static let disconnected = SharedTunnelSnapshot(state: .disconnected)

    public static func from(phase: TunnelPhase, serverName: String?,
                            upload: Int64 = 0, download: Int64 = 0) -> SharedTunnelSnapshot {
        let state: State
        switch phase {
        case .connected: state = .connected
        case .connecting: state = .connecting
        case .reconnecting: state = .reconnecting
        case .disconnecting: state = .disconnecting
        case .extensionMissing, .appGroupUnavailable, .failed: state = .unavailable
        default: state = .disconnected
        }
        return SharedTunnelSnapshot(state: state, serverName: serverName,
                                    uploadBytes: upload, downloadBytes: download)
    }
}

/// Mirror of `TunnelConfigExchange` (same source as above): the
/// payload the app hands to the provider via `providerConfiguration`
/// and the App Group `sora.tunnel.config.v1` key, and — ARCHITECTURE
/// §3.4 — as `current-config.json` in the App Group container.
public struct MacTunnelConfigExchange: Codable, Equatable, Sendable {
    public var configJSON: String
    public var serverName: String
    public var profileID: String
    public var tun: MacTunSettings
    public var updatedAt: Date

    public struct MacTunSettings: Codable, Equatable, Sendable {
        public var mtu: Int = 1400
        public var dnsServers: [String] = ["1.1.1.1", "8.8.8.8"]
        public var killSwitch: Bool = true
        public var includedRoutes: [String] = []
        public var excludedRoutes: [String] = []
        public var ipv6Address: String? = nil
    }

    /// Shape of `NETunnelProviderProtocol.providerConfiguration`
    /// (identical to `TunnelConfigExchange.providerDictionary`).
    public var providerDictionary: [String: Any] {
        var tunDict: [String: Any] = [
            "mtu": tun.mtu, "dnsServers": tun.dnsServers,
            "killSwitch": tun.killSwitch,
            "includedRoutes": tun.includedRoutes,
            "excludedRoutes": tun.excludedRoutes,
        ]
        if let ipv6 = tun.ipv6Address { tunDict["ipv6Address"] = ipv6 }
        return ["configJSON": configJSON, "serverName": serverName,
                "profileID": profileID, "tun": tunDict]
    }
}

/// Mirror of `TunnelAppMessage` (same source): commands for
/// `NETunnelProviderSession.sendProviderMessage` — status / stats /
/// wake / sleep / reloadConfig (fast switch, ARCHITECTURE §4.3).
public struct MacTunnelAppMessage: Codable, Equatable, Sendable {
    public enum Command: String, Codable, Sendable {
        case status, stats, wake, sleep, reloadConfig
    }
    public var command: Command
    public var configJSON: String?
    public init(command: Command, configJSON: String? = nil) {
        self.command = command; self.configJSON = configJSON
    }
    public var encoded: Data { (try? JSONEncoder().encode(self)) ?? Data() }
}
