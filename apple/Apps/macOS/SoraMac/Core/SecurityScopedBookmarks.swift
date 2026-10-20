import Foundation

/// Security-scoped bookmarks (task §7).
///
/// Distribution split, honestly:
///  * App Sandbox (Mac App Store build): the app may touch a
///    user-picked file only while a security scope is open. Dropping or
///    picking a subscription/config file therefore creates a
///    bookmark, and every later re-read (subscription refresh of a
///    local file) resolves it and balances start/stop access.
///  * Developer ID build (non-sandboxed): bookmarks still work and are
///    used identically, so behaviour does not fork between channels —
///    one code path, no `#if SANDBOX` behaviour differences except the
///    entitlement file itself.
public enum SecurityScopedBookmarks {
    private static let defaultsKey = "securityScopedBookmarks" // [String: Data]

    public static func store(url: URL, forKey key: String) {
        guard let data = try? url.bookmarkData(options: [.withSecurityScope],
                                               includingResourceValuesForKeys: nil,
                                               relativeTo: nil) else { return }
        var all = loadAll(); all[key] = data; saveAll(all)
    }

    /// Resolves a bookmark and runs `body` inside the access scope.
    /// Returns nil when there is no (longer valid) bookmark.
    public static func withAccess<T>(forKey key: String, _ body: (URL) -> T) -> T? {
        guard let data = loadAll()[key] else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope],
                                 relativeTo: nil, bookmarkDataIsStale: &stale) else { return nil }
        if stale { store(url: url, forKey: key) } // refresh transparently
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        return body(url)
    }

    /// Immediate access for a just-picked/dropped URL (scope is held by
    /// the picker / drop session); also persists a bookmark for later.
    public static func importPickedFile(at url: URL, bookmarkKey: String) -> Data? {
        store(url: url, forKey: bookmarkKey)
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        return try? Data(contentsOf: url)
    }

    private static func loadAll() -> [String: Data] {
        UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Data] ?? [:]
    }
    private static func saveAll(_ all: [String: Data]) {
        UserDefaults.standard.set(all, forKey: defaultsKey)
    }
}
