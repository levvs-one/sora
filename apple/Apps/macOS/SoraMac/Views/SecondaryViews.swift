import SwiftUI

// MARK: - Subscriptions

/// Subscriptions: add by URL, refresh, delete (with its servers).
/// The subscription URL itself is shown truncated in the middle and
/// never written to logs — it carries the user's token.
public struct SubscriptionsView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.colorScheme) private var scheme
    @State private var newURL = ""
    @State private var newName = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            addForm
            if state.subscriptions.isEmpty {
                EmptyStateView(
                    titleKey: "mac.subscriptions.emptyTitle", titleFallback: "No subscriptions yet",
                    bodyKey: "mac.subscriptions.emptyBody",
                    bodyFallback: "Add a subscription link from your provider and its servers will appear under Servers.",
                    actionKey: "mac.subscriptions.focusField", actionFallback: "Add a subscription",
                    action: {})
            } else {
                List {
                    ForEach(state.subscriptions) { sub in
                        HStack(spacing: DesignTokens.Space.xs) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sub.name)
                                    .foregroundColor(DesignTokens.ink(scheme))
                                    .lineLimit(1).truncationMode(.tail)
                                Text(sub.urlString)
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.ink2(scheme))
                                    .lineLimit(1).truncationMode(.middle)
                                Text(sub.updatedAt.map {
                                    String(format: tr("mac.subscriptions.updated", "Updated %@"),
                                           $0.formatted(date: .abbreviated, time: .shortened))
                                } ?? tr("mac.subscriptions.never", "Not updated yet"))
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.ink3(scheme))
                                    .lineLimit(1).truncationMode(.tail)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(String(format: tr("mac.subscriptions.count", "%d servers"), sub.serverIDs.count))
                                .font(.caption)
                                .foregroundColor(DesignTokens.ink2(scheme))
                                .frame(width: 92, alignment: .trailing)
                            Button(tr("mac.subscriptions.refresh", "Refresh")) {
                                Task { await state.refreshSubscription(sub) }
                            }
                            .accessibilityLabel(String(format: tr("mac.a11y.refreshSub", "Refresh %@"), sub.name))
                            Button(tr("delete", "Delete"), role: .destructive) {
                                state.deleteSubscription(sub)
                            }
                            .accessibilityLabel(String(format: tr("mac.a11y.deleteSub", "Delete %@"), sub.name))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(sub.name), \(sub.serverIDs.count)")
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var addForm: some View {
        HStack(spacing: DesignTokens.Space.xs) {
            TextField(tr("subscriptionLink", "Subscription link"), text: $newURL)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(tr("subscriptionLink", "Subscription link"))
            TextField(tr("mac.subscriptions.name", "Name (optional)"), text: $newName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)
                .accessibilityLabel(tr("mac.subscriptions.name", "Name (optional)"))
            Button(tr("add", "Add")) {
                let url = newURL, name = newName
                newURL = ""; newName = ""
                Task { await state.addSubscription(urlString: url, name: name) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(URL(string: newURL)?.scheme?.hasPrefix("http") != true)
            .accessibilityLabel(tr("addSubscription", "Add subscription"))
        }
        .padding(DesignTokens.Space.md)
    }
}

// MARK: - Settings

/// Settings: launch at login (both backends via the capability
/// ladder), auto-reconnect (on-demand), global hot key, notifications,
/// and honest capability readouts (AppIntents / Handoff / widget) —
/// a feature that cannot work on this Mac is shown as unavailable
/// with a reason, never as a dead toggle.
public struct SettingsView: View {
    @ObservedObject private var launch = LaunchAtLogin.shared
    @ObservedObject private var hotKey = HotKeyManager.shared
    @ObservedObject private var tunnel = TunnelManager.shared
    @Environment(\.colorScheme) private var scheme
    @State private var notificationsEnabled = true

    public init() {}

    public var body: some View {
        Form {
            Section(tr("mac.settings.general", "General")) {
                Toggle(isOn: Binding(
                    get: { launch.status == .enabled },
                    set: { launch.setEnabled($0) })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tr("launchAtLogin", "Start with the system"))
                        Text(launchDetail)
                            .font(.caption).foregroundColor(DesignTokens.ink2(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .disabled(launch.status == .unavailable)
                .accessibilityLabel(tr("launchAtLogin", "Start with the system"))
                if launch.status == .requiresApproval {
                    Button(tr("mac.state.openSettings", "Open System Settings")) {
                        launch.openApprovalSettings()
                    }
                    .accessibilityLabel(tr("mac.state.openSettings", "Open System Settings"))
                }

                Toggle(isOn: $tunnel.autoReconnect) {
                    Text(tr("mac.settings.autoReconnect", "Reconnect automatically"))
                }
                .accessibilityLabel(tr("mac.settings.autoReconnect",
                                       "Reconnect automatically when the network changes or the Mac wakes"))
                Text(tr("mac.settings.autoReconnectDetail",
                        "Keeps the connection up across network changes and sleep using on-demand rules."))
                    .font(.caption).foregroundColor(DesignTokens.ink2(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section(tr("mac.settings.convenience", "Convenience")) {
                Toggle(isOn: $hotKey.isEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tr("mac.settings.hotKey", "Global hot key: Control–Option–S"))
                        Text(hotKey.isRegistered || !hotKey.isEnabled
                             ? tr("mac.settings.hotKeyDetail", "Connects or disconnects from any app.")
                             : tr("mac.settings.hotKeyConflict",
                                  "This combination is taken by another app; the hot key is inactive."))
                            .font(.caption).foregroundColor(DesignTokens.ink2(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityLabel(tr("mac.settings.hotKey", "Global hot key Control Option S"))

                Toggle(isOn: $notificationsEnabled) {
                    Text(tr("mac.settings.notifications", "Connection notifications"))
                }
                .accessibilityLabel(tr("mac.settings.notifications", "Connection notifications"))
                .onChange(of: notificationsEnabled) { _ in
                    if notificationsEnabled { NotificationManager.shared.requestAuthorization() }
                }
            }

            Section(tr("mac.settings.capabilities", "On this Mac")) {
                capabilityRow("mac.cap.appIntents", "Shortcuts (App Intents)",
                              available: FeatureAvailability.appIntentsAvailable)
                capabilityRow("mac.cap.handoff", "Handoff between Mac and iPhone",
                              available: FeatureAvailability.handoffDeclared)
                capabilityRow("mac.cap.widget", "Status widget",
                              available: FeatureAvailability.widgetEmbedded)
                capabilityRow("mac.cap.systemExtension", "System extension",
                              available: FeatureAvailability.systemExtensionEmbedded)
            }
        }
        .background(DesignTokens.background(scheme))
    }

    private var launchDetail: String {
        switch launch.status {
        case .enabled: return tr("mac.launch.enabled", "Sora opens when you log in.")
        case .disabled: return tr("launchAtLoginDetail", "Off")
        case .requiresApproval:
            return tr("state.autoLaunchUnavailable",
                      "Approve Sora in System Settings → General → Login Items to use launch at login.")
        case .unavailable:
            return tr("mac.launch.unavailable",
                      "Not available in this build (the login helper is not bundled).")
        }
    }

    private func capabilityRow(_ key: String, _ fallback: String, available: Bool) -> some View {
        HStack {
            Text(tr(key, fallback)).lineLimit(1).truncationMode(.tail)
            Spacer()
            Text(available ? tr("mac.cap.available", "Available")
                           : tr("mac.cap.unavailable", "Not available on this system"))
                .font(.caption)
                .foregroundColor(DesignTokens.ink2(scheme))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tr(key, fallback)): \(available ? tr("mac.cap.available", "Available") : tr("mac.cap.unavailable", "Not available on this system"))")
    }
}

// MARK: - Statistics

/// Statistics: session duration, traffic counters from the provider
/// (via provider messages — ARCHITECTURE §4.3), current server. When
/// disconnected it is an honest empty state, not zeroes dressed up
/// as data.
public struct StatisticsView: View {
    @ObservedObject private var tunnel = TunnelManager.shared
    @EnvironmentObject private var state: AppState
    @Environment(\.colorScheme) private var scheme
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    public init() {}

    public var body: some View {
        Group {
            if tunnel.phase.isConnected {
                Form {
                    Section(tr("currentServer", "Current server")) {
                        StatRow(label: tr("servers", "Servers"),
                                value: tunnel.currentServer?.name ?? "—")
                        StatRow(label: tr("mac.stats.duration", "Session duration"),
                                value: durationText)
                    }
                    Section(tr("mac.stats.traffic", "Traffic")) {
                        StatRow(label: tr("mac.stats.download", "Downloaded"),
                                value: ByteFormatMac.string(tunnel.downloadBytes))
                        StatRow(label: tr("mac.stats.upload", "Uploaded"),
                                value: ByteFormatMac.string(tunnel.uploadBytes))
                    }
                    Section(tr("mac.stats.library", "Library")) {
                        StatRow(label: tr("servers", "Servers"), value: "\(state.servers.count)")
                        StatRow(label: tr("subscriptions", "Subscriptions"), value: "\(state.subscriptions.count)")
                    }
                }
                        .onReceive(timer) { _ in tunnel.refreshStats() }
            } else {
                EmptyStateView(
                    titleKey: "mac.stats.emptyTitle", titleFallback: "Nothing to show yet",
                    bodyKey: "mac.stats.emptyBody",
                    bodyFallback: "Connect to a server and traffic statistics for the session will appear here.",
                    actionKey: "mac.connect", actionFallback: "Connect",
                    action: {
                        Task {
                            if let server = state.selectedServer {
                                await tunnel.connect(to: server)
                            }
                        }
                    })
            }
        }
        .background(DesignTokens.background(scheme))
    }

    private var durationText: String {
        guard let since = tunnel.connectedSince else { return "—" }
        let seconds = Int(Date().timeIntervalSince(since))
        return String(format: "%d:%02d:%02d", seconds / 3600, (seconds / 60) % 60, seconds % 60)
    }
}

/// Label/value row used instead of `LabeledContent` (macOS 13+) so
/// Statistics renders identically on macOS 11–12 (capability parity).
public struct StatRow: View {
    let label: String; let value: String
    @Environment(\.colorScheme) private var scheme
    public var body: some View {
        HStack {
            Text(label).foregroundColor(DesignTokens.ink(scheme))
                .lineLimit(1).truncationMode(.tail)
            Spacer()
            Text(value).foregroundColor(DesignTokens.ink2(scheme))
                .lineLimit(1).truncationMode(.middle)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// Byte formatting ("1.2 MB"), same helper shape as the iOS Design.
public enum ByteFormatMac {
    public static func string(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - About

/// About: name, version (from the bundle — never hard-coded),
/// product description in the main app's terms, links to the repo.
public struct AboutView: View {
    @Environment(\.colorScheme) private var scheme

    public init() {}

    public var body: some View {
        VStack(spacing: DesignTokens.Space.sm) {
            Spacer()
            Text("Sora")
                .font(.largeTitle).bold()
                .foregroundColor(DesignTokens.ink(scheme))
                .accessibilityLabel("Sora")
            Text(versionText)
                .font(.subheadline)
                .foregroundColor(DesignTokens.ink2(scheme))
                .accessibilityLabel(versionText)
            Text(tr("mac.about.tagline",
                    "An open proxy and VPN client. No hidden telemetry; the code is the showcase."))
                .font(.body)
                .foregroundColor(DesignTokens.ink2(scheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 420)
            Link(tr("mac.about.repository", "Source code on GitHub"),
                 destination: URL(string: "https://github.com/levvs-one/sora")!)
                .accessibilityLabel(tr("mac.about.repository", "Source code on GitHub"))
            Spacer()
            Text(tr("appCopyright", "© 2026 Sora contributors"))
                .font(.caption)
                .foregroundColor(DesignTokens.ink3(scheme))
        }
        .padding(DesignTokens.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.background(scheme))
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        return String(format: tr("appVersion", "Version %@"), version.isEmpty ? build : "\(version) (\(build))")
    }
}
