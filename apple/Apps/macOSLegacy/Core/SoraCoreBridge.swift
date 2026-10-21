import Foundation
#if canImport(SoraCore)
import SoraCore
#endif

/// LEGACY REPLACEMENT — macOSLegacy target (deployment target 11.0).
///
/// Replaces: `Apps/macOS/SoraMac/Core/SoraCoreBridge.swift`
/// (same types — `ServerRow`, `SubscriptionRecord`,
/// `SoraCoreBridgeError`, `SoraCoreBridge` — and the same public
/// surface, so `AppState` and `TunnelManager` are reused unchanged).
///
/// Why a replacement exists — two deltas, everything else in the
/// file is identical to the original:
///  1. The original fetches subscriptions with the async
///     `URLSession.data(for:)` API, which is available only from
///     macOS 12. `fetchSubscription(url:)` here is rebuilt on the
///     completion-handler `dataTask` (present since long before
///     macOS 11) wrapped in a checked continuation — continuations
///     themselves back-deploy with the Swift concurrency runtime.
///     Behaviour is unchanged: same request, same User-Agent, same
///     status-code gate, same refusal to log the URL (it carries
///     the user's token).
///  2. `buildConfig` renders for the `.legacy` engine tier
///     (sing-box-lx v1.13.13-lx.15) instead of the builder's
///     `.main` default — the legacy engine rejects main-tier
///     configs; see the note at the call site.
///
/// The contract summary of the original file is preserved below,
/// because it is still the only file in this app that talks to
/// `SoraCore` directly:
///
///   * `ServerProfile` — `id: String`, `name`, `protocol: ProxyProtocol`,
///     `address`, `port`, `subscriptionID: String?`, …
///   * `LinkParser.parse(_:) throws -> ServerProfile` (ONE link)
///   * `SubscriptionParser.parse(_ data: Data) -> SubscriptionResult`
///     (`profiles` + `skipped`) — the multi-format importer
///   * `LibboxConfigBuilder.build(profile:settings:tier:) throws -> String`,
///     `buildChain(profiles:settings:tier:) throws -> String`
///     (tier defaults to `.main` upstream of this file; the legacy
///     composition always passes `.legacy` — see `buildConfig`)
///   * `JSONFileProfileStore(directory:)` — `load()/save(_:)`,
///     `loadSettings()/saveSettings(_:)`
///   * `AppSettings()` with defaults
///
/// Views work with `ServerRow`, a thin wrapper around `ServerProfile`,
/// so parser/model changes stay contained in this file. libbox is
/// NEVER touched by the app: the built config JSON goes to the tunnel
/// extension via the App Group (`current-config.json` +
/// providerConfiguration), and the extension's bridge owns libbox,
/// exactly as on iOS. (On the legacy target that is the legacy bridge
/// from `PacketTunnel/Legacy/` — same bridge API, older engine pin;
/// see TARGET-NOTES.md.)
public struct ServerRow: Identifiable, Equatable, Sendable {
    #if canImport(SoraCore)
    public var profile: ServerProfile
    public var id: String { profile.id }
    public var name: String { profile.name.isEmpty ? profile.address : profile.name }
    public var proto: String { profile.protocol.rawValue }
    public var host: String { profile.address }
    public var port: Int { profile.port }
    public init(profile: ServerProfile) { self.profile = profile }
    #else
    public var id: String; public var name: String; public var proto: String
    public var host: String; public var port: Int
    #endif
    public var endpointLabel: String { "\(host):\(port)" }
    public var protoLabel: String { proto.uppercased() }
}

public struct SubscriptionRecord: Identifiable, Equatable, Codable, Sendable {
    public var id: String
    public var name: String
    public var urlString: String
    public var updatedAt: Date?
    public var serverIDs: [String] = []
}

public enum SoraCoreBridgeError: LocalizedError {
    case coreUnavailable
    case emptyImport
    public var errorDescription: String? {
        switch self {
        case .coreUnavailable: return NSLocalizedString("state.tunnelUnavailable", comment: "")
        case .emptyImport: return NSLocalizedString("error.import_empty", comment: "")
        }
    }
}

public final class SoraCoreBridge: @unchecked Sendable {
    public static let shared = SoraCoreBridge()

    /// Profile store directory: the ARCHITECTURE.md §3.4 App Group
    /// container. Deliberately NOT `JSONFileProfileStore
    /// .sharedContainer()` — see the divergence note in
    /// `AppIdentifiers`. Falls back to Application Support so
    /// Developer ID / unsigned dev builds never crash on a missing
    /// container (the UI surfaces `state.appGroupUnavailable` then).
    public static var storeDirectory: URL {
        if let group = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppIdentifiers.appGroupID) {
            return group
        }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Sora", isDirectory: true)
    }

    public static var appGroupAvailable: Bool {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppIdentifiers.appGroupID) != nil
    }

    #if canImport(SoraCore)
    private var store: JSONFileProfileStore { JSONFileProfileStore(directory: Self.storeDirectory) }
    #endif

    public func loadProfiles() -> [ServerRow] {
        #if canImport(SoraCore)
        return ((try? store.load()) ?? []).map(ServerRow.init(profile:))
        #else
        return []
        #endif
    }

    public func saveProfiles(_ rows: [ServerRow]) throws {
        #if canImport(SoraCore)
        try store.save(rows.map(\.profile))
        #else
        throw SoraCoreBridgeError.coreUnavailable
        #endif
    }

    public func loadSettings() -> Any? {
        #if canImport(SoraCore)
        return try? store.loadSettings()
        #else
        return nil
        #endif
    }

    // MARK: Import

    /// Multi-format import (link lists, base64, Clash YAML, sing-box
    /// JSON, SIP008, WireGuard conf) via `SubscriptionParser`.
    /// Returns the imported rows plus how many lines were skipped, so
    /// the UI can say "added N, M lines were not recognised" honestly
    /// instead of silently dropping them.
    public func parseImport(data: Data) -> (rows: [ServerRow], skipped: Int) {
        #if canImport(SoraCore)
        let result = SubscriptionParser.parse(data)
        return (result.profiles.map(ServerRow.init(profile:)), result.skipped.count)
        #else
        return ([], 0)
        #endif
    }

    public func parseImport(text: String) -> (rows: [ServerRow], skipped: Int) {
        parseImport(data: Data(text.utf8))
    }

    /// Parses exactly one share link (URL-scheme delivery of a single
    /// `vless://…` etc.). Throws `SoraParseError` from SoraCore.
    public func parseSingleLink(_ link: String) throws -> ServerRow {
        #if canImport(SoraCore)
        return ServerRow(profile: try LinkParser.parse(link))
        #else
        throw SoraCoreBridgeError.coreUnavailable
        #endif
    }

    /// Downloads a subscription and parses its payload.
    /// The URL is never logged — it carries the user's token.
    ///
    /// LEGACY DELTA (the reason this file exists): the download runs
    /// on the completion-handler data task inside a continuation,
    /// because the async URLSession convenience API starts at
    /// macOS 12 and this target's floor is 11.0.
    public func fetchSubscription(url: URL) async throws -> (rows: [ServerRow], skipped: Int) {
        var req = URLRequest(url: url)
        req.setValue("sora-macos", forHTTPHeaderField: "User-Agent")
        let (data, response): (Data, URLResponse) = try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: req) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data, let response else {
                    continuation.resume(throwing: SoraCoreBridgeError.emptyImport)
                    return
                }
                continuation.resume(returning: (data, response))
            }.resume()
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw SoraCoreBridgeError.emptyImport
        }
        let parsed = parseImport(data: data)
        if parsed.rows.isEmpty { throw SoraCoreBridgeError.emptyImport }
        return parsed
    }

    // MARK: Config building

    /// Builds the sing-box JSON for one server (or a chain, in order).
    /// The string is written to the App Group by `TunnelManager`
    /// (`current-config.json`, ARCHITECTURE.md §3.4/§4.3).
    ///
    /// LEGACY TIER: this composition always renders for the
    /// `.legacy` engine tier (sing-box-lx v1.13.13-lx.15). The
    /// builder's capability table for that tier applies the
    /// version gates measured in `apple/Legacy/ENGINES.md` §4 (no
    /// 1.14-only fields) and refuses profiles whose mandatory
    /// features the pin cannot emit — the main client's default
    /// `.main` tier would produce a config the legacy engine
    /// rejects, so the tier is stated here, at the one call site
    /// this app owns, never left to the default.
    public func buildConfig(for row: ServerRow, chain: [ServerRow] = []) throws -> String {
        #if canImport(SoraCore)
        let settings = (try? store.loadSettings()) ?? AppSettings()
        if chain.isEmpty {
            return try LibboxConfigBuilder.build(profile: row.profile, settings: settings, tier: .legacy)
        }
        return try LibboxConfigBuilder.buildChain(profiles: chain.map(\.profile), settings: settings, tier: .legacy)
        #else
        throw SoraCoreBridgeError.coreUnavailable
        #endif
    }

    // MARK: Subscriptions persistence (app-side, in the same container)

    private static var subscriptionsFile: URL { storeDirectory.appendingPathComponent("mac-subscriptions.json") }

    public func loadSubscriptions() -> [SubscriptionRecord] {
        guard let data = try? Data(contentsOf: Self.subscriptionsFile) else { return [] }
        return (try? JSONDecoder().decode([SubscriptionRecord].self, from: data)) ?? []
    }

    public func saveSubscriptions(_ subs: [SubscriptionRecord]) {
        try? FileManager.default.createDirectory(at: Self.storeDirectory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(subs) {
            try? data.write(to: Self.subscriptionsFile, options: [.atomic])
        }
    }
}
