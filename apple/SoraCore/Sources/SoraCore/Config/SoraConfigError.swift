import Foundation

/// Validation failures of a profile, mirroring the refusals of the Go
/// core's plan validation (`core/engine/validate.go`, `reality.go`,
/// `mux.go`). One case per refusal class so the UI can localize by case
/// instead of matching message text.
///
/// `userMessage` follows the UI glossary («сервер», «подписка») and one
/// style everywhere: a short name of the problem, then what to do.
public enum SoraConfigError: Error, Equatable {
    case emptyAddress(profileID: String)
    case invalidPort(profileID: String, port: Int)
    case missingUUID(profileID: String)
    case missingPassword(profileID: String)
    case missingMethod(profileID: String)
    /// mux + XTLS vision flow: vision users are not mux users (Go
    /// `RealityMux` suppresses mux under vision; a profile that asks for
    /// both explicitly is a config bug, refused here).
    case muxVisionConflict(profileID: String)
    /// XHTTP + vision flow without VLESS Encryption (Go validateXHTTP).
    /// The profile model carries no VLESS Encryption field, so on this
    /// core the combination is always refused.
    case xhttpVisionConflict(profileID: String)
    case realityMissingPublicKey(profileID: String)
    /// Not a 32-byte base64url X25519 key (Go ValidateReality).
    case realityInvalidPublicKey(profileID: String)
    /// Not hex of at most 8 bytes (Go ValidateReality).
    case realityInvalidShortID(profileID: String)
    /// A REALITY mldsa65Verify key is set: sing-box does not implement
    /// the check, and the Go renderer refuses rather than completing a
    /// handshake without it.
    case realityMLDSA65Unsupported(profileID: String)
    case echWithoutTLS(profileID: String)
    case echWithReality(profileID: String)
    case amneziaMissingPrivateKey(profileID: String)
    case amneziaMissingPeerPublicKey(profileID: String)
    case amneziaMissingAddress(profileID: String)
    case amneziaJunkRangeInverted(profileID: String)
    /// AmneziaWG 1.5 junk-session parameters (J1/J2/J3/Itime) combined
    /// with 3.1 mechanisms — no engine carries that combination (Go
    /// validateAmneziaWG).
    case amneziaLegacyJunkWith31(profileID: String)
    /// Junk-session parameters on their own: the Go sing-box renderer
    /// refuses them (they require another engine).
    case amneziaJunkSessionUnsupported(profileID: String)
    case hysteriaObfsMissingPassword(profileID: String)
    /// downloadSettings set on a non-XHTTP transport, half-set, or with
    /// the stream-one mode (Go validateXHTTP).
    case downloadSettingsInvalid(profileID: String, reason: String)
    case unsupportedTransport(profileID: String, transport: String)
    case emptyChain
    case duplicateChainProfile(id: String)
    /// A mandatory feature of the profile (protocol, transport or obfs
    /// framing) that the target engine tier cannot emit — the mirror of
    /// the desktop catalog's `Missing()` refusal: the build refuses
    /// instead of emitting a different connection than the server
    /// speaks. Degradable missing features never throw; they are marked
    /// by `EngineTier.unavailableFeatures(for:)` and omitted.
    case featureUnavailableOnTier(profileID: String, feature: EngineFeature, tier: EngineTier)
    /// A generated DNS section the tier's legacy DNS format cannot spell
    /// (a new-format key with no old-format counterpart). Refused
    /// instead of silently dropped (ENGINES §5.3 translation contract).
    case dnsUntranslatableForTier(tier: EngineTier, detail: String)

    /// Short problem name + what to do, in the UI glossary. The UI shows
    /// this verbatim next to the server; it never shows case names or
    /// engine terms.
    public var userMessage: String {
        switch self {
        case .emptyAddress:
            return "У сервера нет адреса: укажите адрес сервера."
        case .invalidPort:
            return "Неверный порт сервера: укажите порт от 1 до 65535."
        case .missingUUID:
            return "У сервера нет UUID: проверьте ссылку или подписку."
        case .missingPassword:
            return "У сервера нет пароля: проверьте ссылку или подписку."
        case .missingMethod:
            return "У сервера нет метода шифрования: проверьте ссылку или подписку."
        case .muxVisionConflict:
            return "Мультиплексирование несовместимо с Vision: отключите одно из двух у сервера."
        case .xhttpVisionConflict:
            return "Транспорт XHTTP несовместим с Vision: смените транспорт или отключите Vision."
        case .realityMissingPublicKey:
            return "У сервера REALITY нет публичного ключа: проверьте ссылку или подписку."
        case .realityInvalidPublicKey:
            return "Публичный ключ REALITY повреждён: проверьте ссылку или обновите подписку."
        case .realityInvalidShortID:
            return "Короткий идентификатор REALITY повреждён: проверьте ссылку или обновите подписку."
        case .realityMLDSA65Unsupported:
            return "Сервер требует проверку ML-DSA-65, которую этот движок не поддерживает: выберите другой сервер."
        case .echWithoutTLS:
            return "ECH включён без TLS: включите TLS у сервера или отключите ECH."
        case .echWithReality:
            return "ECH несовместим с REALITY: отключите одно из двух у сервера."
        case .amneziaMissingPrivateKey:
            return "У сервера нет приватного ключа: проверьте конфигурацию сервера."
        case .amneziaMissingPeerPublicKey:
            return "У сервера нет публичного ключа пира: проверьте конфигурацию сервера."
        case .amneziaMissingAddress:
            return "У сервера нет локального адреса туннеля: проверьте конфигурацию сервера."
        case .amneziaLegacyJunkWith31:
            return "Параметры AmneziaWG 1.5 несовместимы с AmneziaWG 3.1: оставьте один набор у сервера."
        case .amneziaJunkSessionUnsupported:
            return "Параметры AmneziaWG 1.5 не поддерживаются этим движком: выберите другой сервер."
        case .amneziaJunkRangeInverted:
            return "Неверный диапазон мусорных пакетов AmneziaWG: нижняя граница не может быть выше верхней."
        case .hysteriaObfsMissingPassword:
            return "У обфускации Hysteria2 нет пароля: проверьте ссылку или подписку."
        case .downloadSettingsInvalid:
            return "Неверные настройки раздельной загрузки XHTTP: проверьте адрес и порт загрузки сервера."
        case .unsupportedTransport:
            return "Транспорт сервера не поддерживается: выберите сервер с другим транспортом."
        case .emptyChain:
            return "Цепочка серверов пуста: добавьте хотя бы один сервер."
        case .duplicateChainProfile:
            return "Сервер встречается в цепочке дважды: уберите повтор."
        case .featureUnavailableOnTier(_, let feature, _):
            switch feature {
            case .xhttpTransport:
                return "Транспорт XHTTP недоступен на этой версии системы: выберите другой сервер."
            case .anytls:
                return "Протокол AnyTLS недоступен на этой версии системы: выберите другой сервер."
            case .amneziaWG:
                return "AmneziaWG недоступен на этой версии системы: выберите другой сервер."
            case .hy2GeckoObfs:
                return "Обфускация Hysteria2 недоступна на этой версии системы: выберите другой сервер."
            case .tlsFragment, .echQueryServerName, .hy2HopIntervalMax,
                 .hy2BBRProfile, .utlsFingerprint:
                // Unreachable by construction (degradable features are
                // omitted, never thrown); kept total over the enum.
                return "Функция сервера недоступна на этой версии системы: выберите другой сервер."
            }
        case .dnsUntranslatableForTier:
            return "Настройки DNS нельзя перенести на эту версию системы: выберите другой сервер DNS в настройках."
        }
    }
}
