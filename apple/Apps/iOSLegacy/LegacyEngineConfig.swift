import Foundation
import SoraCore

/// Thin tier adapter: the ONE place in the legacy target where a
/// sing-box config is requested from SoraCore.
///
/// The core sub-department is adding a tier parameter to
/// `LibboxConfigBuilder` (API source-compatible, tier defaults to
/// `.main`). When that lands, the coordinator closes the legacy tier
/// by changing ONLY the marked call below to pass the tier — every
/// legacy screen, shortcut and preflight already funnels through
/// this adapter, so no other file changes.
enum LegacyEngineConfig {

    /// Engine pin for this tier (apple/Legacy/ENGINES.md): sing-box-lx
    /// v1.13.13-lx.15. The builder must not emit the five 1.14-only
    /// additions for this tier (ENGINES.md §4: `http_clients`,
    /// Hysteria2 `hop_interval_max` / `bbr_profile` / gecko obfs,
    /// uTLS `chrome_155`) — that gating is the builder's tier job;
    /// this adapter's job is to name the tier at the call site.
    static func buildConfig(profile: ServerProfile, settings: AppSettings) throws -> String {
        // tier: .legacy (iOS 13–14 pin lx.15)
        return try LibboxConfigBuilder.build(profile: profile, settings: settings)
    }

    /// Chain variant, same tier, for parity with the builder's
    /// `buildChain` entry point.
    static func buildChainConfig(profiles: [ServerProfile], settings: AppSettings) throws -> String {
        // tier: .legacy (iOS 13–14 pin lx.15)
        return try LibboxConfigBuilder.buildChain(profiles: profiles, settings: settings)
    }
}
