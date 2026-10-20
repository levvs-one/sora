import XCTest
@testable import SoraCore

final class SubscriptionParserTests: XCTestCase {
    let uuid = "123e4567-e89b-12d3-a456-426614174000"

    func testPlainLinkListWithBrokenLine() {
        let text = """
        vless://\(uuid)@a.example:443#One
        openvpn://vpn.example.com:1194
        trojan://pw@b.example:443#Two
        vless://bad-uuid@a.example:443#Broken
        """
        let r = SubscriptionParser.parse(Data(text.utf8))
        XCTAssertEqual(r.profiles.count, 2)
        XCTAssertEqual(r.skipped.count, 2)
        XCTAssertEqual(r.skipped[0].reason, "unsupported link")
        XCTAssertEqual(r.skipped[1].reason, "invalid link")
    }

    func testBase64BlobOfLinks() {
        // Go TestBase64Wrapped shape, plus newline-split encoding.
        let raw = "vless://\(uuid)@example.com:443\nss://YWVzLTI1Ni1nY206cGFzcw@example.com:8388#SS\n"
        let enc = Base64.encode(Data(raw.utf8))
        let r = SubscriptionParser.parse(Data(enc.utf8))
        XCTAssertEqual(r.profiles.count, 2)
        XCTAssertEqual(r.profiles[1].protocol, .shadowsocks)
    }

    func testDuplicateLinksSkipped() {
        let text = "vless://\(uuid)@a.example:443#One\nvless://\(uuid)@a.example:443#Two"
        let r = SubscriptionParser.parse(Data(text.utf8))
        XCTAssertEqual(r.profiles.count, 1)
        XCTAssertEqual(r.skipped.first?.reason, "duplicate server")
    }

    func testSingBoxJSON() {
        let json = """
        {"outbounds":[
          {"type":"vless","tag":"First","server":"a.example.com","server_port":443,"uuid":"\(uuid)",
           "tls":{"enabled":true,"server_name":"a.example.com","utls":{"enabled":true,"fingerprint":"chrome"}},
           "transport":{"type":"ws","path":"/ws"}},
          {"type":"direct","tag":"direct"},
          {"type":"hysteria2","tag":"H","server":"h.example.com","server_port":443,"password":"pw","up_mbps":20,"down_mbps":100}
        ]}
        """
        let r = SubscriptionParser.parse(Data(json.utf8))
        XCTAssertEqual(r.profiles.count, 2)
        XCTAssertEqual(r.profiles[0].transport.type, "ws")
        XCTAssertEqual(r.profiles[0].tls.fingerprint, "chrome")
        XCTAssertEqual(r.profiles[1].hy2UpMbps, 20)
        XCTAssertEqual(r.skipped.first?.reason, "unsupported server")
    }

    func testSIP008() {
        // Go TestParseSIP008ImportsShadowsocksServers vector (incl. dedup).
        let json = """
        {"version":1,"servers":[
          {"id":"1","remarks":"tokyo","server":"tokyo.example.com","server_port":8388,"password":"pw1","method":"aes-256-gcm"},
          {"id":"2","remarks":"osaka","server":"osaka.example.com","server_port":8389,"password":"pw2","method":"chacha20-ietf-poly1305","plugin":"v2ray-plugin","plugin_opts":"tls;host=cdn.example.com"},
          {"id":"3","remarks":"tokyo-again","server":"tokyo.example.com","server_port":8388,"password":"pw1","method":"aes-256-gcm"}
        ]}
        """
        let r = SubscriptionParser.parse(Data(json.utf8))
        XCTAssertEqual(r.profiles.count, 2)
        XCTAssertEqual(r.profiles[0].protocol, .shadowsocks)
        XCTAssertEqual(r.profiles[0].name, "tokyo")
        XCTAssertEqual(r.profiles[1].plugin, "v2ray-plugin")
        XCTAssertEqual(r.profiles[1].pluginOptions, "tls;host=cdn.example.com")
        XCTAssertEqual(r.skipped.first?.reason, "duplicate server")
    }

    func testClashFlowStyleWithDuplicates() {
        // Go TestParseClashDuplicatesByStableKey vector.
        let yaml = """
        proxies:
          - {name: First, type: vless, server: a.example.com, port: 443, uuid: \(uuid)}
          - {name: Second, type: vless, server: a.example.com, port: 443, uuid: \(uuid)}
        """
        let r = SubscriptionParser.parse(Data(yaml.utf8))
        XCTAssertEqual(r.profiles.count, 1)
        XCTAssertEqual(r.profiles[0].name, "First")
        XCTAssertEqual(r.skipped.first?.reason, "duplicate server")
    }

    func testClashBlockStyle() {
        let yaml = """
        port: 7890
        proxies:
          - name: Trojan NL
            type: trojan
            server: nl.example.com
            port: 443
            password: s3cret
            sni: nl.example.com
            skip-cert-verify: true
          - name: SS
            type: ss
            server: ss.example.com
            port: 8388
            cipher: aes-256-gcm
            password: pass
        rules:
          - MATCH,Proxy
        """
        let r = SubscriptionParser.parse(Data(yaml.utf8))
        XCTAssertEqual(r.profiles.count, 2)
        XCTAssertEqual(r.profiles[0].protocol, .trojan)
        XCTAssertEqual(r.profiles[0].password, "s3cret")
        XCTAssertTrue(r.profiles[0].tls.allowInsecure)
        XCTAssertEqual(r.profiles[1].protocol, .shadowsocks)
        XCTAssertEqual(r.profiles[1].method, "aes-256-gcm")
    }

    func testWireGuardConfWithAWG() {
        let conf = """
        [Interface]
        PrivateKey = cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk=
        Address = 10.0.0.2/32
        Jc = 4
        Jmin = 40
        Jmax = 70
        S1 = 15
        S2 = 25
        H1 = 100000-100100
        H2 = 200000
        I1 = <b 0xf6ab>

        [Peer]
        PublicKey = peerkey=
        Endpoint = 198.51.100.7:51820
        AllowedIPs = 0.0.0.0/0
        PersistentKeepalive = 25
        """
        let r = SubscriptionParser.parse(Data(conf.utf8))
        XCTAssertEqual(r.profiles.count, 1)
        let p = r.profiles[0]
        XCTAssertEqual(p.protocol, .amneziaWG)
        XCTAssertEqual(p.wgPrivateKey, "cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk=")
        XCTAssertEqual(p.wgPeerPublicKey, "peerkey=")
        XCTAssertEqual(p.wgLocalAddresses, ["10.0.0.2/32"])
        XCTAssertEqual(p.wgPersistentKeepalive, 25)
        XCTAssertEqual(p.awg?.jc, 4)
        XCTAssertEqual(p.awg?.h1, "100000-100100")
        XCTAssertEqual(p.awg?.i1, "<b 0xf6ab>")
    }

    func testEmptyAndGarbage() {
        XCTAssertEqual(SubscriptionParser.parse(Data()).skipped.first?.reason, "empty subscription")
        let r = SubscriptionParser.parse(Data("hello world, no links here".utf8))
        XCTAssertTrue(r.profiles.isEmpty)
        XCTAssertEqual(r.skipped.first?.reason, "unsupported subscription format")
    }
}
