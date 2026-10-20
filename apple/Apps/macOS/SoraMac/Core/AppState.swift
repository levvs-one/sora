import Foundation
import Combine
#if canImport(AppKit)
import AppKit
#endif

/// UI-facing state for the whole Mac app: profiles, subscriptions,
/// selection, search, import feedback. All persistence goes through
/// `SoraCoreBridge`; all tunnel actions go through `TunnelManager`.
/// One instance, injected as an environment object — the menu bar,
/// the status-item controller and the intents all read the same one.
@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    @Published public private(set) var servers: [ServerRow] = []
    @Published public private(set) var subscriptions: [SubscriptionRecord] = []
    @Published public var selectedServerID: String? {
        didSet { WidgetSync.publishSelectedServer(id: selectedServerID) }
    }
    @Published public var searchText: String = ""
    /// Last import outcome, rendered as a calm inline message (never a
    /// raw error): "added N servers", "M lines were not recognised".
    @Published public var importMessage: String?
    @Published public var importFailed: Bool = false

    public var selectedServer: ServerRow? {
        servers.first { $0.id == selectedServerID } ?? servers.first
    }

    public var filteredServers: [ServerRow] {
        guard !searchText.isEmpty else { return servers }
        let q = searchText.lowercased()
        return servers.filter {
            $0.name.lowercased().contains(q) || $0.host.lowercased().contains(q)
                || $0.proto.lowercased().contains(q)
        }
    }

    private init() { reload() }

    public func reload() {
        servers = SoraCoreBridge.shared.loadProfiles()
        subscriptions = SoraCoreBridge.shared.loadSubscriptions()
        if selectedServerID == nil {
            selectedServerID = WidgetSync.sharedDefaults?
                .string(forKey: AppIdentifiers.AppGroupKey.activeProfileID)
                ?? servers.first?.id
        }
    }

    // MARK: Selection / connect (one click)

    /// One-click switch: selecting a row selects it; if the tunnel is
    /// up, it also fast-switches (TunnelManager §4.3 path).
    public func select(_ server: ServerRow, connectIfActive: Bool = true) {
        selectedServerID = server.id
        if connectIfActive, TunnelManager.shared.phase.isConnected {
            Task { await TunnelManager.shared.connect(to: server) }
        }
    }

    // MARK: Import — file / clipboard / URL / drag & drop / deep link

    @discardableResult
    public func importText(_ text: String, subscriptionName: String? = nil) -> Int {
        // A bare http(s) URL in pasted text is a subscription, not a link.
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), ["http", "https"].contains(url.scheme ?? ""),
           !trimmed.contains("\n"), trimmed.components(separatedBy: "://").count == 2 {
            Task { await addSubscription(urlString: trimmed, name: subscriptionName ?? "") }
            return 0
        }
        let parsed = SoraCoreBridge.shared.parseImport(text: text)
        return mergeImported(parsed.rows, skipped: parsed.skipped)
    }

    @discardableResult
    public func importFile(at url: URL) -> Int {
        guard let data = SecurityScopedBookmarks.importPickedFile(
            at: url, bookmarkKey: "import.\(url.lastPathComponent)") else {
            importFailed = true
            importMessage = tr("alert.importFailed",
                               "Import failed. The text was not recognized as a server, subscription or config; nothing was added.")
            return 0
        }
        let parsed = SoraCoreBridge.shared.parseImport(data: data)
        return mergeImported(parsed.rows, skipped: parsed.skipped)
    }

    public func importClipboard() {
        #if canImport(AppKit)
        if let text = NSPasteboard.general.string(forType: .string), !text.isEmpty {
            importText(text)
        } else {
            importFailed = true
            importMessage = tr("error.import_empty", "Nothing importable was found in that text.")
        }
        #endif
    }

    private func mergeImported(_ rows: [ServerRow], skipped: Int) -> Int {
        guard !rows.isEmpty else {
            importFailed = true
            importMessage = tr("alert.importFailed",
                               "Import failed. The text was not recognized as a server, subscription or config; nothing was added.")
            return 0
        }
        var byID = Dictionary(uniqueKeysWithValues: servers.map { ($0.id, $0) })
        for row in rows { byID[row.id] = row }
        servers = Array(byID.values).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        do { try SoraCoreBridge.shared.saveProfiles(servers) } catch {
            importFailed = true
            importMessage = tr("alert.profileStoreFailed",
                               "Sora could not save to the profile storage. Your existing profiles were not modified.")
            return 0
        }
        if selectedServerID == nil { selectedServerID = rows.first?.id }
        importFailed = false
        var message = String(format: tr("mac.import.added", "Added %d servers"), rows.count)
        if skipped > 0 {
            message += " " + String(format: tr("mac.import.skipped", "%d lines were not recognised"), skipped)
        }
        importMessage = message
        return rows.count
    }

    // MARK: Subscriptions

    public func addSubscription(urlString: String, name: String) async {
        guard let url = URL(string: urlString) else { return }
        do {
            let parsed = try await SoraCoreBridge.shared.fetchSubscription(url: url)
            let subID = UUID().uuidString
            var rows = parsed.rows
            #if canImport(SoraCore)
            for i in rows.indices { rows[i].profile.subscriptionID = subID }
            #endif
            let record = SubscriptionRecord(
                id: subID,
                name: name.isEmpty ? (url.host ?? urlString) : name,
                urlString: urlString, updatedAt: Date(),
                serverIDs: rows.map(\.id))
            subscriptions.append(record)
            SoraCoreBridge.shared.saveSubscriptions(subscriptions)
            mergeImported(rows, skipped: parsed.skipped)
            // Re-tag after merge so refresh can replace exactly these.
            persistSubscriptionTags()
        } catch {
            importFailed = true
            importMessage = tr("alert.importFailed",
                               "Import failed. The text was not recognized as a server, subscription or config; nothing was added.")
        }
    }

    public func refreshSubscription(_ sub: SubscriptionRecord) async {
        guard let url = URL(string: sub.urlString) else { return }
        do {
            let parsed = try await SoraCoreBridge.shared.fetchSubscription(url: url)
            servers.removeAll { sub.serverIDs.contains($0.id) }
            var updated = sub
            updated.updatedAt = Date()
            updated.serverIDs = parsed.rows.map(\.id)
            if let idx = subscriptions.firstIndex(where: { $0.id == sub.id }) {
                subscriptions[idx] = updated
            }
            SoraCoreBridge.shared.saveSubscriptions(subscriptions)
            mergeImported(parsed.rows, skipped: parsed.skipped)
            persistSubscriptionTags()
        } catch {
            importFailed = true
            importMessage = tr("mac.subscription.refreshFailed",
                               "The subscription could not be updated. Your existing servers were kept.")
        }
    }

    public func deleteSubscription(_ sub: SubscriptionRecord) {
        subscriptions.removeAll { $0.id == sub.id }
        servers.removeAll { sub.serverIDs.contains($0.id) }
        SoraCoreBridge.shared.saveSubscriptions(subscriptions)
        try? SoraCoreBridge.shared.saveProfiles(servers)
    }

    private func persistSubscriptionTags() {
        // ServerRow wraps the SoraCore profile; tags live on the
        // profile (`subscriptionID`) and are saved with the profiles.
        try? SoraCoreBridge.shared.saveProfiles(servers)
    }

    public func deleteServer(_ server: ServerRow) {
        servers.removeAll { $0.id == server.id }
        if selectedServerID == server.id { selectedServerID = servers.first?.id }
        try? SoraCoreBridge.shared.saveProfiles(servers)
    }
}

