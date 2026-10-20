import XCTest
@testable import SoraCore

final class SHA256Tests: XCTestCase {
    // Official NIST / FIPS 180-4 example vectors.
    func testNISTVectors() {
        XCTAssertEqual(SHA256.hexDigest(of: ""),
                       "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual(SHA256.hexDigest(of: "abc"),
                       "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        XCTAssertEqual(SHA256.hexDigest(of: "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"),
                       "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")
        XCTAssertEqual(SHA256.hexDigest(of: "The quick brown fox jumps over the lazy dog"),
                       "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592")
    }

    func testMillionA() {
        let data = Data(repeating: UInt8(ascii: "a"), count: 1_000_000)
        XCTAssertEqual(SHA256.hex(SHA256.hash(data)),
                       "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
    }
}

final class StableIDTests: XCTestCase {
    func testStableIDShapeAndDeterminism() {
        let a = ServerProfile(name: "A", protocol: .vless, address: "example.com", port: 443,
                              uuid: "123e4567-e89b-12d3-a456-426614174000")
        let b = ServerProfile(name: "B (renamed)", protocol: .vless, address: "example.com", port: 443,
                              uuid: "123e4567-e89b-12d3-a456-426614174000")
        // Name is not identity (Go StableKey): renaming keeps the id.
        XCTAssertEqual(a.id, b.id)
        XCTAssertTrue(a.id.hasPrefix("vless:example.com:443:"))
        XCTAssertEqual(a.id.split(separator: ":").last?.count, 16)
        let c = ServerProfile(name: "A", protocol: .vless, address: "example.com", port: 443,
                              uuid: "123e4567-e89b-42d3-a456-426614174001")
        XCTAssertNotEqual(a.id, c.id)
    }

    func testCodableRoundTripAndAdditiveDecoding() throws {
        let p = ServerProfile(name: "X", protocol: .hysteria2, address: "h.example", port: 443,
                              password: "pw", hy2UpMbps: 20, hy2DownMbps: 100,
                              hy2HopPorts: "20000-30000", tls: TLSSpec(enabled: true, serverName: "h.example"))
        let data = try JSONEncoder().encode(p)
        let back = try JSONDecoder().decode(ServerProfile.self, from: data)
        XCTAssertEqual(back, p)
        XCTAssertEqual(back.id, p.id)
        // A document written before newer fields existed still decodes:
        // migrations are additive only.
        let legacy = #"{"name":"old","protocol":"vless","address":"a.example","port":443,"uuid":"123e4567-e89b-12d3-a456-426614174000"}"#
        let old = try JSONDecoder().decode(ServerProfile.self, from: Data(legacy.utf8))
        XCTAssertEqual(old.address, "a.example")
        XCTAssertEqual(old.transport.type, "tcp")
        XCTAssertFalse(old.muxEnabled)
    }
}
