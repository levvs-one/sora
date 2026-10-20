import Foundation
import NetworkExtension
import os.log

/// Packet Tunnel provider: owns the TUN interface and the libbox service.
///
/// Lifecycle contract with the app:
///  * config arrives via `providerConfiguration` (see
///    `TunnelConfigExchange`) and is mirrored in the App Group suite;
///  * the app talks to a running provider with `TunnelAppMessage`s;
///  * sleep/wake: iOS calls `sleep(completionHandler:)` / `wake()` on
///    power transitions — `wake()` re-asserts network settings, which
///    repairs routes torn down across a Wi-Fi/cellular handover; the app
///    may also send explicit `.sleep` / `.wake` messages.
final class PacketTunnelProvider: NEPacketTunnelProvider {
    private let log = Logger(subsystem: SoraIdentifiers.tunnelBundleID, category: "provider")
    private let bridge: LibboxBridge = LibboxBridgeImpl()
    private var current: TunnelConfigExchange?
    private var startedAt: Date?

    // MARK: Start / stop

    override func startTunnel(options: [String: NSObject]?,
                              completionHandler: @escaping (Error?) -> Void) {
        guard let exchange = loadExchange() else {
            log.error("startTunnel without config")
            completionHandler(TunnelProviderError.missingConfig)
            return
        }
        current = exchange

        let group = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SoraIdentifiers.appGroup)
        let base = group?.path ?? NSTemporaryDirectory()
        do {
            try bridge.setup(basePath: base,
                             workingPath: base + "/working",
                             tempPath: NSTemporaryDirectory())
        } catch {
            completionHandler(error); return
        }

        setTunnelNetworkSettings(makeNetworkSettings(for: exchange)) { [weak self] error in
            guard let self else { completionHandler(error); return }
            if let error { completionHandler(error); return }
            do {
                try self.bridge.startService(configJSON: exchange.configJSON)
                self.startedAt = Date()
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason,
                             completionHandler: @escaping () -> Void) {
        try? bridge.stopService()
        startedAt = nil
        completionHandler()
    }

    // MARK: Sleep / wake (system power + network transitions)

    override func sleep(completionHandler: @escaping () -> Void) {
        // The pinned libbox exposes no explicit pause API, so the honest
        // equivalent is to let iOS suspend the extension process. We only
        // note the transition; `wake()` re-asserts the settings.
        log.debug("provider sleep")
        completionHandler()
    }

    override func wake() {
        log.debug("provider wake")
        guard let exchange = current, bridge.isRunning else { return }
        // Re-asserting identical settings is cheap and repairs routes
        // iOS may have torn down while the device slept.
        setTunnelNetworkSettings(makeNetworkSettings(for: exchange), completionHandler: nil)
    }

    // MARK: App messages

    override func handleAppMessage(_ messageData: Data,
                                   completionHandler: ((Data?) -> Void)?) {
        guard let message = TunnelAppMessage(data: messageData) else {
            completionHandler?(nil); return
        }
        switch message.command {
        case .status, .stats:
            completionHandler?(statusPayload().encoded)
        case .wake:
            wake(); completionHandler?(statusPayload().encoded)
        case .sleep:
            completionHandler?(statusPayload().encoded)
        case .reloadConfig:
            handleReload(configJSON: message.configJSON, completionHandler: completionHandler)
        }
    }

    private func handleReload(configJSON: String?,
                              completionHandler: ((Data?) -> Void)?) {
        guard let configJSON, var exchange = current else {
            completionHandler?(nil); return
        }
        do {
            try bridge.stopService()
            try bridge.startService(configJSON: configJSON)
            exchange.configJSON = configJSON
            current = exchange
            completionHandler?(statusPayload().encoded)
        } catch {
            log.error("reload failed")
            completionHandler?(nil)
        }
    }

    // MARK: Helpers

    private func statusPayload() -> TunnelStatusPayload {
        if let stats = try? bridge.queryStats() {
            var payload = stats
            payload.serverName = payload.serverName ?? current?.serverName
            payload.profileID = payload.profileID ?? current?.profileID
            payload.startedAt = payload.startedAt ?? startedAt
            return payload
        }
        return TunnelStatusPayload(running: bridge.isRunning,
                                   serverName: current?.serverName,
                                   profileID: current?.profileID,
                                   startedAt: startedAt)
    }

    private func loadExchange() -> TunnelConfigExchange? {
        if let proto = protocolConfiguration as? NETunnelProviderProtocol,
           let exchange = TunnelConfigExchange(providerDictionary: proto.providerConfiguration) {
            return exchange
        }
        // System-restart fallback: the App Group mirror.
        let defaults = UserDefaults(suiteName: SoraIdentifiers.appGroup)
        guard let data = defaults?.data(forKey: AppGroupKey.tunnelConfig) else { return nil }
        return try? JSONDecoder().decode(TunnelConfigExchange.self, from: data)
    }

    private func makeNetworkSettings(for exchange: TunnelConfigExchange) -> NEPacketTunnelNetworkSettings {
        let tun = exchange.tun
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.mtu = NSNumber(value: tun.mtu)

        let ipv4 = NEIPv4Settings(addresses: ["172.19.0.1"], subnetMasks: ["255.255.255.252"])
        if tun.includedRoutes.isEmpty && tun.excludedRoutes.isEmpty {
            ipv4.includedRoutes = [NEIPv4Route.default()]
        } else {
            ipv4.includedRoutes = tun.includedRoutes.map(Self.route(cidr:))
            ipv4.excludedRoutes = tun.excludedRoutes.map(Self.route(cidr:))
        }
        settings.ipv4Settings = ipv4

        if let v6 = tun.ipv6Address {
            let ipv6 = NEIPv6Settings(addresses: [v6], networkPrefixLengths: [128])
            ipv6.includedRoutes = [NEIPv6Route.default()]
            settings.ipv6Settings = ipv6
        }

        if !tun.dnsServers.isEmpty {
            let dns = NEDNSSettings(servers: tun.dnsServers)
            dns.matchDomains = [""] // route all DNS through the tunnel servers
            settings.dnsSettings = dns
        }
        return settings
    }

    private static func route(cidr: String) -> NEIPv4Route {
        let parts = cidr.split(separator: "/")
        let address = parts.first.map(String.init) ?? cidr
        let prefix = parts.count > 1 ? Int(parts[1]) ?? 32 : 32
        return NEIPv4Route(destinationAddress: address,
                           subnetMask: mask(prefixLength: prefix))
    }

    private static func mask(prefixLength: Int) -> String {
        let clamped = max(0, min(32, prefixLength))
        let value: UInt32 = clamped == 0 ? 0 : UInt32.max << (32 - clamped)
        return [24, 16, 8, 0].map { shift in
            String((value >> UInt32(shift)) & 0xFF)
        }.joined(separator: ".")
    }
}

enum TunnelProviderError: Error { case missingConfig }
