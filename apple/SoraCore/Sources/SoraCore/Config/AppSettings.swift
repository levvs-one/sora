import Foundation

/// Capabilities of the host system that change how a libbox config must be
/// rendered. The app layer fills this in from runtime probes (OS version,
/// NetworkExtension entitlements, stack support); the generator never
/// branches on an OS version itself. Every field defaults to "auto" so a
/// stored settings file written before a capability existed keeps working
/// (additive decoding: `decodeIfPresent` everywhere).
public struct PlatformCapabilities: Codable, Equatable {
    public enum TUNStack: String, Codable, Equatable {
        case auto, system, gvisor, mixed
    }
    /// How the kill switch should be enforced when it is on.
    /// - auto: strict_route on the TUN inbound (the Go core's behaviour).
    /// - strictRoute: same as auto today, pinned explicitly by the app.
    /// - blockOnFailure: strict_route plus explicit block rules for DNS and
    ///   direct traffic, for systems where strict_route alone is not trusted.
    public enum KillSwitchBehavior: String, Codable, Equatable {
        case auto, strictRoute, blockOnFailure
    }

    public var tunStack: TUNStack
    /// nil = auto (the app layer has not probed IPv6 support).
    public var ipv6InTunnel: Bool?
    public var killSwitchBehavior: KillSwitchBehavior

    public init(tunStack: TUNStack = .auto, ipv6InTunnel: Bool? = nil,
                killSwitchBehavior: KillSwitchBehavior = .auto) {
        self.tunStack = tunStack
        self.ipv6InTunnel = ipv6InTunnel
        self.killSwitchBehavior = killSwitchBehavior
    }

    public static let auto = PlatformCapabilities()

    /// Resolved TUN stack spelled the way sing-box expects it. Mirrors the
    /// Go renderer: the legacy default is "mixed" (system TCP + gVisor UDP).
    public var resolvedTUNStack: String {
        switch tunStack {
        case .auto, .mixed: return "mixed"
        case .system: return "system"
        case .gvisor: return "gvisor"
        }
    }

    /// Resolved IPv6-in-tunnel decision. Auto resolves to enabled: Apple
    /// platforms always have a v6-capable TUN path, and silently dropping
    /// AAAA was the leak class the Go core fixed with its S7 fake-IP rules.
    /// The app layer overrides this to false when a probe says otherwise.
    public var resolvedIPv6: Bool { ipv6InTunnel ?? true }

    private enum CodingKeys: String, CodingKey { case tunStack, ipv6InTunnel, killSwitchBehavior }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tunStack = try c.decodeIfPresent(TUNStack.self, forKey: .tunStack) ?? .auto
        ipv6InTunnel = try c.decodeIfPresent(Bool.self, forKey: .ipv6InTunnel)
        killSwitchBehavior = try c.decodeIfPresent(KillSwitchBehavior.self, forKey: .killSwitchBehavior) ?? .auto
    }
}

/// User-facing settings that shape every generated config. Mirrors the
/// plan-level options of the Go core (DNS servers, kill switch, TUN MTU,
/// split tunnelling, LAN bypass, log level).
public struct AppSettings: Codable, Equatable {
    public var dnsServers: [String]
    public var dnsStrategy: String?
    public var killSwitch: Bool
    public var tunMTU: Int
    public var splitTunnelExcludedRoutes: [String]
    public var splitTunnelIncludedRoutes: [String]
    public var bypassLAN: Bool
    public var logLevel: String
    public var capabilities: PlatformCapabilities

    public init(dnsServers: [String] = ["https://1.1.1.1/dns-query"],
                dnsStrategy: String? = nil,
                killSwitch: Bool = true,
                tunMTU: Int = 1500,
                splitTunnelExcludedRoutes: [String] = [],
                splitTunnelIncludedRoutes: [String] = [],
                bypassLAN: Bool = true,
                logLevel: String = "warn",
                capabilities: PlatformCapabilities = .auto) {
        self.dnsServers = dnsServers
        self.dnsStrategy = dnsStrategy
        self.killSwitch = killSwitch
        self.tunMTU = tunMTU
        self.splitTunnelExcludedRoutes = splitTunnelExcludedRoutes
        self.splitTunnelIncludedRoutes = splitTunnelIncludedRoutes
        self.bypassLAN = bypassLAN
        self.logLevel = logLevel
        self.capabilities = capabilities
    }

    private enum CodingKeys: String, CodingKey {
        case dnsServers, dnsStrategy, killSwitch, tunMTU
        case splitTunnelExcludedRoutes, splitTunnelIncludedRoutes
        case bypassLAN, logLevel, capabilities
    }

    // Additive decoding: a settings file from an older build (no
    // `capabilities`, no split-tunnel keys) must still load.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings()
        dnsServers = try c.decodeIfPresent([String].self, forKey: .dnsServers) ?? d.dnsServers
        dnsStrategy = try c.decodeIfPresent(String.self, forKey: .dnsStrategy)
        killSwitch = try c.decodeIfPresent(Bool.self, forKey: .killSwitch) ?? d.killSwitch
        tunMTU = try c.decodeIfPresent(Int.self, forKey: .tunMTU) ?? d.tunMTU
        splitTunnelExcludedRoutes = try c.decodeIfPresent([String].self, forKey: .splitTunnelExcludedRoutes) ?? []
        splitTunnelIncludedRoutes = try c.decodeIfPresent([String].self, forKey: .splitTunnelIncludedRoutes) ?? []
        bypassLAN = try c.decodeIfPresent(Bool.self, forKey: .bypassLAN) ?? d.bypassLAN
        logLevel = try c.decodeIfPresent(String.self, forKey: .logLevel) ?? d.logLevel
        capabilities = try c.decodeIfPresent(PlatformCapabilities.self, forKey: .capabilities) ?? .auto
    }
}
