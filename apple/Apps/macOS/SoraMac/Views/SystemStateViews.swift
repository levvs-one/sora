import SwiftUI

/// Designed empty state (detail standard §3): a title in the main
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
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(tr(actionKey, actionFallback))
        }
        .padding(DesignTokens.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.background(scheme))
    }
}

/// Banner for the honest system states (mandate §2): extension not
/// approved, extension needs restart, VPN profile not created,
/// extension missing, App Group unavailable, failure. One banner
/// component, one text + one action per state, all from `state.*`
/// keys — raw system text never appears here.
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
                        Text(tr("state.vpnProfileApprovalPathMac",
                                "On macOS: System Settings → General → Login Items & Extensions (or Network → VPN) and approve Sora."))
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
            Button(tr("mac.state.openSettings", "Open System Settings")) {
                NSWorkspaceOpen(SystemExtensionManager.shared.approvalSettingsURL)
            }
            .accessibilityLabel(tr("mac.state.openSettings", "Open System Settings"))
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
