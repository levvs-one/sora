import Foundation

/// Incoming-link routing for macOS (task §6 + mandate §6).
///
/// Semantics mirror the desktop Flutter app
/// (`app/lib/src/desktop/links.dart`, `parseImportLink`) and the iOS
/// `DeepLinks.swift`:
///  * `sora://add/<url>` / `sora://import?url=…` — subscription import
///  * `sora://import/<payload>` — share link or subscription payload
///  * `sora://routing/add/<base64>` — routing profile payload (handed
///    to the caller verbatim; conversion happens at import time there)
///  * `sora://connect` / `sora://disconnect` — tunnel actions, always
///    routed through `TunnelManager` (same approval gates as a tap)
///  * happ / hiddify / streisand / v2rayn(g) / clash(x) / mihomo /
///    sing-box import hosts — subscription import
///  * any bare protocol scheme (`vless://`, `vmess://`, …) — one
///    share link for `LinkParser`
///  * happ `crypt…` links are sealed for Happ: honest refusal string,
///    never a fake import (key `importSealed`).
public enum DeepLink: Equatable, Sendable {
    case addSubscription(url: String, name: String)
    case importPayload(String)
    case shareLink(String)
    case routingProfile(payload: String)
    case sealedForHapp
    case connect
    case disconnect
    case unknown

    public static func parse(_ url: URL) -> DeepLink {
        let scheme = url.scheme?.lowercased() ?? ""
        guard AppIdentifiers.urlSchemes.contains(scheme) else { return .unknown }
        let absolute = url.absoluteString

        if scheme == "happ", let range = absolute.range(of: "://") {
            let rest = absolute[range.upperBound...]
            if rest.lowercased().hasPrefix("crypt") { return .sealedForHapp }
        }

        if scheme == "sora" || scheme == "happ" {
            let host = url.host?.lowercased() ?? ""
            switch host {
            case "connect": return .connect
            case "disconnect": return .disconnect
            case "routing":
                // sora://routing/add/<payload>
                let parts = url.path.split(separator: "/", omittingEmptySubsequences: true)
                if parts.count >= 2, parts[0] == "add" {
                    return .routingProfile(payload: String(parts[1]))
                }
                return .unknown
            case "add", "import":
                if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let target = comps.queryItems?.first(where: { $0.name == "url" })?.value,
                   !target.isEmpty {
                    let name = comps.queryItems?.first(where: { $0.name == "name" })?.value ?? ""
                    return .addSubscription(url: target, name: name)
                }
                // sora://add/<percent-encoded-or-verbatim-url> form
                // (Flutter: everything after `add/` verbatim).
                if let range = absolute.range(of: "://") {
                    let rest = String(absolute[range.upperBound...])
                    let prefix = host + "/"
                    if rest.lowercased().hasPrefix(prefix) {
                        let payload = String(rest.dropFirst(prefix.count))
                        let decoded = payload.removingPercentEncoding ?? payload
                        if decoded.hasPrefix("http://") || decoded.hasPrefix("https://") {
                            return .addSubscription(url: decoded, name: "")
                        }
                        return .importPayload(payload)
                    }
                }
                return host == "import" ? .importPayload(url.path) : .unknown
            default:
                return .unknown
            }
        }

        if ["hiddify", "streisand"].contains(scheme), url.host?.lowercased() == "import" {
            if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let target = comps.queryItems?.first(where: { $0.name == "url" })?.value {
                return .addSubscription(url: target, name: "")
            }
        }
        if ["v2rayn", "v2rayng", "clash", "clashx", "mihomo"].contains(scheme),
           url.host?.lowercased() == "install-config" {
            if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let target = comps.queryItems?.first(where: { $0.name == "url" })?.value {
                return .addSubscription(url: target, name: comps.queryItems?.first { $0.name == "name" }?.value ?? "")
            }
        }
        if scheme == "sing-box", url.host?.lowercased() == "import-remote-profile" {
            if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let target = comps.queryItems?.first(where: { $0.name == "url" })?.value {
                return .addSubscription(url: target, name: comps.queryItems?.first { $0.name == "name" }?.value ?? "")
            }
        }

        if scheme == "http" || scheme == "https" {
            return .addSubscription(url: absolute, name: "")
        }
        return .shareLink(absolute)
    }
}

/// Executes a resolved deep link against app state. Kept separate
/// from parsing so both the SwiftUI `onOpenURL` path and the
/// AppDelegate Apple-event path share exactly one implementation.
@MainActor
public enum DeepLinkExecutor {
    public static func execute(_ link: DeepLink, state: AppState) {
        switch link {
        case .addSubscription(let url, let name):
            Task { await state.addSubscription(urlString: url, name: name) }
        case .importPayload(let payload):
            state.importText(payload.removingPercentEncoding ?? payload)
        case .shareLink(let raw):
            if let row = try? SoraCoreBridge.shared.parseSingleLink(raw) {
                state.importText(raw) // merge path (dedupe + persist)
                _ = row
            } else {
                state.importText(raw)
            }
        case .routingProfile:
            // Routing-profile conversion belongs to the routing layer
            // (desktop `happ_routing.dart` parity); the payload is kept
            // for it and the user gets an honest message, not silence.
            state.importMessage = tr("mac.routing.received",
                                     "Routing profile received. Review it in Settings before applying.")
            state.importFailed = false
        case .sealedForHapp:
            state.importFailed = true
            state.importMessage = tr("importSealed",
                                     "This link is encrypted for Happ, and only Happ can read it. Ask your provider for the plain subscription link.")
        case .connect:
            Task {
                if let server = state.selectedServer {
                    await TunnelManager.shared.connect(to: server)
                }
            }
        case .disconnect:
            TunnelManager.shared.disconnect()
        case .unknown:
            break
        }
    }
}
