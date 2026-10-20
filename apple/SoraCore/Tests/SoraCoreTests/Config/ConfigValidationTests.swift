import XCTest
@testable import SoraCore

final class ConfigValidationTests: XCTestCase {

    private func expect(_ profile: ServerProfile, _ expected: SoraConfigError,
                        file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try LibboxConfigBuilder.build(profile: profile, settings: AppSettings()),
                             file: file, line: line) { error in
            XCTAssertEqual(error as? SoraConfigError, expected, file: file, line: line)
        }
    }

    func testMuxVisionConflictRefused() {
        var p = ProfileFixtures.vless // flow = vision
        p.muxEnabled = true
        expect(p, .muxVisionConflict(profileID: p.id))
    }

    func testRealityVisionWithoutMuxIsAllowed() throws {
        XCTAssertNoThrow(try LibboxConfigBuilder.build(
            profile: ProfileFixtures.vless, settings: AppSettings()))
    }

    func testMuxWithoutVisionIsAllowed() throws {
        var p = ProfileFixtures.vless
        p.flow = ""
        p.muxEnabled = true
        let cfg = JSONTestHelper.parse(try LibboxConfigBuilder.build(profile: p, settings: AppSettings()))
        XCTAssertNotNil(JSONTestHelper.proxy(cfg)["multiplex"])
    }

    func testXHTTPVisionRefused() {
        var p = ProfileFixtures.vless
        p.flow = "xtls-rprx-vision"
        p.transport = TransportSpec(type: "xhttp")
        expect(p, .xhttpVisionConflict(profileID: p.id))
    }

    func testRealityMissingPublicKey() {
        var p = ProfileFixtures.vless
        p.tls.reality = RealitySpec(publicKey: "", shortId: "")
        expect(p, .realityMissingPublicKey(profileID: p.id))
    }

    func testRealityInvalidPublicKey() {
        var p = ProfileFixtures.vless
        p.tls.reality = RealitySpec(publicKey: "not-a-key", shortId: "")
        expect(p, .realityInvalidPublicKey(profileID: p.id))
    }

    func testRealityInvalidShortID() {
        var p = ProfileFixtures.vless
        p.tls.reality = RealitySpec(publicKey: ProfileFixtures.realityKey, shortId: "xyz!")
        expect(p, .realityInvalidShortID(profileID: p.id))
    }

    func testAmneziaMissingAddress() {
        var p = ProfileFixtures.amneziaWG
        p.wgLocalAddresses = []
        expect(p, .amneziaMissingAddress(profileID: p.id))
    }

    func testAmneziaMissingPrivateKey() {
        var p = ProfileFixtures.wireguard
        p.wgPrivateKey = ""
        expect(p, .amneziaMissingPrivateKey(profileID: p.id))
    }

    func testAmneziaJunkRangeInverted() {
        var p = ProfileFixtures.amneziaWG
        p.awg?.jmin = 90
        p.awg?.jmax = 10
        expect(p, .amneziaJunkRangeInverted(profileID: p.id))
    }

    func testAmneziaLegacyJunkWith31Refused() {
        var p = ProfileFixtures.amneziaWG
        p.awg?.j1 = "<b 0x01>"
        p.awg?.headerProtectionKey = String(repeating: "A", count: 43) + "="
        expect(p, .amneziaLegacyJunkWith31(profileID: p.id))
    }

    func testRealityMLDSA65RefusedForSingBox() {
        var p = ProfileFixtures.vless
        p.tls.mldsa65Verify = String(repeating: "A", count: 100)
        expect(p, .realityMLDSA65Unsupported(profileID: p.id))
    }

    func testErrorMessagesFollowUIGlossary() {
        // One style everywhere: short problem name + what to do, in the
        // UI glossary («сервер», «подписка») — never engine terms.
        for error in [SoraConfigError.emptyAddress(profileID: "x"),
                      .muxVisionConflict(profileID: "x"),
                      .realityMissingPublicKey(profileID: "x")] {
            XCTAssertTrue(error.userMessage.contains("сервер"), error.userMessage)
            XCTAssertTrue(error.userMessage.hasSuffix("."), error.userMessage)
        }
    }

    func testDownloadSettingsOnTCPRefused() {
        var p = ProfileFixtures.vless
        p.flow = ""
        p.transport = TransportSpec(type: "tcp", downloadAddress: "down.example.com", downloadPort: 8443)
        expect(p, .downloadSettingsInvalid(profileID: p.id,
                                           reason: "downloadSettings needs the xhttp transport"))
    }

    func testDownloadSettingsStreamOneRefused() {
        var p = ProfileFixtures.vless
        p.flow = ""
        p.transport = TransportSpec(type: "xhttp", mode: "stream-one",
                                    downloadAddress: "down.example.com", downloadPort: 8443)
        expect(p, .downloadSettingsInvalid(
            profileID: p.id,
            reason: "downloadSettings is incompatible with mode stream-one (use stream-up)"))
    }

    func testECHWithRealityRefused() {
        var p = ProfileFixtures.vless
        p.tls.ech = "ech-config-list"
        expect(p, .echWithReality(profileID: p.id))
    }

    func testEmptyAddressAndBadPort() {
        var p = ProfileFixtures.trojan
        p.address = "  "
        expect(p, .emptyAddress(profileID: p.id))
        p = ProfileFixtures.trojan
        p.port = 0
        expect(p, .invalidPort(profileID: p.id, port: 0))
    }

    func testMissingCredentials() {
        var p = ProfileFixtures.vless
        p.uuid = ""
        expect(p, .missingUUID(profileID: p.id))
        p = ProfileFixtures.trojan
        p.password = ""
        expect(p, .missingPassword(profileID: p.id))
        p = ProfileFixtures.shadowsocks
        p.method = ""
        expect(p, .missingMethod(profileID: p.id))
    }

    func testHysteriaObfsWithoutPassword() {
        var p = ProfileFixtures.hysteria2
        p.hy2ObfsPassword = ""
        expect(p, .hysteriaObfsMissingPassword(profileID: p.id))
    }

    func testEmptyChainAndDuplicateIDs() {
        XCTAssertThrowsError(try LibboxConfigBuilder.buildChain(profiles: [], settings: AppSettings())) {
            XCTAssertEqual($0 as? SoraConfigError, .emptyChain)
        }
        XCTAssertThrowsError(try LibboxConfigBuilder.buildChain(
            profiles: [ProfileFixtures.vless, ProfileFixtures.vless], settings: AppSettings())) {
            XCTAssertEqual($0 as? SoraConfigError, .duplicateChainProfile(id: ProfileFixtures.vless.id))
        }
    }
}
