import Foundation

/// Persistence boundary for profiles and settings. The app layer depends
/// on this protocol; tests and Linux use `JSONFileProfileStore` (or an
/// in-memory fake) — no Apple-only API leaks through here.
public protocol ProfilePersisting {
    func load() throws -> [ServerProfile]
    func save(_ profiles: [ServerProfile]) throws
    func loadSettings() throws -> AppSettings
    func saveSettings(_ settings: AppSettings) throws
}

public enum SoraStorageError: Error, Equatable {
    /// The file exists but is not any known format version. Never
    /// silently drop user profiles: the caller surfaces this.
    case corruptFile(name: String)
    /// A migration step is missing for a stored version. Migrations are
    /// additive only; a downgrade path does not exist by design.
    case unsupportedVersion(found: Int, current: Int)
}

/// Versioned on-disk envelope for the profile list.
///
/// - v1 (legacy): a bare JSON array of profiles, no envelope.
/// - v2 (current): `{"version": 2, "profiles": [...]}`.
///
/// Migrations are additive only: a newer format may add fields (decoded
/// with defaults), never rename or repurpose existing ones. Loading a v1
/// file migrates it in memory; the next save writes v2.
public enum ProfileFileFormat {
    public static let currentVersion = 2

    struct Envelope: Codable {
        var version: Int
        var profiles: [ServerProfile]
    }

    public static func decodeProfiles(from data: Data) throws -> [ServerProfile] {
        let decoder = JSONDecoder()
        // v2 envelope first; a bare array fails keyed decoding and falls
        // through to the v1 path.
        if let envelope = try? decoder.decode(Envelope.self, from: data) {
            guard envelope.version <= currentVersion else {
                throw SoraStorageError.unsupportedVersion(
                    found: envelope.version, current: currentVersion)
            }
            guard envelope.version == currentVersion else {
                // A versioned envelope older than current would need a
                // step migration; none exists yet because v1 predates
                // envelopes. Fail loudly rather than guessing.
                throw SoraStorageError.unsupportedVersion(
                    found: envelope.version, current: currentVersion)
            }
            return envelope.profiles
        }
        if let v1 = try? decoder.decode([ServerProfile].self, from: data) {
            return migrateV1(v1)
        }
        throw SoraStorageError.corruptFile(name: SoraSharedIdentifiers.profilesFileName)
    }

    /// v1 → current: the profile model only gained defaulted fields
    /// since v1, so migration is the decode itself (additive fields take
    /// their defaults). Kept as an explicit step so the next format bump
    /// has a chain to extend, never an in-place edit.
    static func migrateV1(_ profiles: [ServerProfile]) -> [ServerProfile] {
        profiles
    }

    public static func encodeProfiles(_ profiles: [ServerProfile]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try encoder.encode(Envelope(version: currentVersion, profiles: profiles))
    }
}
