import Foundation

/// Base64 helpers mirroring Go's decodeBase64 in core/parser: whitespace is
/// stripped, the standard and URL-safe alphabets are both accepted, and
/// missing padding is restored. Decoding is hand-rolled so acceptance does
/// not depend on a platform decoder's leniency differences.
public enum Base64 {
    private static let table: [UInt8] = {
        var t = [UInt8](repeating: 0xff, count: 128)
        let alphabet = [UInt8]("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8)
        for (i, c) in alphabet.enumerated() { t[Int(c)] = UInt8(i) }
        t[Int(UInt8(ascii: "-"))] = 62
        t[Int(UInt8(ascii: "_"))] = 63
        return t
    }()

    /// Decodes `string` under any of Go's four encodings (Std/RawStd/
    /// URL/RawURL). Returns nil when a non-alphabet byte appears, the length
    /// is impossible, or padding is misplaced.
    public static func decode(_ string: String) -> Data? {
        var bytes = [UInt8]()
        bytes.reserveCapacity(string.utf8.count)
        for b in string.utf8 {
            switch b {
            case 0x0d, 0x0a, 0x20, 0x09: continue // \r \n space \t, as in Go
            default: bytes.append(b)
            }
        }
        // Padding: Go's padded encodings accept it only at the end; the raw
        // encodings reject it, but the padded forms are tried after the raw
        // ones in Go with padding restored, so trailing '=' is tolerated.
        var pad = 0
        while bytes.last == UInt8(ascii: "=") {
            bytes.removeLast()
            pad += 1
        }
        if pad > 2 || bytes.count % 4 == 1 { return nil }
        var out = Data()
        out.reserveCapacity(bytes.count * 3 / 4 + 3)
        var acc: UInt32 = 0
        var nbits = 0
        for b in bytes {
            if b >= 128 { return nil }
            let v = table[Int(b)]
            if v == 0xff { return nil }
            acc = (acc << 6) | UInt32(v)
            nbits += 6
            if nbits >= 8 {
                nbits -= 8
                out.append(UInt8((acc >> UInt32(nbits)) & 0xff))
            }
        }
        return out
    }

    /// Decodes and interprets the result as UTF-8 (Go requires utf8.Valid).
    public static func decodeUTF8(_ string: String) -> String? {
        guard let data = decode(string) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Standard-alphabet encoding with padding (used by tests and fixtures).
    public static func encode(_ data: Data) -> String {
        let alphabet = [UInt8]("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8)
        var out = [UInt8]()
        let bytes = [UInt8](data)
        var i = 0
        while i < bytes.count {
            let b0 = UInt32(bytes[i])
            let b1 = i + 1 < bytes.count ? UInt32(bytes[i + 1]) : 0
            let b2 = i + 2 < bytes.count ? UInt32(bytes[i + 2]) : 0
            out.append(alphabet[Int(b0 >> 2)])
            out.append(alphabet[Int(((b0 & 3) << 4) | (b1 >> 4))])
            out.append(i + 1 < bytes.count ? alphabet[Int(((b1 & 0xf) << 2) | (b2 >> 6))] : UInt8(ascii: "="))
            out.append(i + 2 < bytes.count ? alphabet[Int(b2 & 0x3f)] : UInt8(ascii: "="))
            i += 3
        }
        return String(decoding: out, as: UTF8.self)
    }
}

/// Percent-decoding mirroring Go's url.QueryUnescape / PathUnescape.
/// `plusAsSpace` is true for query and fragment text, false for userinfo.
enum PercentCoding {
    static func decode(_ s: String, plusAsSpace: Bool) -> String {
        let bytes = [UInt8](s.utf8)
        var out = [UInt8]()
        out.reserveCapacity(bytes.count)
        var i = 0
        while i < bytes.count {
            let b = bytes[i]
            if b == UInt8(ascii: "%"), i + 2 < bytes.count + 0, i + 2 <= bytes.count - 1,
               let hi = hexValue(bytes[i + 1]), let lo = hexValue(bytes[i + 2]) {
                out.append(UInt8(hi * 16 + lo))
                i += 3
            } else if b == UInt8(ascii: "+"), plusAsSpace {
                out.append(0x20)
                i += 1
            } else {
                out.append(b)
                i += 1
            }
        }
        // Go returns the raw string on unescape errors; for a lone malformed
        // '%' we keep the byte verbatim, which matches that fallback closely
        // enough for field-level parsing (the field is validated later).
        return String(decoding: out, as: UTF8.self)
    }

    static func hexValue(_ b: UInt8) -> Int? {
        switch b {
        case UInt8(ascii: "0")...UInt8(ascii: "9"): return Int(b - UInt8(ascii: "0"))
        case UInt8(ascii: "a")...UInt8(ascii: "f"): return Int(b - UInt8(ascii: "a")) + 10
        case UInt8(ascii: "A")...UInt8(ascii: "F"): return Int(b - UInt8(ascii: "A")) + 10
        default: return nil
        }
    }
}

/// Strict UUID shape check, the exact equivalent of Go's uuidRE:
/// `^[0-9a-fA-F]{8}-…-[1-8]…-[89abAB]…-{12}$` — versions 1–8 (RFC 9562,
/// so Remnawave-issued v6/v7/v8 UUIDs import), variant and length strict.
enum UUIDValidation {
    static func isValid(_ s: String) -> Bool {
        let c = [UInt8](s.utf8)
        guard c.count == 36 else { return false }
        for (i, b) in c.enumerated() {
            switch i {
            case 8, 13, 18, 23:
                if b != UInt8(ascii: "-") { return false }
            case 14:
                if b < UInt8(ascii: "1") || b > UInt8(ascii: "8") { return false }
            case 19:
                if ![UInt8(ascii: "8"), UInt8(ascii: "9"), UInt8(ascii: "a"), UInt8(ascii: "b"),
                     UInt8(ascii: "A"), UInt8(ascii: "B")].contains(b) { return false }
            default:
                if PercentCoding.hexValue(b) == nil { return false }
            }
        }
        return true
    }
}
