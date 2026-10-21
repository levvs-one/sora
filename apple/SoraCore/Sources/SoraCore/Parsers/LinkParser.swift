import Foundation

/// Parses single share links into server profiles. The semantics mirror
/// Go's core/parser.parseLink field-by-field: the same acceptances, the
/// same refusals, the same defaults. Link splitting and percent-decoding
/// are hand-rolled (not URLComponents) so acceptance never depends on a
/// platform URL parser's version-specific quirks — a link either parses by
/// the data it carries or it does not.
public enum LinkParser {
    public static func parse(_ link: String) throws -> ServerProfile {
        let raw = link.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty { throw SoraParseError.emptyInput }
        guard let sep = raw.range(of: "://") else { throw SoraParseError.invalidLink }
        let scheme = raw[..<sep.lowerBound].lowercased()
        switch scheme {
        case "vmess":
            return try parseVMess(raw: raw)
        case "wireguard", "wg":
            return try parseWireGuard(raw: raw, scheme: scheme)
        case "vless", "trojan", "ss", "hysteria2", "hy2", "tuic":
            return try parseStandard(raw: raw, scheme: scheme)
        default:
            throw SoraParseError.unsupportedScheme(scheme)
        }
    }

    // MARK: - URL splitting (Go url.Parse equivalent for share links)

    struct Parts {
        var scheme: String
        var user: String = ""
        var password: String = ""
        var hasUserinfo: Bool = false
        var host: String = ""
        var portString: String? = nil
        var query: [(String, String)] = []
        var fragment: String = ""

        func q(_ keys: String...) -> String {
            for k in keys {
                if let v = query.first(where: { $0.0 == k })?.1, !v.isEmpty { return v }
            }
            return ""
        }
    }

    static func split(_ raw: String, scheme: String) -> Parts {
        var rest = String(raw[raw.range(of: "://")!.upperBound...])
        var p = Parts(scheme: scheme)
        if let h = rest.firstIndex(of: "#") {
            p.fragment = PercentCoding.decode(String(rest[rest.index(after: h)...]), plusAsSpace: true)
            rest = String(rest[..<h])
        }
        var queryString: String? = nil
        if let qm = rest.firstIndex(of: "?") {
            queryString = String(rest[rest.index(after: qm)...])
            rest = String(rest[..<qm])
        }
        // Authority ends at the first '/'; any path is ignored (Go reads the
        // transport path from the query, not the URL path).
        var authority = rest
        if let sl = rest.firstIndex(of: "/") {
            authority = String(rest[..<sl])
        }
        if let at = authority.lastIndex(of: "@") {
            p.hasUserinfo = true
            let userinfo = String(authority[..<at])
            authority = String(authority[authority.index(after: at)...])
            if let colon = userinfo.firstIndex(of: ":") {
                p.user = PercentCoding.decode(String(userinfo[..<colon]), plusAsSpace: false)
                p.password = PercentCoding.decode(String(userinfo[userinfo.index(after: colon)...]), plusAsSpace: false)
            } else {
                p.user = PercentCoding.decode(userinfo, plusAsSpace: false)
            }
        }
        if authority.hasPrefix("[") {
            if let close = authority.firstIndex(of: "]") {
                p.host = String(authority[authority.index(after: authority.startIndex)..<close])
                let tail = authority[authority.index(after: close)...]
                if tail.hasPrefix(":") { p.portString = String(tail.dropFirst()) }
            } else {
                p.host = authority
            }
        } else if let colon = authority.lastIndex(of: ":") {
            p.host = String(authority[..<colon])
            p.portString = String(authority[authority.index(after: colon)...])
        } else {
            p.host = authority
        }
        if let qs = queryString {
            for pair in qs.split(separator: "&", omittingEmptySubsequences: false) {
                if let eq = pair.firstIndex(of: "=") {
                    let k = PercentCoding.decode(String(pair[..<eq]), plusAsSpace: true)
                    let v = PercentCoding.decode(String(pair[pair.index(after: eq)...]), plusAsSpace: true)
                    p.query.append((k, v))
                } else {
                    p.query.append((PercentCoding.decode(String(pair), plusAsSpace: true), ""))
                }
            }
        }
        return p
    }

    static func port(_ s: String?) throws -> Int {
        guard let s = s, !s.isEmpty, s.allSatisfy({ $0.isASCII && $0.isNumber }),
              let n = Int(s), n >= 1, n <= 65535 else {
            throw SoraParseError.invalidPort
        }
        return n
    }

    static func parseBool(_ s: String) -> Bool {
        // Go strconv.ParseBool spellings.
        ["1", "t", "T", "true", "TRUE", "True"].contains(s)
    }

    // MARK: - Standard schemes

    private static func parseStandard(raw: String, scheme: String) throws -> ServerProfile {
        let p = split(raw, scheme: scheme)
        // Fail closed on Hysteria2 certificate pinning, exactly as Go:
        // pinSHA256 reaches no engine, so importing would silently unpin.
        if (scheme == "hysteria2" || scheme == "hy2"),
           !p.q("pinSHA256", "pin_sha256").isEmpty {
            throw SoraParseError.unsupportedOption("hy2 pinSHA256 certificate pinning is not implemented")
        }
        let port = try port(p.portString)
        if p.host.isEmpty { throw SoraParseError.invalidLink }

        var profile: ServerProfile
        switch scheme {
        case "ss":
            profile = try parseShadowsocks(p: p, port: port)
        case "tuic":
            var t = ServerProfile(name: p.fragment, protocol: .tuic, address: p.host, port: port,
                                  uuid: p.user, password: p.password,
                                  transport: TransportSpec(type: "tcp"),
                                  tls: TLSSpec(enabled: true))
            t.tuicCongestionControl = p.q("congestion_control")
            t.tuicUDPRelayMode = p.q("udp_relay_mode")
            t.tuicToken = p.q("token")
            t.tuicHeartbeat = Int(p.q("heartbeat")) ?? 0
            profile = t
        case "trojan", "hysteria2", "hy2":
            let proto: ProxyProtocol = scheme == "trojan" ? .trojan : .hysteria2
            var t = ServerProfile(name: p.fragment, protocol: proto, address: p.host, port: port,
                                  password: p.password.isEmpty ? p.user : p.password,
                                  transport: TransportSpec(type: p.q("type", "transport").isEmpty ? "tcp" : p.q("type", "transport")),
                                  tls: TLSSpec(enabled: true))
            if proto == .hysteria2 {
                t.hy2Obfs = p.q("obfs")
                t.hy2ObfsPassword = p.q("obfs-password", "obfs_password")
                t.hy2UpMbps = Int(p.q("upmbps")) ?? 0
                t.hy2DownMbps = Int(p.q("downmbps")) ?? 0
                t.hy2HopPorts = p.q("mport", "ports")
            }
            profile = t
        default: // vless
            var t = ServerProfile(name: p.fragment, protocol: .vless, address: p.host, port: port,
                                  uuid: p.user, transport: TransportSpec(type: "tcp"),
                                  tls: TLSSpec())
            t.flow = p.q("flow")
            t.encryption = p.q("encryption")
            profile = t
        }

        // Shared transport/TLS fields (Go reads them for every scheme).
        var transport = profile.transport
        if scheme == "vless" || scheme == "tuic" {
            let ty = p.q("type", "transport")
            if !ty.isEmpty { transport.type = ty }
        }
        transport.path = p.q("path")
        transport.host = p.q("host")
        transport.serviceName = p.q("serviceName", "service_name")
        transport.mode = p.q("mode")
        transport.extra = p.q("extra")
        applyExtraDownloadSettings(extra: transport.extra, transport: &transport)
        profile.transport = transport

        var tls = profile.tls
        let security = p.q("security")
        switch scheme {
        case "trojan", "hysteria2", "hy2", "tuic":
            tls.enabled = true
        default:
            tls.enabled = security == "tls" || security == "reality"
        }
        if security == "reality" || !p.q("pbk", "public-key").isEmpty {
            tls.enabled = true
            tls.reality = RealitySpec(publicKey: p.q("pbk", "public-key"),
                                      shortId: p.q("sid", "short-id"),
                                      spiderX: p.q("spx"))
        }
        tls.mldsa65Verify = p.q("pqv", "mldsa65-verify")
        tls.serverName = p.q("sni")
        tls.fingerprint = p.q("fp")
        tls.allowInsecure = parseBool(p.q("allowInsecure", "insecure", "skip-cert-verify"))
        let alpn = p.q("alpn")
        if !alpn.isEmpty { tls.alpn = alpn.split(separator: ",").map(String.init) }
        let ech = p.q("ech")
        if !ech.isEmpty { tls.ech = ech }
        profile.tls = tls

        try validate(profile)
        profile.refreshID()
        return profile
    }

    private static func parseShadowsocks(p: Parts, port: Int) throws -> ServerProfile {
        var method = p.user
        var password = p.password
        // SIP002: the userinfo may be base64(method:password) — Go decodes
        // it and splits on the first ':' when that succeeds.
        if let decoded = Base64.decodeUTF8(p.user),
           let colon = decoded.firstIndex(of: ":") {
            method = String(decoded[..<colon])
            password = String(decoded[decoded.index(after: colon)...])
        }
        if password.isEmpty { password = p.q("password") }
        var profile = ServerProfile(name: p.fragment, protocol: .shadowsocks,
                                    address: p.host, port: port, password: password,
                                    method: method, transport: TransportSpec(type: "tcp"),
                                    tls: TLSSpec())
        if method.hasPrefix("2022-") {
            profile.ss2022Key = password
        }
        // SIP002 plugin: combined "plugin=name;opts" or split plugin_opts.
        var pluginName = ""
        var pluginOpts = p.q("plugin_opts", "plugin-opts")
        let plug = p.q("plugin")
        if !plug.isEmpty {
            if let semi = plug.firstIndex(of: ";") {
                pluginName = String(plug[..<semi]).trimmingCharacters(in: .whitespaces)
                if pluginOpts.isEmpty {
                    pluginOpts = String(plug[plug.index(after: semi)...])
                }
            } else {
                pluginName = plug.trimmingCharacters(in: .whitespaces)
            }
        }
        profile.plugin = pluginName
        profile.pluginOptions = pluginOpts
        return profile
    }

    // MARK: - VMess (classic base64 JSON + AEAD URL style)

    private static func parseVMess(raw: String) throws -> ServerProfile {
        // Classic form: vmess://<base64 JSON>. The blob is recovered from
        // the raw text, as in Go's vmessBlob (url.URL fields never hold it).
        var rest = String(raw[raw.range(of: "://")!.upperBound...])
        var frag = ""
        if let h = rest.firstIndex(of: "#") {
            frag = PercentCoding.decode(String(rest[rest.index(after: h)...]), plusAsSpace: true)
            rest = String(rest[..<h])
        }
        if let qm = rest.firstIndex(of: "?") {
            rest = String(rest[..<qm])
        }
        let blob = rest.trimmingCharacters(in: .whitespaces)
        if !blob.isEmpty, let decoded = Base64.decode(blob),
           let obj = try? JSONSerialization.jsonObject(with: decoded),
           let m = obj as? [String: Any] {
            if m["add"] != nil || m["id"] != nil {
                return try mapVMessClassic(m, frag: frag)
            }
            return try mapJSONSpec(m, fallback: .vmess)
        }
        // URL style (AEAD): vmess://uuid@host:port?…
        let p = split(raw, scheme: "vmess")
        if p.host.isEmpty { throw SoraParseError.invalidLink }
        let port = try port(p.portString)
        var profile = ServerProfile(name: p.fragment, protocol: .vmess, address: p.host, port: port,
                                    uuid: p.user, password: p.password,
                                    vmessSecurity: "auto",
                                    transport: TransportSpec(type: p.q("type", "transport").isEmpty ? "tcp" : p.q("type", "transport")),
                                    tls: TLSSpec())
        let security = p.q("security")
        profile.tls.enabled = security == "tls" || security == "reality"
        profile.transport.path = p.q("path")
        profile.transport.host = p.q("host")
        profile.tls.serverName = p.q("sni")
        try validate(profile)
        profile.refreshID()
        return profile
    }

    static func mapVMessClassic(_ m: [String: Any], frag: String) throws -> ServerProfile {
        var host = jsonString(m["add"])
        if host.isEmpty { host = jsonString(m["address"]) }
        let portNum = jsonPort(m["port"])
        var profile = ServerProfile(name: jsonString(m["ps"]).isEmpty ? frag : jsonString(m["ps"]),
                                    protocol: .vmess, address: host, port: portNum,
                                    uuid: jsonString(m["id"]),
                                    vmessSecurity: jsonString(m["scy"]).isEmpty ? "auto" : jsonString(m["scy"]),
                                    transport: TransportSpec(type: "tcp"),
                                    tls: TLSSpec())
        if !jsonString(m["net"]).isEmpty { profile.transport.type = jsonString(m["net"]) }
        profile.transport.host = jsonString(m["host"])
        profile.transport.path = jsonString(m["path"])
        switch jsonString(m["tls"]) {
        case "tls": profile.tls.enabled = true
        case "reality":
            profile.tls.enabled = true
            profile.tls.reality = RealitySpec()
        default: break
        }
        profile.tls.serverName = jsonString(m["sni"])
        profile.tls.fingerprint = jsonString(m["fp"])
        let alpn = jsonString(m["alpn"])
        if !alpn.isEmpty { profile.tls.alpn = alpn.split(separator: ",").map(String.init) }
        profile.tls.allowInsecure = jsonBool(m["insecure"]) || jsonBool(m["allowInsecure"])
        try validate(profile)
        profile.refreshID()
        return profile
    }

    // MARK: - WireGuard links

    private static func parseWireGuard(raw: String, scheme: String) throws -> ServerProfile {
        let p = split(raw, scheme: scheme)
        let port = try port(p.portString)
        if p.host.isEmpty { throw SoraParseError.invalidLink }
        var profile = ServerProfile(name: p.fragment, protocol: .wireguard, address: p.host, port: port,
                                    transport: TransportSpec(type: "udp"), tls: TLSSpec())
        // Go: the private key rides in the userinfo (or ?privatekey=).
        profile.wgPrivateKey = p.q("privatekey").isEmpty ? p.user : p.q("privatekey")
        if !p.password.isEmpty {
            // userinfo "key:..." forms keep the whole userinfo as the key in Go.
            profile.wgPrivateKey = p.hasUserinfo && !p.password.isEmpty ? (p.user + ":" + p.password) : profile.wgPrivateKey
        }
        profile.wgPeerPublicKey = p.q("publickey")
        profile.wgPreSharedKey = p.q("presharedkey")
        let address = p.q("address")
        if !address.isEmpty {
            profile.wgLocalAddresses = address.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
        }
        let reserved = p.q("reserved")
        if !reserved.isEmpty {
            profile.wgReserved = reserved.split(separator: ",").compactMap {
                UInt8($0.trimmingCharacters(in: .whitespaces))
            }
        }
        let allowed = p.q("allowedips")
        if !allowed.isEmpty {
            profile.wgAllowedIPs = allowed.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
        }
        profile.awg = awgFromQuery { p.q($0) }
        if let awg = profile.awg, !awg.isEmpty {
            // Keep protocol wireguard: Go identifies AWG configs as
            // wireguard with amnezia options; the amneziaWG case is used by
            // the .conf importer when the config carries AWG parameters as
            // its defining feature. Links keep Go's identity.
        }
        try validate(profile)
        profile.refreshID()
        return profile
    }

    /// Reads AWG parameters from a key lookup (link query or conf section).
    static func awgFromQuery(_ get: (String) -> String) -> AWGSpec? {
        let truthy: (String) -> Bool = { $0 == "1" || $0.lowercased() == "true" }
        let spec = AWGSpec(jc: Int(get("jc")) ?? 0, jmin: Int(get("jmin")) ?? 0,
                           jmax: Int(get("jmax")) ?? 0, s1: Int(get("s1")) ?? 0,
                           s2: Int(get("s2")) ?? 0, s3: Int(get("s3")) ?? 0,
                           s4: Int(get("s4")) ?? 0, h1: get("h1"), h2: get("h2"),
                           h3: get("h3"), h4: get("h4"), i1: get("i1"), i2: get("i2"),
                           i3: get("i3"), i4: get("i4"), i5: get("i5"),
                           j1: get("j1"), j2: get("j2"), j3: get("j3"),
                           itime: Int(get("itime")) ?? 0,
                           headerProtectionKey: get("headerprotectionkey"),
                           contentPaddingAddition: get("contentpaddingaddition"),
                           rekeyAfterTime: get("rekeyaftertime"),
                           rekeyTimeout: get("rekeytimeout"),
                           rejectAfterTime: get("rejectaftertime"),
                           keepaliveTimeout: get("keepalivetimeout"),
                           maxHandshakeAttempts: get("maxhandshakeattempts"),
                           randomTrailers: truthy(get("randomtrailers")),
                           disableCookies: truthy(get("disablecookies")),
                           masqueradeProtocol: get("masqueradeprotocol"),
                           masqueradeDomain: get("masqueradedomain"),
                           masqueradeBrowser: get("masqueradebrowser"))
        return spec.isEmpty ? nil : spec
    }

    // MARK: - Shared JSON mapping (sing-box / SIP008 / generic)

    static func mapJSONSpec(_ m: [String: Any], fallback: ProxyProtocol?) throws -> ServerProfile {
        var proto = fallback
        if let t = m["type"] as? String, let mapped = protocolFromType(t) {
            proto = mapped
        }
        guard let proto else { throw SoraParseError.unsupportedFormat }
        var host = ""
        for k in ["server", "address", "host"] {
            if let s = m[k] as? String, !s.isEmpty { host = s; break }
        }
        var portNum = jsonPort(m["server_port"])
        if portNum == 0 { portNum = jsonPort(m["port"]) }
        var profile = ServerProfile(name: jsonString(m["tag"]), protocol: proto,
                                    address: host, port: portNum,
                                    uuid: jsonString(m["uuid"]),
                                    password: jsonString(m["password"]),
                                    method: jsonString(m["method"]),
                                    flow: jsonString(m["flow"]),
                                    transport: TransportSpec(type: "tcp"),
                                    tls: TLSSpec())
        var transportType = jsonString(m["network"])
        if transportType.isEmpty { transportType = jsonString(m["transport"]) }
        if !transportType.isEmpty { profile.transport.type = transportType }
        if profile.name.isEmpty { profile.name = jsonString(m["name"]) }
        if profile.name.isEmpty { profile.name = jsonString(m["remarks"]) }
        applyJSONTransportTLS(m, profile: &profile)
        if proto == .shadowsocks {
            if profile.method.hasPrefix("2022-") { profile.ss2022Key = profile.password }
            let plug = jsonString(m["plugin"])
            if !plug.isEmpty {
                if let semi = plug.firstIndex(of: ";") {
                    profile.plugin = String(plug[..<semi])
                    if profile.pluginOptions.isEmpty {
                        profile.pluginOptions = String(plug[plug.index(after: semi)...])
                    }
                } else { profile.plugin = plug }
            }
            if !jsonString(m["plugin_opts"]).isEmpty {
                profile.pluginOptions = jsonString(m["plugin_opts"])
            }
        }
        if proto == .hysteria2 {
            profile.hy2UpMbps = jsonInt(m["up_mbps"]) ?? Int(jsonString(m["up_mbps"])) ?? 0
            profile.hy2DownMbps = jsonInt(m["down_mbps"]) ?? Int(jsonString(m["down_mbps"])) ?? 0
            if let obfs = m["obfs"] as? [String: Any] {
                profile.hy2Obfs = jsonString(obfs["type"])
                profile.hy2ObfsPassword = jsonString(obfs["password"])
            }
            let ports = jsonString(m["ports"])
            if !ports.isEmpty { profile.hy2HopPorts = ports }
        }
        if proto == .tuic {
            profile.tuicCongestionControl = jsonString(m["congestion_control"])
            profile.tuicUDPRelayMode = jsonString(m["udp_relay_mode"])
        }
        if proto == .wireguard || proto == .amneziaWG {
            profile.wgPrivateKey = jsonString(m["private_key"])
            if let addr = m["local_address"] as? [Any] {
                profile.wgLocalAddresses = addr.compactMap { $0 as? String }
            }
            if let peers = m["peers"] as? [[String: Any]], let first = peers.first {
                profile.wgPeerPublicKey = jsonString(first["public_key"])
                profile.wgPreSharedKey = jsonString(first["pre_shared_key"])
                if !jsonString(first["address"]).isEmpty { profile.address = jsonString(first["address"]) }
                profile.port = jsonPort(first["port"]) == 0 ? profile.port : jsonPort(first["port"])
            }
        }
        try validate(profile)
        profile.refreshID()
        return profile
    }

    static func applyJSONTransportTLS(_ m: [String: Any], profile: inout ServerProfile) {
        if let tr = m["transport"] as? [String: Any] {
            if !jsonString(tr["type"]).isEmpty { profile.transport.type = jsonString(tr["type"]) }
            profile.transport.path = jsonString(tr["path"])
            if let hosts = tr["host"] as? [Any], let first = hosts.first as? String {
                profile.transport.host = first
            } else {
                profile.transport.host = jsonString(tr["host"])
            }
            profile.transport.serviceName = jsonString(tr["service_name"])
            if let headers = tr["headers"] as? [String: Any] {
                for (k, v) in headers {
                    if let s = v as? String { profile.transport.headers[k] = s }
                }
            }
        }
        if let tls = m["tls"] as? [String: Any] {
            profile.tls.enabled = jsonBool(tls["enabled"])
            profile.tls.serverName = jsonString(tls["server_name"])
            profile.tls.allowInsecure = jsonBool(tls["insecure"])
            if let alpn = tls["alpn"] as? [Any] {
                profile.tls.alpn = alpn.compactMap { $0 as? String }
            }
            if let utls = tls["utls"] as? [String: Any] {
                profile.tls.fingerprint = jsonString(utls["fingerprint"])
            }
            if profile.tls.fingerprint.isEmpty {
                profile.tls.fingerprint = jsonString(tls["fingerprint"])
            }
            if let reality = tls["reality"] as? [String: Any], jsonBool(reality["enabled"]) || !jsonString(reality["public_key"]).isEmpty {
                profile.tls.enabled = true
                profile.tls.reality = RealitySpec(publicKey: jsonString(reality["public_key"]),
                                                  shortId: jsonString(reality["short_id"]),
                                                  spiderX: jsonString(reality["spider_x"]))
            }
            if let ech = tls["ech"] as? [String: Any], jsonBool(ech["enabled"]) {
                profile.tls.ech = jsonString(ech["config"]).isEmpty ? "enabled" : jsonString(ech["config"])
            }
        }
        if let mux = m["multiplex"] as? [String: Any] {
            profile.muxEnabled = jsonBool(mux["enabled"])
        }
    }

    static func protocolFromType(_ t: String) -> ProxyProtocol? {
        switch t.lowercased() {
        case "vless": return .vless
        case "trojan": return .trojan
        case "shadowsocks", "ss": return .shadowsocks
        case "vmess": return .vmess
        case "hysteria2", "hysteria", "hy2": return .hysteria2
        case "tuic": return .tuic
        case "anytls": return .anytls
        case "wireguard", "wg": return .wireguard
        case "amneziawg", "amnezia-wg": return .amneziaWG
        default: return nil
        }
    }

    // MARK: - XHTTP extra

    static func applyExtraDownloadSettings(extra: String, transport: inout TransportSpec) {
        // Garbage extra is provider decoration, never an import error (Go).
        guard !extra.isEmpty,
              let data = extra.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let m = obj as? [String: Any],
              let ds = m["downloadSettings"] as? [String: Any] else { return }
        let address = jsonString(ds["address"])
        let portNum = jsonPort(ds["port"])
        guard !address.isEmpty, portNum >= 1 else { return }
        transport.downloadAddress = address
        transport.downloadPort = portNum
    }

    // MARK: - Validation (Go OutboundSpec.validate)

    static func validate(_ profile: ServerProfile) throws {
        if profile.address.isEmpty || profile.port < 1 {
            throw SoraParseError.invalidLink
        }
        switch profile.protocol {
        case .vless, .vmess, .tuic:
            if !profile.uuid.isEmpty && !UUIDValidation.isValid(profile.uuid) {
                throw SoraParseError.invalidUUID
            }
        default:
            break
        }
    }

    // MARK: - Loosely-typed JSON helpers (Go stringValue/number/jsonBool)

    static func jsonString(_ v: Any?) -> String {
        if let s = v as? String { return s }
        if let n = v as? NSNumber { return n.stringValue }
        return ""
    }

    static func jsonInt(_ v: Any?) -> Int? {
        if let n = v as? NSNumber { return n.intValue }
        if let s = v as? String { return Int(s) }
        return nil
    }

    /// Port from a loosely typed JSON value; 0 outside 1...65535 (Go portNumber).
    static func jsonPort(_ v: Any?) -> Int {
        let n = jsonInt(v) ?? 0
        return (n >= 1 && n <= 65535) ? n : 0
    }

    static func jsonBool(_ v: Any?) -> Bool {
        switch v {
        case let b as Bool: return b
        case let n as NSNumber: return n.doubleValue != 0
        case let s as String: return s == "1" || s.lowercased() == "true"
        default: return false
        }
    }
}
