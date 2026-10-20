import Foundation
@testable import SoraCore

/// One canonical profile per protocol, mirroring the Go enginetest
/// vectors (same UUID, REALITY key and test passwords) so Swift goldens
/// and Go renders describe the same servers.
enum ProfileFixtures {
    static let uuid = "b831381d-6324-4d53-ad4f-8cda48b30811"
    static let realityKey = "Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw"
    static let wgPrivateKey = "cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk="
    static let wgPeerKey = "Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw="

    static var vless: ServerProfile {
        var p = ServerProfile(name: "Test vless", protocol: .vless,
                              address: "edge.example.com", port: 443)
        p.uuid = uuid
        p.flow = "xtls-rprx-vision"
        p.tls = TLSSpec(enabled: true, serverName: "www.example.com",
                        fingerprint: "chrome",
                        reality: RealitySpec(publicKey: realityKey,
                                             shortId: "6ba85179e30d4fc2"))
        p.refreshID()
        return p
    }

    static var vmess: ServerProfile {
        var p = ServerProfile(name: "Test vmess", protocol: .vmess,
                              address: "edge.example.com", port: 443)
        p.uuid = uuid
        p.transport = TransportSpec(type: "ws", path: "/ws", host: "cdn.example.com")
        p.tls = TLSSpec(enabled: true, serverName: "cdn.example.com")
        p.refreshID()
        return p
    }

    static var trojan: ServerProfile {
        var p = ServerProfile(name: "Test trojan", protocol: .trojan,
                              address: "edge.example.com", port: 443)
        p.password = "trojan-test-password"
        p.transport = TransportSpec(type: "grpc", serviceName: "tunnel")
        p.tls = TLSSpec(enabled: true, serverName: "edge.example.com", alpn: ["h2"])
        p.refreshID()
        return p
    }

    static var shadowsocks: ServerProfile {
        var p = ServerProfile(name: "Test shadowsocks", protocol: .shadowsocks,
                              address: "edge.example.com", port: 443)
        p.method = "2022-blake3-aes-128-gcm"
        p.ss2022Key = "MTIzNDU2Nzg5MDEyMzQ1Ng=="
        p.refreshID()
        return p
    }

    static var hysteria2: ServerProfile {
        var p = ServerProfile(name: "Test hysteria2", protocol: .hysteria2,
                              address: "edge.example.com", port: 443)
        p.password = "hy2-test-password"
        p.hy2Obfs = "salamander"
        p.hy2ObfsPassword = "obfs-test-password"
        p.tls = TLSSpec(enabled: true, serverName: "edge.example.com")
        p.refreshID()
        return p
    }

    static var tuic: ServerProfile {
        var p = ServerProfile(name: "Test tuic", protocol: .tuic,
                              address: "edge.example.com", port: 443)
        p.uuid = uuid
        p.password = "tuic-test-password"
        p.tls = TLSSpec(enabled: true, serverName: "edge.example.com", alpn: ["h3"])
        p.refreshID()
        return p
    }

    static var wireguard: ServerProfile {
        var p = ServerProfile(name: "Test wireguard", protocol: .wireguard,
                              address: "198.51.100.7", port: 51820)
        p.wgPrivateKey = wgPrivateKey
        p.wgPeerPublicKey = wgPeerKey
        p.wgLocalAddresses = ["10.7.0.2/32"]
        p.wgPersistentKeepalive = 25
        p.refreshID()
        return p
    }

    static var amneziaWG: ServerProfile {
        var p = ServerProfile(name: "Test amneziawg", protocol: .amneziaWG,
                              address: "198.51.100.7", port: 51820)
        p.wgPrivateKey = wgPrivateKey
        p.wgPeerPublicKey = wgPeerKey
        p.wgLocalAddresses = ["10.7.0.2/32"]
        p.wgPersistentKeepalive = 25
        p.awg = AWGSpec(jc: 4, jmin: 40, jmax: 70, s1: 15, s2: 25, s3: 10, s4: 5,
                        h1: "100000-100100", h2: "200000-200100",
                        h3: "300000", h4: "400000",
                        i1: "<b 0xf6ab3267fa><c><b 0xf6ab><t><r 10><wt 10>")
        p.refreshID()
        return p
    }

    static let all: [ServerProfile] = [vless, vmess, trojan, shadowsocks,
                                       hysteria2, tuic, wireguard, amneziaWG]
}

/// Parses a built config back into JSON objects: golden tests compare
/// structure, never raw strings (key order is an encoder detail, the
/// structure is the contract).
enum JSONTestHelper {
    static func parse(_ string: String) -> [String: Any] {
        let data = Data(string.utf8)
        return try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    }
    static func outbounds(_ cfg: [String: Any]) -> [[String: Any]] {
        cfg["outbounds"] as! [[String: Any]]
    }
    static func proxy(_ cfg: [String: Any]) -> [String: Any] {
        outbounds(cfg).first { $0["tag"] as? String == "proxy" }!
    }
    static func tun(_ cfg: [String: Any]) -> [String: Any] {
        (cfg["inbounds"] as! [[String: Any]]).first { $0["type"] as? String == "tun" }!
    }
    static func route(_ cfg: [String: Any]) -> [String: Any] {
        cfg["route"] as! [String: Any]
    }
    static func dns(_ cfg: [String: Any]) -> [String: Any] {
        cfg["dns"] as! [String: Any]
    }
}
