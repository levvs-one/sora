import Foundation

/// Builds a sing-box (libbox) JSON config semantically equivalent to the
/// Go core's sing-box renderer (`core/engine/singbox/render.go`) for the
/// same profile: same per-protocol fields, same TLS shape (REALITY, uTLS,
/// ECH), same fake-IP DNS discipline, same chain wiring — spelled with
/// `detour`, the field sing-box 1.12+ uses where the Go plan's `Via`
/// becomes `dialer_proxy` in its legacy rendering.
///
/// Every emitted key is spelled byte-for-byte as in the Go renderer
/// (`server_port`, `packet_encoding`, `inet4_range`, `ip_is_private`, …);
/// no near-miss variants. Output is deterministic: keys are sorted at
/// every level, so tests and diffs compare stable structures.
public enum LibboxConfigBuilder {

    public static func build(profile: ServerProfile, settings: AppSettings) throws -> String {
        try buildChain(profiles: [profile], settings: settings)
    }

    /// Profiles are in path order: the first is the entry hop (closest to
    /// the client), the last is the exit. The exit carries tag "proxy"
    /// (the route final); every later hop dials through the previous one
    /// via `detour`, exactly like Go chains dial through `Via`.
    public static func buildChain(profiles: [ServerProfile], settings: AppSettings) throws -> String {
        guard !profiles.isEmpty else { throw SoraConfigError.emptyChain }
        var seen = Set<String>()
        for p in profiles {
            guard seen.insert(p.id).inserted else {
                throw SoraConfigError.duplicateChainProfile(id: p.id)
            }
            try ConfigValidation.validate(p)
        }

        var outbounds: [[String: Any]] = []
        var endpoints: [[String: Any]] = []
        var tags: [String] = []
        for (i, p) in profiles.enumerated() {
            let tag = i == profiles.count - 1 ? "proxy" : "proxy-hop-\(i + 1)"
            tags.append(tag)
            let detour = i > 0 ? tags[i - 1] : nil
            if p.protocol == .wireguard || p.protocol == .amneziaWG {
                endpoints.append(wireGuardEndpoint(p, tag: tag, detour: detour))
            } else {
                outbounds.append(proxyOutbound(p, tag: tag, detour: detour))
            }
        }
        outbounds.append(["type": "direct", "tag": "direct"])
        outbounds.append(["type": "block", "tag": "block"])
        outbounds.append(["type": "dns", "tag": "dns-out"])

        var config: [String: Any] = [
            "log": logConfig(settings.logLevel),
            "dns": dnsConfig(settings),
            "inbounds": inbounds(settings),
            "outbounds": outbounds,
            "route": routeConfig(settings),
            "experimental": ["cache_file": ["enabled": true, "path": "cache.db",
                                            "store_fakeip": true]],
        ]
        if !endpoints.isEmpty { config["endpoints"] = endpoints }
        return try serialize(config)
    }

    // MARK: - Sections

    /// Go logConfig: "silent" disables, "warning"/"" become "warn",
    /// timestamps off.
    static func logConfig(_ level: String) -> [String: Any] {
        if level == "silent" { return ["disabled": true] }
        let resolved = (level == "warning" || level.isEmpty) ? "warn" : level
        return ["level": resolved, "timestamp": false]
    }

    static func dnsConfig(_ s: AppSettings) -> [String: Any] {
        var servers: [[String: Any]] = []
        for (i, raw) in s.dnsServers.enumerated() {
            servers.append(dnsServer(raw, tag: "dns-\(i + 1)"))
        }
        if servers.isEmpty {
            servers.append(["type": "local", "tag": "local"])
        }
        let ipv6 = s.capabilities.resolvedIPv6
        // FakeIP, as in the Go renderer: a fakeip server plus a query_type
        // rule; AAAA joins only when IPv6 is on, and the fake-IP filter
        // suffixes (LAN/mDNS, NTP, STUN, connectivity checks — Go
        // DefaultFakeIPFilter, suffix subset) resolve for real.
        var fakeip: [String: Any] = ["type": "fakeip", "tag": "fakeip",
                                     "inet4_range": "198.18.0.0/15"]
        if ipv6 { fakeip["inet6_range"] = "fc00::/18" }
        servers.append(fakeip)
        let realTag = (servers.first?["tag"] as? String) ?? "local"
        var rules: [[String: Any]] = []
        for suffix in ["lan", "local", "home.arpa", "invalid", "localhost",
                       "pool.ntp.org", "msftconnecttest.com", "msftncsi.com",
                       "stun.l.google.com", "time.google.com", "time.cloudflare.com"] {
            rules.append(["domain_suffix": [suffix], "server": realTag])
        }
        rules.append(["query_type": ipv6 ? ["A", "AAAA"] : ["A"], "server": "fakeip"])
        return ["servers": servers, "rules": rules, "final": realTag,
                "strategy": s.dnsStrategy ?? (ipv6 ? "prefer_ipv6" : "ipv4_only")]
    }

    static func dnsServer(_ raw: String, tag: String) -> [String: Any] {
        if raw == "local" || raw == "system" { return ["type": "local", "tag": tag] }
        guard let url = URL(string: raw), let scheme = url.scheme, url.host != nil else {
            // Bare IP / hostname: plain UDP, like Go's default transport.
            var host = raw, port = 0
            if let idx = raw.lastIndex(of: ":"), let p = Int(raw[raw.index(after: idx)...]) {
                host = String(raw[..<idx]); port = p
            }
            var out: [String: Any] = ["type": "udp", "tag": tag, "server": host]
            if port > 0 { out["server_port"] = port }
            return out
        }
        let type: String
        switch scheme {
        case "https", "http": type = "https"
        case "tls": type = "tls"
        case "quic": type = "quic"
        case "h3": type = "h3"
        case "tcp": type = "tcp"
        default: type = "udp"
        }
        var out: [String: Any] = ["type": type, "tag": tag, "server": url.host ?? raw]
        if let port = url.port { out["server_port"] = port }
        if type == "https", url.path != "/", !url.path.isEmpty { out["path"] = url.path }
        return out
    }

    static func inbounds(_ s: AppSettings) -> [[String: Any]] {
        // Local mixed listener (Go LocalProxy on loopback) plus the TUN
        // inbound the NetworkExtension owns.
        let mixed: [String: Any] = ["type": "mixed", "tag": "mixed-in",
                                    "listen": "127.0.0.1", "listen_port": 7890]
        var addresses = ["172.19.0.1/30"]
        if s.capabilities.resolvedIPv6 { addresses.append("fdfe:dcba:9876::1/126") }
        var tun: [String: Any] = [
            "type": "tun", "tag": "tun-in",
            "address": addresses,
            "auto_route": true,
            "strict_route": s.killSwitch,
            "mtu": s.tunMTU > 0 ? s.tunMTU : 1500,
            "stack": s.capabilities.resolvedTUNStack,
        ]
        if !s.splitTunnelIncludedRoutes.isEmpty {
            tun["route_address"] = s.splitTunnelIncludedRoutes
        }
        if !s.splitTunnelExcludedRoutes.isEmpty {
            tun["route_exclude_address"] = s.splitTunnelExcludedRoutes
        }
        return [tun, mixed]
    }

    static func routeConfig(_ s: AppSettings) -> [String: Any] {
        // Sniff + DNS hijack first, like the Go route(): nothing may
        // resolve or route before those two actions see it. The Go
        // renderer spells the DNS rule {"protocol": "dns", …} — a plain
        // string, not an array.
        var rules: [[String: Any]] = [["action": "sniff"],
                                      ["protocol": "dns", "action": "hijack-dns"]]
        if s.bypassLAN {
            rules.append(["ip_is_private": true, "action": "route", "outbound": "direct"])
        }
        for cidr in s.splitTunnelExcludedRoutes {
            rules.append(["ip_cidr": [cidr], "action": "route", "outbound": "direct"])
        }
        if s.killSwitch, s.capabilities.killSwitchBehavior == .blockOnFailure {
            // Explicit blocks instead of relying on strict_route alone,
            // for systems where the app layer does not trust strict_route.
            rules.append(["port": [53], "network": ["udp"], "action": "route", "outbound": "block"])
            rules.append(["ip_cidr": ["0.0.0.0/0", "::/0"], "inbound": ["mixed-in"],
                          "action": "route", "outbound": "proxy"])
        }
        return ["rules": rules, "final": "proxy", "auto_detect_interface": true]
    }

    // MARK: - Outbounds

    static func proxyOutbound(_ p: ServerProfile, tag: String, detour: String?) -> [String: Any] {
        var out: [String: Any] = ["tag": tag, "server": p.address, "server_port": p.port]
        if let detour { out["detour"] = detour }
        var needsTLS = false
        switch p.protocol {
        case .vless:
            out["type"] = "vless"
            out["uuid"] = p.uuid
            out["packet_encoding"] = "xudp"
            if !p.flow.isEmpty { out["flow"] = p.flow }
            if !p.encryption.isEmpty, p.encryption != "none" { out["encryption"] = p.encryption }
        case .vmess:
            out["type"] = "vmess"
            out["uuid"] = p.uuid
            out["security"] = p.vmessSecurity.isEmpty ? "auto" : p.vmessSecurity
        case .trojan:
            out["type"] = "trojan"
            out["password"] = p.password
            needsTLS = true
        case .shadowsocks:
            out["type"] = "shadowsocks"
            out["method"] = p.method
            // Go: the password field carries the key; for 2022 methods
            // the ss2022Key composite replaces it when present.
            out["password"] = p.ss2022Key.isEmpty ? p.password : p.ss2022Key
            if !p.plugin.isEmpty {
                out["plugin"] = p.plugin
                if !p.pluginOptions.isEmpty { out["plugin_opts"] = p.pluginOptions }
            }
        case .hysteria2:
            out["type"] = "hysteria2"
            out["password"] = p.password
            // Bandwidth caps switch the engine from BBR to Brutal; zero
            // means auto (Go render emits the keys only when positive).
            if p.hy2UpMbps > 0 { out["up_mbps"] = p.hy2UpMbps }
            if p.hy2DownMbps > 0 { out["down_mbps"] = p.hy2DownMbps }
            if !p.hy2HopPorts.isEmpty {
                out["server_ports"] = singBoxHopPorts(p.hy2HopPorts)
            }
            if !p.hy2Obfs.isEmpty {
                out["obfs"] = ["type": p.hy2Obfs, "password": p.hy2ObfsPassword]
            }
            needsTLS = true
        case .tuic:
            out["type"] = "tuic"
            out["uuid"] = p.uuid
            out["password"] = p.password
            // The effective values always render, as in Go: the plan
            // value or the shared defaults (bbr / 10s heartbeat).
            out["congestion_control"] = p.tuicCongestionControl.isEmpty ? "bbr" : p.tuicCongestionControl
            if !p.tuicUDPRelayMode.isEmpty { out["udp_relay_mode"] = p.tuicUDPRelayMode }
            out["heartbeat"] = p.tuicHeartbeat > 0 ? "\(p.tuicHeartbeat)s" : "10s"
            needsTLS = true
        case .wireguard, .amneziaWG:
            preconditionFailure("wireguard renders as an endpoint")
        }
        if p.tls.enabled || p.tls.reality != nil || needsTLS {
            out["tls"] = tlsConfig(p)
        }
        if let transport = transportConfig(p) { out["transport"] = transport }
        // Multiplex: validation already refused mux+vision. Go emits it
        // under RealityMux (REALITY default); here the profile's explicit
        // muxEnabled is the opt-in, spelled identically.
        if p.muxEnabled {
            out["multiplex"] = ["enabled": true, "protocol": "smux", "max_streams": 8]
        }
        return out
    }

    /// Go tls(): REALITY forces a uTLS fingerprint (default "chrome"),
    /// ECH carries its pinned config, spiderX is Xray-only and
    /// deliberately not emitted (the Go sing-box renderer has no field
    /// for it either).
    static func tlsConfig(_ p: ServerProfile) -> [String: Any] {
        let tls = p.tls
        var t: [String: Any] = ["enabled": true]
        t["server_name"] = tls.serverName.isEmpty ? p.address : tls.serverName
        if tls.allowInsecure { t["insecure"] = true }
        if !tls.alpn.isEmpty { t["alpn"] = tls.alpn }
        var fingerprint = tls.fingerprint
        if let reality = tls.reality {
            fingerprint = fingerprint.isEmpty ? "chrome" : fingerprint
            var r: [String: Any] = ["enabled": true, "public_key": reality.publicKey]
            if !reality.shortId.isEmpty { r["short_id"] = reality.shortId }
            t["reality"] = r
        }
        if !fingerprint.isEmpty {
            t["utls"] = ["enabled": true, "fingerprint": fingerprint]
        }
        if let ech = tls.ech, !ech.isEmpty {
            // The profile keeps the link's ECH value verbatim; it is a
            // pinned ECHConfigList, rendered as the sing-box `config`.
            t["ech"] = ["enabled": true, "config": [ech]] as [String: Any]
        }
        return t
    }

    static func transportConfig(_ p: ServerProfile) -> [String: Any]? {
        let t = p.transport
        switch t.type.isEmpty ? "tcp" : t.type {
        case "tcp":
            return nil
        case "ws":
            var out: [String: Any] = ["type": "ws"]
            if !t.path.isEmpty { out["path"] = t.path }
            var headers = t.headers
            if !t.host.isEmpty { headers["Host"] = t.host }
            if !headers.isEmpty { out["headers"] = headers }
            return out
        case "grpc":
            var out: [String: Any] = ["type": "grpc"]
            if !t.serviceName.isEmpty { out["service_name"] = t.serviceName }
            return out
        case "h2", "http":
            var out: [String: Any] = ["type": "http"]
            if !t.path.isEmpty { out["path"] = t.path }
            if !t.host.isEmpty { out["host"] = [t.host] }
            return out
        case "httpupgrade":
            var out: [String: Any] = ["type": "httpupgrade"]
            if !t.host.isEmpty { out["host"] = t.host }
            if !t.path.isEmpty { out["path"] = t.path }
            if !t.headers.isEmpty { out["headers"] = t.headers }
            return out
        case "xhttp":
            var out: [String: Any] = ["type": "xhttp",
                                      "mode": t.mode.isEmpty ? "auto" : t.mode]
            if !t.host.isEmpty { out["host"] = t.host }
            if !t.path.isEmpty { out["path"] = t.path }
            if !t.headers.isEmpty { out["headers"] = t.headers }
            // NOTE — divergence from the Go core, by engine capability:
            // sing-box has no XHTTP downloadSettings spelling (Go
            // catalog: the feature is missing on sing-box), so the
            // validated split downlink cannot be rendered here; it is
            // documented instead of being dropped silently in the JSON.
            return out
        default:
            return nil // unreachable: validation refuses unknown transports
        }
    }

    /// WireGuard renders as an endpoint since sing-box 1.13 (Go
    /// wireguard()). AmneziaWG adds the obfuscation parameters and drops
    /// the MTU to 1280, and the 3.1 mechanisms follow the Go spellings.
    /// AmneziaWG 3.1 range: a plain integer stays a JSON number, a
    /// range passes through as a string (Go awgRange).
    private static func setRange(_ out: inout [String: Any], _ key: String, _ value: String) {
        if value.isEmpty { return }
        if let n = Int(value) { out[key] = n } else { out[key] = value }
    }

    static func wireGuardEndpoint(_ p: ServerProfile, tag: String, detour: String?) -> [String: Any] {
        var out: [String: Any] = ["type": "wireguard", "tag": tag,
                                  "address": p.wgLocalAddresses,
                                  "private_key": p.wgPrivateKey,
                                  "mtu": 1420]
        if let detour { out["detour"] = detour }
        if p.protocol == .amneziaWG, let a = p.awg, !a.isEmpty {
            out["mtu"] = 1280
            setInt(&out, "jc", a.jc); setInt(&out, "jmin", a.jmin); setInt(&out, "jmax", a.jmax)
            setInt(&out, "s1", a.s1); setInt(&out, "s2", a.s2)
            setInt(&out, "s3", a.s3); setInt(&out, "s4", a.s4)
            setStr(&out, "h1", a.h1); setStr(&out, "h2", a.h2)
            setStr(&out, "h3", a.h3); setStr(&out, "h4", a.h4)
            setStr(&out, "i1", a.i1); setStr(&out, "i2", a.i2); setStr(&out, "i3", a.i3)
            setStr(&out, "i4", a.i4); setStr(&out, "i5", a.i5)
            // AmneziaWG 3.1 (Go render): header protection, ranged
            // timings, masquerade sugar (id/ip/ib spellings are Go's).
            setStr(&out, "header_protection_key", a.headerProtectionKey)
            setRange(&out, "content_padding_addition", a.contentPaddingAddition)
            if a.randomTrailers { out["random_trailers"] = true }
            if a.disableCookies { out["disable_cookies"] = true }
            setRange(&out, "rekey_after_time", a.rekeyAfterTime)
            setRange(&out, "rekey_timeout", a.rekeyTimeout)
            setRange(&out, "reject_after_time", a.rejectAfterTime)
            setRange(&out, "keepalive_timeout", a.keepaliveTimeout)
            setRange(&out, "max_handshake_attempts", a.maxHandshakeAttempts)
            setStr(&out, "id", a.masqueradeDomain)
            setStr(&out, "ip", a.masqueradeProtocol)
            setStr(&out, "ib", a.masqueradeBrowser)
        }
        // Peer endpoint: the explicit wgPeerEndpoint ("host:port") when
        // the profile carries one, else the profile's own address:port.
        var peerHost = p.address, peerPort = p.port
        if let endpoint = p.wgPeerEndpoint, !endpoint.isEmpty {
            let parts = endpoint.split(separator: ":", maxSplits: 1)
            if let host = parts.first { peerHost = String(host) }
            if parts.count > 1, let port = Int(parts[1]) { peerPort = port }
        }
        var peer: [String: Any] = [
            "address": peerHost,
            "port": peerPort,
            "public_key": p.wgPeerPublicKey,
            "allowed_ips": p.wgAllowedIPs.isEmpty ? ["0.0.0.0/0", "::/0"] : p.wgAllowedIPs,
        ]
        if !p.wgPreSharedKey.isEmpty { peer["pre_shared_key"] = p.wgPreSharedKey }
        if p.wgPersistentKeepalive > 0 {
            peer["persistent_keepalive_interval"] = p.wgPersistentKeepalive
        }
        out["peers"] = [peer]
        return out
    }

    // MARK: - Helpers

    /// Share-link hop spec "20000-30000,40000" → sing-box colon ranges
    /// with explicit upper bounds (Go SingBoxHopPorts; the verbatim
    /// spelling is rejected by sing-box at load). Malformed tokens are
    /// dropped here only because validation upstream owns the refusal
    /// vocabulary for profile fields; the translation itself never
    /// invents ports.
    static func singBoxHopPorts(_ spec: String) -> [String] {
        var out: [String] = []
        for part in spec.split(separator: ",") {
            let token = part.trimmingCharacters(in: .whitespaces)
            if token.contains("-") {
                let bounds = token.split(separator: "-")
                if bounds.count == 2, let lo = Int(bounds[0]), let hi = Int(bounds[1]) {
                    out.append("\(lo):\(hi)")
                }
            } else if let single = Int(token) {
                out.append("\(single):\(single)")
            }
        }
        return out
    }

    private static func setInt(_ out: inout [String: Any], _ key: String, _ value: Int) {
        if value != 0 { out[key] = value }
    }
    private static func setStr(_ out: inout [String: Any], _ key: String, _ value: String) {
        if !value.isEmpty { out[key] = value }
    }

    static func serialize(_ config: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: config,
                                              options: [.sortedKeys, .prettyPrinted])
        return String(decoding: data, as: UTF8.self)
    }
}
