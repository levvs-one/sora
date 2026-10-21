import Foundation

/// One engine pin the Apple clients ship, as data. The generator never
/// branches on an OS version or a tier name: every version gate reads
/// `capabilities`, the single table below, whose values are measured
/// facts from `apple/Legacy/ENGINES.md` (§4 delta table, §5 corpus runs)
/// — each field cites the row it comes from.
///
/// - main: sing-box-lx 1.14.3-lx.22, the product pin (iOS 15+ / macOS 13+).
/// - legacy: sing-box-lx v1.13.13-lx.15 (iOS 13–14 / macOS 11–12, full TUN);
///   passes the main corpus 12/12 as-is (ENGINES §5.1).
/// - catalina: upstream sing-box v1.11.15 (macOS 10.15, limited mode:
///   system proxy / mixed inbound, no TUN); needs the DNS translation and
///   the feature gates of ENGINES §5.3.
public enum EngineTier: String, Codable, CaseIterable, Equatable {
    case main
    case legacy
    case catalina

    /// The exact engine build this tier renders for (ENGINES §1).
    public var engineVersion: String {
        switch self {
        case .main: return "1.14.3-lx.22"
        case .legacy: return "1.13.13-lx.15"
        case .catalina: return "1.11.15"
        }
    }

    /// The capability table of this tier's pin. All generator gating goes
    /// through these values; there is no other place a tier difference
    /// may be spelled.
    public var capabilities: EngineCapabilities {
        switch self {
        case .main: return .main
        case .legacy: return .legacy
        case .catalina: return .catalina
        }
    }

    /// Censorship/obfuscation means this tier honestly offers, derived
    /// from the same table (UI labels and plan assessment read this, so
    /// the UI can never promise what the generator cannot emit).
    public var obfuscation: ObfuscationCapabilities {
        ObfuscationCapabilities(capabilities: capabilities)
    }

    /// Features of `profile` this tier cannot emit, split by the
    /// requirement class of each feature (see `EngineFeature.isMandatory`).
    /// A stored profile is never an import error for carrying one of
    /// these: the degradable ones are marked here and simply not emitted
    /// (the ML-DSA-65 pattern of the desktop core — the field is kept in
    /// the profile, the engine never sees it); the mandatory ones make
    /// `LibboxConfigBuilder` throw `SoraConfigError.featureUnavailableOnTier`,
    /// mirroring the desktop catalog's `Missing()` refusal at selection
    /// time rather than a silent drop.
    public func unavailableFeatures(for profile: ServerProfile) -> [UnavailableFeature] {
        let caps = capabilities
        var out: [UnavailableFeature] = []

        let transportType = profile.transport.type.isEmpty ? "tcp" : profile.transport.type
        if transportType == "xhttp", !caps.xhttp {
            out.append(UnavailableFeature(feature: .xhttpTransport, profileID: profile.id))
        }
        if profile.protocol == .anytls, !caps.anytls {
            out.append(UnavailableFeature(feature: .anytls, profileID: profile.id))
        }
        if profile.protocol == .amneziaWG, !caps.amneziaWG {
            // Only the AmneziaWG parameter set is gated: a plain
            // WireGuard profile carries none and stays available
            // (ENGINES §5.3: the plain wireguard golden passes on 1.11).
            out.append(UnavailableFeature(feature: .amneziaWG, profileID: profile.id))
        }
        if profile.protocol == .hysteria2 {
            if profile.hy2Obfs == "gecko", !caps.hy2Gecko {
                out.append(UnavailableFeature(feature: .hy2GeckoObfs, profileID: profile.id))
            }
            if profile.hy2HopIntervalMax > 0, !caps.hy2HopIntervalMax {
                out.append(UnavailableFeature(feature: .hy2HopIntervalMax, profileID: profile.id))
            }
            if !profile.hy2BBRProfile.isEmpty, !caps.hy2BBRProfile {
                out.append(UnavailableFeature(feature: .hy2BBRProfile, profileID: profile.id))
            }
        }
        let tls = profile.tls
        if tls.fragment, !caps.tlsFragment {
            out.append(UnavailableFeature(feature: .tlsFragment, profileID: profile.id))
        }
        if !(tls.ech ?? "").isEmpty, !tls.echQueryServerName.isEmpty, !caps.echQueryServerName {
            out.append(UnavailableFeature(feature: .echQueryServerName, profileID: profile.id))
        }
        if !tls.fingerprint.isEmpty, !caps.utlsFingerprints.contains(tls.fingerprint) {
            out.append(UnavailableFeature(feature: .utlsFingerprint, profileID: profile.id,
                                          detail: tls.fingerprint))
        }
        return out
    }

    /// The subset of `unavailableFeatures(for:)` that must refuse a build:
    /// dropping them would fake a working config (a different protocol,
    /// transport or obfs framing than the server speaks).
    public func mandatoryUnavailableFeatures(for profile: ServerProfile) -> [UnavailableFeature] {
        unavailableFeatures(for: profile).filter { $0.feature.isMandatory }
    }
}

/// DNS wire format of a tier's engine (ENGINES §4 row 1).
public enum EngineDNSFormat: String, Codable, Equatable {
    /// sing-box 1.12+ format: typed servers (`type`/`server`/`path`).
    case new
    /// Pre-1.12 format: `address` strings, the fake-IP pool as the
    /// `dns.fakeip` block, `domain_resolver` spelled `address_resolver`.
    case legacy
}

/// The measured capability table of one engine pin. Every value is a fact
/// from `apple/Legacy/ENGINES.md`; the comment on each property names the
/// table row, and the per-tier tables below cite the probe or corpus run
/// behind a `false`.
public struct EngineCapabilities: Equatable {
    /// `http_clients` + `route.default_http_client` (ENGINES §4 row 4).
    /// When false, remote rule-sets cannot ride a reusable HTTP client:
    /// the Go renderer spells their download per rule-set
    /// (`download_detour`) for such builds. SoraCore renders no remote
    /// rule-sets today, so no tier emits either spelling here; the flag
    /// is the gate any future rule-set rendering must read.
    public var httpClients: Bool
    /// DNS server format (ENGINES §4 row 1).
    public var dnsFormat: EngineDNSFormat
    /// `route.default_domain_resolver` (ENGINES §4 row 2).
    public var defaultDomainResolver: Bool
    /// Hysteria2 `hop_interval_max` (ENGINES §4 row 8).
    public var hy2HopIntervalMax: Bool
    /// Hysteria2 `bbr_profile` (ENGINES §4 row 9).
    public var hy2BBRProfile: Bool
    /// Hysteria2 obfs type `gecko` with its packet-size fields
    /// (ENGINES §4 row 11). `salamander` exists on every tier (row 10).
    public var hy2Gecko: Bool
    /// V2Ray XHTTP transport (ENGINES §4 row 19).
    public var xhttp: Bool
    /// AmneziaWG parameters on the WireGuard endpoint
    /// (ENGINES §4 row 15).
    public var amneziaWG: Bool
    /// AnyTLS protocol (ENGINES §4 row 16).
    public var anytls: Bool
    /// Outbound TLS `fragment` (ENGINES §4 row 22).
    public var tlsFragment: Bool
    /// ECH `query_server_name` (ENGINES §4 row 21). ECH itself exists on
    /// every tier (row 20); only this field is gated.
    public var echQueryServerName: Bool
    /// uTLS fingerprint names the pin's uTLS build resolves
    /// (ENGINES §4 row 23). An unknown name is refused by the engine at
    /// load, so the generator must never emit one outside this set.
    public var utlsFingerprints: Set<String>

    public init(httpClients: Bool, dnsFormat: EngineDNSFormat, defaultDomainResolver: Bool,
                hy2HopIntervalMax: Bool, hy2BBRProfile: Bool, hy2Gecko: Bool,
                xhttp: Bool, amneziaWG: Bool, anytls: Bool, tlsFragment: Bool,
                echQueryServerName: Bool, utlsFingerprints: Set<String>) {
        self.httpClients = httpClients
        self.dnsFormat = dnsFormat
        self.defaultDomainResolver = defaultDomainResolver
        self.hy2HopIntervalMax = hy2HopIntervalMax
        self.hy2BBRProfile = hy2BBRProfile
        self.hy2Gecko = hy2Gecko
        self.xhttp = xhttp
        self.amneziaWG = amneziaWG
        self.anytls = anytls
        self.tlsFragment = tlsFragment
        self.echQueryServerName = echQueryServerName
        self.utlsFingerprints = utlsFingerprints
    }

    /// Fingerprints of the 1.12/1.13 uTLS builds (ENGINES §4 row 23,
    /// "1.12" column): the 1.11 list plus `chrome_pq_psk`.
    private static let utlsV112: Set<String> = [
        "chrome", "chrome_psk", "chrome_psk_shuffle",
        "chrome_padding_psk_shuffle", "chrome_pq", "chrome_pq_psk",
        "firefox", "edge", "safari", "360", "qq", "ios", "android",
        "random", "randomized",
    ]

    /// sing-box-lx 1.14.3-lx.22 (ENGINES §4: every gated row is present;
    /// row 23 adds only `chrome_155` over the 1.12 list).
    public static let main = EngineCapabilities(
        httpClients: true,              // row 4: есть
        dnsFormat: .new,                // row 1: новый формат
        defaultDomainResolver: true,    // row 2: есть
        hy2HopIntervalMax: true,        // row 8: есть (1.14)
        hy2BBRProfile: true,            // row 9: есть (1.14)
        hy2Gecko: true,                 // row 11: есть
        xhttp: true,                    // row 19: есть
        amneziaWG: true,                // row 15: есть
        anytls: true,                   // row 16: есть
        tlsFragment: true,              // row 22: есть
        echQueryServerName: true,       // row 21: есть
        utlsFingerprints: utlsV112.union(["chrome_155"]) // row 23: + chrome_155
    )

    /// sing-box-lx v1.13.13-lx.15 (ENGINES §4, "lx.15" column; §5.2 probes).
    /// The delta against main is exactly rows 4, 8, 9, 11 and 23 — five
    /// additive 1.14 fields the generator must not emit for this tier.
    public static let legacy = EngineCapabilities(
        httpClients: false,             // row 4: нет (probe: unknown field)
        dnsFormat: .new,                // row 1: новый формат
        defaultDomainResolver: true,    // row 2: есть
        hy2HopIntervalMax: false,       // row 8: нет (probe: unknown field)
        hy2BBRProfile: false,           // row 9: нет (probe: unknown field)
        hy2Gecko: false,                // row 11: нет (probe: unknown field)
        xhttp: true,                    // row 19: есть (probe exit 0, with_xhttp)
        amneziaWG: true,                // row 15: есть (golden amneziaWG 12/12)
        anytls: true,                   // row 16: есть (protocol/anytls)
        tlsFragment: true,              // row 22: есть (probe exit 0)
        echQueryServerName: true,       // row 21: есть (probe: field accepted)
        utlsFingerprints: utlsV112      // row 23: тот же список, что 1.12
    )

    /// Upstream sing-box v1.11.15 (ENGINES §4, "v1.11.15" column; §5.3).
    public static let catalina = EngineCapabilities(
        httpClients: false,             // row 4: нет
        dnsFormat: .legacy,             // row 1: старый формат (address-строки)
        defaultDomainResolver: false,   // row 2: нет (снимается трансляцией)
        hy2HopIntervalMax: false,       // row 8: нет
        hy2BBRProfile: false,           // row 9: нет
        hy2Gecko: false,                // row 11: нет
        xhttp: false,                   // row 19: нет (unknown transport type)
        amneziaWG: false,               // row 15: нет (probe: unknown field "h1")
        anytls: false,                  // row 16: нет (protocol/anytls отсутствует)
        tlsFragment: false,             // row 22: нет (probe: unknown field "fragment")
        echQueryServerName: false,      // row 21: нет (ECH без него — есть, row 20)
        utlsFingerprints: [             // row 23, 1.11 list: без chrome_pq_psk и chrome_155
            "chrome", "chrome_psk", "chrome_psk_shuffle",
            "chrome_padding_psk_shuffle", "chrome_pq",
            "firefox", "edge", "safari", "360", "qq", "ios", "android",
            "random", "randomized",
        ]
    )
}

/// One feature a profile asks for that a tier cannot emit. The two
/// classes are kept distinct everywhere (assessment, builder, tests):
/// a *mandatory* feature changes what the server speaks, so building
/// without it would fake a working config and the builder refuses;
/// a *degradable* one is an additive tuning/obfuscation field, so the
/// stored profile keeps it, the build omits it, and this type marks it
/// for honest UI display.
public enum EngineFeature: String, CaseIterable, Equatable {
    case xhttpTransport
    case anytls
    case amneziaWG
    case hy2GeckoObfs
    case tlsFragment
    case echQueryServerName
    case hy2HopIntervalMax
    case hy2BBRProfile
    case utlsFingerprint

    /// Whether a build for a tier lacking this feature must refuse
    /// instead of silently emitting a different connection.
    public var isMandatory: Bool {
        switch self {
        case .xhttpTransport, .anytls, .amneziaWG, .hy2GeckoObfs:
            // Protocol, transport and obfs framing: the server speaks
            // exactly this; anything else is a different connection.
            // (hy2Gecko measured on lx.15: "unknown obfs type: gecko" —
            // dropping the whole obfs block would connect unobfuscated
            // to a server expecting gecko framing.)
            return true
        case .tlsFragment, .echQueryServerName, .hy2HopIntervalMax,
             .hy2BBRProfile, .utlsFingerprint:
            // Additive fields: the connection is the same without them,
            // only tuning/obfuscation strength drops — the ML-DSA-65
            // pattern (stored, not emitted, marked unavailable).
            return false
        }
    }

    /// Technical name for diagnostics and reports (never the sole text
    /// shown to the user; `SoraConfigError.userMessage` carries the
    /// human wording).
    public var displayName: String {
        switch self {
        case .xhttpTransport: return "XHTTP transport"
        case .anytls: return "AnyTLS"
        case .amneziaWG: return "AmneziaWG"
        case .hy2GeckoObfs: return "Hysteria2 gecko obfs"
        case .tlsFragment: return "TLS fragment"
        case .echQueryServerName: return "ECH query_server_name"
        case .hy2HopIntervalMax: return "Hysteria2 hop_interval_max"
        case .hy2BBRProfile: return "Hysteria2 bbr_profile"
        case .utlsFingerprint: return "uTLS fingerprint"
        }
    }
}

/// A feature of one profile that a tier cannot emit, as returned by
/// `EngineTier.unavailableFeatures(for:)`. `detail` carries the concrete
/// value where one exists (the fingerprint name), else it is empty.
public struct UnavailableFeature: Equatable {
    public var feature: EngineFeature
    public var profileID: String
    public var detail: String

    public init(feature: EngineFeature, profileID: String, detail: String = "") {
        self.feature = feature
        self.profileID = profileID
        self.detail = detail
    }

    public var isMandatory: Bool { feature.isMandatory }
}

/// The censorship/obfuscation means of one tier, derived from
/// `EngineCapabilities` — one derivation, so the UI's honesty labels,
/// plan assessment and the generator can never disagree.
public struct ObfuscationCapabilities: Equatable {
    /// REALITY (ENGINES §4 row 5: есть на всех тирах).
    public var reality: Bool
    /// XTLS Vision flow (ENGINES §4 row 5: есть на всех тирах).
    public var vision: Bool
    /// XHTTP transport (capabilities.xhttp, row 19).
    public var xhttp: Bool
    /// ECH (ENGINES §4 row 20: есть на всех тирах).
    public var ech: Bool
    /// ECH `query_server_name` (capabilities.echQueryServerName, row 21).
    public var echQueryServerName: Bool
    /// TLS fragment (capabilities.tlsFragment, row 22).
    public var tlsFragment: Bool
    /// AmneziaWG parameter set (capabilities.amneziaWG, row 15).
    public var amneziaWG: Bool
    /// Hysteria2 obfs types: `salamander` on every tier (row 10),
    /// `gecko` only where capabilities.hy2Gecko (row 11).
    public var hy2Obfs: [String]
    /// uTLS fingerprint names (capabilities.utlsFingerprints, row 23).
    public var utlsFingerprints: Set<String>

    public init(capabilities caps: EngineCapabilities) {
        reality = true
        vision = true
        xhttp = caps.xhttp
        ech = true
        echQueryServerName = caps.echQueryServerName
        tlsFragment = caps.tlsFragment
        amneziaWG = caps.amneziaWG
        hy2Obfs = caps.hy2Gecko ? ["salamander", "gecko"] : ["salamander"]
        utlsFingerprints = caps.utlsFingerprints
    }
}
