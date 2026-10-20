import Foundation

/// The result of parsing a subscription payload: the profiles that parsed
/// and, for every skipped entry, the source line (or item description) and a
/// stable human-readable reason. Broken entries never fail the whole
/// import — mirroring Go's LinkParser.Parse report semantics.
public struct SubscriptionResult {
    public var profiles: [ServerProfile]
    public var skipped: [(line: String, reason: String)]

    public init(profiles: [ServerProfile] = [], skipped: [(line: String, reason: String)] = []) {
        self.profiles = profiles
        self.skipped = skipped
    }
}

/// Parses subscription payloads with format auto-detection mirroring Go's
/// ImportDetector order: JSON (sing-box outbounds / SIP008 / Xray-style
/// arrays), Clash YAML subset (`proxies:`), WireGuard .conf, base64 blobs of
/// links, and plain link lists. Detection keys off the payload bytes only —
/// never off OS version, locale or platform heuristics.
public enum SubscriptionParser {
    public static let maxInputSize = 16 << 20
    public static let maxItems = 20000

    public static func parse(_ data: Data) -> SubscriptionResult {
        guard data.count <= maxInputSize else {
            return SubscriptionResult(skipped: [(line: "", reason: "subscription too large")])
        }
        guard let text = String(data: data, encoding: .utf8) else {
            return SubscriptionResult(skipped: [(line: "", reason: "unreadable subscription")])
        }
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty {
            return SubscriptionResult(skipped: [(line: "", reason: "empty subscription")])
        }
        // JSON shapes first (Go detects them before YAML/WG/base64).
        if s.hasPrefix("{") || s.hasPrefix("[") {
            if let result = parseJSON(s) {
                return result
            }
        }
        if s.contains("proxies:") {
            return parseClash(s)
        }
        if s.contains("[Interface]") && s.contains("[Peer]") {
            return parseWireGuardConf(s)
        }
        // Base64 blob: the decoded payload must itself look like a link
        // list (Go's FormatBase64 condition).
        if let decoded = Base64.decodeUTF8(s), looksLikeLinkList(decoded) {
            return parseLinkList(decoded)
        }
        if looksLikeLinkList(s) {
            return parseLinkList(s)
        }
        return SubscriptionResult(skipped: [(line: String(s.prefix(120)), reason: "unsupported subscription format")])
    }

    // MARK: - Link lists

    private static let knownSchemes = ["vless://", "vmess://", "trojan://", "ss://",
                                       "hysteria2://", "hy2://", "tuic://", "wireguard://", "wg://"]

    static func looksLikeLinkList(_ s: String) -> Bool {
        s.split(separator: "\n").contains { line in
            let l = line.trimmingCharacters(in: .whitespaces).lowercased()
            return knownSchemes.contains { l.hasPrefix($0) }
        }
    }

    static func parseLinkList(_ s: String) -> SubscriptionResult {
        var result = SubscriptionResult()
        var seen = Set<String>()
        for rawLine in s.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            if result.profiles.count >= maxItems {
                result.skipped.append((line: line, reason: "server limit reached"))
                continue
            }
            do {
                let profile = try LinkParser.parse(line)
                if seen.contains(profile.id) {
                    result.skipped.append((line: line, reason: "duplicate server"))
                    continue
                }
                seen.insert(profile.id)
                result.profiles.append(profile)
            } catch let e as SoraParseError {
                switch e {
                case .unsupportedScheme, .unsupportedOption:
                    result.skipped.append((line: line, reason: "unsupported link"))
                default:
                    result.skipped.append((line: line, reason: "invalid link"))
                }
            } catch {
                result.skipped.append((line: line, reason: "invalid link"))
            }
        }
        return result
    }

    // MARK: - JSON (sing-box / SIP008 / Xray-style lists)

    private static func parseJSON(_ s: String) -> SubscriptionResult? {
        guard let data = s.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        var items: [[String: Any]] = []
        var fallback: ProxyProtocol? = nil
        var isSIP008 = false
        if let arr = obj as? [[String: Any]] {
            items = arr
        } else if let m = obj as? [String: Any] {
            if let outbounds = m["outbounds"] as? [[String: Any]] {
                items = outbounds
            } else if let servers = m["servers"] as? [[String: Any]] {
                items = servers
                fallback = .shadowsocks
                isSIP008 = true
            } else {
                items = [m]
            }
        } else {
            return SubscriptionResult(skipped: [(line: "", reason: "unsupported subscription format")])
        }
        var result = SubscriptionResult()
        var seen = Set<String>()
        for (i, item) in items.enumerated() {
            // Direct nodes: sing-box marks client outbounds with a server;
            // infrastructure entries (direct/block/dns/selector) have no
            // server and are skipped, not treated as broken servers.
            let typeName = (item["type"] as? String)?.lowercased() ?? ""
            if ["direct", "block", "dns", "selector", "urltest"].contains(typeName) {
                result.skipped.append((line: "item \(i)", reason: "unsupported server"))
                continue
            }
            do {
                let profile = try LinkParser.mapJSONSpec(item, fallback: isSIP008 ? .shadowsocks : fallback)
                if seen.contains(profile.id) {
                    result.skipped.append((line: "item \(i)", reason: "duplicate server"))
                    continue
                }
                seen.insert(profile.id)
                result.profiles.append(profile)
            } catch {
                result.skipped.append((line: "item \(i)", reason: "invalid server"))
            }
        }
        return result
    }

    // MARK: - WireGuard .conf (incl. AmneziaWG parameters)

    static func parseWireGuardConf(_ s: String) -> SubscriptionResult {
        var interface: [String: String] = [:]
        var peer: [String: String] = [:]
        var section = ""
        for rawLine in s.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") {
                section = line.lowercased()
                continue
            }
            guard let eq = line.firstIndex(of: "=") else { continue }
            let key = line[..<eq].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)
            if section == "[interface]" { interface[key] = value }
            if section == "[peer]" { peer[key] = value }
        }
        let endpoint = peer["endpoint"] ?? ""
        var host = endpoint
        var port = 0
        if let colon = endpoint.lastIndex(of: ":") {
            host = String(endpoint[..<colon]).trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            port = Int(endpoint[endpoint.index(after: colon)...]) ?? 0
        }
        let awg = LinkParser.awgFromQuery { interface[$0] ?? "" }
        var profile = ServerProfile(name: "", protocol: awg == nil ? .wireguard : .amneziaWG,
                                    address: host, port: port,
                                    wgPrivateKey: interface["privatekey"] ?? "",
                                    wgPeerPublicKey: peer["publickey"] ?? "",
                                    wgPreSharedKey: peer["presharedkey"] ?? "",
                                    transport: TransportSpec(type: "udp"), tls: TLSSpec())
        if let address = interface["address"] {
            profile.wgLocalAddresses = address.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
        }
        if let allowed = peer["allowedips"] {
            profile.wgAllowedIPs = allowed.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
        }
        profile.wgPersistentKeepalive = Int(peer["persistentkeepalive"] ?? "") ?? 0
        if !endpoint.isEmpty { profile.wgPeerEndpoint = endpoint }
        profile.awg = awg
        do {
            try LinkParser.validate(profile)
        } catch {
            return SubscriptionResult(skipped: [(line: "[Peer] endpoint", reason: "invalid server")])
        }
        profile.refreshID()
        return SubscriptionResult(profiles: [profile])
    }

    // MARK: - Clash YAML subset

    /// Parses the `proxies:` section of a Clash document. Supports the two
    /// shapes providers emit: flow maps (`- {name: …, type: …}`) and block
    /// maps (`- name: …` with indented keys, one level of nesting for
    /// ws-opts/grpc-opts/reality-opts/plugin-opts).
    static func parseClash(_ s: String) -> SubscriptionResult {
        var items: [[String: Any]] = []
        var inProxies = false
        var current: [String: String] = [:]
        var nestedKey = ""
        var nested: [String: String] = [:]

        func flushNested() {
            if !nestedKey.isEmpty {
                current[nestedKey] = nested.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ";")
                nestedKey = ""
                nested = [:]
            }
        }
        func flushItem() {
            flushNested()
            if !current.isEmpty {
                items.append(current.mapValues { $0 as Any })
                current = [:]
            }
        }

        for rawLine in s.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            if !line.hasPrefix(" ") && !line.hasPrefix("\t") {
                if trimmed.hasPrefix("proxies:") {
                    inProxies = true
                    continue
                }
                if inProxies && trimmed.contains(":") {
                    // A new top-level key ends the proxies section.
                    flushItem()
                    inProxies = false
                }
                continue
            }
            if !inProxies { continue }
            if trimmed.hasPrefix("- ") || trimmed == "-" {
                flushItem()
                let rest = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if rest.hasPrefix("{") {
                    // Flow map on one line.
                    let body = rest.trimmingCharacters(in: CharacterSet(charactersIn: "{}"))
                    for pair in splitFlowPairs(body) {
                        if let kv = splitKeyValue(pair) { current[kv.0] = kv.1 }
                    }
                    flushItem()
                } else if let kv = splitKeyValue(rest) {
                    current[kv.0] = kv.1
                }
                continue
            }
            // Indented continuation of the current item.
            let indent = line.prefix(while: { $0 == " " || $0 == "\t" }).count
            if let kv = splitKeyValue(trimmed) {
                if kv.1.isEmpty && indent <= 6 {
                    flushNested()
                    nestedKey = kv.0
                } else if !nestedKey.isEmpty && indent > 4 {
                    nested[kv.0] = kv.1
                } else {
                    flushNested()
                    current[kv.0] = kv.1
                }
            }
        }
        flushItem()

        var result = SubscriptionResult()
        var seen = Set<String>()
        for (i, item) in items.enumerated() {
            do {
                let profile = try mapClashProxy(item)
                if seen.contains(profile.id) {
                    result.skipped.append((line: "proxies item \(i)", reason: "duplicate server"))
                    continue
                }
                seen.insert(profile.id)
                result.profiles.append(profile)
            } catch {
                result.skipped.append((line: "proxies item \(i)", reason: "invalid server"))
            }
        }
        return result
    }

    private static func splitFlowPairs(_ body: String) -> [String] {
        var parts: [String] = []
        var depth = 0
        var cur = ""
        for ch in body {
            if ch == "{" || ch == "[" { depth += 1 }
            if ch == "}" || ch == "]" { depth -= 1 }
            if ch == "," && depth == 0 {
                parts.append(cur)
                cur = ""
            } else {
                cur.append(ch)
            }
        }
        if !cur.isEmpty { parts.append(cur) }
        return parts
    }

    private static func splitKeyValue(_ s: String) -> (String, String)? {
        guard let colon = s.firstIndex(of: ":") else { return nil }
        let key = s[..<colon].trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        var value = s[s.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        if value.count >= 2,
           (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
            value = String(value.dropFirst().dropLast())
        }
        return (key.lowercased(), value)
    }

    private static func mapClashProxy(_ m: [String: Any]) throws -> ServerProfile {
        // Reuse the generic JSON mapping after translating Clash key names
        // onto the sing-box spellings it understands.
        var j: [String: Any] = [:]
        func str(_ k: String) -> String { (m[k] as? String) ?? "" }
        j["type"] = str("type")
        j["server"] = str("server")
        j["port"] = str("port")
        j["uuid"] = str("uuid")
        j["password"] = str("password")
        j["method"] = str("cipher")
        j["flow"] = str("flow")
        j["network"] = str("network")
        j["tag"] = str("name")
        var tls: [String: Any] = [:]
        let tlsOn = ["true", "1"].contains(str("tls")) || !str("sni").isEmpty || !str("servername").isEmpty
        if tlsOn || !str("reality-opts").isEmpty {
            tls["enabled"] = true
            tls["server_name"] = str("sni").isEmpty ? str("servername") : str("sni")
            tls["insecure"] = ["true", "1"].contains(str("skip-cert-verify"))
            if !str("fingerprint").isEmpty {
                tls["utls"] = ["fingerprint": str("fingerprint")]
            }
            if !str("alpn").isEmpty {
                tls["alpn"] = str("alpn").trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                    .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
            if !str("reality-opts").isEmpty {
                var reality: [String: Any] = ["enabled": true]
                for pair in str("reality-opts").split(separator: ";") {
                    let kv = pair.split(separator: "=", maxSplits: 1)
                    if kv.count == 2 {
                        if kv[0] == "public-key" { reality["public_key"] = String(kv[1]) }
                        if kv[0] == "short-id" { reality["short_id"] = String(kv[1]) }
                    }
                }
                tls["reality"] = reality
            }
            j["tls"] = tls
        }
        var transport: [String: Any] = [:]
        for key in ["ws-opts", "grpc-opts", "h2-opts", "http-opts"] where !str(key).isEmpty {
            for pair in str(key).split(separator: ";") {
                let kv = pair.split(separator: "=", maxSplits: 1)
                guard kv.count == 2 else { continue }
                if kv[0] == "path" { transport["path"] = String(kv[1]) }
                if kv[0] == "grpc-service-name" { transport["service_name"] = String(kv[1]) }
                if kv[0] == "headers" {
                    // headers arrive as "Host=example.com" inside the opts.
                    let hv = String(kv[1])
                    if hv.hasPrefix("Host=") { transport["host"] = String(hv.dropFirst(5)) }
                }
            }
        }
        if !transport.isEmpty { j["transport"] = transport }
        if !str("plugin").isEmpty { j["plugin"] = str("plugin") }
        if !str("plugin-opts").isEmpty {
            // Clash plugin-opts is a nested map flattened as k=v;k=v; the
            // SIP002 spelling joins mode/host the same way engines read.
            j["plugin_opts"] = str("plugin-opts").split(separator: ";").map {
                $0.replacingOccurrences(of: "=", with: "=")
            }.joined(separator: ";")
        }
        var profile = try LinkParser.mapJSONSpec(j, fallback: nil)
        if profile.protocol == .hysteria2 {
            profile.hy2UpMbps = Int(str("up")) ?? 0
            profile.hy2DownMbps = Int(str("down")) ?? 0
            if !str("ports").isEmpty { profile.hy2HopPorts = str("ports") }
            if !str("obfs").isEmpty { profile.hy2Obfs = str("obfs") }
            profile.hy2ObfsPassword = str("obfs-password")
        }
        if profile.protocol == .tuic {
            profile.tuicCongestionControl = str("congestion-controller")
            profile.tuicUDPRelayMode = str("udp-relay-mode")
        }
        profile.refreshID()
        return profile
    }
}
