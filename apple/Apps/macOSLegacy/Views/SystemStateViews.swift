import SwiftUI

/// LEGACY REPLACEMENT — macOSLegacy target (deployment target 11.0).
///
/// Replaces: `Apps/macOS/SoraMac/Views/SystemStateViews.swift`
/// (same types — `EmptyStateView`, `SystemStateBanner` — same
/// initialisers, so every reused and replaced view compiles
/// unchanged against these).
///
/// Why a replacement exists, two deltas, both honest-floor items:
///  1. The original's empty-state action uses the prominent bordered
///     button style introduced in macOS 12; here it is the bordered
///     style that exists on macOS 11, with the default-action
///     shortcut marking it as the primary action.
///  2. The extension-approval hint. The original points at the
///     current system's Settings wording (the shared
///     `state.vpnProfileApprovalPathMac` string describes the
///     macOS 13+ pane). On macOS 11–12 approval happens in System
///     Preferences → Security & Privacy → General, so the banner
///     uses the legacy-only string `mac.legacy.extensionApprovalPath`
///     (listed in TARGET-NOTES.md for the localisation pass). The
///     button still opens the security pane through the reused
///     `SystemExtensionManager` — the same anchor lands in Security
///     & Privacy on 11–12.
/// Everything else — states, actions, tokens, motion — is the
/// original's.

/// Designed empty state (detail standard §8): a title in the main
/// app's glossary terms, one sentence on what to do, and one action.
/// Never a blank list, never a dead end.
public struct EmptyStateView: View {
    let titleKey: String; let titleFallback: String
    let bodyKey: String; let bodyFallback: String
    let actionKey: String; let actionFallback: String
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        VStack(spacing: DesignTokens.Space.sm) {
            Text(tr(titleKey, titleFallback))
                .font(.headline)
                .foregroundColor(DesignTokens.ink(scheme))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .truncationMode(.tail)
            Text(tr(bodyKey, bodyFallback))
                .font(.subheadline)
                .foregroundColor(DesignTokens.ink2(scheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button(tr(actionKey, actionFallback), action: action)
                .buttonStyle(.bordered)
                .keyboardShortcut(.defaultAction)
                .accessibilityLabel(tr(actionKey, actionFallback))
        }
        .padding(DesignTokens.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.background(scheme))
    }
}

/// Banner for the honest system states: extension not approved,
/// extension needs restart, VPN profile not created, extension
/// missing, App Group unavailable, failure. One banner component,
/// one text + one action per state, all from `state.*` keys (plus
/// the one legacy approval-path key noted in the header) — raw
/// system text never appears here.
public struct SystemStateBanner: View {
    @ObservedObject private var tunnel = TunnelManager.shared
    @ObservedObject private var ext = SystemExtensionManager.shared
    @Environment(\.colorScheme) private var scheme

    public init() {}

    public var body: some View {
        if tunnel.phase.needsAttention {
            HStack(alignment: .top, spacing: DesignTokens.Space.xs) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(DesignTokens.ink2(scheme))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DesignTokens.Space.xxs) {
                    Text(tunnel.phase.localizedTitle)
                        .font(.subheadline).bold()
                        .foregroundColor(DesignTokens.ink(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                    if tunnel.phase == .extensionNotApproved {
                        Text(tr("mac.legacy.extensionApprovalPath",
                                "On this system: open System Preferences → Security & Privacy → General and allow Sora when it appears there."))
                            .font(.caption)
                            .foregroundColor(DesignTokens.ink2(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: DesignTokens.Space.xs)
                actionButton
            }
            .padding(DesignTokens.Space.sm)
            .background(DesignTokens.field(scheme))
            .cornerRadius(DesignTokens.Radius.md)
            .padding(.horizontal, DesignTokens.Space.md)
            .padding(.top, DesignTokens.Space.xs)
            .transition(.opacity)
            .animation(DesignTokens.Motion.respectingSystem(DesignTokens.Motion.fastAnimation),
                       value: tunnel.phase)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(tunnel.phase.localizedTitle)
        }
    }

    @ViewBuilder private var actionButton: some View {
        switch tunnel.phase {
        case .extensionNotApproved, .extensionMissing:
            Button(tr("mac.state.openSettings", "Open System Preferences")) {
                NSWorkspaceOpen(SystemExtensionManager.shared.approvalSettingsURL)
            }
            .accessibilityLabel(tr("mac.state.openSettings", "Open System Preferences"))
        case .extensionNeedsRestart:
            Button(tr("mac.state.retryExtension", "Retry")) { ext.activate() }
                .accessibilityLabel(tr("mac.state.retryExtension", "Retry activating the extension"))
        case .profileNotCreated:
            Button(tr("mac.state.createProfile", "Create profile")) {
                Task {
                    if let server = AppState.shared.selectedServer {
                        await TunnelManager.shared.connect(to: server)
                    }
                }
            }
            .accessibilityLabel(tr("mac.state.createProfile", "Create the VPN profile"))
        default:
            Button(tr("mac.state.retry", "Retry")) {
                Task { await TunnelManager.shared.bootstrap() }
            }
            .accessibilityLabel(tr("mac.state.retry", "Retry"))
        }
    }
}
