import Foundation

/// Legacy libbox bridge for the iOS 13–14 / macOS 11–12 tier, pinned
/// to sing-box-lx **v1.13.13-lx.15** (apple/Legacy/ENGINES.md §1).
///
/// DROP-IN REPLACEMENT for `PacketTunnel/LibboxBridge.swift`: this
/// file defines the SAME internal Swift API — `LibboxBridge`,
/// `LibboxBridgeError`, `LibboxBridgeImpl` — so the shared
/// `PacketTunnelProvider.swift` compiles against either bridge with
/// zero changes. The legacy PacketTunnel target (TARGET-NOTES in
/// Apps/iOSLegacy) includes the shared PacketTunnel sources plus
/// this file INSTEAD of `LibboxBridge.swift`; never both.
///
/// ============================================================
/// DIVERGENCES from the 1.14 bridge (all derived from the pinned
/// sources, tree `experimental/libbox` of v1.13.13-lx.15, checked
/// against v1.14.3-lx.22 on 2026-10-21 — full map in
/// LegacyBridgeNotes.md next to this file):
///
///  D1. NO BoxService. Neither pin has a `LibboxNewService` /
///      `LibboxBoxService` in `experimental/libbox` — the 1.14
///      bridge's service calls are unverified guesses (its own
///      TODOs say so). In lx.15 the service is owned by
///      **CommandServer**: `NewCommandServer(handler,
///      platformInterface)`, `Start()`, `StartOrReloadService(
///      config, options)`, `CloseService()`, `Close()`, plus
///      `Pause()` / `Wake()` / `ResetNetwork()`. lx.22's
///      CommandServer has the same core shape (plus `WakeNow()`,
///      `RecordScreenState()`), so this is also the shape the main
///      bridge will converge to at its Mac verification.
///  D2. SetupOptions is SMALLER: lx.15 has exactly 8 fields
///      (BasePath, WorkingPath, TempPath, FixAndroidStack,
///      CommandServerListenPort, CommandServerSecret, LogMaxLines,
///      Debug). lx.22 adds CrashReportSource, AppVersion,
///      AppMarketingVersion, OomKiller*, PowerReportEnabled,
///      PlatformMetadata and a `ReloadSetupOptions` call — none of
///      which exist in lx.15 and none of which are set here.
///  D3. PlatformInterface is SMALLER: 19 methods in lx.15.
///      lx.22 adds CancelNotification, neighbor monitoring,
///      platform shell sessions, bridge creation, RegisterMyInterface
///      and Tailscale hostname. Nothing here implements those.
///  D4. The platform interface is MANDATORY, not a footnote: in
///      lx.15 nothing starts without it (NewCommandServer registers
///      the wrapper into the box context). The 1.14 bridge defers
///      this to a TODO; here the interface is implemented below,
///      with the TUN-fd handoff behind a registration hook (D6).
///  D5. Stats are a STREAM, not a query: `CommandClient` +
///      `CommandClientHandler.WriteStatus(StatusMessage)` with
///      `TrafficAvailable`, `Uplink/Downlink` (rates) and
///      `UplinkTotal/DownlinkTotal` (cumulative bytes),
///      `ConnectionsIn/Out`. `queryStats()` below serves the latest
///      streamed message; no message yet / TrafficAvailable=false
///      → `.capabilityUnavailable`, never fabricated zeroes.
///  D6. TUN fd: `PlatformInterface.OpenTun(TunOptions)` must return
///      the packet-flow fd. The fd lives in the provider
///      (`NEPacketTunnelFlow`), which is bridge-agnostic shared code,
///      so the fd source is registered through
///      `LibboxBridgeImpl.registerTUNFDProvider(_:)` — one call the
///      coordinator wires at target composition (TODO(verify-on-mac)
///      in TARGET-NOTES). Until registered, OpenTun throws and the
///      start fails honestly instead of running without a TUN.
///  D7. `CheckConfig(config)` exists in lx.15 (config.go) and is
///      used as a preflight: a config the engine would reject fails
///      as `.invalidConfig` before any service start.
/// ============================================================
public protocol LibboxBridge: AnyObject, Sendable {
    /// One-time process setup. Must be called before `startService`.
    /// `basePath` is the App Group container: config, cache and logs live
    /// there so app and extension agree on locations.
    func setup(basePath: String, workingPath: String, tempPath: String) throws
    /// Start the sing-box service with a complete config JSON.
    func startService(configJSON: String) throws
    /// Stop the service. Safe to call when already stopped.
    func stopService() throws
    /// Whether the service object reports itself started.
    var isRunning: Bool { get }
    /// Cumulative traffic + live connection counts, if the linked libbox
    /// build exposes them; throws `.capabilityUnavailable` otherwise.
    func queryStats() throws -> TunnelStatusPayload
}

public enum LibboxBridgeError: Error, Equatable {
    case frameworkMissing
    case capabilityUnavailable(String)
    case startFailed(String)
    case invalidConfig(String)
}

#if canImport(Libbox)
import Libbox
import os.log

/// Real bridge over the lx.15 generated bindings.
///
/// TODO(verify-on-mac): reconcile every generated spelling below
/// with the headers of the lx.15 Libbox.xcframework (built from the
/// pin per ENGINES.md §2.3 — the fork publishes no xcframework):
/// gomobile renames Go exports (`NewCommandServer` →
/// `LibboxNewCommandServer`, interfaces → `Libbox…Protocol`), and
/// the argument labels / NSError out-parameter positions follow the
/// generated header, not this file's expectations.
public final class LibboxBridgeImpl: LibboxBridge, @unchecked Sendable {
    private var server: LibboxCommandServer?
    private var client: LibboxCommandClient?
    private var statusHandler: LegacyCommandClientHandler?
    private var serviceStarted = false
    private let lock = NSLock()
    private let log = Logger(subsystem: SoraIdentifiers.tunnelBundleID, category: "libbox-legacy")

    /// TUN file-descriptor source for the platform interface's
    /// OpenTun (divergence D6). Registered once by the target's
    /// composition code; returns the packet-flow fd or nil.
    private static var tunFDProvider: (() -> Int32?)?
    public static func registerTUNFDProvider(_ provider: @escaping () -> Int32?) {
        tunFDProvider = provider
    }
    static var currentTUNFD: Int32? { tunFDProvider?() }

    public init() {}

    public func setup(basePath: String, workingPath: String, tempPath: String) throws {
        // TODO(verify-on-mac): exact generated signature — lx.15 Go:
        // `Setup(options *SetupOptions) error`, options fields per D2.
        let options = LibboxSetupOptions()
        options.basePath = basePath
        options.workingPath = workingPath
        options.tempPath = tempPath
        options.logMaxLines = 500
        var error: NSError?
        LibboxSetup(options, &error)
        if let error { throw LibboxBridgeError.startFailed(error.localizedDescription) }
    }

    public func startService(configJSON: String) throws {
        lock.lock(); defer { lock.unlock() }

        // D7 preflight: reject before touching the service.
        var checkError: NSError?
        LibboxCheckConfig(configJSON, &checkError)
        if let checkError {
            throw LibboxBridgeError.invalidConfig(checkError.localizedDescription)
        }

        if server == nil {
            // TODO(verify-on-mac): constructor spelling/order — lx.15
            // Go: `NewCommandServer(handler, platformInterface)
            // (*CommandServer, error)`. Setup() must have run first:
            // the server reads the setup globals (debug, log lines).
            let handler = LegacyCommandServerHandler(bridge: self)
            let platform = LegacyPlatformInterface()
            var error: NSError?
            let created = LibboxNewCommandServer(handler, platform, &error)
            if let error { throw LibboxBridgeError.startFailed(error.localizedDescription) }
            guard let created else { throw LibboxBridgeError.frameworkMissing }
            created.start(&error)
            if let error { throw LibboxBridgeError.startFailed(error.localizedDescription) }
            server = created
            startStatusClient()
        }
        guard let server else { throw LibboxBridgeError.frameworkMissing }

        // TODO(verify-on-mac): spelling — lx.15 Go:
        // `StartOrReloadService(configContent string, options
        // *OverrideOptions) error`; nil-safe iterator fields per the
        // generated OverrideOptions type.
        let options = LibboxOverrideOptions()
        var error: NSError?
        server.startOrReloadService(configJSON, options, &error)
        if let error { throw LibboxBridgeError.startFailed(error.localizedDescription) }
        serviceStarted = true
    }

    public func stopService() throws {
        lock.lock(); defer { lock.unlock() }
        var error: NSError?
        client?.disconnect(&error)
        client = nil
        statusHandler = nil
        if serviceStarted {
            server?.closeService(&error)
            serviceStarted = false
        }
        server?.close()
        server = nil
    }

    public var isRunning: Bool { serviceStarted }

    public func queryStats() throws -> TunnelStatusPayload {
        lock.lock(); defer { lock.unlock() }
        guard serviceStarted, let status = statusHandler?.latestStatus else {
            throw LibboxBridgeError.capabilityUnavailable("stats")
        }
        // D5: lx.15 StatusMessage carries `TrafficAvailable`; when the
        // engine cannot account traffic it says so — mirror that.
        guard status.trafficAvailable else {
            throw LibboxBridgeError.capabilityUnavailable("stats")
        }
        return TunnelStatusPayload(
            running: true,
            uploadBytes: status.uplinkTotal,
            downloadBytes: status.downlinkTotal,
            activeConnections: Int(status.connectionsIn) + Int(status.connectionsOut))
    }

    // MARK: Command client (status stream)

    private func startStatusClient() {
        // TODO(verify-on-mac): spellings — lx.15 Go:
        // `NewCommandClient(handler, options) *CommandClient` (no
        // error return), `CommandClientOptions{StatusInterval}`,
        // `options.AddCommand(CommandStatus)`, `client.Connect()`.
        let handler = LegacyCommandClientHandler()
        statusHandler = handler
        let options = LibboxCommandClientOptions()
        options.statusInterval = 2_000_000_000 // ns — TODO(verify-on-mac): unit in generated header
        options.addCommand(LibboxCommandStatus)
        let created = LibboxNewCommandClient(handler, options)
        client = created
        var error: NSError?
        created.connect(&error)
        if error != nil {
            // Stats are a ladder rung, not the tunnel: log and run
            // without counters; queryStats() reports unavailable.
            log.debug("legacy command client connect failed; stats unavailable")
            statusHandler = nil
            client = nil
            return
        }
    }

    /// CommandServer's ServiceStop callback: the engine asks the
    /// platform to stop (e.g. service-mode shutdown). The provider
    /// owns the tunnel lifecycle, so this only drops our flag; the
    /// provider's stopTunnel performs the real teardown.
    fileprivate func noteServiceStop() {
        lock.lock(); defer { lock.unlock() }
        serviceStarted = false
    }
}

// MARK: - Platform interface (lx.15, divergence D3/D4)

/// Swift implementation of lx.15's `PlatformInterface`
/// (experimental/libbox/platform.go of the pin). Every method maps
/// 1:1 to the Go interface listed in LegacyBridgeNotes.md.
/// TODO(verify-on-mac): the generated protocol name and each
/// method's exact Swift spelling come from the lx.15 framework
/// headers; the semantics below are the pin's, the spellings are
/// gomobile's conventions.
final class LegacyPlatformInterface: NSObject, LibboxPlatformInterfaceProtocol {
    // No platform-local DNS transport: configs resolve through the
    // box's own DNS module (the SFI client does the same on iOS).
    func localDNSTransport() -> LibboxLocalDNSTransportProtocol? { nil }

    // The provider's own traffic never traverses its TUN on iOS, and
    // route control belongs to NEPacketTunnelNetworkSettings, so
    // libbox does not need per-fd interface binding from us.
    func usePlatformAutoDetectInterfaceControl() -> Bool { false }
    func autoDetectInterfaceControl(_ fd: Int32) throws {
        throw NSError(domain: "sora.libbox.legacy", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "auto-detect interface control is platform-owned"])
    }

    /// The TUN fd handoff (D6): the registered provider supplies the
    /// packet-flow fd; the TunOptions are already reflected in the
    /// provider's network settings, so they are not re-applied here.
    func openTun(_ options: LibboxTunOptionsProtocol?) throws -> Int32 {
        guard let fd = LibboxBridgeImpl.currentTUNFD else {
            throw NSError(domain: "sora.libbox.legacy", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "TUN file descriptor not registered (see TARGET-NOTES)"])
        }
        return fd
    }

    func useProcFS() -> Bool { false } // iOS has no procfs.

    func findConnectionOwner(_ ipProtocol: Int32, sourceAddress: String?,
                             sourcePort: Int32, destinationAddress: String?,
                             destinationPort: Int32) throws -> LibboxConnectionOwner? {
        // Per-connection owner lookup is not possible for another
        // app's traffic on iOS; honest error, not a fabricated owner.
        throw NSError(domain: "sora.libbox.legacy", code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "connection owner lookup unavailable on iOS"])
    }

    // Interface monitoring: the shared provider re-asserts network
    // settings on wake/network change (PacketTunnelProvider.wake),
    // which is this tier's repair path; a path-monitor feed into
    // libbox is TODO(verify-on-mac) — silently swallowing the
    // listener here would fake a capability, so registration is
    // accepted but documented as inert in LegacyBridgeNotes.md.
    private var monitorListener: LibboxInterfaceUpdateListenerProtocol?
    func startDefaultInterfaceMonitor(_ listener: LibboxInterfaceUpdateListenerProtocol?) throws {
        monitorListener = listener
    }
    func closeDefaultInterfaceMonitor(_ listener: LibboxInterfaceUpdateListenerProtocol?) throws {
        monitorListener = nil
    }

    func getInterfaces() throws -> LibboxNetworkInterfaceIteratorProtocol? {
        // TODO(verify-on-mac): enumerate via getifaddrs like SFI;
        // until verified on a Mac, report none rather than inventing
        // interface data (auto_route comes from NE settings anyway).
        return LegacyNetworkInterfaceIterator()
    }

    func underNetworkExtension() -> Bool { true }
    func includeAllNetworks() -> Bool { false }

    func readWIFIState() -> LibboxWIFIState? {
        // Without the hotspot entitlement the SSID is unavailable on
        // iOS; an empty state is the platform's true answer.
        return LibboxNewWIFIState("", "")
    }

    func systemCertificates() -> LibboxStringIteratorProtocol? {
        // TODO(verify-on-mac): PEM anchors via SecTrust; empty until
        // the encoding choice is verified against the pin's parser.
        return LegacyStringIterator(values: [])
    }

    func clearDNSCache() {
        // iOS exposes no per-app DNS cache flush; the box clears its
        // own cache on reload. Nothing honest to do here.
    }

    func sendNotification(_ notification: LibboxNotification?) throws {
        throw NSError(domain: "sora.libbox.legacy", code: 4,
                      userInfo: [NSLocalizedDescriptionKey: "notifications are app-owned in the legacy target"])
    }
}

// MARK: - Command server handler (lx.15)

/// lx.15 `CommandServerHandler`: ServiceStop, ServiceReload,
/// GetSystemProxyStatus, SetSystemProxyEnabled, WriteDebugMessage.
/// TODO(verify-on-mac): generated protocol spelling.
final class LegacyCommandServerHandler: NSObject, LibboxCommandServerHandlerProtocol {
    private weak var bridge: LibboxBridgeImpl?
    init(bridge: LibboxBridgeImpl) { self.bridge = bridge }

    func serviceStop() throws { bridge?.noteServiceStop() }
    func serviceReload() throws {
        // Reload is driven by the app through StartOrReloadService;
        // an engine-initiated reload request has no config source
        // here, so it is acknowledged without action (the daemon
        // performs its internal reload path itself).
    }
    func getSystemProxyStatus() throws -> LibboxSystemProxyStatus? {
        // iOS has no user system-proxy concept for the extension:
        // Available=false is the honest answer (mirrors the pin's
        // SystemProxyStatus{Available, Enabled}).
        let status = LibboxSystemProxyStatus()
        status.available = false
        status.enabled = false
        return status
    }
    func setSystemProxyEnabled(_ enabled: Bool) throws {
        throw NSError(domain: "sora.libbox.legacy", code: 5,
                      userInfo: [NSLocalizedDescriptionKey: "system proxy is not available on iOS"])
    }
    func writeDebugMessage(_ message: String?) {
        // Debug lines from the engine: log channel only, never UI.
        if let message { NSLog("%@", message) }
    }
}

// MARK: - Command client handler (lx.15, stats stream)

/// lx.15 `CommandClientHandler`; only WriteStatus is consumed —
/// the rest are acknowledged no-ops (logs/groups/clash-mode are not
/// surfaces of this tier; the main app doesn't surface them either).
/// TODO(verify-on-mac): generated protocol spelling + StatusMessage
/// property spellings (uplinkTotal/downlinkTotal are Int64 in Go).
final class LegacyCommandClientHandler: NSObject, LibboxCommandClientHandlerProtocol {
    private(set) var latestStatus: LibboxStatusMessage?
    private let statusLock = NSLock()

    func connected() {}
    func disconnected(_ message: String?) {
        statusLock.lock(); defer { statusLock.unlock() }
        latestStatus = nil
    }
    func setDefaultLogLevel(_ level: Int32) {}
    func clearLogs() {}
    func writeLogs(_ messageList: LibboxLogIteratorProtocol?) {}
    func writeStatus(_ message: LibboxStatusMessage?) {
        statusLock.lock(); defer { statusLock.unlock() }
        latestStatus = message
    }
    func writeGroups(_ message: LibboxOutboundGroupIteratorProtocol?) {}
    func initializeClashMode(_ modeList: LibboxStringIteratorProtocol?, currentMode: String?) {}
    func updateClashMode(_ newMode: String?) {}
    func writeConnectionEvents(_ events: LibboxConnectionEvents?) {}
}

// MARK: - Iterator helpers (gomobile iterator protocols)

/// TODO(verify-on-mac): generated protocol spelling — Go
/// `StringIterator` is `Next() string / HasNext() bool`.
final class LegacyStringIterator: NSObject, LibboxStringIteratorProtocol {
    private let values: [String]
    private var index = 0
    init(values: [String]) { self.values = values }
    func hasNext() -> Bool { index < values.count }
    func next() -> String? {
        guard index < values.count else { return nil }
        defer { index += 1 }
        return values[index]
    }
}

/// TODO(verify-on-mac): generated protocol spelling — Go
/// `NetworkInterfaceIterator` is `Next() *NetworkInterface /
/// HasNext() bool`. Empty by design (see getInterfaces).
final class LegacyNetworkInterfaceIterator: NSObject, LibboxNetworkInterfaceIteratorProtocol {
    func hasNext() -> Bool { false }
    func next() -> LibboxNetworkInterface? { nil }
}
#else
/// Used in Simulator builds without the XCFramework and in Linux
/// parse checks — identical fallback contract to the main bridge:
/// fails honestly; the provider surfaces a start error and the app
/// shows `state.tunnelUnavailable` instead of a fake tunnel.
public final class LibboxBridgeImpl: LibboxBridge, @unchecked Sendable {
    public init() {}
    public func setup(basePath: String, workingPath: String, tempPath: String) throws {
        throw LibboxBridgeError.frameworkMissing
    }
    public func startService(configJSON: String) throws {
        throw LibboxBridgeError.frameworkMissing
    }
    public func stopService() throws {}
    public var isRunning: Bool { false }
    public func queryStats() throws -> TunnelStatusPayload {
        throw LibboxBridgeError.frameworkMissing
    }
}
#endif
