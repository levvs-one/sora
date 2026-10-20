import Foundation

/// The single seam between Sora and the libbox XCFramework (sing-box).
///
/// HONESTY NOTE — read before wiring the real framework:
/// The libbox Swift API is generated from the Go module
/// `github.com/sagernet/sing-box/experimental/libbox` via gomobile, and its
/// exact Swift spellings have changed between sing-box releases. Every
/// signature in `LibboxBridgeImpl` below is therefore marked
/// `TODO(verify-on-mac)`: on a Mac, open the pinned `Libbox.xcframework`'s
/// generated headers and reconcile names one by one. Nothing outside this
/// file may reference libbox types, so the reconciliation is confined to
/// this one file by design.
///
/// What the real API is expected to provide (sing-box libbox, recent):
///  * a setup call taking base/work/temp paths and flags,
///  * a platform interface for TUN file-descriptor handoff,
///  * a service object with start/close over a config string,
///  * traffic + connection counters via the command client.
/// If a given release lacks one of these, the bridge throws
/// `LibboxBridgeError.capabilityUnavailable` and the UI shows the honest
/// `state.statsUnavailable` state instead of fabricated numbers.
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

/// Real bridge over the generated libbox bindings.
///
/// TODO(verify-on-mac): reconcile every call below with the headers of
/// the pinned Libbox.xcframework before the first device run:
///   * `LibboxSetup` argument order/labels and the options type name,
///   * service constructor + type name (`LibboxBoxService` in recent
///     releases),
///   * how the TUN file descriptor is handed over (platform interface
///     `LibboxPlatformInterfaceProtocol` in recent releases — the
///     provider may need to implement that protocol and pass it at setup;
///     this is the first thing to fix if the pinned headers differ),
///   * stats access (`LibboxCommandClient` group/traffic queries).
public final class LibboxBridgeImpl: LibboxBridge, @unchecked Sendable {
    private var service: LibboxBoxService?
    private let lock = NSLock()

    public init() {}

    public func setup(basePath: String, workingPath: String, tempPath: String) throws {
        // TODO(verify-on-mac): exact generated signature.
        let options = LibboxSetupOptions()
        options.basePath = basePath
        options.workingPath = workingPath
        options.tempPath = tempPath
        var error: NSError?
        LibboxSetup(options, &error)
        if let error { throw LibboxBridgeError.startFailed(error.localizedDescription) }
    }

    public func startService(configJSON: String) throws {
        lock.lock(); defer { lock.unlock() }
        var error: NSError?
        // TODO(verify-on-mac): constructor name + config argument label.
        let newService = LibboxNewService(configJSON, nil, &error)
        if let error { throw LibboxBridgeError.invalidConfig(error.localizedDescription) }
        guard let newService else { throw LibboxBridgeError.frameworkMissing }
        newService.start(&error)
        if let error { throw LibboxBridgeError.startFailed(error.localizedDescription) }
        service = newService
    }

    public func stopService() throws {
        lock.lock(); defer { lock.unlock() }
        service?.close(nil)
        service = nil
    }

    public var isRunning: Bool { service != nil }

    public func queryStats() throws -> TunnelStatusPayload {
        // TODO(verify-on-mac): wire the LibboxCommandClient traffic query.
        // Until the pinned headers confirm the counter API, report the
        // honest capability error rather than zeroes dressed as data.
        throw LibboxBridgeError.capabilityUnavailable("stats")
    }
}
#else
/// Used in Simulator builds without the XCFramework and in Linux parse
/// checks. Fails honestly: the provider surfaces a start error and the
/// app shows `state.tunnelUnavailable` instead of a fake tunnel.
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
