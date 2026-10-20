import Foundation

/// User-facing tunnel states. Rule of the house (parity with the Flutter
/// app, where `CoreFailure` maps to localized text): the UI never shows a
/// raw system error string. Every state below renders through a
/// localization key; the `state.*` keys are the shared namespace owned by
/// the localization sub-department and are picked up from this code.
///
/// Keys already present in `apple/Localizations/Localizable.xcstrings`
/// are marked (existing); the rest are new proposals in the same
/// namespace, listed in Apps/iOS/README.md for the localization pass.
public enum TunnelUIState: Equatable, Sendable {
    /// No NETunnelProviderManager configuration exists yet — the user
    /// has not created a VPN profile in Sora.
    case profileMissing            // state.vpnProfileMissing (new)
    /// Configuration exists but iOS has not approved it (the system
    /// "Allow VPN configuration" prompt was dismissed), or the tunnel
    /// extension is not approved in Settings.
    case profileNotApproved        // state.vpnProfileNotApproved (existing)
    case extensionNotApproved      // state.extensionNotApproved (existing)
    /// Where the user fixes approval on iOS (shown as a hint line).
    /// Rendered alongside the two cases above.
    // hint key: state.vpnProfileApprovalPathIos (existing)
    case disconnected              // stateOff (existing)
    case connecting                // stateConnecting (existing)
    case connected                 // stateConnected (existing)
    /// iOS reports `.reasserting`: network changed under a live tunnel.
    case reconnectingAfterNetworkChange // state.reconnectingAfterNetworkChange (existing)
    case networkOffline            // state.networkChangedOffline (existing)
    case disconnecting             // stateDisconnecting (existing)
    /// The provider binary/framework is unavailable on this build
    /// (e.g. libbox not linked). Honest dead end, not a fake spinner.
    case tunnelUnavailable         // state.tunnelUnavailable (new)
    /// The App Group container could not be opened — app and extension
    /// cannot exchange the config.
    case appGroupUnavailable       // state.appGroupUnavailable (existing)

    /// Localization key rendered for this state. Never a raw error.
    public var localizationKey: String {
        switch self {
        case .profileMissing: return "state.vpnProfileMissing"
        case .profileNotApproved: return "state.vpnProfileNotApproved"
        case .extensionNotApproved: return "state.extensionNotApproved"
        case .disconnected: return "stateOff"
        case .connecting: return "stateConnecting"
        case .connected: return "stateConnected"
        case .reconnectingAfterNetworkChange: return "state.reconnectingAfterNetworkChange"
        case .networkOffline: return "state.networkChangedOffline"
        case .disconnecting: return "stateDisconnecting"
        case .tunnelUnavailable: return "state.tunnelUnavailable"
        case .appGroupUnavailable: return "state.appGroupUnavailable"
        }
    }

    public var isTransitional: Bool {
        switch self {
        case .connecting, .disconnecting, .reconnectingAfterNetworkChange: return true
        default: return false
        }
    }

    public var isConnected: Bool { self == .connected }
}

/// Errors the app layer itself produces. Each case maps to a localized,
/// user-readable alert — the associated raw values are for logs only and
/// must never reach a label.
public enum SoraAppError: Error, Equatable {
    case noProfileSelected          // alert.noProfileSelected (new)
    case configBuildFailed          // alert.configBuildFailed (new)
    case profileStoreFailed         // alert.profileStoreFailed (new)
    case importFailed(reasonKey: String) // key supplied by the parser mapping
    case cameraUnavailable          // qrNoCamera (existing)
    case providerMessageFailed      // alert.providerMessageFailed (new)

    public var localizationKey: String {
        switch self {
        case .noProfileSelected: return "alert.noProfileSelected"
        case .configBuildFailed: return "alert.configBuildFailed"
        case .profileStoreFailed: return "alert.profileStoreFailed"
        case .importFailed(let key): return key
        case .cameraUnavailable: return "qrNoCamera"
        case .providerMessageFailed: return "alert.providerMessageFailed"
        }
    }
}

/// Maps a SoraCore parse failure to a localization key, mirroring the
/// Flutter app's CoreFailure -> l10n mapping. Unknown failures collapse
/// to one honest generic key; the raw error goes to the log, not the UI.
public enum ParseFailureLocalization {
    public static func key(forErrorDescription description: String) -> String {
        let lower = description.lowercased()
        if lower.contains("unsupported") || lower.contains("scheme") {
            return "qrInvalid" // existing: link not recognized
        }
        if lower.contains("base64") || lower.contains("malformed") || lower.contains("invalid") {
            return "qrInvalid"
        }
        return "alert.importFailed" // (new) generic import failure
    }
}
