import Foundation

/// Proxy protocols SoraCore can represent. Raw values are the canonical
/// wire/storage spellings; they are part of the stable-id material and must
/// never be renamed (additive changes only).
public enum ProxyProtocol: String, Codable, CaseIterable {
    case vless
    case trojan
    case shadowsocks
    case vmess
    case hysteria2
    case tuic
    case anytls
    case wireguard
    case amneziaWG
}

/// Stream transport of an outbound. `type` is one of
/// tcp/ws/grpc/httpupgrade/xhttp/quic (unknown values are preserved
/// verbatim; validation belongs to the engine layer, mirroring Go).
public struct TransportSpec: Codable, Equatable {
    public var type: String
    public var path: String
    public var host: String
    public var serviceName: String
    /// XHTTP: the raw `extra` JSON string of the share link, kept verbatim.
    public var extra: String
    /// XHTTP mode (the link's `mode` parameter).
    public var mode: String
    public var headers: [String: String]
    /// XHTTP up/down split decoded from `extra` (downloadSettings).
    public var downloadAddress: String
    public var downloadPort: Int

    public init(type: String = "tcp", path: String = "", host: String = "",
                serviceName: String = "", extra: String = "", mode: String = "",
                headers: [String: String] = [:], downloadAddress: String = "",
                downloadPort: Int = 0) {
        self.type = type; self.path = path; self.host = host
        self.serviceName = serviceName; self.extra = extra; self.mode = mode
        self.headers = headers; self.downloadAddress = downloadAddress
        self.downloadPort = downloadPort
    }

    private enum CodingKeys: String, CodingKey {
        case type, path, host, serviceName, extra, mode, headers, downloadAddress, downloadPort
    }

    // Additive-only decoding: every field tolerates absence so older stored
    // documents keep decoding after new fields are added.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "tcp"
        path = try c.decodeIfPresent(String.self, forKey: .path) ?? ""
        host = try c.decodeIfPresent(String.self, forKey: .host) ?? ""
        serviceName = try c.decodeIfPresent(String.self, forKey: .serviceName) ?? ""
        extra = try c.decodeIfPresent(String.self, forKey: .extra) ?? ""
        mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? ""
        headers = try c.decodeIfPresent([String: String].self, forKey: .headers) ?? [:]
        downloadAddress = try c.decodeIfPresent(String.self, forKey: .downloadAddress) ?? ""
        downloadPort = try c.decodeIfPresent(Int.self, forKey: .downloadPort) ?? 0
    }
}

/// REALITY parameters of a TLS-secured outbound.
public struct RealitySpec: Codable, Equatable {
    public var publicKey: String
    public var shortId: String
    public var spiderX: String

    public init(publicKey: String = "", shortId: String = "", spiderX: String = "") {
        self.publicKey = publicKey; self.shortId = shortId; self.spiderX = spiderX
    }

    private enum CodingKeys: String, CodingKey { case publicKey, shortId, spiderX }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        publicKey = try c.decodeIfPresent(String.self, forKey: .publicKey) ?? ""
        shortId = try c.decodeIfPresent(String.self, forKey: .shortId) ?? ""
        spiderX = try c.decodeIfPresent(String.self, forKey: .spiderX) ?? ""
    }
}

/// TLS parameters. `fingerprint` is the uTLS fingerprint name; empty means
/// none. `ech` carries the link's ECH parameter verbatim when present.
public struct TLSSpec: Codable, Equatable {
    public var enabled: Bool
    public var serverName: String
    public var allowInsecure: Bool
    public var alpn: [String]
    public var fingerprint: String
    public var reality: RealitySpec?
    public var ech: String?
    /// ECH `query_server_name`: the domain used for the ECH DNS query
    /// when it differs from the server name (Go TLS.ECH.QueryServerName).
    /// Additive per tier: engines without it (ENGINES §4 row 21) keep the
    /// field stored and receive ECH without it.
    public var echQueryServerName: String
    /// TLS ClientHello fragmentation (Go plan Fragment, rendered by
    /// sing-box as `tls.fragment`). Additive per tier: engines without
    /// it (ENGINES §4 row 22) keep the field stored, not emitted.
    public var fragment: Bool
    /// REALITY ML-DSA-65 verify key (the link's `pqv` parameter).
    public var mldsa65Verify: String

    public init(enabled: Bool = false, serverName: String = "", allowInsecure: Bool = false,
                alpn: [String] = [], fingerprint: String = "", reality: RealitySpec? = nil,
                ech: String? = nil, echQueryServerName: String = "", fragment: Bool = false,
                mldsa65Verify: String = "") {
        self.enabled = enabled; self.serverName = serverName
        self.allowInsecure = allowInsecure; self.alpn = alpn
        self.fingerprint = fingerprint; self.reality = reality; self.ech = ech
        self.echQueryServerName = echQueryServerName; self.fragment = fragment
        self.mldsa65Verify = mldsa65Verify
    }

    private enum CodingKeys: String, CodingKey {
        case enabled, serverName, allowInsecure, alpn, fingerprint, reality, ech, mldsa65Verify
        case echQueryServerName, fragment
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        serverName = try c.decodeIfPresent(String.self, forKey: .serverName) ?? ""
        allowInsecure = try c.decodeIfPresent(Bool.self, forKey: .allowInsecure) ?? false
        alpn = try c.decodeIfPresent([String].self, forKey: .alpn) ?? []
        fingerprint = try c.decodeIfPresent(String.self, forKey: .fingerprint) ?? ""
        reality = try c.decodeIfPresent(RealitySpec.self, forKey: .reality)
        ech = try c.decodeIfPresent(String.self, forKey: .ech)
        echQueryServerName = try c.decodeIfPresent(String.self, forKey: .echQueryServerName) ?? ""
        fragment = try c.decodeIfPresent(Bool.self, forKey: .fragment) ?? false
        mldsa65Verify = try c.decodeIfPresent(String.self, forKey: .mldsa65Verify) ?? ""
    }
}

/// AmneziaWG obfuscation parameters. The numeric fields are counts/sizes;
/// H1–H4 are kept as strings because they may carry ranges ("100000-100100"),
/// and I1–I5 are signature-packet templates — exactly as the Go core keeps
/// them (engine.AmneziaWG).
public struct AWGSpec: Codable, Equatable {
    public var jc: Int
    public var jmin: Int
    public var jmax: Int
    public var s1: Int
    public var s2: Int
    public var s3: Int
    public var s4: Int
    public var h1: String
    public var h2: String
    public var h3: String
    public var h4: String
    public var i1: String
    public var i2: String
    public var i3: String
    public var i4: String
    public var i5: String
    // AmneziaWG 3.1 (Go engine.AmneziaWG): range/protection values are
    // strings kept verbatim, exactly as the Go credential layer keeps them.
    public var j1: String
    public var j2: String
    public var j3: String
    public var itime: Int
    public var headerProtectionKey: String
    public var contentPaddingAddition: String
    public var rekeyAfterTime: String
    public var rekeyTimeout: String
    public var rejectAfterTime: String
    public var keepaliveTimeout: String
    public var maxHandshakeAttempts: String
    public var randomTrailers: Bool
    public var disableCookies: Bool
    public var masqueradeProtocol: String
    public var masqueradeDomain: String
    public var masqueradeBrowser: String

    public init(jc: Int = 0, jmin: Int = 0, jmax: Int = 0, s1: Int = 0, s2: Int = 0,
                s3: Int = 0, s4: Int = 0, h1: String = "", h2: String = "", h3: String = "",
                h4: String = "", i1: String = "", i2: String = "", i3: String = "",
                i4: String = "", i5: String = "", j1: String = "", j2: String = "",
                j3: String = "", itime: Int = 0, headerProtectionKey: String = "",
                contentPaddingAddition: String = "", rekeyAfterTime: String = "",
                rekeyTimeout: String = "", rejectAfterTime: String = "",
                keepaliveTimeout: String = "", maxHandshakeAttempts: String = "",
                randomTrailers: Bool = false, disableCookies: Bool = false,
                masqueradeProtocol: String = "", masqueradeDomain: String = "",
                masqueradeBrowser: String = "") {
        self.jc = jc; self.jmin = jmin; self.jmax = jmax
        self.s1 = s1; self.s2 = s2; self.s3 = s3; self.s4 = s4
        self.h1 = h1; self.h2 = h2; self.h3 = h3; self.h4 = h4
        self.i1 = i1; self.i2 = i2; self.i3 = i3; self.i4 = i4; self.i5 = i5
        self.j1 = j1; self.j2 = j2; self.j3 = j3; self.itime = itime
        self.headerProtectionKey = headerProtectionKey
        self.contentPaddingAddition = contentPaddingAddition
        self.rekeyAfterTime = rekeyAfterTime; self.rekeyTimeout = rekeyTimeout
        self.rejectAfterTime = rejectAfterTime; self.keepaliveTimeout = keepaliveTimeout
        self.maxHandshakeAttempts = maxHandshakeAttempts
        self.randomTrailers = randomTrailers; self.disableCookies = disableCookies
        self.masqueradeProtocol = masqueradeProtocol
        self.masqueradeDomain = masqueradeDomain
        self.masqueradeBrowser = masqueradeBrowser
    }

    public var isEmpty: Bool {
        jc == 0 && jmin == 0 && jmax == 0 && s1 == 0 && s2 == 0 && s3 == 0 && s4 == 0 &&
        h1.isEmpty && h2.isEmpty && h3.isEmpty && h4.isEmpty &&
        i1.isEmpty && i2.isEmpty && i3.isEmpty && i4.isEmpty && i5.isEmpty &&
        j1.isEmpty && j2.isEmpty && j3.isEmpty && itime == 0 &&
        headerProtectionKey.isEmpty && contentPaddingAddition.isEmpty &&
        rekeyAfterTime.isEmpty && rekeyTimeout.isEmpty && rejectAfterTime.isEmpty &&
        keepaliveTimeout.isEmpty && maxHandshakeAttempts.isEmpty &&
        !randomTrailers && !disableCookies &&
        masqueradeProtocol.isEmpty && masqueradeDomain.isEmpty && masqueradeBrowser.isEmpty
    }

    /// Alias used by config builders (Go AmneziaWG.IsZero naming).
    public var isZero: Bool { isEmpty }

    private enum CodingKeys: String, CodingKey {
        case jc, jmin, jmax, s1, s2, s3, s4, h1, h2, h3, h4, i1, i2, i3, i4, i5
        case j1, j2, j3, itime, headerProtectionKey, contentPaddingAddition
        case rekeyAfterTime, rekeyTimeout, rejectAfterTime, keepaliveTimeout
        case maxHandshakeAttempts, randomTrailers, disableCookies
        case masqueradeProtocol, masqueradeDomain, masqueradeBrowser
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        jc = try c.decodeIfPresent(Int.self, forKey: .jc) ?? 0
        jmin = try c.decodeIfPresent(Int.self, forKey: .jmin) ?? 0
        jmax = try c.decodeIfPresent(Int.self, forKey: .jmax) ?? 0
        s1 = try c.decodeIfPresent(Int.self, forKey: .s1) ?? 0
        s2 = try c.decodeIfPresent(Int.self, forKey: .s2) ?? 0
        s3 = try c.decodeIfPresent(Int.self, forKey: .s3) ?? 0
        s4 = try c.decodeIfPresent(Int.self, forKey: .s4) ?? 0
        h1 = try c.decodeIfPresent(String.self, forKey: .h1) ?? ""
        h2 = try c.decodeIfPresent(String.self, forKey: .h2) ?? ""
        h3 = try c.decodeIfPresent(String.self, forKey: .h3) ?? ""
        h4 = try c.decodeIfPresent(String.self, forKey: .h4) ?? ""
        i1 = try c.decodeIfPresent(String.self, forKey: .i1) ?? ""
        i2 = try c.decodeIfPresent(String.self, forKey: .i2) ?? ""
        i3 = try c.decodeIfPresent(String.self, forKey: .i3) ?? ""
        i4 = try c.decodeIfPresent(String.self, forKey: .i4) ?? ""
        i5 = try c.decodeIfPresent(String.self, forKey: .i5) ?? ""
        j1 = try c.decodeIfPresent(String.self, forKey: .j1) ?? ""
        j2 = try c.decodeIfPresent(String.self, forKey: .j2) ?? ""
        j3 = try c.decodeIfPresent(String.self, forKey: .j3) ?? ""
        itime = try c.decodeIfPresent(Int.self, forKey: .itime) ?? 0
        headerProtectionKey = try c.decodeIfPresent(String.self, forKey: .headerProtectionKey) ?? ""
        contentPaddingAddition = try c.decodeIfPresent(String.self, forKey: .contentPaddingAddition) ?? ""
        rekeyAfterTime = try c.decodeIfPresent(String.self, forKey: .rekeyAfterTime) ?? ""
        rekeyTimeout = try c.decodeIfPresent(String.self, forKey: .rekeyTimeout) ?? ""
        rejectAfterTime = try c.decodeIfPresent(String.self, forKey: .rejectAfterTime) ?? ""
        keepaliveTimeout = try c.decodeIfPresent(String.self, forKey: .keepaliveTimeout) ?? ""
        maxHandshakeAttempts = try c.decodeIfPresent(String.self, forKey: .maxHandshakeAttempts) ?? ""
        randomTrailers = try c.decodeIfPresent(Bool.self, forKey: .randomTrailers) ?? false
        disableCookies = try c.decodeIfPresent(Bool.self, forKey: .disableCookies) ?? false
        masqueradeProtocol = try c.decodeIfPresent(String.self, forKey: .masqueradeProtocol) ?? ""
        masqueradeDomain = try c.decodeIfPresent(String.self, forKey: .masqueradeDomain) ?? ""
        masqueradeBrowser = try c.decodeIfPresent(String.self, forKey: .masqueradeBrowser) ?? ""
    }
}

/// One parsed server, independent of any engine — the Swift mirror of the
/// Go core's parser.OutboundSpec, narrowed to the contracted fields.
public struct ServerProfile: Codable, Equatable, Identifiable {
    /// Stable identity: `<protocol>:<address>:<port>:<hex>` where the hex is
    /// the first 8 bytes of SHA-256 over the canonical identity string (see
    /// `stableID`). The shape mirrors Go's OutboundSpec.StableKey.
    public var id: String
    public var name: String
    public var `protocol`: ProxyProtocol
    public var address: String
    public var port: Int

    public var uuid: String
    public var password: String
    /// Shadowsocks cipher ("method").
    public var method: String
    /// Shadowsocks plugin name (SIP002), e.g. "v2ray-plugin".
    public var plugin: String
    public var pluginOptions: String
    /// VMess security ("scy" / AEAD cipher), e.g. "auto", "aes-128-gcm".
    public var vmessSecurity: String
    public var flow: String
    /// SS-2022 key material: the full password composite
    /// ("<server key>[:<personal key>]") for 2022-* methods.
    public var ss2022Key: String

    public var hy2Obfs: String
    public var hy2ObfsPassword: String
    public var hy2UpMbps: Int
    public var hy2DownMbps: Int
    /// Hysteria2 hop ports verbatim ("20000-30000,40000"): mport/ports.
    public var hy2HopPorts: String
    /// Hysteria2 port-hop interval, seconds (the link's `hop-interval`);
    /// 0 = unset. Exists on every tier (ENGINES §4 row 7).
    public var hy2HopInterval: Int
    /// Hysteria2 randomized hop interval upper bound, seconds; 0 = unset.
    /// A sing-box 1.14 field (ENGINES §4 row 8): tiers without it keep
    /// the value stored and do not emit it.
    public var hy2HopIntervalMax: Int
    /// Hysteria2 BBR congestion profile ("standard"/"conservative"/
    /// "aggressive"); "" = unset. A sing-box 1.14 field (ENGINES §4
    /// row 9): tiers without it keep the value stored, not emitted.
    public var hy2BBRProfile: String
    /// Gecko obfs packet-size bounds; 0 = unset. Emitted only inside a
    /// `gecko` obfs block on tiers that carry gecko (ENGINES §4 row 11).
    public var hy2ObfsMinPacketSize: Int
    public var hy2ObfsMaxPacketSize: Int

    public var tuicCongestionControl: String
    public var tuicUDPRelayMode: String
    /// TUIC heartbeat seconds (the link's `heartbeat` parameter); 0 = unset.
    public var tuicHeartbeat: Int
    /// VLESS encryption parameter of the link; "" = unset ("none" in links).
    public var encryption: String
    /// TUIC v4 token authentication (alternative to uuid:password).
    public var tuicToken: String

    public var wgPrivateKey: String
    public var wgPeerPublicKey: String
    public var wgPreSharedKey: String
    public var wgReserved: [UInt8]
    public var wgLocalAddresses: [String]
    public var wgAllowedIPs: [String]
    public var wgPersistentKeepalive: Int
    /// Explicit peer endpoint ("host:port") when it differs from
    /// address:port, e.g. from a .conf [Peer] section.
    public var wgPeerEndpoint: String?
    public var awg: AWGSpec?

    // Convenience aliases over the canonical fields above (single source
    // of truth; these never store anything themselves).
    /// First local interface address, sing-box spelling.
    public var wgAddress: String? { wgLocalAddresses.first }
    /// Persistent keepalive, seconds.
    public var wgKeepalive: Int? { wgPersistentKeepalive == 0 ? nil : wgPersistentKeepalive }
    /// TUIC congestion control, short alias.
    public var tuicCongestion: String? { tuicCongestionControl.isEmpty ? nil : tuicCongestionControl }

    public var transport: TransportSpec
    public var tls: TLSSpec
    public var muxEnabled: Bool
    public var subscriptionID: String?

    public init(name: String = "", protocol: ProxyProtocol, address: String, port: Int,
                uuid: String = "", password: String = "", method: String = "",
                plugin: String = "", pluginOptions: String = "", vmessSecurity: String = "",
                flow: String = "", ss2022Key: String = "",
                hy2Obfs: String = "", hy2ObfsPassword: String = "",
                hy2UpMbps: Int = 0, hy2DownMbps: Int = 0, hy2HopPorts: String = "",
                hy2HopInterval: Int = 0, hy2HopIntervalMax: Int = 0, hy2BBRProfile: String = "",
                hy2ObfsMinPacketSize: Int = 0, hy2ObfsMaxPacketSize: Int = 0,
                tuicCongestionControl: String = "", tuicUDPRelayMode: String = "",
                tuicToken: String = "", tuicHeartbeat: Int = 0, encryption: String = "",
                wgPrivateKey: String = "", wgPeerPublicKey: String = "",
                wgPreSharedKey: String = "", wgReserved: [UInt8] = [],
                wgLocalAddresses: [String] = [], wgAllowedIPs: [String] = [],
                wgPersistentKeepalive: Int = 0, wgPeerEndpoint: String? = nil, awg: AWGSpec? = nil,
                transport: TransportSpec = TransportSpec(), tls: TLSSpec = TLSSpec(),
                muxEnabled: Bool = false, subscriptionID: String? = nil) {
        self.name = name; self.protocol = `protocol`; self.address = address; self.port = port
        self.uuid = uuid; self.password = password; self.method = method
        self.plugin = plugin; self.pluginOptions = pluginOptions
        self.vmessSecurity = vmessSecurity; self.flow = flow; self.ss2022Key = ss2022Key
        self.hy2Obfs = hy2Obfs; self.hy2ObfsPassword = hy2ObfsPassword
        self.hy2UpMbps = hy2UpMbps; self.hy2DownMbps = hy2DownMbps; self.hy2HopPorts = hy2HopPorts
        self.hy2HopInterval = hy2HopInterval; self.hy2HopIntervalMax = hy2HopIntervalMax
        self.hy2BBRProfile = hy2BBRProfile
        self.hy2ObfsMinPacketSize = hy2ObfsMinPacketSize
        self.hy2ObfsMaxPacketSize = hy2ObfsMaxPacketSize
        self.tuicCongestionControl = tuicCongestionControl
        self.tuicUDPRelayMode = tuicUDPRelayMode; self.tuicToken = tuicToken
        self.tuicHeartbeat = tuicHeartbeat; self.encryption = encryption
        self.wgPrivateKey = wgPrivateKey; self.wgPeerPublicKey = wgPeerPublicKey
        self.wgPreSharedKey = wgPreSharedKey; self.wgReserved = wgReserved
        self.wgLocalAddresses = wgLocalAddresses; self.wgAllowedIPs = wgAllowedIPs
        self.wgPersistentKeepalive = wgPersistentKeepalive
        self.wgPeerEndpoint = wgPeerEndpoint; self.awg = awg
        self.transport = transport; self.tls = tls
        self.muxEnabled = muxEnabled; self.subscriptionID = subscriptionID
        self.id = ServerProfile.stableID(protocol: `protocol`, address: address, port: port,
                                         uuid: uuid, password: password, method: method)
    }

    /// Canonical identity string, built field-by-field in a fixed order with
    /// NUL separators — never via JSONEncoder, DateFormatter, Locale or any
    /// other platform/version-dependent formatting, so the same profile
    /// yields the same id on every OS version (mirrors Go's StableKey
    /// material: protocol, host, port, UUID, user; passwords are excluded
    /// for the UUID protocols exactly as in Go, while the password-only
    /// protocols identify by their credential and Shadowsocks by method).
    public static func stableID(protocol proto: ProxyProtocol, address: String, port: Int,
                                uuid: String, password: String, method: String) -> String {
        let protoName: String
        switch proto {
        case .amneziaWG: protoName = "wireguard"
        default: protoName = proto.rawValue
        }
        let user: String
        switch proto {
        case .shadowsocks: user = method
        case .trojan, .hysteria2, .anytls: user = password
        default: user = ""
        }
        let material = protoName + "\u{0}" + address + "\u{0}" + String(port) + "\u{0}" + uuid + "\u{0}" + user
        let digest = SHA256.hash([UInt8](material.utf8))
        return protoName + ":" + address + ":" + String(port) + ":" + SHA256.hex(Data(digest.prefix(8)))
    }

    /// Recomputes `id` after direct field mutation.
    public mutating func refreshID() {
        id = ServerProfile.stableID(protocol: `protocol`, address: address, port: port,
                                    uuid: uuid, password: password, method: method)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, `protocol`, address, port, uuid, password, method, plugin, pluginOptions
        case vmessSecurity, flow, ss2022Key, hy2Obfs, hy2ObfsPassword, hy2UpMbps, hy2DownMbps
        case hy2HopPorts, hy2HopInterval, hy2HopIntervalMax, hy2BBRProfile
        case hy2ObfsMinPacketSize, hy2ObfsMaxPacketSize
        case tuicCongestionControl, tuicUDPRelayMode, tuicToken, tuicHeartbeat, encryption
        case wgPrivateKey, wgPeerPublicKey, wgPreSharedKey, wgReserved, wgLocalAddresses
        case wgAllowedIPs, wgPersistentKeepalive, wgPeerEndpoint, awg, transport, tls, muxEnabled, subscriptionID
    }

    // Additive-only decoding: unknown keys are ignored by Codable and every
    // known key tolerates absence, so a document written by an older build
    // decodes in a newer one and vice versa (forward/backward compatible
    // within the same major shape).
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        `protocol` = try c.decodeIfPresent(ProxyProtocol.self, forKey: .protocol) ?? .vless
        address = try c.decodeIfPresent(String.self, forKey: .address) ?? ""
        port = try c.decodeIfPresent(Int.self, forKey: .port) ?? 0
        uuid = try c.decodeIfPresent(String.self, forKey: .uuid) ?? ""
        password = try c.decodeIfPresent(String.self, forKey: .password) ?? ""
        method = try c.decodeIfPresent(String.self, forKey: .method) ?? ""
        plugin = try c.decodeIfPresent(String.self, forKey: .plugin) ?? ""
        pluginOptions = try c.decodeIfPresent(String.self, forKey: .pluginOptions) ?? ""
        vmessSecurity = try c.decodeIfPresent(String.self, forKey: .vmessSecurity) ?? ""
        flow = try c.decodeIfPresent(String.self, forKey: .flow) ?? ""
        ss2022Key = try c.decodeIfPresent(String.self, forKey: .ss2022Key) ?? ""
        hy2Obfs = try c.decodeIfPresent(String.self, forKey: .hy2Obfs) ?? ""
        hy2ObfsPassword = try c.decodeIfPresent(String.self, forKey: .hy2ObfsPassword) ?? ""
        hy2UpMbps = try c.decodeIfPresent(Int.self, forKey: .hy2UpMbps) ?? 0
        hy2DownMbps = try c.decodeIfPresent(Int.self, forKey: .hy2DownMbps) ?? 0
        hy2HopPorts = try c.decodeIfPresent(String.self, forKey: .hy2HopPorts) ?? ""
        hy2HopInterval = try c.decodeIfPresent(Int.self, forKey: .hy2HopInterval) ?? 0
        hy2HopIntervalMax = try c.decodeIfPresent(Int.self, forKey: .hy2HopIntervalMax) ?? 0
        hy2BBRProfile = try c.decodeIfPresent(String.self, forKey: .hy2BBRProfile) ?? ""
        hy2ObfsMinPacketSize = try c.decodeIfPresent(Int.self, forKey: .hy2ObfsMinPacketSize) ?? 0
        hy2ObfsMaxPacketSize = try c.decodeIfPresent(Int.self, forKey: .hy2ObfsMaxPacketSize) ?? 0
        tuicCongestionControl = try c.decodeIfPresent(String.self, forKey: .tuicCongestionControl) ?? ""
        tuicUDPRelayMode = try c.decodeIfPresent(String.self, forKey: .tuicUDPRelayMode) ?? ""
        tuicToken = try c.decodeIfPresent(String.self, forKey: .tuicToken) ?? ""
        tuicHeartbeat = try c.decodeIfPresent(Int.self, forKey: .tuicHeartbeat) ?? 0
        encryption = try c.decodeIfPresent(String.self, forKey: .encryption) ?? ""
        wgPrivateKey = try c.decodeIfPresent(String.self, forKey: .wgPrivateKey) ?? ""
        wgPeerPublicKey = try c.decodeIfPresent(String.self, forKey: .wgPeerPublicKey) ?? ""
        wgPreSharedKey = try c.decodeIfPresent(String.self, forKey: .wgPreSharedKey) ?? ""
        wgReserved = try c.decodeIfPresent([UInt8].self, forKey: .wgReserved) ?? []
        wgLocalAddresses = try c.decodeIfPresent([String].self, forKey: .wgLocalAddresses) ?? []
        wgAllowedIPs = try c.decodeIfPresent([String].self, forKey: .wgAllowedIPs) ?? []
        wgPersistentKeepalive = try c.decodeIfPresent(Int.self, forKey: .wgPersistentKeepalive) ?? 0
        wgPeerEndpoint = try c.decodeIfPresent(String.self, forKey: .wgPeerEndpoint)
        awg = try c.decodeIfPresent(AWGSpec.self, forKey: .awg)
        transport = try c.decodeIfPresent(TransportSpec.self, forKey: .transport) ?? TransportSpec()
        tls = try c.decodeIfPresent(TLSSpec.self, forKey: .tls) ?? TLSSpec()
        muxEnabled = try c.decodeIfPresent(Bool.self, forKey: .muxEnabled) ?? false
        subscriptionID = try c.decodeIfPresent(String.self, forKey: .subscriptionID)
        // A stored id is data, not truth: recompute it from the identity
        // fields so a document written by any build maps to the same id.
        id = ServerProfile.stableID(protocol: `protocol`, address: address, port: port,
                                    uuid: uuid, password: password, method: method)
    }
}
