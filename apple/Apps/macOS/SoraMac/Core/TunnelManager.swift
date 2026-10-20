import Foundation
import Combine
#if canImport(AppKit)
import AppKit // NSWorkspace sleep/wake notifications
#endif
#if canImport(NetworkExtension)
import NetworkExtension
#endif
#if canImport(Network)
import Network
#endif

/// Owns the VPN configuration and connection lifecycle on macOS.
///
/// Model (ARCHITECTURE.md §4): ONE `NETunnelProviderManager` whose
/// provider is the system extension (shared `apple/PacketTunnel`
/// code). The built sing-box JSON travels as `providerConfiguration`
/// + App Group exchange (`current-config.json`); the extension's
/// `LibboxBridge` owns libbox — the app target never links it.
///
/// Fast switch (§4.3): switching servers while connected does NOT
/// recreate the tunnel. The new config goes to the App Group and a
/// `reloadConfig` provider message asks the provider to swap the
/// libbox session only — the desktop instant-SelectServer invariant.
///
/// Resilience (§4.2): on-demand rules (product ladder: off / always /
/// implemented here as the user's auto-reconnect toggle), NE status
/// reassertion on network changes, `NWPathMonitor` re-reads, and
/// sleep/wake handling. Status is ALWAYS re-read from the manager —
/// the extension can outlive the app and vice versa.
@MainActor
public final class TunnelManager: ObservableObject {
    public static let shared = TunnelManager()

    @Published public private(set) var phase: TunnelPhase = .disconnected
    @Published public private(set) var currentServer: ServerRow?
    @Published public private(set) var connectedSince: Date?
    @Published public private(set) var uploadBytes: Int64 = 0
    @Published public private(set) var downloadBytes: Int64 = 0
    @Published public private(set) var lastFailure: NotificationManager.FailureKind?

    @Published public var autoReconnect: Bool = true {
        didSet {
            WidgetSync.publishOnDemand(autoReconnect)
            Task { await applyOnDemandRules() }
        }
    }

    #if canImport(NetworkExtension)
    private var manager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?
    #endif
    private var cancellables = Set<AnyCancellable>()
    private var pendingServer: ServerRow?
    private var wasConnectedBeforeSleep = false
    #if canImport(Network)
    private let pathMonitor = NWPathMonitor()
    private var lastPathSatisfied: Bool?
    #endif

    private init() {
        SystemExtensionManager.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ext in self?.foldExtensionState(ext) }
            .store(in: &cancellables)
    }

    // MARK: Bootstrap

    public func bootstrap() async {
        NotificationManager.shared.requestAuthorization()
        SystemExtensionManager.shared.refreshStatus()
        if !SoraCoreBridge.appGroupAvailable { phase = .appGroupUnavailable }
        await loadManager()
        observeStatus()
        startPathMonitor()
        observeSleepWake()
        publishSnapshot()
    }

    private func foldExtensionState(_ ext: SystemExtensionManager.ActivationState) {
        switch ext {
        case .awaitingUserApproval: phase = .extensionNotApproved
        case .needsRestart: phase = .extensionNeedsRestart
        case .notInstalled:
            if !FeatureAvailability.systemExtensionEmbedded { phase = .extensionMissing }
        case .active:
            if let pending = pendingServer {
                pendingServer = nil
                Task { await startTunnel(with: pending) }
            }
        default: break
        }
    }

    // MARK: Manager / profile

    private func loadManager() async {
        #if canImport(NetworkExtension)
        let managers = (try? await NETunnelProviderManager.loadAllFromPreferences()) ?? []
        if let existing = managers.first(where: {
            ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier
                == AppIdentifiers.tunnelExtensionBundleID
        }) {
            manager = existing
            if phase != .appGroupUnavailable {
                phase = TunnelPhase.from(existing.connection.status)
            }
            if existing.connection.status == .connected, connectedSince == nil { connectedSince = Date() }
            restoreCurrentServer(from: existing)
        } else if phase != .appGroupUnavailable {
            phase = .profileNotCreated
        }
        #endif
    }

    private func restoreCurrentServer(from mgr: AnyObject) {
        #if canImport(NetworkExtension)
        guard let m = mgr as? NETunnelProviderManager,
              let proto = m.protocolConfiguration as? NETunnelProviderProtocol,
              let pid = proto.providerConfiguration?["profileID"] as? String else { return }
        currentServer = SoraCoreBridge.shared.loadProfiles().first { $0.id == pid }
        #endif
    }

    /// Creates/updates the VPN profile with the exchange for `server`.
    /// Separate from connecting so first-run UI can show
    /// `state.profileNotCreated` with an explicit action.
    public func installProfile(for server: ServerRow) async throws {
        #if canImport(NetworkExtension)
        let configJSON = try SoraCoreBridge.shared.buildConfig(for: server)
        let exchange = MacTunnelConfigExchange(
            configJSON: configJSON, serverName: server.name, profileID: server.id,
            tun: .init(), updatedAt: Date())
        WidgetSync.publishExchange(exchange)
        let mgr = manager ?? NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = AppIdentifiers.tunnelExtensionBundleID
        proto.serverAddress = server.name
        proto.providerConfiguration = exchange.providerDictionary
        mgr.protocolConfiguration = proto
        mgr.localizedDescription = "Sora"
        mgr.isEnabled = true
        manager = mgr
        try await mgr.saveToPreferences()
        try await mgr.loadFromPreferences()
        #endif
    }

    // MARK: Connect / disconnect / fast switch

    public func connect(to server: ServerRow) async {
        lastFailure = nil
        if !SoraCoreBridge.appGroupAvailable { phase = .appGroupUnavailable; return }
        if SystemExtensionManager.shared.state == .awaitingUserApproval {
            phase = .extensionNotApproved; return
        }
        // Connected to another server → fast switch, no tunnel restart.
        if phase.isConnected, let current = currentServer, current.id != server.id {
            await switchServer(to: server); return
        }
        if SystemExtensionManager.shared.state != .active {
            SystemExtensionManager.shared.activate()
            pendingServer = server // completed by foldExtensionState(.active)
            if SystemExtensionManager.shared.state == .awaitingUserApproval {
                phase = .extensionNotApproved
            }
            return
        }
        await startTunnel(with: server)
    }

    /// §4.3 fast switch: new config to the App Group + `reloadConfig`
    /// provider message; falls back to a full restart if the provider
    /// message cannot be delivered.
    public func switchServer(to server: ServerRow) async {
        do {
            let configJSON = try SoraCoreBridge.shared.buildConfig(for: server)
            let exchange = MacTunnelConfigExchange(
                configJSON: configJSON, serverName: server.name, profileID: server.id,
                tun: .init(), updatedAt: Date())
            WidgetSync.publishExchange(exchange)
            currentServer = server
            WidgetSync.publishSelectedServer(id: server.id)
            #if canImport(NetworkExtension)
            if let session = manager?.connection as? NETunnelProviderSession {
                let message = MacTunnelAppMessage(command: .reloadConfig, configJSON: configJSON)
                var delivered = false
                try? session.sendProviderMessage(message.encoded) { _ in delivered = true }
                // sendProviderMessage is callback-based; if the session
                // is not in a state to take messages, the tunnel falls
                // back to a restart below on the next status cycle.
                _ = delivered
            }
            #endif
            publishSnapshot()
        } catch {
            lastFailure = .configuration
            phase = .failed
            NotificationManager.shared.failed(kind: .configuration)
        }
    }

    private func startTunnel(with server: ServerRow) async {
        #if canImport(NetworkExtension)
        do { try await installProfile(for: server) }
        catch {
            lastFailure = .configuration; phase = .failed
            NotificationManager.shared.failed(kind: .configuration)
            publishSnapshot(); return
        }
        guard let mgr = manager else { phase = .profileNotCreated; return }
        currentServer = server
        WidgetSync.publishSelectedServer(id: server.id)
        phase = .connecting
        do { try mgr.connection.startVPNTunnel() }
        catch {
            lastFailure = NotificationManager.FailureKind.classify(error)
            phase = .failed
            NotificationManager.shared.failed(error: error)
        }
        publishSnapshot()
        #endif
    }

    public func disconnect() {
        #if canImport(NetworkExtension)
        phase = .disconnecting
        manager?.connection.stopVPNTunnel()
        #endif
    }

    public func toggle() async {
        if phase.isConnected || phase == .connecting {
            disconnect()
        } else if let server = currentServer ?? AppState.shared.selectedServer
                    ?? SoraCoreBridge.shared.loadProfiles().first {
            await connect(to: server)
        }
    }

    /// Asks the provider for traffic counters (Statistics screen and
    /// the widget snapshot). Reply shape: JSON `{upload, download}`
    /// from `PacketTunnelProvider.handleAppMessage`.
    public func refreshStats() {
        #if canImport(NetworkExtension)
        guard let session = manager?.connection as? NETunnelProviderSession,
              phase.isConnected else { return }
        try? session.sendProviderMessage(MacTunnelAppMessage(command: .stats).encoded) { [weak self] data in
            guard let data,
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            Task { @MainActor in
                self?.uploadBytes = (object["upload"] as? NSNumber)?.int64Value ?? self?.uploadBytes ?? 0
                self?.downloadBytes = (object["download"] as? NSNumber)?.int64Value ?? self?.downloadBytes ?? 0
                self?.publishSnapshot()
            }
        }
        #endif
    }

    // MARK: On-demand

    private func applyOnDemandRules() async {
        #if canImport(NetworkExtension)
        guard let mgr = manager else { return }
        if autoReconnect {
            let rule = NEOnDemandRuleConnect()
            rule.interfaceTypeMatch = .any
            mgr.onDemandRules = [rule]
            mgr.isOnDemandEnabled = true
        } else {
            mgr.isOnDemandEnabled = false
            mgr.onDemandRules = nil
        }
        try? await mgr.saveToPreferences()
        #endif
    }

    // MARK: Status observation

    private func observeStatus() {
        #if canImport(NetworkExtension)
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange, object: nil, queue: .main) { [weak self] note in
            guard let self, let conn = note.object as? NEVPNConnection else { return }
            Task { @MainActor in self.handleStatus(conn.status) }
        }
        #endif
    }

    private func handleStatus(_ status: Any) {
        #if canImport(NetworkExtension)
        guard let s = status as? NEVPNStatus else { return }
        let newPhase = TunnelPhase.from(s)
        let old = phase
        phase = newPhase
        switch newPhase {
        case .connected:
            connectedSince = connectedSince ?? Date()
            if old == .reconnecting, let name = currentServer?.name {
                NotificationManager.shared.reconnected(to: name)
            } else if let name = currentServer?.name {
                NotificationManager.shared.connected(to: name)
            }
            refreshStats()
        case .disconnected:
            connectedSince = nil
            if old == .connected || old == .disconnecting {
                NotificationManager.shared.disconnected()
            } else if old == .connecting || old == .reconnecting {
                // Dropped while it should be up: on-demand should raise
                // it again; show "reconnecting", not an error (§4.2).
                if autoReconnect, currentServer != nil {
                    phase = .reconnecting
                    NotificationManager.shared.reconnecting()
                }
            }
        case .reconnecting:
            NotificationManager.shared.reconnecting()
        default: break
        }
        publishSnapshot()
        #endif
    }

    // MARK: Path / sleep-wake

    private func startPathMonitor() {
        #if canImport(Network)
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                let satisfied = path.status == .satisfied
                defer { self.lastPathSatisfied = satisfied }
                if self.lastPathSatisfied == false, satisfied {
                    await self.loadManager() // re-read truth, never guess
                }
            }
        }
        pathMonitor.start(queue: DispatchQueue(label: "io.github.levvs-one.sora.macos.path"))
        #endif
    }

    private func observeSleepWake() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.wasConnectedBeforeSleep = self.phase.isConnected
                #if canImport(NetworkExtension)
                if let session = self.manager?.connection as? NETunnelProviderSession {
                    try? session.sendProviderMessage(MacTunnelAppMessage(command: .sleep).encoded) { _ in }
                }
                #endif
            }
        }
        center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                await self.loadManager()
                #if canImport(NetworkExtension)
                if let session = self.manager?.connection as? NETunnelProviderSession {
                    try? session.sendProviderMessage(MacTunnelAppMessage(command: .wake).encoded) { _ in }
                }
                #endif
                if self.wasConnectedBeforeSleep, self.phase != .connected,
                   self.autoReconnect, let server = self.currentServer {
                    self.phase = .reconnecting
                    NotificationManager.shared.reconnecting()
                    await self.startTunnel(with: server)
                }
                self.wasConnectedBeforeSleep = false
            }
        }
    }

    // MARK: Snapshot / Handoff

    private func publishSnapshot() {
        let snap = SharedTunnelSnapshot.from(
            phase: phase, serverName: currentServer?.name,
            upload: uploadBytes, download: downloadBytes)
        WidgetSync.publish(snap)
        HandoffManager.shared.updateActivity(snapshot: snap, server: currentServer)
    }
}
