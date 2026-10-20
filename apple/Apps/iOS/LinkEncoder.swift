import Foundation
import SoraCore

/// Reverse of `LinkParser`: builds a share link from a `ServerProfile`.
///
/// SoraCore (per the shared contract) ships parsing only, so the encoder
/// lives in the app layer and mirrors the parser field-for-field: every
/// parameter emitted here must be one `LinkParser` reads back, in the
/// spelling the Go core's parser uses (the Swift parser mirrors it).
/// Protocols whose canonical share format is a full config document
/// (WireGuard, AmneziaWG) encode as the `wg://` URL form the parser
/// accepts; profiles that cannot round-trip return nil and the UI hides
/// the share action instead of emitting a lossy link.
public enum LinkEncoder {
    public static func encode(_ profile: ServerProfile) -> String? {
        switch profile.protocol {
        case .vless: return encodeVLESS(profile)
        case .trojan: return encodeTrojan(profile)
        case .vmess: return encodeVMess(profile)
        case .shadowsocks: return encodeShadowsocks(profile)
        case .hysteria2: return encodeHysteria2(profile)
        case .tuic: return encodeTUIC(profile)
        case .wireguard, .amneziaWG: return encodeWireGuard(profile)
        }
    }

    // MARK: Shared query building (transport + TLS), parser spellings.

    private static func queryItems(for p: ServerProfile) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        let t = p.transport
        if t.type != "tcp" || !t.path.isEmpty || !t.host.isEmpty || !t.serviceName.isEmpty {
            items.append(URLQueryItem(name: "type", value: t.type))
        }
        if !t.path.isEmpty { items.append(URLQueryItem(name: "path", value: t.path)) }
        if !t.host.isEmpty { items.append(URLQueryItem(name: "host", value: t.host)) }
        if !t.serviceName.isEmpty {
            items.append(URLQueryItem(name: "serviceName", value: t.serviceName))
        }
        if !t.mode.isEmpty { items.append(URLQueryItem(name: "mode", value: t.mode)) }
        if !t.extra.isEmpty { items.append(URLQueryItem(name: "extra", value: t.extra)) }

        let tls = p.tls
        if let reality = tls.reality {
            items.append(URLQueryItem(name: "security", value: "reality"))
            if !tls.serverName.isEmpty { items.append(URLQueryItem(name: "sni", value: tls.serverName)) }
            if !tls.fingerprint.isEmpty { items.append(URLQueryItem(name: "fp", value: tls.fingerprint)) }
            if !reality.publicKey.isEmpty { items.append(URLQueryItem(name: "pbk", value: reality.publicKey)) }
            if !reality.shortId.isEmpty { items.append(URLQueryItem(name: "sid", value: reality.shortId)) }
            if !reality.spiderX.isEmpty { items.append(URLQueryItem(name: "spx", value: reality.spiderX)) }
            if !tls.mldsa65Verify.isEmpty { items.append(URLQueryItem(name: "pqv", value: tls.mldsa65Verify)) }
        } else if tls.enabled {
            items.append(URLQueryItem(name: "security", value: "tls"))
            if !tls.serverName.isEmpty { items.append(URLQueryItem(name: "sni", value: tls.serverName)) }
            if !tls.fingerprint.isEmpty { items.append(URLQueryItem(name: "fp", value: tls.fingerprint)) }
            if !tls.alpn.isEmpty { items.append(URLQueryItem(name: "alpn", value: tls.alpn.joined(separator: ","))) }
            if tls.allowInsecure { items.append(URLQueryItem(name: "allowInsecure", value: "1")) }
        }
        if !p.flow.isEmpty { items.append(URLQueryItem(name: "flow", value: p.flow)) }
        return items
    }

    private static func url(scheme: String, userinfo: String, host: String,
                            port: Int, query: [URLQueryItem], fragment: String) -> String? {
        var c = URLComponents()
        c.scheme = scheme
        c.percentEncodedUser = userinfo
        c.host = host
        c.port = port
        if !query.isEmpty { c.queryItems = query }
        if !fragment.isEmpty { c.percentEncodedFragment = fragment.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) }
        return c.string
    }

    private static func nameFragment(_ p: ServerProfile) -> String {
        p.name.isEmpty ? "\(p.address):\(p.port)" : p.name
    }

    // MARK: Per-protocol encoders

    private static func encodeVLESS(_ p: ServerProfile) -> String? {
        guard !p.uuid.isEmpty else { return nil }
        var q = queryItems(for: p)
        q.append(URLQueryItem(name: "encryption", value: "none"))
        return url(scheme: "vless", userinfo: p.uuid, host: p.address,
                   port: p.port, query: q, fragment: nameFragment(p))
    }

    private static func encodeTrojan(_ p: ServerProfile) -> String? {
        guard !p.password.isEmpty else { return nil }
        return url(scheme: "trojan", userinfo: pct(p.password), host: p.address,
                   port: p.port, query: queryItems(for: p), fragment: nameFragment(p))
    }

    private static func encodeVMess(_ p: ServerProfile) -> String? {
        guard !p.uuid.isEmpty else { return nil }
        // Canonical VMess share form: base64 of a JSON object (v2rayN).
        var obj: [String: Any] = [
            "v": "2", "ps": nameFragment(p), "add": p.address,
            "port": String(p.port), "id": p.uuid,
            "aid": "0", "scy": p.vmessSecurity.isEmpty ? "auto" : p.vmessSecurity,
            "net": p.transport.type, "type": "none",
            "host": p.transport.host, "path": p.transport.path,
            "tls": p.tls.enabled ? "tls" : "", "sni": p.tls.serverName,
            "alpn": p.tls.alpn.joined(separator: ","),
            "fp": p.tls.fingerprint,
        ]
        if p.transport.type == "grpc" { obj["path"] = p.transport.serviceName }
        guard let data = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys])
        else { return nil }
        return "vmess://" + data.base64EncodedString()
    }

    private static func encodeShadowsocks(_ p: ServerProfile) -> String? {
        guard !p.method.isEmpty else { return nil }
        let secret = p.ss2022Key.isEmpty ? p.password : p.ss2022Key
        let userinfo = "\(p.method):\(secret)"
        guard let data = userinfo.data(using: .utf8) else { return nil }
        let b64 = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        var query: [URLQueryItem] = []
        if !p.plugin.isEmpty {
            let pluginValue = p.pluginOptions.isEmpty ? p.plugin : "\(p.plugin);\(p.pluginOptions)"
            query.append(URLQueryItem(name: "plugin", value: pluginValue))
        }
        return url(scheme: "ss", userinfo: b64, host: p.address,
                   port: p.port, query: query, fragment: nameFragment(p))
    }

    private static func encodeHysteria2(_ p: ServerProfile) -> String? {
        guard !p.password.isEmpty else { return nil }
        var q: [URLQueryItem] = []
        if !p.tls.serverName.isEmpty { q.append(URLQueryItem(name: "sni", value: p.tls.serverName)) }
        if p.tls.allowInsecure { q.append(URLQueryItem(name: "insecure", value: "1")) }
        if !p.hy2Obfs.isEmpty {
            q.append(URLQueryItem(name: "obfs", value: p.hy2Obfs))
            if !p.hy2ObfsPassword.isEmpty {
                q.append(URLQueryItem(name: "obfs-password", value: p.hy2ObfsPassword))
            }
        }
        if !p.hy2HopPorts.isEmpty { q.append(URLQueryItem(name: "mport", value: p.hy2HopPorts)) }
        return url(scheme: "hysteria2", userinfo: pct(p.password), host: p.address,
                   port: p.port, query: q, fragment: nameFragment(p))
    }

    private static func encodeTUIC(_ p: ServerProfile) -> String? {
        let userinfo: String
        if !p.tuicToken.isEmpty {
            userinfo = pct(p.tuicToken)
        } else {
            guard !p.uuid.isEmpty else { return nil }
            userinfo = "\(p.uuid):\(pct(p.password))"
        }
        var q: [URLQueryItem] = []
        if !p.tuicCongestionControl.isEmpty {
            q.append(URLQueryItem(name: "congestion_control", value: p.tuicCongestionControl))
        }
        if !p.tuicUDPRelayMode.isEmpty {
            q.append(URLQueryItem(name: "udp_relay_mode", value: p.tuicUDPRelayMode))
        }
        if !p.tls.serverName.isEmpty { q.append(URLQueryItem(name: "sni", value: p.tls.serverName)) }
        if p.tls.allowInsecure { q.append(URLQueryItem(name: "allow_insecure", value: "1")) }
        return url(scheme: "tuic", userinfo: userinfo, host: p.address,
                   port: p.port, query: q, fragment: nameFragment(p))
    }

    private static func encodeWireGuard(_ p: ServerProfile) -> String? {
        guard !p.wgPrivateKey.isEmpty, !p.wgPeerPublicKey.isEmpty else { return nil }
        var q: [URLQueryItem] = [URLQueryItem(name: "publickey", value: p.wgPeerPublicKey)]
        if !p.wgPreSharedKey.isEmpty { q.append(URLQueryItem(name: "presharedkey", value: p.wgPreSharedKey)) }
        if !p.wgLocalAddresses.isEmpty {
            q.append(URLQueryItem(name: "address", value: p.wgLocalAddresses.joined(separator: ",")))
        }
        if !p.wgReserved.isEmpty {
            q.append(URLQueryItem(name: "reserved", value: p.wgReserved.map(String.init).joined(separator: ",")))
        }
        if p.wgPersistentKeepalive > 0 {
            q.append(URLQueryItem(name: "keepalive", value: String(p.wgPersistentKeepalive)))
        }
        return url(scheme: "wg", userinfo: pct(p.wgPrivateKey), host: p.address,
                   port: p.port, query: q, fragment: nameFragment(p))
    }

    /// Percent-encode a userinfo secret (passwords, keys, tokens).
    private static func pct(_ s: String) -> String {
        var allowed = CharacterSet.urlUserAllowed
        allowed.remove(charactersIn: ":@/?#[]")
        return s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s
    }
}
