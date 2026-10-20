import XCTest
@testable import SoraCore

final class LinkParserTests: XCTestCase {
    let uuid = "123e4567-e89b-12d3-a456-426614174000"

    // MARK: vless (vectors from core/parser/parser_test.go)

    func testVlessTLSWebSocket() throws {
        let p = try LinkParser.parse("vless://\(uuid)@example.com:443?security=tls&type=ws&path=%2F#Berlin")
        XCTAssertEqual(p.protocol, .vless)
        XCTAssertEqual(p.address, "example.com")
        XCTAssertEqual(p.port, 443)
        XCTAssertEqual(p.uuid, uuid)
        XCTAssertTrue(p.tls.enabled)
        XCTAssertEqual(p.transport.type, "ws")
        XCTAssertEqual(p.transport.path, "/")
        XCTAssertEqual(p.name, "Berlin")
    }

    func testVlessPlainDefaultsToNoTLS() throws {
        let p = try LinkParser.parse("vless://\(uuid)@example.com:443")
        XCTAssertFalse(p.tls.enabled)
        XCTAssertEqual(p.transport.type, "tcp")
    }

    func testVlessRealityAndFingerprint() throws {
        let p = try LinkParser.parse("vless://\(uuid)@example.com:443?security=reality&pbk=PUBKEY&sid=ab12&spx=%2Fspider&fp=chrome&flow=xtls-rprx-vision&sni=cdn.example.com")
        XCTAssertTrue(p.tls.enabled)
        XCTAssertEqual(p.tls.reality?.publicKey, "PUBKEY")
        XCTAssertEqual(p.tls.reality?.shortId, "ab12")
        XCTAssertEqual(p.tls.reality?.spiderX, "/spider")
        XCTAssertEqual(p.tls.fingerprint, "chrome")
        XCTAssertEqual(p.flow, "xtls-rprx-vision")
        XCTAssertEqual(p.tls.serverName, "cdn.example.com")
    }

    func testVlessXHTTPExtraDownloadSettings() throws {
        let extra = "%7B%22downloadSettings%22%3A%7B%22address%22%3A%22down.example.com%22%2C%22port%22%3A8443%7D%7D"
        let p = try LinkParser.parse("vless://\(uuid)@up.example.com:443?type=xhttp&security=tls&extra=\(extra)#X")
        XCTAssertEqual(p.transport.type, "xhttp")
        XCTAssertEqual(p.transport.downloadAddress, "down.example.com")
        XCTAssertEqual(p.transport.downloadPort, 8443)
        // Garbage extra is decoration, never an import error (Go).
        let q = try LinkParser.parse("vless://\(uuid)@up.example.com:443?type=xhttp&extra=%7Bnot%20json#X")
        XCTAssertEqual(q.transport.downloadAddress, "")
        XCTAssertEqual(q.transport.downloadPort, 0)
    }

    func testUUIDVersions1To8Accepted() throws {
        // Go TestParserAcceptsNewerUUIDVersions (RFC 9562 v6–v8 included).
        for id in ["123e4567-e89b-12d3-a456-426614174000",
                   "123e4567-e89b-22d3-a456-426614174000",
                   "123e4567-e89b-32d3-a456-426614174000",
                   "123e4567-e89b-42d3-a456-426614174000",
                   "123e4567-e89b-52d3-a456-426614174000",
                   "123e4567-e89b-62d3-a456-426614174000",
                   "01926f2a-9c6e-7c3b-b9e8-2b1b3f6a4c5d",
                   "123e4567-e89b-82d3-a456-426614174000",
                   "01926F2A-9C6E-7C3B-B9E8-2B1B3F6A4C5D"] {
            let p = try LinkParser.parse("vless://\(id)@a.example:443")
            XCTAssertEqual(p.uuid, id)
        }
    }

    func testInvalidUUIDsRejected() {
        // Go TestParserRejectsInvalidUUIDVersions.
        for id in ["123e4567-e89b-02d3-a456-426614174000",
                   "123e4567-e89b-92d3-a456-426614174000",
                   "123e4567-e89b-42d3-c456-426614174000",
                   "123e4567-e89b-42d3-0456-426614174000",
                   "123e4567-e89b-42d3-a456-42661417400",
                   "123e4567-e89b-42d3-a456-4266141740000",
                   "123e4567-e89b-42d3-a456-42661417400g",
                   "not-a-uuid",
                   "123e4567e89b42d3a456426614174000"] {
            XCTAssertThrowsError(try LinkParser.parse("vless://\(id)@a.example:443")) { e in
                XCTAssertEqual(e as? SoraParseError, .invalidUUID)
            }
        }
    }

    // MARK: trojan

    func testTrojanPasswordLandsInPassword() throws {
        // Go TestParsePasswordOnlyCredentials.
        let p = try LinkParser.parse("trojan://s3cret@example.com:443?sni=example.com#T")
        XCTAssertEqual(p.protocol, .trojan)
        XCTAssertEqual(p.password, "s3cret")
        XCTAssertEqual(p.uuid, "")
        XCTAssertTrue(p.tls.enabled)
        XCTAssertEqual(p.tls.serverName, "example.com")
    }

    func testTrojanGRPC() throws {
        let p = try LinkParser.parse("trojan://s3cret@example.com:443?type=grpc&serviceName=svc&sni=example.com#T")
        XCTAssertEqual(p.transport.type, "grpc")
        XCTAssertEqual(p.transport.serviceName, "svc")
    }

    func testTrojanBadPortRejected() {
        XCTAssertThrowsError(try LinkParser.parse("trojan://s3cret@example.com:99999#T")) { e in
            XCTAssertEqual(e as? SoraParseError, .invalidPort)
        }
        XCTAssertThrowsError(try LinkParser.parse("trojan://s3cret@example.com#T")) { e in
            XCTAssertEqual(e as? SoraParseError, .invalidPort)
        }
    }

    // MARK: shadowsocks

    func testShadowsocksSIP002Base64Userinfo() throws {
        // ss://YWVzLTI1Ni1nY206cGFzcw@… == base64("aes-256-gcm:pass")
        let p = try LinkParser.parse("ss://YWVzLTI1Ni1nY206cGFzcw@example.com:8388#SS")
        XCTAssertEqual(p.protocol, .shadowsocks)
        XCTAssertEqual(p.method, "aes-256-gcm")
        XCTAssertEqual(p.password, "pass")
        XCTAssertEqual(p.port, 8388)
    }

    func testShadowsocksPlainAndPlugin() throws {
        let p = try LinkParser.parse("ss://aes-256-gcm:pass@example.com:8388?plugin=v2ray-plugin%3Btls%3Bhost%3Dexample.com#SS")
        XCTAssertEqual(p.method, "aes-256-gcm")
        XCTAssertEqual(p.password, "pass")
        XCTAssertEqual(p.plugin, "v2ray-plugin")
        XCTAssertEqual(p.pluginOptions, "tls;host=example.com")
        // Split form: plugin_opts wins over the plugin ;-suffix (Go).
        let q = try LinkParser.parse("ss://aes-256-gcm:pass@example.com:8388?plugin=v2ray-plugin%3Btls&plugin_opts=tls%3Bhost%3Dother.example#SS")
        XCTAssertEqual(q.pluginOptions, "tls;host=other.example")
    }

    func testShadowsocks2022CompositeKey() throws {
        let userinfo = Base64.encode(Data("2022-blake3-aes-128-gcm:c2VydmVya2V5MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0:cGVyc29uYWxrZXk=".utf8))
        let p = try LinkParser.parse("ss://\(userinfo)@example.com:8388#SS2022")
        XCTAssertEqual(p.method, "2022-blake3-aes-128-gcm")
        XCTAssertEqual(p.ss2022Key, "c2VydmVya2V5MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0:cGVyc29uYWxrZXk=")
        XCTAssertEqual(p.password, p.ss2022Key)
    }

    func testShadowsocksMissingHostRejected() {
        XCTAssertThrowsError(try LinkParser.parse("ss://YWVzLTI1Ni1nY206cGFzcw@:8388#SS"))
    }

    // MARK: vmess

    func testVMessClassicBase64JSON() throws {
        // Go TestParseClassicVMessJSON vector.
        let doc = #"{"v":"2","ps":"VMess Berlin","add":"vmess.example.com","port":"24444","id":"123e4567-e89b-12d3-a456-426614174000","aid":"0","scy":"aes-128-gcm","net":"ws","type":"none","host":"cdn.example.com","path":"/ws","tls":"tls","sni":"vmess.example.com","alpn":"h2,http/1.1","fp":"chrome"}"#
        let p = try LinkParser.parse("vmess://" + Base64.encode(Data(doc.utf8)))
        XCTAssertEqual(p.protocol, .vmess)
        XCTAssertEqual(p.address, "vmess.example.com")
        XCTAssertEqual(p.port, 24444)
        XCTAssertEqual(p.uuid, uuid)
        XCTAssertEqual(p.vmessSecurity, "aes-128-gcm")
        XCTAssertEqual(p.transport.type, "ws")
        XCTAssertEqual(p.transport.host, "cdn.example.com")
        XCTAssertEqual(p.transport.path, "/ws")
        XCTAssertTrue(p.tls.enabled)
        XCTAssertEqual(p.tls.serverName, "vmess.example.com")
        XCTAssertEqual(p.tls.alpn, ["h2", "http/1.1"])
        XCTAssertEqual(p.tls.fingerprint, "chrome")
        XCTAssertEqual(p.name, "VMess Berlin")
    }

    func testVMessURLStyleAEAD() throws {
        let p = try LinkParser.parse("vmess://\(uuid)@node.example.com:443?type=ws&security=tls&path=%2Fws&host=cdn.example.com&sni=cdn.example.com#VMess")
        XCTAssertEqual(p.protocol, .vmess)
        XCTAssertEqual(p.transport.type, "ws")
        XCTAssertTrue(p.tls.enabled)
    }

    func testVMessGarbageRejected() {
        XCTAssertThrowsError(try LinkParser.parse("vmess://!!!not-base64!!!"))
        XCTAssertThrowsError(try LinkParser.parse("vmess://" + Base64.encode(Data(#"{"add":"","id":""}"#.utf8))))
    }

    // MARK: hysteria2

    func testHysteria2Tuning() throws {
        // Go TestParseHysteria2TuningOptions vector.
        let p = try LinkParser.parse("hysteria2://secret@example.com:443?upmbps=20&downmbps=100&mport=20000-30000%2C40000&hop-interval=30&sni=example.com#H2")
        XCTAssertEqual(p.protocol, .hysteria2)
        XCTAssertEqual(p.password, "secret")
        XCTAssertEqual(p.hy2UpMbps, 20)
        XCTAssertEqual(p.hy2DownMbps, 100)
        XCTAssertEqual(p.hy2HopPorts, "20000-30000,40000")
        XCTAssertTrue(p.tls.enabled)
    }

    func testHysteria2AliasAndObfs() throws {
        let p = try LinkParser.parse("hy2://secret@example.com:443?obfs=salamander&obfs-password=obfspw#H2")
        XCTAssertEqual(p.protocol, .hysteria2)
        XCTAssertEqual(p.hy2Obfs, "salamander")
        XCTAssertEqual(p.hy2ObfsPassword, "obfspw")
    }

    func testHysteria2PinSHA256Refused() {
        // Go TestPinnedHysteria2LinkIsRefusedNotUnpinned.
        XCTAssertThrowsError(try LinkParser.parse("hysteria2://secret@example.com:443?pinSHA256=PEgHXXPzTsMBr6Uf5FYZ9CDpGHuCkSKpAZcJZU1hRVc%3D#H2")) { e in
            XCTAssertEqual(e as? SoraParseError, .unsupportedOption("hy2 pinSHA256 certificate pinning is not implemented"))
        }
    }

    // MARK: tuic

    func testTUICOptions() throws {
        // Go TestParseTUICTuningOptions vector.
        let p = try LinkParser.parse("tuic://\(uuid):pass@example.com:443?congestion_control=cubic&udp_relay_mode=quic#TUIC")
        XCTAssertEqual(p.protocol, .tuic)
        XCTAssertEqual(p.uuid, uuid)
        XCTAssertEqual(p.password, "pass")
        XCTAssertEqual(p.tuicCongestionControl, "cubic")
        XCTAssertEqual(p.tuicUDPRelayMode, "quic")
        XCTAssertTrue(p.tls.enabled)
    }

    func testTUICv4Token() throws {
        let p = try LinkParser.parse("tuic://example.com:443?token=v4secret#TUICv4")
        XCTAssertEqual(p.tuicToken, "v4secret")
    }

    func testTUICInvalidUUIDRejected() {
        XCTAssertThrowsError(try LinkParser.parse("tuic://not-a-uuid:pass@example.com:443")) { e in
            XCTAssertEqual(e as? SoraParseError, .invalidUUID)
        }
    }

    // MARK: wireguard

    func testWireGuardLink() throws {
        let key = "cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk%3D"
        let p = try LinkParser.parse("wireguard://\(key)@198.51.100.7:51820?publickey=peerkey%3D&address=10.0.0.2%2F32&reserved=1%2C2%2C3#WG")
        XCTAssertEqual(p.protocol, .wireguard)
        XCTAssertEqual(p.wgPrivateKey, "cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk=")
        XCTAssertEqual(p.wgPeerPublicKey, "peerkey=")
        XCTAssertEqual(p.wgLocalAddresses, ["10.0.0.2/32"])
        XCTAssertEqual(p.wgReserved, [1, 2, 3])
        XCTAssertEqual(p.port, 51820)
    }

    func testWireGuardAliasAndAWGParams() throws {
        let p = try LinkParser.parse("wg://cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk%3D@198.51.100.7:51820?jc=4&jmin=40&jmax=70&s1=15&s2=25&h1=100000-100100&i1=%3Cb%200x1234%3E#AWG")
        XCTAssertEqual(p.protocol, .wireguard)
        XCTAssertEqual(p.awg?.jc, 4)
        XCTAssertEqual(p.awg?.jmin, 40)
        XCTAssertEqual(p.awg?.jmax, 70)
        XCTAssertEqual(p.awg?.s1, 15)
        XCTAssertEqual(p.awg?.h1, "100000-100100")
        XCTAssertEqual(p.awg?.i1, "<b 0x1234>")
    }

    func testWireGuardBadPortRejected() {
        XCTAssertThrowsError(try LinkParser.parse("wireguard://key@example.com:0"))
    }

    // MARK: unknown schemes

    func testUnknownSchemesRejected() {
        for link in ["openvpn://vpn.example.com:1194", "socks://user:pass@example.com:1080",
                     "https://user:pass@example.com:443", "happ://routing/add/xyz", ""] {
            XCTAssertThrowsError(try LinkParser.parse(link), "link: \(link)")
        }
        XCTAssertThrowsError(try LinkParser.parse("openvpn://vpn.example.com:1194")) { e in
            XCTAssertEqual(e as? SoraParseError, .unsupportedScheme("openvpn"))
        }
    }
}
