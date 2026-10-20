import Foundation

/// Parse failures, mirroring the Go parser's sentinel errors
/// (parser.ErrEmptySource / ErrInputTooLarge / ErrUnsupported / ErrInvalid)
/// refined by refusal kind. No case carries user data beyond the scheme or
/// parameter name, so errors are safe to log — as in Go.
public enum SoraParseError: Error, Equatable {
    /// The source was empty or whitespace only (Go: ErrEmptySource).
    case emptyInput
    /// The source exceeds the 16 MiB import cap (Go: ErrInputTooLarge).
    case inputTooLarge
    /// Unknown or unsupported link scheme, e.g. "openvpn" (Go: ErrUnsupported).
    case unsupportedScheme(String)
    /// A recognised scheme with an option Sora refuses to honour silently,
    /// e.g. Hysteria2 pinSHA256 (Go: ErrUnsupported with a reason).
    case unsupportedOption(String)
    /// The link is malformed: no host, no/invalid port, broken structure
    /// (Go: ErrInvalid).
    case invalidLink
    /// The port is missing, non-numeric or outside 1...65535 (Go: ErrInvalid).
    case invalidPort
    /// A UUID field fails the strict shape check — versions 1–8 with the
    /// RFC 9562 variant only (Go: ErrInvalid "invalid UUID").
    case invalidUUID
    /// A base64 payload that had to decode did not (Go: ErrInvalid paths).
    case invalidBase64
    /// The payload format is not one the subscription parser recognises
    /// (Go: ErrUnsupported "no supported parser matched").
    case unsupportedFormat

    /// Short, user-facing description. Terminology follows the main app's
    /// glossary — one concept, one word: «сервер» (server), «подписка»
    /// (subscription), «ссылка» (link). No technical jargon.
    public var message: String {
        switch self {
        case .emptyInput: return "The link is empty"
        case .inputTooLarge: return "The subscription is too large"
        case .unsupportedScheme: return "This link is not supported"
        case .unsupportedOption: return "This link uses an option that is not supported"
        case .invalidLink: return "The link is invalid"
        case .invalidPort: return "The server port in the link is invalid"
        case .invalidUUID: return "The server identifier in the link is invalid"
        case .invalidBase64: return "The link is damaged"
        case .unsupportedFormat: return "This subscription format is not supported"
        }
    }
}
