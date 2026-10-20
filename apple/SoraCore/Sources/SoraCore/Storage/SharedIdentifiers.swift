import Foundation

/// Single source of truth for the identifiers the app and the tunnel
/// extension must agree on. Both targets import SoraCore and read these
/// constants — neither hardcodes its own copy, so the two processes can
/// never drift into different containers (the silent failure mode where
/// the app writes profiles the provider never sees).
///
/// Canonical values: `apple/docs/ARCHITECTURE.md` §3.4 (identifiers
/// table). Changing any value means changing that document first, this
/// file second — never the other way round.
public enum SoraSharedIdentifiers {
    /// Bundle-id prefix of every Apple target of the product.
    public static let bundlePrefix = "io.github.levvs-one.sora"
    /// App Group container holding profiles.json / settings.json, shared
    /// between the app (writer) and the tunnel extension (reader).
    public static let appGroup = "group.io.github.levvs-one.sora"
    /// Keychain access group for credentials shared with the extension.
    /// §3.4 spells the full value `$(AppIdentifierPrefix)` + this suffix;
    /// the entitlement carries the prefix, the constant carries the
    /// canonical suffix so app and extension agree by construction.
    public static let keychainAccessGroup = "io.github.levvs-one.sora"
    /// File names inside the shared container.
    public static let profilesFileName = "profiles.json"
    public static let settingsFileName = "settings.json"
}
