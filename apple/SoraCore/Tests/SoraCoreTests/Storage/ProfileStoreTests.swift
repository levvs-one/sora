import XCTest
@testable import SoraCore

final class ProfileStoreTests: XCTestCase {
    private var dir: URL!
    private var store: JSONFileProfileStore!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("soracore-tests-\(UUID().uuidString)", isDirectory: true)
        store = JSONFileProfileStore(directory: dir)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func testRoundTripProfiles() throws {
        let profiles = ProfileFixtures.all
        try store.save(profiles)
        XCTAssertEqual(try store.load(), profiles)
    }

    func testLoadMissingFileReturnsEmpty() throws {
        XCTAssertEqual(try store.load(), [])
        XCTAssertEqual(try store.loadSettings(), AppSettings())
    }

    func testRoundTripSettingsWithCapabilities() throws {
        var caps = PlatformCapabilities()
        caps.tunStack = .gvisor
        caps.ipv6InTunnel = false
        caps.killSwitchBehavior = .blockOnFailure
        let settings = AppSettings(dnsServers: ["tls://dns.google"], killSwitch: false,
                                   tunMTU: 1400, capabilities: caps)
        try store.saveSettings(settings)
        XCTAssertEqual(try store.loadSettings(), settings)
    }

    func testSaveIsAtomicAndLeavesNoTempFiles() throws {
        try store.save(ProfileFixtures.all)
        try store.save([ProfileFixtures.vless]) // overwrite via replaceItemAt
        let names = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        XCTAssertEqual(names, [SoraSharedIdentifiers.profilesFileName])
        XCTAssertEqual(try store.load(), [ProfileFixtures.vless])
    }

    /// v1 files are bare arrays without the envelope. Loading must
    /// migrate additively; the next save writes the current envelope.
    func testMigrationV1BareArrayToCurrent() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let v1Data = try encoder.encode(ProfileFixtures.all) // bare array = v1
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try v1Data.write(to: dir.appendingPathComponent(SoraSharedIdentifiers.profilesFileName))

        XCTAssertEqual(try store.load(), ProfileFixtures.all, "v1 must load via migration")

        try store.save(ProfileFixtures.all)
        let written = try String(contentsOf: dir.appendingPathComponent(
            SoraSharedIdentifiers.profilesFileName), encoding: .utf8)
        XCTAssertTrue(written.contains("\"version\" : 2"), "save after migration writes v2: \(written)")
        XCTAssertEqual(try store.load(), ProfileFixtures.all)
    }

    func testFutureVersionRefusedNotDropped() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("{\"version\": 99, \"profiles\": []}".utf8).write(
            to: dir.appendingPathComponent(SoraSharedIdentifiers.profilesFileName))
        XCTAssertThrowsError(try store.load()) {
            XCTAssertEqual($0 as? SoraStorageError,
                           .unsupportedVersion(found: 99, current: ProfileFileFormat.currentVersion))
        }
    }

    func testCorruptFileReported() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("not json".utf8).write(
            to: dir.appendingPathComponent(SoraSharedIdentifiers.profilesFileName))
        XCTAssertThrowsError(try store.load()) {
            XCTAssertEqual($0 as? SoraStorageError,
                           .corruptFile(name: SoraSharedIdentifiers.profilesFileName))
        }
    }

    func testOldSettingsWithoutCapabilitiesDecodeWithAuto() throws {
        // Additive migration: a settings JSON predating `capabilities`
        // (and split-tunnel keys) loads with defaults.
        let legacy = """
        {"dnsServers": ["1.1.1.1"], "killSwitch": false, "tunMTU": 1500,
         "bypassLAN": true, "logLevel": "warn"}
        """
        let decoded = try JSONDecoder().decode(AppSettings.self, from: Data(legacy.utf8))
        XCTAssertEqual(decoded.capabilities, .auto)
        XCTAssertEqual(decoded.dnsServers, ["1.1.1.1"])
        XCTAssertEqual(decoded.killSwitch, false)
    }

    func testInMemorySecretsRoundTrip() throws {
        let secrets = InMemorySecretsStore()
        XCTAssertNil(try secrets.secret(forKey: "wg-key"))
        try secrets.setSecret("secret-value", forKey: "wg-key")
        XCTAssertEqual(try secrets.secret(forKey: "wg-key"), "secret-value")
        try secrets.setSecret(nil, forKey: "wg-key")
        XCTAssertNil(try secrets.secret(forKey: "wg-key"))
    }

    func testSharedIdentifiersAreStable() {
        // The app and the extension read these from this one enum; the
        // literals are pinned so an accidental rename breaks a test, not
        // a shipped pairing.
        XCTAssertEqual(SoraSharedIdentifiers.appGroup, "group.io.github.levvs-one.sora")
        XCTAssertEqual(SoraSharedIdentifiers.keychainAccessGroup, "io.github.levvs-one.sora")
        XCTAssertEqual(SoraSharedIdentifiers.bundlePrefix, "io.github.levvs-one.sora")
    }
}
