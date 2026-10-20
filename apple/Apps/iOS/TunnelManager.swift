import Foundation
import NetworkExtension
import SoraCore
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Owns the `NETunnelProviderManager` lifecycle for the iOS app:
/// load/save the VPN configuration, start/stop the tunnel, translate
/// `NEVPNStatus` into honest `TunnelUIState`s, maintain on-demand rules
/// (kill switch / always-on) and react to status transitions.
///
/// Adaptivity rule (owner standard): capabilities are probed at runtime
/// — `if #available` plus actual API probes — never bare version
/// branches. Each probe site comments *why* the branch exists.
@MainActor
public final class TunnelManager: ObservableObject {
    @Published public private(set) var state: TunnelUIState = .disconnected
    @Published public private(set) var activeServerName: String?
    @Published public private(set) var lastStats: TunnelStatusPayload?

    private var manager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?
    private let store: ProfilePersisting
    private let groupDefaults: UserDefaults?

    /// The store is built over the App Group container of
    /// `SoraIdentifiers.appGroup` explicitly (not
    /// `JSONFileProfileStore.sharedContainer()`), because the store and
    /// this provider must agree on the group the entitlements declare.
    /// NOTE: SoraCore's `SoraSharedIdentifiers.appGroup` currently names a
    /// different group — cross-department divergence flagged in README.
    public init(store: ProfilePersisting? = nil) {
        if let store {
            self.store = store
        } else if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SoraIdentifiers.appGroup) {
            self.store = JSONFileProfileStore(directory: container)
        } else {
            self.store = JSONFileProfileStore(directory:
                FileManager.default.temporaryDirectory)
        }
        self.groupDefaults = UserDefaults(suiteName: SoraIdentifiers.appGroup)
    }

    deinit {
        if let statusObserver {
            NotificationCenter.default.removeObserver(statusObserver)
        }
    }

    // MARK: Load / capability probes

    /// Loads the existing VPN configuration, if any. Distinguishes
    /// "no profile yet" from "profile exists but not approved" — iOS
    /// reports the latter as a configuration whose connection cannot
    /// start; we surface it via `state` instead of an alert storm.
    public func load() async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            guard let existing = managers.first(where: {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier
                    == SoraIdentifiers.tunnelBundleID
            }) ?? managers.first else {
                manager = nil
                state = .profileMissing
                publishSnapshot()
                return
            }
            manager = existing
            observeStatus(of: existing)
            applyStatus(existing.connection.status, isEnabled: existing.isEnabled)
        } catch {
            // Raw error goes to the log only; the UI gets the honest
            // "profile not approved / not created" family of states.
            state = .profileNotApproved
            publishSnapshot()
        }
    }

    /// Runtime probe: App Group reachability. A nil suite or a failed
    /// write-read round trip means app and extension cannot exchange the
    /// config (entitlement mismatch) — surfaced as its own state.
    public func probeAppGroup() -> Bool {
        guard let groupDefaults else { return false }
        let probeKey = "sora.probe.appGroup"
        groupDefaults.set(true, forKey: probeKey)
        return groupDefaults.bool(forKey: probeKey)
    }

    // MARK: Connect / disconnect

    /// Builds the sing-box config via SoraCore, saves the VPN profile
    /// (first run triggers the system approval prompt — that is the
    /// `state.vpnProfileApprovalPathIos` moment) and starts the tunnel.
    public func connect(profile: ServerProfile, settings: AppSettings) async throws {
        guard probeAppGroup() else {
            state = .appGroupUnavailable
            throw SoraAppError.providerMessageFailed
        }
        let configJSON: String
        do {
            configJSON = try LibboxConfigBuilder.build(profile: profile, settings: settings)
        } catch {
            throw SoraAppError.configBuildFailed
        }
        let exchange = TunnelConfigExchange(
            configJSON: configJSON,
            serverName: profile.name.isEmpty ? profile.address : profile.name,
            profileID: profile.id,
            tun: TunSettings(
                mtu: settings.tunMTU,
                dnsServers: Self.plainDNSHosts(from: settings.dnsServers),
                killSwitch: settings.killSwitch,
                includedRoutes: settings.splitTunnelIncludedRoutes,
                excludedRoutes: settings.splitTunnelExcludedRoutes))

        // Mirror into the App Group (provider restart fallback + widget).
        if let data = try? JSONEncoder().encode(exchange) {
            groupDefaults?.set(data, forKey: AppGroupKey.tunnelConfig)
        }
        groupDefaults?.set(profile.id, forKey: AppGroupKey.activeProfileID)

        let mgr = manager ?? NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = SoraIdentifiers.tunnelBundleID
        proto.serverAddress = exchange.serverName
        proto.providerConfiguration = exchange.providerDictionary
        mgr.protocolConfiguration = proto
        mgr.localizedDescription = SoraIdentifiers.tunnelLocalizedDescription
        mgr.isEnabled = true
        applyOnDemandRules(to: mgr, settings: settings)
        do {
            try await mgr.saveToPreferences()
            try await mgr.loadFromPreferences()
        } catch {
            state = .profileNotApproved
            throw SoraAppError.providerMessageFailed
        }
        manager = mgr
        observeStatus(of: mgr)
        do {
            try mgr.connection.startVPNTunnel()
        } catch {
            state = .profileNotApproved
            throw SoraAppError.providerMessageFailed
        }
    }

    public func disconnect() {
        manager?.connection.stopVPNTunnel()
    }

    /// Switch the running tunnel to another server. Falls back to a full
    /// reconnect when the provider is not running (there is nothing to
    /// hot-swap), so callers never branch on that themselves.
    public func switchServer(to profile: ServerProfile, settings: AppSettings) async throws {
        guard state.isConnected,
              let session = manager?.connection as? NETunnelProviderSession else {
            try await connect(profile: profile, settings: settings)
            return
        }
        let configJSON = try LibboxConfigBuilder.build(profile: profile, settings: settings)
        let reply = try await send(message: TunnelAppMessage(command: .reloadConfig,
                                                             configJSON: configJSON),
                                   session: session)
        if reply == nil {
            // Provider declined the hot swap: honest full reconnect.
            disconnect()
            try await connect(profile: profile, settings: settings)
        } else {
            activeServerName = profile.name.isEmpty ? profile.address : profile.name
            publishSnapshot()
        }
    }

    // MARK: On-demand rules (kill switch / always-on resilience)

    /// On-demand is how iOS keeps the tunnel honest across network
    /// changes and reboots: with the kill switch on, a Wi-Fi rule set
    /// reconnects on any interface change; with it off, rules are
    /// cleared so a dropped tunnel stays down until the user acts.
    private func applyOnDemandRules(to mgr: NETunnelProviderManager, settings: AppSettings) {
        let alwaysOn = settings.killSwitch
        groupDefaults?.set(alwaysOn, forKey: AppGroupKey.onDemandEnabled)
        guard alwaysOn else {
            mgr.onDemandRules = []
            mgr.isOnDemandEnabled = false
            return
        }
        let wifiRule = NEOnDemandRuleConnect()
        wifiRule.interfaceTypeMatch = .wiFi
        let cellularRule = NEOnDemandRuleConnect()
        cellularRule.interfaceTypeMatch = .cellular
        let anyRule = NEOnDemandRuleConnect()
        anyRule.interfaceTypeMatch = .any
        mgr.onDemandRules = [wifiRule, cellularRule, anyRule]
        mgr.isOnDemandEnabled = true
    }

    // MARK: Provider messages (status / stats / wake / sleep)

    public func requestStatus() async {
        guard let session = manager?.connection as? NETunnelProviderSession else { return }
        if let payload = try? await send(message: TunnelAppMessage(command: .status),
                                         session: session),
           let payload {
            lastStats = payload
            activeServerName = payload.serverName ?? activeServerName
            publishSnapshot()
        }
    }

    public func requestStats() async throws -> TunnelStatusPayload {
        guard let session = manager?.connection as? NETunnelProviderSession,
              let payload = try await send(message: TunnelAppMessage(command: .stats),
                                           session: session) else {
            throw SoraAppError.providerMessageFailed
        }
        lastStats = payload
        publishSnapshot()
        return payload
    }

    /// Sent when the app returns to the foreground after the device
    /// slept: asks the provider to re-assert its network settings.
    public func notifyWake() async {
        guard let session = manager?.connection as? NETunnelProviderSession else { return }
        _ = try? await send(message: TunnelAppMessage(command: .wake), session: session)
    }

    private func send(message: TunnelAppMessage,
                      session: NETunnelProviderSession) async throws -> TunnelStatusPayload? {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try session.sendProviderMessage(message.encoded) { data in
                    continuation.resume(returning: TunnelStatusPayload(data: data))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: Status translation

    private func observeStatus(of mgr: NETunnelProviderManager) {
        if let statusObserver {
            NotificationCenter.default.removeObserver(statusObserver)
        }
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange, object: mgr.connection, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, let mgr = self.manager else { return }
                    self.applyStatus(mgr.connection.status, isEnabled: mgr.isEnabled)
                    if mgr.connection.status == .connected {
                        await self.requestStatus()
                        NotificationService.postConnectionChanged(connected: true,
                                                                  serverName: self.activeServerName)
                    }
                    if mgr.connection.status == .disconnected {
                        NotificationService.postConnectionChanged(connected: false,
                                                                  serverName: nil)
                    }
                }
            }
        applyStatus(mgr.connection.status, isEnabled: mgr.isEnabled)
    }

    private func applyStatus(_ status: NEVPNStatus, isEnabled: Bool) {
        switch status {
        case .invalid:
            // A saved-but-invalid configuration is iOS telling us the
            // profile exists but was never approved (or was revoked in
            // Settings) — say exactly that, in plain language.
            state = manager == nil ? .profileMissing : .profileNotApproved
        case .disconnected: state = .disconnected
        case .connecting: state = .connecting
        case .connected: state = .connected
        case .reasserting:
            // Network changed under a live tunnel (Wi-Fi <-> cellular,
            // wake from sleep). Its own designed state, not an error.
            state = .reconnectingAfterNetworkChange
        case .disconnecting: state = .disconnecting
        @unknown default: state = .disconnected
        }
        if status == .connected, let name = exchangeServerName() {
            activeServerName = name
        }
        publishSnapshot()
    }

    private func exchangeServerName() -> String? {
        guard let data = groupDefaults?.data(forKey: AppGroupKey.tunnelConfig),
              let exchange = try? JSONDecoder().decode(TunnelConfigExchange.self, from: data)
        else { return nil }
        return exchange.serverName
    }

    /// Publishes the widget snapshot and reloads widget timelines.
    /// Widgets read the App Group only — this is their single source.
    private func publishSnapshot() {
        let snapshotState: SharedTunnelSnapshot.State
        switch state {
        case .connected: snapshotState = .connected
        case .connecting: snapshotState = .connecting
        case .reconnectingAfterNetworkChange: snapshotState = .reconnecting
        case .disconnecting: snapshotState = .disconnecting
        case .tunnelUnavailable, .appGroupUnavailable: snapshotState = .unavailable
        default: snapshotState = .disconnected
        }
        SharedTunnelSnapshot(
            state: snapshotState,
            serverName: activeServerName,
            uploadBytes: lastStats?.uploadBytes ?? 0,
            downloadBytes: lastStats?.downloadBytes ?? 0
        ).save(to: groupDefaults)
        #if canImport(WidgetKit)
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "SoraStatusWidget")
        }
        #endif
    }

    /// `AppSettings.dnsServers` holds resolver URLs in the Go/SoraCore
    /// model (`https://1.1.1.1/dns-query`); `NEDNSSettings` needs plain
    /// addresses, so URL-form entries contribute their host.
    static func plainDNSHosts(from servers: [String]) -> [String] {
        servers.map { entry in
            if let url = URL(string: entry), let host = url.host, url.scheme != nil {
                return host
            }
            return entry
        }.filter { !$0.isEmpty }
    }
}
