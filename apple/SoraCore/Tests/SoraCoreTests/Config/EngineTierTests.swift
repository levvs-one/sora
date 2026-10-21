import XCTest
@testable import SoraCore

/// Tier golden tests: the same profiles rendered for each engine pin
/// must differ exactly where ENGINES §4/§5 say the pins differ — and
/// nowhere else. External verification (the generated configs through
/// the real lx.15 and 1.11.15 binaries) is driven by
/// `testExportTierConfigsForExternalCheck` + the check run recorded in
/// reports/legacy-systems/CORE.md.
final class EngineTierTests: XCTestCase {
    private let settings = AppSettings()

    private func build(_ p: ServerProfile, tier: EngineTier,
                         settings: AppSettings? = nil) throws -> [String: Any] {
        JSONTestHelper.parse(try LibboxConfigBuilder.build(
            profile: p, settings: settings ?? self.settings, tier: tier))
    }

    // MARK: Fixtures

    private var vlessXHTTP: ServerProfile {
        var p = ServerProfile(name: "Test xhttp", protocol: .vless,
                              address: "edge.example.com", port: 443)
        p.uuid = ProfileFixtures.uuid
        p.transport = TransportSpec(type: "xhttp", path: "/xhttp", host: "cdn.example.com")
        p.tls = TLSSpec(enabled: true, serverName: "cdn.example.com", fingerprint: "chrome")
        p.refreshID()
        return p
    }

    /// Hysteria2 carrying every 1.14 tuning field (hop_interval_max,
    /// bbr_profile) plus the all-tier hop_interval.
    private var hy2Tuned: ServerProfile {
        var p = ProfileFixtures.hysteria2
        p.hy2HopPorts = "20000-30000,40000"
        p.hy2HopInterval = 30
        p.hy2HopIntervalMax = 90
        p.hy2BBRProfile = "standard"
        p.refreshID()
        return p
    }

    private var hy2Gecko: ServerProfile {
        var p = ProfileFixtures.hysteria2
        p.hy2Obfs = "gecko"
        p.hy2ObfsMinPacketSize = 100
        p.hy2ObfsMaxPacketSize = 1400
        p.refreshID()
        return p
    }

    private var anytls: ServerProfile {
        var p = ServerProfile(name: "Test anytls", protocol: .anytls,
                              address: "edge.example.com", port: 443)
        p.password = "anytls-test-password"
        p.tls = TLSSpec(enabled: true, serverName: "edge.example.com")
        p.refreshID()
        return p
    }

    // MARK: Capability table (ENGINES §4/§5 as data)

    func testCapabilityTableMatchesEnginesFacts() {
        let main = EngineTier.main.capabilities
        XCTAssertTrue(main.httpClients)
        XCTAssertEqual(main.dnsFormat, .new)
        XCTAssertTrue(main.defaultDomainResolver)
        XCTAssertTrue(main.hy2HopIntervalMax && main.hy2BBRProfile && main.hy2Gecko)
        XCTAssertTrue(main.xhttp && main.amneziaWG && main.anytls)
        XCTAssertTrue(main.tlsFragment && main.echQueryServerName)
        XCTAssertTrue(main.utlsFingerprints.contains("chrome_155"))
        XCTAssertEqual(main.utlsFingerprints.count, 16)

        let legacy = EngineTier.legacy.capabilities
        XCTAssertFalse(legacy.httpClients)
        XCTAssertEqual(legacy.dnsFormat, .new)
        XCTAssertTrue(legacy.defaultDomainResolver)
        XCTAssertFalse(legacy.hy2HopIntervalMax || legacy.hy2BBRProfile || legacy.hy2Gecko)
        XCTAssertTrue(legacy.xhttp && legacy.amneziaWG && legacy.anytls)
        XCTAssertTrue(legacy.tlsFragment && legacy.echQueryServerName)
        XCTAssertFalse(legacy.utlsFingerprints.contains("chrome_155"))
        XCTAssertTrue(legacy.utlsFingerprints.contains("chrome_pq_psk"))
        XCTAssertEqual(legacy.utlsFingerprints.count, 15)

        let catalina = EngineTier.catalina.capabilities
        XCTAssertFalse(catalina.httpClients)
        XCTAssertEqual(catalina.dnsFormat, .legacy)
        XCTAssertFalse(catalina.defaultDomainResolver)
        XCTAssertFalse(catalina.hy2HopIntervalMax || catalina.hy2BBRProfile || catalina.hy2Gecko)
        XCTAssertFalse(catalina.xhttp || catalina.amneziaWG || catalina.anytls)
        XCTAssertFalse(catalina.tlsFragment || catalina.echQueryServerName)
        XCTAssertFalse(catalina.utlsFingerprints.contains("chrome_pq_psk"))
        XCTAssertTrue(catalina.utlsFingerprints.contains("chrome_pq"))
        XCTAssertEqual(catalina.utlsFingerprints.count, 14)
    }

    func testEnginePins() {
        XCTAssertEqual(EngineTier.main.engineVersion, "1.14.3-lx.22")
        XCTAssertEqual(EngineTier.legacy.engineVersion, "1.13.13-lx.15")
        XCTAssertEqual(EngineTier.catalina.engineVersion, "1.11.15")
    }

    func testObfuscationDerivation() {
        let main = EngineTier.main.obfuscation
        XCTAssertTrue(main.reality && main.vision && main.xhttp && main.ech)
        XCTAssertTrue(main.echQueryServerName && main.tlsFragment && main.amneziaWG)
        XCTAssertEqual(main.hy2Obfs, ["salamander", "gecko"])

        let legacy = EngineTier.legacy.obfuscation
        XCTAssertTrue(legacy.reality && legacy.vision && legacy.xhttp && legacy.ech)
        XCTAssertTrue(legacy.echQueryServerName && legacy.tlsFragment && legacy.amneziaWG)
        XCTAssertEqual(legacy.hy2Obfs, ["salamander"])

        let catalina = EngineTier.catalina.obfuscation
        XCTAssertTrue(catalina.reality && catalina.vision && catalina.ech,
                      "REALITY/Vision/ECH exist on 1.11 (ENGINES §4 rows 5, 20)")
        XCTAssertFalse(catalina.xhttp || catalina.echQueryServerName ||
                       catalina.tlsFragment || catalina.amneziaWG)
        XCTAssertEqual(catalina.hy2Obfs, ["salamander"])
    }

    // MARK: Golden per tier

    func testTierVLESSReality() throws {
        // No gated field in this profile: main and legacy output must be
        // byte-identical (lx.15 passes the main corpus as-is, §5.1).
        let mainStr = try LibboxConfigBuilder.build(
            profile: ProfileFixtures.vless, settings: settings, tier: .main)
        let legacyStr = try LibboxConfigBuilder.build(
            profile: ProfileFixtures.vless, settings: settings, tier: .legacy)
        XCTAssertEqual(mainStr, legacyStr)

        let catalina = try build(ProfileFixtures.vless, tier: .catalina)
        let proxy = JSONTestHelper.proxy(catalina)
        XCTAssertEqual(proxy["type"] as? String, "vless")
        let reality = (proxy["tls"] as! [String: Any])["reality"] as! [String: Any]
        XCTAssertEqual(reality["public_key"] as? String, ProfileFixtures.realityKey)
        XCTAssertNil(JSONTestHelper.route(catalina)["default_domain_resolver"],
                     "1.11 has no route.default_domain_resolver (§4 row 2)")
        let dns = JSONTestHelper.dns(catalina)
        let servers = dns["servers"] as! [[String: Any]]
        XCTAssertTrue(servers.allSatisfy { $0["type"] == nil && $0["address"] != nil },
                      "catalina DNS servers are address strings, not typed servers")
    }

    func testTierVLESSXHTTP() throws {
        for tier in [EngineTier.main, .legacy] {
            let proxy = JSONTestHelper.proxy(try build(vlessXHTTP, tier: tier))
            XCTAssertEqual((proxy["transport"] as? [String: Any])?["type"] as? String,
                           "xhttp", "XHTTP exists on \(tier) (lx: with_xhttp)")
        }
        XCTAssertThrowsError(try LibboxConfigBuilder.build(
            profile: vlessXHTTP, settings: settings, tier: .catalina)) { error in
            XCTAssertEqual(error as? SoraConfigError,
                           .featureUnavailableOnTier(profileID: vlessXHTTP.id,
                                                     feature: .xhttpTransport,
                                                     tier: .catalina))
        }
    }

    func testTierHysteria2Fields114() throws {
        let main = JSONTestHelper.proxy(try build(hy2Tuned, tier: .main))
        XCTAssertEqual(main["hop_interval"] as? String, "30s")
        XCTAssertEqual(main["hop_interval_max"] as? String, "90s")
        XCTAssertEqual(main["bbr_profile"] as? String, "standard")
        XCTAssertEqual(main["server_ports"] as? [String], ["20000:30000", "40000:40000"])

        for tier in [EngineTier.legacy, .catalina] {
            let proxy = JSONTestHelper.proxy(try build(hy2Tuned, tier: tier))
            XCTAssertEqual(proxy["hop_interval"] as? String, "30s",
                           "hop_interval exists on every tier (§4 row 7)")
            XCTAssertEqual(proxy["server_ports"] as? [String], ["20000:30000", "40000:40000"])
            XCTAssertNil(proxy["hop_interval_max"], "1.14 field must not reach \(tier)")
            XCTAssertNil(proxy["bbr_profile"], "1.14 field must not reach \(tier)")
        }
    }

    func testTierHysteria2GeckoGate() throws {
        let main = JSONTestHelper.proxy(try build(hy2Gecko, tier: .main))
        let obfs = main["obfs"] as! [String: Any]
        XCTAssertEqual(obfs["type"] as? String, "gecko")
        XCTAssertEqual(obfs["min_packet_size"] as? Int, 100)
        XCTAssertEqual(obfs["max_packet_size"] as? Int, 1400)

        // Gecko is mandatory, not degradable: lx.15 itself rejects the
        // type ("unknown obfs type: gecko", measured), so omitting the
        // block would fake an unobfuscated connection.
        for tier in [EngineTier.legacy, .catalina] {
            XCTAssertThrowsError(try LibboxConfigBuilder.build(
                profile: hy2Gecko, settings: settings, tier: tier)) { error in
                XCTAssertEqual(error as? SoraConfigError,
                               .featureUnavailableOnTier(profileID: hy2Gecko.id,
                                                         feature: .hy2GeckoObfs,
                                                         tier: tier))
            }
        }
    }

    func testTierAmneziaWG() throws {
        let legacy = try build(ProfileFixtures.amneziaWG, tier: .legacy)
        let endpoint = (legacy["endpoints"] as! [[String: Any]])[0]
        XCTAssertEqual(endpoint["jc"] as? Int, 4)
        XCTAssertEqual(endpoint["h1"] as? String, "100000-100100")

        XCTAssertThrowsError(try LibboxConfigBuilder.build(
            profile: ProfileFixtures.amneziaWG, settings: settings, tier: .catalina)) { error in
            XCTAssertEqual(error as? SoraConfigError,
                           .featureUnavailableOnTier(profileID: ProfileFixtures.amneziaWG.id,
                                                     feature: .amneziaWG,
                                                     tier: .catalina))
        }
        // A plain WireGuard profile carries no AmneziaWG parameters:
        // not gated, endpoint renders on catalina too (§5.3 corpus).
        let wg = try build(ProfileFixtures.wireguard, tier: .catalina)
        XCTAssertEqual((wg["endpoints"] as! [[String: Any]])[0]["type"] as? String, "wireguard")
    }

    func testTierAnyTLS() throws {
        for tier in [EngineTier.main, .legacy] {
            let proxy = JSONTestHelper.proxy(try build(anytls, tier: tier))
            XCTAssertEqual(proxy["type"] as? String, "anytls")
            XCTAssertEqual(proxy["password"] as? String, "anytls-test-password")
            XCTAssertNotNil(proxy["tls"])
        }
        XCTAssertThrowsError(try LibboxConfigBuilder.build(
            profile: anytls, settings: settings, tier: .catalina)) { error in
            XCTAssertEqual(error as? SoraConfigError,
                           .featureUnavailableOnTier(profileID: anytls.id,
                                                     feature: .anytls, tier: .catalina))
        }
    }

    // MARK: Catalina DNS translation

    func testTierCatalinaDNSFakeIPLegacyFormat() throws {
        let cfg = try build(ProfileFixtures.vless, tier: .catalina)
        let dns = JSONTestHelper.dns(cfg)
        let servers = dns["servers"] as! [[String: Any]]
        XCTAssertEqual(servers[0]["address"] as? String, "https://1.1.1.1/dns-query")
        XCTAssertNil(servers[0]["type"])
        let fakeipServers = servers.filter { $0["address"] as? String == "fakeip" }
        XCTAssertEqual(fakeipServers.count, 1, "the 1.11 fakeip transport spelling")
        let fakeip = dns["fakeip"] as! [String: Any]
        XCTAssertEqual(fakeip["enabled"] as? Bool, true)
        XCTAssertEqual(fakeip["inet4_range"] as? String, "198.18.0.0/15")
        XCTAssertEqual(fakeip["inet6_range"] as? String, "fc00::/18")
        let rules = dns["rules"] as! [[String: Any]]
        XCTAssertTrue(rules.contains {
            ($0["query_type"] as? [String]) == ["A", "AAAA"] && $0["server"] as? String == "fakeip"
        }, "the query_type rule still steers A/AAAA at fakeip after translation")
        XCTAssertNil(JSONTestHelper.route(cfg)["default_domain_resolver"])
    }

    func testTierCatalinaDNSHostnameResolverBecomesAddressResolver() throws {
        let hostSettings = AppSettings(dnsServers: ["https://dns.example.com/dns-query"])
        let cfg = try build(ProfileFixtures.vless, tier: .catalina, settings: hostSettings)
        let servers = JSONTestHelper.dns(cfg)["servers"] as! [[String: Any]]
        XCTAssertEqual(servers[0]["address"] as? String, "https://dns.example.com/dns-query")
        XCTAssertEqual(servers[0]["address_resolver"] as? String, "local",
                       "new-format domain_resolver maps to legacy address_resolver")
        XCTAssertTrue(servers.contains { $0["address"] as? String == "local" })
    }

    func testLegacyDNSTranslationRefusesUntranslatableKey() {
        // A new-format server key with no old-format counterpart (here a
        // hypothetical per-server tls block) must gate, not drop.
        let newFormat: [String: Any] = [
            "servers": [["type": "https", "tag": "dns-1", "server": "1.1.1.1",
                         "tls": ["enabled": true]]],
            "rules": [], "final": "dns-1", "strategy": "ipv4_only",
        ]
        XCTAssertThrowsError(try LibboxConfigBuilder.legacyDNSConfig(newFormat, tier: .catalina)) { error in
            guard case SoraConfigError.dnsUntranslatableForTier(.catalina, _) = error as! SoraConfigError else {
                return XCTFail("want dnsUntranslatableForTier, got \(error)")
            }
        }
    }

    // MARK: Degradable features — marked, not emitted, never an error

    func testTierECHQueryServerNameDegrades() throws {
        var p = ProfileFixtures.trojan
        p.tls.ech = "test-ech-config"
        p.tls.echQueryServerName = "ech.example.com"
        p.refreshID()

        for tier in [EngineTier.main, .legacy] {
            let proxy = JSONTestHelper.proxy(try build(p, tier: tier))
            let ech = (proxy["tls"] as! [String: Any])["ech"] as! [String: Any]
            XCTAssertEqual(ech["query_server_name"] as? String, "ech.example.com")
        }
        let proxy = JSONTestHelper.proxy(try build(p, tier: .catalina))
        let ech = (proxy["tls"] as! [String: Any])["ech"] as! [String: Any]
        XCTAssertEqual(ech["config"] as? [String], ["test-ech-config"],
                       "ECH itself is emitted on catalina (§4 row 20)")
        XCTAssertNil(ech["query_server_name"], "only query_server_name is gated (row 21)")

        let marked = EngineTier.catalina.unavailableFeatures(for: p)
        XCTAssertEqual(marked.map(\.feature), [.echQueryServerName])
        XCTAssertFalse(marked[0].isMandatory)
    }

    func testTierTLSFragmentDegrades() throws {
        var p = ProfileFixtures.vmess
        p.tls.fragment = true
        p.refreshID()
        for tier in [EngineTier.main, .legacy] {
            let proxy = JSONTestHelper.proxy(try build(p, tier: tier))
            XCTAssertEqual((proxy["tls"] as! [String: Any])["fragment"] as? Bool, true)
        }
        let proxy = JSONTestHelper.proxy(try build(p, tier: .catalina))
        XCTAssertNil((proxy["tls"] as! [String: Any])["fragment"])
        XCTAssertEqual(EngineTier.catalina.unavailableFeatures(for: p).map(\.feature),
                       [.tlsFragment])
    }

    func testTierFingerprintOutsideSetIsMarkedNotEmitted() throws {
        var p = ProfileFixtures.vless
        p.tls.fingerprint = "chrome_155"
        p.refreshID()
        let main = JSONTestHelper.proxy(try build(p, tier: .main))
        XCTAssertEqual(((main["tls"] as! [String: Any])["utls"] as! [String: Any])["fingerprint"] as? String,
                       "chrome_155")
        for tier in [EngineTier.legacy, .catalina] {
            let proxy = JSONTestHelper.proxy(try build(p, tier: tier))
            XCTAssertNil((proxy["tls"] as! [String: Any])["utls"],
                         "chrome_155 would be refused by \(tier) at load; never emitted")
            let marked = tier.unavailableFeatures(for: p)
            XCTAssertEqual(marked.map(\.feature), [.utlsFingerprint])
            XCTAssertEqual(marked[0].detail, "chrome_155")
            XCTAssertFalse(marked[0].isMandatory)
        }
    }

    func testTierHy2TuningMarkedDegradableOnLegacy() throws {
        let marked = EngineTier.legacy.unavailableFeatures(for: hy2Tuned)
        XCTAssertEqual(Set(marked.map(\.feature)), [.hy2HopIntervalMax, .hy2BBRProfile])
        XCTAssertTrue(marked.allSatisfy { !$0.isMandatory })
        XCTAssertTrue(EngineTier.legacy.mandatoryUnavailableFeatures(for: hy2Tuned).isEmpty)
        XCTAssertNoThrow(try LibboxConfigBuilder.build(
            profile: hy2Tuned, settings: settings, tier: .legacy))
    }

    /// The two cases of the tier contract, side by side: importing /
    /// validating a profile with tier-unavailable features never fails;
    /// building with a mandatory one refuses with the typed error.
    func testValidationIsTierAgnosticButBuildGatesMandatory() throws {
        XCTAssertNoThrow(try ConfigValidation.validate(vlessXHTTP))
        XCTAssertNoThrow(try ConfigValidation.validate(anytls))
        XCTAssertNoThrow(try ConfigValidation.validate(ProfileFixtures.amneziaWG))
        XCTAssertNoThrow(try ConfigValidation.validate(hy2Tuned))

        XCTAssertEqual(EngineTier.catalina.mandatoryUnavailableFeatures(for: vlessXHTTP).map(\.feature),
                       [.xhttpTransport])
        XCTAssertEqual(EngineTier.catalina.mandatoryUnavailableFeatures(for: anytls).map(\.feature),
                       [.anytls])
        XCTAssertThrowsError(try LibboxConfigBuilder.buildChain(
            profiles: [ProfileFixtures.trojan, vlessXHTTP], settings: settings, tier: .catalina),
            "the gate applies to every hop of a chain, not only the exit")
    }

    // MARK: Source compatibility of the pre-tier API

    func testDefaultTierIsMain() throws {
        let implicit = try LibboxConfigBuilder.build(profile: hy2Tuned, settings: settings)
        let explicit = try LibboxConfigBuilder.build(profile: hy2Tuned, settings: settings, tier: .main)
        XCTAssertEqual(implicit, explicit)
    }

    // MARK: External-check export

    /// Writes one config per (tier, profile) pair the external check
    /// runs on: legacy pairs through the real lx.15 binary, catalina
    /// pairs through the real 1.11.15 binary. Directory:
    /// $SORA_TIER_CHECK_DIR or a temp folder; the run and its results
    /// are recorded in reports/legacy-systems/CORE.md.
    func testExportTierConfigsForExternalCheck() throws {
        let dir = ProcessInfo.processInfo.environment["SORA_TIER_CHECK_DIR"]
            ?? NSTemporaryDirectory() + "sora-tier-check"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let cases: [(String, ServerProfile, EngineTier)] = [
            ("legacy-vless-reality", ProfileFixtures.vless, .legacy),
            ("legacy-vless-xhttp", vlessXHTTP, .legacy),
            ("legacy-hy2-tuned", hy2Tuned, .legacy),
            ("legacy-awg", ProfileFixtures.amneziaWG, .legacy),
            ("legacy-anytls", anytls, .legacy),
            ("legacy-trojan", ProfileFixtures.trojan, .legacy),
            ("catalina-vless-reality", ProfileFixtures.vless, .catalina),
            ("catalina-hy2-tuned", hy2Tuned, .catalina),
            ("catalina-wireguard", ProfileFixtures.wireguard, .catalina),
            ("catalina-vmess", ProfileFixtures.vmess, .catalina),
            ("catalina-trojan", ProfileFixtures.trojan, .catalina),
            ("catalina-shadowsocks", ProfileFixtures.shadowsocks, .catalina),
        ]
        for (name, profile, tier) in cases {
            let config = try LibboxConfigBuilder.build(profile: profile, settings: settings, tier: tier)
            try config.write(toFile: "\(dir)/\(name).json", atomically: true, encoding: .utf8)
        }
    }
}
