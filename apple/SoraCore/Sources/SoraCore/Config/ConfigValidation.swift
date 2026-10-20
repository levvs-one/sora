import Foundation

/// Pre-generation validation with the same refusal semantics as the Go
/// core (`Outbound.Validate`, `ValidateReality`, `validateXHTTP`,
/// `validateAmneziaWG`, `validateHysteria2Tuning`). The builder runs this
/// first and never emits a config the Go core would have refused.
public enum ConfigValidation {

    public static func isVisionFlow(_ flow: String) -> Bool {
        flow == "xtls-rprx-vision" || flow == "xtls-rprx-vision-udp443"
    }

    public static func validate(_ p: ServerProfile) throws {
        let id = p.id
        if p.address.trimmingCharacters(in: .whitespaces).isEmpty {
            throw SoraConfigError.emptyAddress(profileID: id)
        }
        guard (1...65535).contains(p.port) else {
            throw SoraConfigError.invalidPort(profileID: id, port: p.port)
        }

        // Transport-scoped refusals (Go validateXHTTP).
        let transportType = p.transport.type.isEmpty ? "tcp" : p.transport.type
        let knownTransports: Set<String> = ["tcp", "ws", "grpc", "h2", "http", "httpupgrade", "xhttp", "quic"]
        guard knownTransports.contains(transportType) else {
            throw SoraConfigError.unsupportedTransport(profileID: id, transport: transportType)
        }
        let hasDownload = !p.transport.downloadAddress.isEmpty || p.transport.downloadPort != 0
        if hasDownload {
            if transportType != "xhttp" {
                throw SoraConfigError.downloadSettingsInvalid(
                    profileID: id, reason: "downloadSettings needs the xhttp transport")
            }
            if p.transport.downloadAddress.isEmpty || p.transport.downloadPort == 0 {
                throw SoraConfigError.downloadSettingsInvalid(
                    profileID: id, reason: "downloadSettings needs both a download address and a download port")
            }
            if (p.transport.mode.isEmpty ? "auto" : p.transport.mode) == "stream-one" {
                throw SoraConfigError.downloadSettingsInvalid(
                    profileID: id, reason: "downloadSettings is incompatible with mode stream-one (use stream-up)")
            }
        }

        // mux gate (Go mux.go): Reality+vision is fine, mux+vision is not.
        if p.muxEnabled, isVisionFlow(p.flow) {
            throw SoraConfigError.muxVisionConflict(profileID: id)
        }
        // XHTTP+Vision without VLESS Encryption cannot work (Go
        // validateXHTTP, PASS3 deep S3b). REALITY is not Encryption.
        let hasEncryption = !p.encryption.isEmpty && p.encryption != "none"
        if transportType == "xhttp", isVisionFlow(p.flow), !hasEncryption {
            throw SoraConfigError.xhttpVisionConflict(profileID: id)
        }

        // Credentials per protocol.
        switch p.protocol {
        case .vless, .vmess:
            if p.uuid.isEmpty { throw SoraConfigError.missingUUID(profileID: id) }
        case .trojan, .hysteria2:
            if p.password.isEmpty { throw SoraConfigError.missingPassword(profileID: id) }
        case .shadowsocks:
            if p.method.isEmpty { throw SoraConfigError.missingMethod(profileID: id) }
            if p.password.isEmpty && p.ss2022Key.isEmpty {
                throw SoraConfigError.missingPassword(profileID: id)
            }
        case .tuic:
            // TUIC v5 authenticates with uuid+password, v4 with a token:
            // either complete credential set is acceptable.
            if p.tuicToken.isEmpty {
                if p.uuid.isEmpty { throw SoraConfigError.missingUUID(profileID: id) }
                if p.password.isEmpty { throw SoraConfigError.missingPassword(profileID: id) }
            }
        case .wireguard, .amneziaWG:
            break // checked by validateWireGuard below
        }

        // Hysteria2 obfs (Go validateHysteria2Tuning): an obfs block
        // without its password is rejected by the engines at load.
        if p.protocol == .hysteria2, !p.hy2Obfs.isEmpty, p.hy2ObfsPassword.isEmpty {
            throw SoraConfigError.hysteriaObfsMissingPassword(profileID: id)
        }

        try validateTLS(p)
        if p.protocol == .wireguard || p.protocol == .amneziaWG {
            try validateWireGuard(p)
        }
    }

    private static func validateTLS(_ p: ServerProfile) throws {
        let id = p.id
        let tls = p.tls
        let echEnabled = !(tls.ech ?? "").isEmpty
        if echEnabled {
            if !tls.enabled, tls.reality == nil {
                throw SoraConfigError.echWithoutTLS(profileID: id)
            }
            if tls.reality != nil {
                throw SoraConfigError.echWithReality(profileID: id)
            }
        }
        guard let reality = tls.reality else { return }
        // Reality+vision is explicitly allowed; only the key material is
        // shape-checked, exactly like Go ValidateReality.
        if !tls.mldsa65Verify.isEmpty {
            throw SoraConfigError.realityMLDSA65Unsupported(profileID: id)
        }
        if reality.publicKey.isEmpty {
            throw SoraConfigError.realityMissingPublicKey(profileID: id)
        }
        if !isX25519PublicKey(reality.publicKey) {
            throw SoraConfigError.realityInvalidPublicKey(profileID: id)
        }
        if !reality.shortId.isEmpty, !isHexID(reality.shortId, maxBytes: 8) {
            throw SoraConfigError.realityInvalidShortID(profileID: id)
        }
    }

    private static func validateWireGuard(_ p: ServerProfile) throws {
        let id = p.id
        if p.wgPrivateKey.isEmpty {
            throw SoraConfigError.amneziaMissingPrivateKey(profileID: id)
        }
        if p.wgPeerPublicKey.isEmpty {
            throw SoraConfigError.amneziaMissingPeerPublicKey(profileID: id)
        }
        if p.wgLocalAddresses.isEmpty {
            throw SoraConfigError.amneziaMissingAddress(profileID: id)
        }
        guard let awg = p.awg else { return }
        if awg.jmin > awg.jmax {
            throw SoraConfigError.amneziaJunkRangeInverted(profileID: id)
        }
        let uses31 = !awg.headerProtectionKey.isEmpty || awg.randomTrailers || awg.disableCookies
            || [awg.contentPaddingAddition, awg.rekeyAfterTime, awg.rekeyTimeout,
                awg.rejectAfterTime, awg.keepaliveTimeout, awg.maxHandshakeAttempts]
                .contains { !($0.isEmpty || $0 == "0" || $0 == "0-0") }
        let legacyJunk = !awg.j1.isEmpty || !awg.j2.isEmpty || !awg.j3.isEmpty || awg.itime != 0
        if uses31, legacyJunk {
            throw SoraConfigError.amneziaLegacyJunkWith31(profileID: id)
        }
        if legacyJunk {
            // Sing-box refuses J1/J2/J3/Itime at render (Go singbox
            // wireguard()); refuse here with the profile context.
            throw SoraConfigError.amneziaJunkSessionUnsupported(profileID: id)
        }
    }

    /// 43 base64url characters decoding to 32 bytes (Go isX25519PublicKey).
    static func isX25519PublicKey(_ s: String) -> Bool {
        guard s.count == 43 else { return false }
        var b64 = s.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while b64.count % 4 != 0 { b64 += "=" }
        guard let raw = Data(base64Encoded: b64) else { return false }
        return raw.count == 32
    }

    static func isHexID(_ s: String, maxBytes: Int) -> Bool {
        guard !s.isEmpty, s.count <= 2 * maxBytes, s.count % 2 == 0 else { return false }
        return s.allSatisfy { $0.isHexDigit }
    }
}
