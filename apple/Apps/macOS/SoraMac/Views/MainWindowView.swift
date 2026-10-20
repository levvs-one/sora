import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Sidebar sections — the desktop sora set required for macOS:
/// Servers, Subscriptions, Settings, Statistics, About (glossary
/// terms of the main app; keys `servers`, `subscriptions`, `settings`,
/// `about` exist in the shared strings, Statistics is `mac.statistics`).
public enum MacSection: Int, CaseIterable, Identifiable {
    case servers, subscriptions, settings, statistics, about
    public var id: Int { rawValue }
    public var title: String {
        switch self {
        case .servers: return tr("servers", "Servers")
        case .subscriptions: return tr("subscriptions", "Subscriptions")
        case .settings: return tr("settings", "Settings")
        case .statistics: return tr("mac.statistics", "Statistics")
        case .about: return tr("about", "About")
        }
    }
    public var systemImage: String {
        switch self {
        case .servers: return "server.rack"
        case .subscriptions: return "tray.full"
        case .settings: return "gearshape"
        case .statistics: return "chart.bar"
        case .about: return "info.circle"
        }
    }
}

/// Root window content. Layout: sidebar + content, with the
/// connection header on top of the content column.
///
/// VoiceOver order (detail standard §2) is deliberate and stable:
/// connection header (status, connect button) → system-state banner →
/// section content. The sidebar is a separate accessibility container
/// reached before the content, mirroring the visual left-to-right,
/// top-to-bottom order. Every interactive element carries a label.
public struct MainWindowView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject private var tunnel = TunnelManager.shared
    @State private var section: MacSection = .servers
    @Environment(\.colorScheme) private var scheme

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            VStack(spacing: 0) {
                connectionHeader
                SystemStateBanner()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(DesignTokens.background(scheme))
        }
        .frame(minWidth: 760, minHeight: 480)
        // Drag & drop of subscription/config files anywhere in the
        // window (task §6): files go to SubscriptionParser via
        // AppState.importFile; dragged text/links to the link parser.
        .onDrop(of: [.fileURL, .plainText, .url], isTargeted: nil) { providers in
            handleDrop(providers)
        }
        .onOpenURL { url in
            DeepLinkExecutor.execute(DeepLink.parse(url), state: state)
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.xxs) {
            Text("Sora")
                .font(.title3).bold()
                .foregroundColor(DesignTokens.ink(scheme))
                .padding(.horizontal, DesignTokens.Space.md)
                .padding(.top, DesignTokens.Space.md)
                .accessibilityLabel("Sora")
            ForEach(MacSection.allCases) { item in
                Button {
                    withAnimation(DesignTokens.Motion.respectingSystem(
                        DesignTokens.Motion.fastAnimation)) { section = item }
                } label: {
                    HStack(spacing: DesignTokens.Space.xs) {
                        Image(systemName: item.systemImage)
                            .accessibilityHidden(true)
                        Text(item.title)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                    .padding(.vertical, DesignTokens.Space.xxs)
                    .padding(.horizontal, DesignTokens.Space.xs)
                    .background(section == item ? DesignTokens.field(scheme) : Color.clear)
                    .cornerRadius(DesignTokens.Radius.sm)
                }
                .buttonStyle(.plain)
                .foregroundColor(DesignTokens.ink(scheme))
                .padding(.horizontal, DesignTokens.Space.xs)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(section == item ? [.isSelected] : [])
            }
            Spacer()
        }
        .frame(width: DesignTokens.Space.sidebarWidth)
        .background(DesignTokens.surface(scheme))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(tr("mac.sidebar", "Sections"))
    }

    // MARK: Connection header

    private var connectionHeader: some View {
        HStack(spacing: DesignTokens.Space.sm) {
            VStack(alignment: .leading, spacing: DesignTokens.Space.xxs) {
                Text(tunnel.phase.localizedTitle)
                    .font(.headline)
                    .foregroundColor(DesignTokens.ink(scheme))
                    .lineLimit(1).truncationMode(.tail)
                Text(tunnel.currentServer?.name ?? state.selectedServer?.name
                     ?? tr("alert.noProfileSelected", "No server is selected. Pick a server first, then connect."))
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.ink2(scheme))
                    .lineLimit(1).truncationMode(.tail)
            }
            Spacer()
            Button {
                Task { await tunnel.toggle() }
            } label: {
                Text(tunnel.phase.isConnected || tunnel.phase == .connecting
                     ? tr("mac.disconnect", "Disconnect")
                     : tr("mac.connect", "Connect"))
                    .frame(minWidth: 110)
            }
            .buttonStyle(.borderedProminent)
            .disabled(state.servers.isEmpty && !tunnel.phase.isConnected)
            .accessibilityLabel(tunnel.phase.isConnected
                                 ? tr("mac.disconnect", "Disconnect")
                                 : tr("mac.connect", "Connect"))
        }
        .padding(DesignTokens.Space.md)
    }

    // MARK: Content

    @ViewBuilder private var content: some View {
        switch section {
        case .servers: ServersView()
        case .subscriptions: SubscriptionsView()
        case .settings: SettingsView()
        case .statistics: StatisticsView()
        case .about: AboutView()
        }
    }

    // MARK: Drop handling

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    var url: URL?
                    if let data = item as? Data { url = URL(dataRepresentation: data, relativeTo: nil) }
                    if let u = item as? URL { url = u }
                    if let s = item as? String { url = URL(string: s) }
                    guard let fileURL = url else { return }
                    Task { @MainActor in AppState.shared.importFile(at: fileURL) }
                }
                handled = true
            } else if provider.hasItemConformingToTypeIdentifier("public.plain-text") {
                provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { item, _ in
                    let text = (item as? String) ?? (item as? Data).flatMap { String(data: $0, encoding: .utf8) }
                    guard let text, !text.isEmpty else { return }
                    Task { @MainActor in AppState.shared.importText(text) }
                }
                handled = true
            }
        }
        return handled
    }
}
