import Foundation
import SoraCore

// MARK: - Servers

/// Servers screen model: profiles grouped by subscription, search,
/// swipe-delete, selection. Terminology follows the main app's glossary:
/// "server" (сервер), "subscription" (подписка), "connection"
/// (подключение) — the same words in every screen and string.
@MainActor
public final class ServersViewModel: ObservableObject {
    @Published public private(set) var profiles: [ServerProfile] = []
    @Published public var searchText: String = ""
    @Published public var alertKey: String?
    public let store: ProfilePersisting

    public init(store: ProfilePersisting) { self.store = store }

    public func reload() {
        do { profiles = try store.load() }
        catch { alertKey = SoraAppError.profileStoreFailed.localizationKey }
    }

    public var filtered: [ServerProfile] {
        guard !searchText.isEmpty else { return profiles }
        let needle = searchText.lowercased()
        return profiles.filter {
            $0.name.lowercased().contains(needle)
                || $0.address.lowercased().contains(needle)
                || $0.protocol.rawValue.contains(needle)
        }
    }

    /// Groups in stable order: named subscriptions first (sorted by
    /// their earliest server name), then manually added servers under a
    /// nil key (rendered with the `customServers` heading).
    public var groups: [(subscriptionID: String?, profiles: [ServerProfile])] {
        var byKey: [String?, [ServerProfile]] = [:]
        for profile in filtered { byKey[profile.subscriptionID, default: []].append(profile) }
        return byKey
            .map { (subscriptionID: $0.key, profiles: $0.value.sorted { $0.name < $1.name }) }
            .sorted { ($0.subscriptionID ?? "~") < ($1.subscriptionID ?? "~") }
    }

    public func delete(_ profile: ServerProfile) {
        profiles.removeAll { $0.id == profile.id }
        persist()
    }

    public func upsert(_ profile: ServerProfile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
        } else {
            profiles.append(profile)
        }
        persist()
    }

    private func persist() {
        do { try store.save(profiles) }
        catch { alertKey = SoraAppError.profileStoreFailed.localizationKey }
    }
}

// MARK: - Import

@MainActor
public final class ImportViewModel: ObservableObject {
    @Published public var input: String = ""
    @Published public private(set) var importedCount: Int?
    @Published public var alertKey: String?
    /// Rebindable: SwiftUI creates the model before the environment's
    /// ServersViewModel is known; the view rebinds on appear.
    var servers: ServersViewModel

    public init(servers: ServersViewModel) { self.servers = servers }

    /// Accepts a single share link, several links (one per line), a
    /// subscription body, or a subscription URL. Parsing is SoraCore's
    /// job; this model only routes and counts.
    public func importFromText() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        var added = 0
        var lastError: Error?
        // Multi-link paste: try line by line first.
        let lines = text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if lines.count > 1 {
            for line in lines {
                if let profile = try? LinkParser.parse(line) {
                    servers.upsert(profile); added += 1
                }
            }
        }
        if added == 0 {
            if let profile = try? LinkParser.parse(text) {
                servers.upsert(profile); added = 1
            } else if let data = text.data(using: .utf8),
                      !SubscriptionParser.parse(data).profiles.isEmpty {
                let parsed = SubscriptionParser.parse(data)
                parsed.profiles.forEach { servers.upsert($0) }
                added = parsed.profiles.count
            } else if let url = URL(string: text), url.scheme == "http" || url.scheme == "https" {
                // Subscription URL: fetching is a network act the user
                // confirms in the subscriptions screen of the main app;
                // here we hand the URL over as a pending import instead
                // of silently fetching from a paste action.
                pendingSubscriptionURL = url
                return
            } else {
                lastError = NSError(domain: "sora.import", code: 0)
            }
        }
        if added > 0 {
            importedCount = added
            input = ""
        } else {
            alertKey = ParseFailureLocalization.key(
                forErrorDescription: String(describing: lastError ?? NSError(domain: "sora.import", code: 0)))
        }
    }

    @Published public var pendingSubscriptionURL: URL?

    public func importScanned(_ code: String) {
        input = code
        importFromText()
    }
}

// MARK: - Stats

@MainActor
public final class StatsViewModel: ObservableObject {
    @Published public private(set) var payload: TunnelStatusPayload?
    /// True when the provider could not supply counters (libbox stats
    /// capability unavailable): the screen says so instead of showing
    /// zeroes. This is the honesty flag for the data source.
    @Published public private(set) var isUnavailable = false
    private let tunnel: TunnelManager

    public init(tunnel: TunnelManager) { self.tunnel = tunnel }

    public func refresh() async {
        do {
            payload = try await tunnel.requestStats()
            isUnavailable = false
        } catch {
            payload = nil
            isUnavailable = true
        }
    }

    /// Direct application paths used by StatsView, which refreshes
    /// through the environment's TunnelManager (the model's own tunnel
    /// reference exists for previews/tests).
    public func apply(_ newPayload: TunnelStatusPayload) {
        payload = newPayload
        isUnavailable = false
    }
    public func applyUnavailable() {
        payload = nil
        isUnavailable = true
    }
}

// MARK: - Settings

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var settings: AppSettings
    @Published public var alertKey: String?
    @Published public var notificationsEnabled: Bool = false
    private let store: ProfilePersisting

    public init(store: ProfilePersisting) {
        self.store = store
        self.settings = (try? store.loadSettings()) ?? AppSettings()
    }

    /// Split-tunnel routes as one CIDR per line, edited in a text view.
    public var excludedRoutesText: String {
        get { settings.splitTunnelExcludedRoutes.joined(separator: "\n") }
        set {
            settings.splitTunnelExcludedRoutes = newValue
                .split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
    }
    public var includedRoutesText: String {
        get { settings.splitTunnelIncludedRoutes.joined(separator: "\n") }
        set {
            settings.splitTunnelIncludedRoutes = newValue
                .split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
    }
    /// DNS servers as one per line (URL or plain address, SoraCore form).
    public var dnsText: String {
        get { settings.dnsServers.joined(separator: "\n") }
        set {
            let lines = newValue
                .split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            if !lines.isEmpty { settings.dnsServers = lines }
        }
    }

    public func save() {
        do { try store.saveSettings(settings) }
        catch { alertKey = SoraAppError.profileStoreFailed.localizationKey }
    }

    public func setNotificationsEnabled(_ enabled: Bool) async {
        if enabled {
            notificationsEnabled = await NotificationService.requestAuthorization()
        } else {
            notificationsEnabled = false
        }
    }
}
