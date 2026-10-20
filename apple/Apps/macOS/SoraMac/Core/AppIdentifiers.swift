import Foundation

/// Single source of truth for cross-process identifiers in the macOS app.
///
/// Values are FIXED by `apple/docs/ARCHITECTURE.md` §3.4 for the whole
/// Apple port — change the document first, this file second:
///
/// | Identifier            | Value |
/// |-----------------------|-------|
/// | macOS app bundle ID   | `io.github.levvs-one.sora` (same as iOS) |
/// | PacketTunnel (macOS)  | `io.github.levvs-one.sora.PacketTunnel` |
/// | Widget extension      | `io.github.levvs-one.sora.Widgets` |
/// | App Group             | `group.io.github.levvs-one.sora` |
/// | Keychain access group | `$(AppIdentifierPrefix)io.github.levvs-one.sora` |
/// | Config file (App Group) | `current-config.json` |
///
/// KNOWN DIVERGENCE (reported, not silently papered over):
/// `SoraCore/SoraSharedIdentifiers` currently carries a THIRD variant
/// of the group/keychain identifiers (neither the §3.4 canon nor any
/// earlier draft), which contradicts ARCHITECTURE.md §3.4 — a fix has
/// been sent to the SoraCore sub-department as well. This app follows
/// the architecture document;
/// `SoraCoreBridge` therefore does NOT use
/// `JSONFileProfileStore.sharedContainer()` (which would resolve the
/// other group) and always passes an explicit directory inside the
/// §3.4 App Group. SoraCore must be fixed at its single source.
public enum AppIdentifiers {
    public static let appBundleID = "io.github.levvs-one.sora"
    public static let tunnelExtensionBundleID = "io.github.levvs-one.sora.PacketTunnel"
    public static let widgetBundleID = "io.github.levvs-one.sora.Widgets"
    /// Login-item helper: not in §3.4 (macOS-only artefact); follows the
    /// same prefix rule as the other extensions.
    public static let loginItemHelperBundleID = "io.github.levvs-one.sora.LoginItemHelper"

    public static let appGroupID = "group.io.github.levvs-one.sora"
    /// Without the `$(AppIdentifierPrefix)` team prefix (added by the
    /// signing system; see the entitlements drafts).
    public static let keychainAccessGroup = "io.github.levvs-one.sora"

    /// ARCHITECTURE.md §3.4: the app writes the built sing-box config
    /// to this file in the App Group; the provider reads it.
    public static let configFileName = "current-config.json"

    /// App Group `UserDefaults` keys — mirrored verbatim from
    /// `apple/PacketTunnel/TunnelConfigExchange.swift` (`AppGroupKey`),
    /// which is compiled into the extension targets; the app target
    /// does not link that file, so the values are repeated here with
    /// this pointer. Change them there first.
    public enum AppGroupKey {
        public static let tunnelConfig = "sora.tunnel.config.v1"
        public static let tunnelSnapshot = "sora.tunnel.snapshot.v1"
        public static let onDemandEnabled = "sora.tunnel.onDemand.v1"
        public static let activeProfileID = "sora.tunnel.activeProfile.v1"
    }

    /// `CFBundleURLTypes` schemes: `sora` (import host) plus every
    /// scheme `LinkParser` accepts. Identical to the iOS list in
    /// `Apps/iOS/DeepLinks.swift` (`SoraURLScheme.all`) — keep in sync;
    /// `LinkParser` remains the authority on what actually parses.
    /// `openvpn` is deliberately absent: sora has no OpenVPN transport
    /// and the core rejects those links as unsupported.
    public static let urlSchemes: [String] = [
        "sora",
        "vless", "vmess", "trojan", "ss", "ssr",
        "socks", "socks5", "http", "https",
        "hysteria", "hysteria2", "hy2", "tuic",
        "wireguard", "wg", "olcrtc",
        "happ", "hiddify", "streisand", "v2rayn", "v2rayng",
        "clash", "clashx", "mihomo", "sing-box",
    ]

    /// NSUserActivity type for Handoff of the live connection.
    /// Not fixed by ARCHITECTURE.md; follows the §3.4 prefix rule.
    public static let handoffActivityType = "io.github.levvs-one.sora.handoff.connection"
}
