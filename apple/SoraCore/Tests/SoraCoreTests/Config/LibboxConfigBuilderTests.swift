import XCTest
@testable import SoraCore

final class LibboxConfigBuilderTests: XCTestCase {
    private let settings = AppSettings()

    private func build(_ p: ServerProfile, settings: AppSettings? = nil) throws -> [String: Any] {
        JSONTestHelper.parse(try LibboxConfigBuilder.build(profile: p, settings: settings ?? self.settings))
    }

    // MARK: Golden per protocol (structural)

    func testGoldenVLESSRealityVision() throws {
        let cfg = try build(ProfileFixtures.vless)
        let proxy = JSONTestHelper.proxy(cfg)
        XCTAssertEqual(proxy["type"] as? String, "vless")
        XCTAssertEqual(proxy["uuid"] as? String, ProfileFixtures.uuid)
        XCTAssertEqual(proxy["flow"] as? String, "xtls-rprx-vision")
        XCTAssertEqual(proxy["packet_encoding"] as? String, "xudp")
        let tls = proxy["tls"] as! [String: Any]
        XCTAssertEqual(tls["server_name"] as? String, "www.example.com")
        let reality = tls["reality"] as! [String: Any]
        XCTAssertEqual(reality["public_key"] as? String, ProfileFixtures.realityKey)
        XCTAssertEqual(reality["short_id"] as? String, "6ba85179e30d4fc2")
        let utls = tls["utls"] as! [String: Any]
        XCTAssertEqual(utls["fingerprint"] as? String, "chrome")
        XCTAssertNil(proxy["multiplex"], "vision must not carry mux")
    }

    func testGoldenVMessWebSocket() throws {
        let cfg = try build(ProfileFixtures.vmess)
        let proxy = JSONTestHelper.proxy(cfg)
        XCTAssertEqual(proxy["type"] as? String, "vmess")
        XCTAssertEqual(proxy["security"] as? String, "auto")
        let transport = proxy["transport"] as! [String: Any]
        XCTAssertEqual(transport["type"] as? String, "ws")
        XCTAssertEqual(transport["path"] as? String, "/ws")
        XCTAssertEqual((transport["headers"] as? [String: String])?["Host"], "cdn.example.com")
    }

    func testGoldenTrojanGRPC() throws {
        let cfg = try build(ProfileFixtures.trojan)
        let proxy = JSONTestHelper.proxy(cfg)
        XCTAssertEqual(proxy["type"] as? String, "trojan")
        XCTAssertEqual(proxy["password"] as? String, "trojan-test-password")
        XCTAssertEqual((proxy["transport"] as? [String: Any])?["service_name"] as? String, "tunnel")
        XCTAssertNotNil(proxy["tls"], "trojan forces TLS")
    }

    func testGoldenShadowsocks2022() throws {
        let cfg = try build(ProfileFixtures.shadowsocks)
        let proxy = JSONTestHelper.proxy(cfg)
        XCTAssertEqual(proxy["type"] as? String, "shadowsocks")
        XCTAssertEqual(proxy["method"] as? String, "2022-blake3-aes-128-gcm")
        XCTAssertEqual(proxy["password"] as? String, "MTIzNDU2Nzg5MDEyMzQ1Ng==")
    }

    func testGoldenHysteria2BandwidthHoppingObfs() throws {
        var p = ProfileFixtures.hysteria2
        p.hy2UpMbps = 50
        p.hy2DownMbps = 200
        p.hy2HopPorts = "20000-30000,40000"
        let proxy = JSONTestHelper.proxy(try build(p))
        XCTAssertEqual(proxy["up_mbps"] as? Int, 50)
        XCTAssertEqual(proxy["down_mbps"] as? Int, 200)
        XCTAssertEqual(proxy["server_ports"] as? [String], ["20000:30000", "40000:40000"])
        XCTAssertEqual((proxy["obfs"] as? [String: Any])?["type"] as? String, "salamander")
    }

    func testGoldenTUICDefaults() throws {
        let proxy = JSONTestHelper.proxy(try build(ProfileFixtures.tuic))
        XCTAssertEqual(proxy["type"] as? String, "tuic")
        XCTAssertEqual(proxy["congestion_control"] as? String, "bbr")
        XCTAssertEqual(proxy["heartbeat"] as? String, "10s")
    }

    func testGoldenWireGuardIsEndpoint() throws {
        let cfg = try build(ProfileFixtures.wireguard)
        let endpoints = cfg["endpoints"] as! [[String: Any]]
        XCTAssertEqual(endpoints.count, 1)
        XCTAssertEqual(endpoints[0]["type"] as? String, "wireguard")
        XCTAssertEqual(endpoints[0]["mtu"] as? Int, 1420)
        XCTAssertFalse(JSONTestHelper.outbounds(cfg).contains { $0["type"] as? String == "wireguard" })
        let peer = (endpoints[0]["peers"] as! [[String: Any]])[0]
        XCTAssertEqual(peer["address"] as? String, "198.51.100.7")
        XCTAssertEqual(peer["port"] as? Int, 51820)
        XCTAssertEqual(peer["persistent_keepalive_interval"] as? Int, 25)
    }

    func testGoldenAmneziaWG() throws {
        let cfg = try build(ProfileFixtures.amneziaWG)
        let endpoint = (cfg["endpoints"] as! [[String: Any]])[0]
        XCTAssertEqual(endpoint["mtu"] as? Int, 1280)
        XCTAssertEqual(endpoint["jc"] as? Int, 4)
        XCTAssertEqual(endpoint["jmin"] as? Int, 40)
        XCTAssertEqual(endpoint["h1"] as? String, "100000-100100")
        XCTAssertNotNil(endpoint["i1"])
    }

    func testGoldenAmneziaWG31() throws {
        var p = ProfileFixtures.amneziaWG
        p.awg?.h1 = "1"; p.awg?.h2 = "2"; p.awg?.h3 = "3"; p.awg?.h4 = "4"
        p.awg?.s3 = 12; p.awg?.s4 = 12
        p.awg?.headerProtectionKey = "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY="
        p.awg?.contentPaddingAddition = "32-96"
        p.awg?.randomTrailers = true
        p.awg?.masqueradeProtocol = "quic"
        p.awg?.masqueradeDomain = "www.google.com"
        p.awg?.masqueradeBrowser = "chrome"
        let cfg = try build(p)
        let endpoint = (cfg["endpoints"] as! [[String: Any]])[0]
        XCTAssertEqual(endpoint["header_protection_key"] as? String,
                       "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=")
        XCTAssertEqual(endpoint["content_padding_addition"] as? String, "32-96")
        XCTAssertEqual(endpoint["random_trailers"] as? Bool, true)
        XCTAssertEqual(endpoint["id"] as? String, "www.google.com")
        XCTAssertEqual(endpoint["ip"] as? String, "quic")
        XCTAssertEqual(endpoint["ib"] as? String, "chrome")
    }

    // MARK: Common sections

    func testCommonSections() throws {
        let cfg = try build(ProfileFixtures.vless)
        let tags = JSONTestHelper.outbounds(cfg).compactMap { $0["tag"] as? String }
        XCTAssertTrue(tags.contains("direct") && tags.contains("block") && tags.contains("dns-out"))
        XCTAssertEqual(JSONTestHelper.route(cfg)["final"] as? String, "proxy")
        let dns = JSONTestHelper.dns(cfg)
        let serverTypes = (dns["servers"] as! [[String: Any]]).compactMap { $0["type"] as? String }
        XCTAssertTrue(serverTypes.contains("fakeip"), "fakeip server must be present")
        XCTAssertEqual((cfg["log"] as! [String: Any])["level"] as? String, "warn")
    }

    func testDeterministicOutput() throws {
        let a = try LibboxConfigBuilder.build(profile: ProfileFixtures.hysteria2, settings: settings)
        let b = try LibboxConfigBuilder.build(profile: ProfileFixtures.hysteria2, settings: settings)
        XCTAssertEqual(a, b)
    }

    // MARK: Chain

    func testChainTwoHopsUsesDetour() throws {
        let cfg = JSONTestHelper.parse(try LibboxConfigBuilder.buildChain(
            profiles: [ProfileFixtures.trojan, ProfileFixtures.vless], settings: settings))
        let proxy = JSONTestHelper.proxy(cfg)
        XCTAssertEqual(proxy["type"] as? String, "vless", "last profile is the exit")
        XCTAssertEqual(proxy["detour"] as? String, "proxy-hop-1")
        let hop = JSONTestHelper.outbounds(cfg).first { $0["tag"] as? String == "proxy-hop-1" }!
        XCTAssertEqual(hop["type"] as? String, "trojan")
        XCTAssertNil(hop["detour"], "entry hop dials directly")
        XCTAssertEqual(JSONTestHelper.route(cfg)["final"] as? String, "proxy")
    }

    // MARK: Kill switch

    func testKillSwitchOnOffDifference() throws {
        let on = try build(ProfileFixtures.vless, settings: AppSettings(killSwitch: true))
        let off = try build(ProfileFixtures.vless, settings: AppSettings(killSwitch: false))
        XCTAssertEqual(JSONTestHelper.tun(on)["strict_route"] as? Bool, true)
        XCTAssertEqual(JSONTestHelper.tun(off)["strict_route"] as? Bool, false)
    }

    func testKillSwitchBlockOnFailureAddsBlockRule() throws {
        var caps = PlatformCapabilities()
        caps.killSwitchBehavior = .blockOnFailure
        let cfg = try build(ProfileFixtures.vless,
                            settings: AppSettings(killSwitch: true, capabilities: caps))
        let rules = JSONTestHelper.route(cfg)["rules"] as! [[String: Any]]
        XCTAssertTrue(rules.contains { $0["outbound"] as? String == "block" })
    }

    func testBypassLANAddsPrivateDirectRule() throws {
        let cfg = try build(ProfileFixtures.vless, settings: AppSettings(bypassLAN: true))
        let rules = JSONTestHelper.route(cfg)["rules"] as! [[String: Any]]
        XCTAssertTrue(rules.contains {
            $0["ip_is_private"] as? Bool == true && $0["outbound"] as? String == "direct"
        })
    }

    // MARK: Platform capabilities

    func testCapabilityTUNStackBothValues() throws {
        var caps = PlatformCapabilities()
        caps.tunStack = .system
        let system = try build(ProfileFixtures.vless, settings: AppSettings(capabilities: caps))
        XCTAssertEqual(JSONTestHelper.tun(system)["stack"] as? String, "system")
        caps.tunStack = .gvisor
        let gvisor = try build(ProfileFixtures.vless, settings: AppSettings(capabilities: caps))
        XCTAssertEqual(JSONTestHelper.tun(gvisor)["stack"] as? String, "gvisor")
        let auto = try build(ProfileFixtures.vless)
        XCTAssertEqual(JSONTestHelper.tun(auto)["stack"] as? String, "mixed", "auto resolves to the Go default")
    }

    func testCapabilityIPv6BothValues() throws {
        var caps = PlatformCapabilities()
        caps.ipv6InTunnel = false
        let v4 = try build(ProfileFixtures.vless, settings: AppSettings(capabilities: caps))
        XCTAssertEqual(JSONTestHelper.tun(v4)["address"] as? [String], ["172.19.0.1/30"])
        XCTAssertEqual(JSONTestHelper.dns(v4)["strategy"] as? String, "ipv4_only")
        caps.ipv6InTunnel = true
        let v6 = try build(ProfileFixtures.vless, settings: AppSettings(capabilities: caps))
        XCTAssertEqual((JSONTestHelper.tun(v6)["address"] as? [String])?.count, 2)
        XCTAssertEqual(JSONTestHelper.dns(v6)["strategy"] as? String, "prefer_ipv6")
        let fakeip = (JSONTestHelper.dns(v6)["servers"] as! [[String: Any]])
            .first { $0["type"] as? String == "fakeip" }!
        XCTAssertEqual(fakeip["inet6_range"] as? String, "fc00::/18")
    }

    func testSplitTunnelRoutes() throws {
        let cfg = try build(ProfileFixtures.vless, settings: AppSettings(
            splitTunnelExcludedRoutes: ["10.0.0.0/8"], splitTunnelIncludedRoutes: ["0.0.0.0/0"]))
        let tun = JSONTestHelper.tun(cfg)
        XCTAssertEqual(tun["route_exclude_address"] as? [String], ["10.0.0.0/8"])
        XCTAssertEqual(tun["route_address"] as? [String], ["0.0.0.0/0"])
    }
}
