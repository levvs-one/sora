import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

/// Foundation-only profile store. The directory is injected: production
/// passes the App Group container URL (see `SoraSharedIdentifiers`),
/// tests pass a temporary directory. Fully functional on Linux.
///
/// Writes are atomic: the payload goes to a uniquely named temporary
/// file in the same directory and is then swapped over the target with
/// `replaceItemAt`, so a crash mid-write can never leave a torn
/// profiles.json for the tunnel extension to read.
public final class JSONFileProfileStore: ProfilePersisting {
    private let directory: URL
    private let fileManager: FileManager

    public init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    /// Production convenience: the App Group container, when the process
    /// is entitled to it. Falls back to Application Support in
    /// unentitled contexts (previews, CLI tools).
    public static func sharedContainer() -> JSONFileProfileStore {
        #if canImport(Darwin)
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SoraSharedIdentifiers.appGroup) {
            return JSONFileProfileStore(directory: container)
        }
        #endif
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return JSONFileProfileStore(directory: base.appendingPathComponent("Sora", isDirectory: true))
    }

    private var profilesURL: URL { directory.appendingPathComponent(SoraSharedIdentifiers.profilesFileName) }
    private var settingsURL: URL { directory.appendingPathComponent(SoraSharedIdentifiers.settingsFileName) }

    public func load() throws -> [ServerProfile] {
        guard fileManager.fileExists(atPath: profilesURL.path) else { return [] }
        return try ProfileFileFormat.decodeProfiles(from: Data(contentsOf: profilesURL))
    }

    public func save(_ profiles: [ServerProfile]) throws {
        try writeAtomically(ProfileFileFormat.encodeProfiles(profiles), to: profilesURL)
    }

    public func loadSettings() throws -> AppSettings {
        guard fileManager.fileExists(atPath: settingsURL.path) else { return AppSettings() }
        do {
            return try JSONDecoder().decode(AppSettings.self, from: Data(contentsOf: settingsURL))
        } catch let error as SoraStorageError {
            throw error
        } catch {
            throw SoraStorageError.corruptFile(name: SoraSharedIdentifiers.settingsFileName)
        }
    }

    public func saveSettings(_ settings: AppSettings) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        try writeAtomically(encoder.encode(settings), to: settingsURL)
    }

    private func writeAtomically(_ data: Data, to target: URL) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let tmp = directory.appendingPathComponent(".\(target.lastPathComponent).tmp-\(UUID().uuidString)")
        try data.write(to: tmp, options: [.withoutOverwriting])
        // rename(2) within one directory is atomic on both Linux and
        // Darwin and replaces an existing target — unlike
        // FileManager.replaceItemAt, whose Linux implementation can
        // fail on an existing file. A crash leaves either the old or
        // the new file, never a torn one.
        if rename(tmp.path, target.path) != 0 {
            let code = errno
            try? fileManager.removeItem(at: tmp)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(code))
        }
    }
}
