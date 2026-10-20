import Foundation

/// Incoming-link routing for the iOS app.
///
/// Registered schemes (Info.plist `CFBundleURLTypes`): `sora` plus every
/// scheme `LinkParser` accepts — registration only decides which links
/// iOS routes to us; `LinkParser` remains the authority on what parses.
/// The list mirrors the macOS sub-department's `AppIdentifiers.urlSchemes`
/// and SoraCore's `LinkParser.supportedSchemes`; keep all three in sync.
public enum SoraURLScheme {
    public static let all: [String] = [
        "sora",
        "vless", "vmess", "trojan", "ss", "ssr",
        "socks", "socks5", "http", "https",
        "hysteria", "hysteria2", "hy2", "tuic",
        "wireguard", "wg", "olcrtc",
        "happ", "hiddify", "streisand", "v2rayn", "v2rayng",
        "clash", "clashx", "mihomo", "sing-box",
    ]
}

/// A resolved incoming link, ready for the UI layer.
public enum DeepLink: Equatable, Sendable {
    /// `sora://import?url=<percent-encoded payload>` — payload is a share
    /// link or a subscription URL; ImportView decides via the parsers.
    case importPayload(String)
    /// A bare share link in any LinkParser scheme, delivered whole.
    case shareLink(String)
    /// `sora://connect` / `sora://disconnect` — used by Shortcuts and by
    /// other apps; requires the same approval state as a manual tap, so
    /// the app routes it through TunnelManager, never around it.
    case connect
    case disconnect
    /// Anything else under `sora://` — ignored by design.
    case unknown

    /// Parse a URL delivered via `onOpenURL` / AppDelegate.
    public static func parse(_ url: URL) -> DeepLink {
        let scheme = url.scheme?.lowercased() ?? ""
        guard SoraURLScheme.all.contains(scheme) else { return .unknown }
        if scheme == "sora" {
            switch url.host?.lowercased() {
            case "import":
                if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let payload = comps.queryItems?.first(where: { $0.name == "url" })?.value,
                   !payload.isEmpty {
                    return .importPayload(payload)
                }
                // `sora://import/<payload>` path form.
                let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                return path.isEmpty ? .unknown : .importPayload(path)
            case "connect": return .connect
            case "disconnect": return .disconnect
            default: return .unknown
            }
        }
        // http/https are subscription URLs when they arrive as links;
        // everything else is a share link for LinkParser.
        if scheme == "http" || scheme == "https" {
            return .importPayload(url.absoluteString)
        }
        return .shareLink(url.absoluteString)
    }
}

/// Clipboard sniffing for ImportView: returns the first plausible payload
/// (share link, subscription URL or `sora://import`) in a text blob, or
/// nil. Pure and Foundation-only so it stays unit-testable on Linux.
public enum ClipboardPayloadFinder {
    public static func find(in text: String) -> String? {
        for token in text.split(whereSeparator: { $0.isWhitespace }) {
            let candidate = String(token)
            guard let schemeEnd = candidate.range(of: "://") else { continue }
            let scheme = candidate[..<schemeEnd.lowerBound].lowercased()
            if SoraURLScheme.all.contains(scheme) { return candidate }
        }
        return nil
    }
}
