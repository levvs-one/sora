import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// LEGACY REPLACEMENT — macOSLegacy target (deployment target 11.0).
///
/// Replaces: `Apps/macOS/SoraMac/Views/MainWindowView.swift`
/// (same types — `MacSection` with the same cases, titles and
/// symbols, and `MainWindowView` — so nothing else in the reused
/// code needs to know this file changed).
///
/// Why a replacement exists, two floor reasons:
///  1. Layout. The legacy window is built on the two-column
///     navigation view — the split-view idiom that exists on
///     macOS 11–12 (the split-view scene type introduced in
///     macOS 13 is not referenced). Sections are the original's
///     five, by fact of the original file: Servers, Subscriptions,
///     Settings, Statistics, About. Import lives inside Servers and
///     Subscriptions, exactly as in the original; the main macOS
///     client has no separate logs screen, so the legacy window
///     does not invent one.
///  2. The original's connect button uses the prominent bordered
///     button style introduced in macOS 12. Here the button keeps
///     its size, label and shortcut semantics with the bordered
///     style that exists on 11.
///
/// Everything else mirrors the original: the connection header and
/// the system-state banner sit on top of every section page, drag &
/// drop and URL delivery behave identically, VoiceOver order stays
/// sidebar → header → banner → content, and all spacing, colours
/// and motion come from the same `DesignTokens`.

/// Sidebar sections — identical to the original (glossary terms of
/// the main app; keys `servers`, `subscriptions`, `settings`,
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

/// Root window content for macOS 11–12: a two-column navigation
/// view — sidebar list on the left, the selected section page
/// (connection header, system-state banner, section content) on
/// the right.
public struct MainWindowView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject private var tunnel = TunnelManager.shared
    @State private var section: MacSection? = .servers
    @Environment(\.colorScheme) private var scheme

    public init() {}

    public var body: some View {
        NavigationView {
            sidebar
            sectionPage(section ?? .servers)
        }
        .frame(minWidth: 760, minHeight: 480)
        // Drag & drop of subscription/config files anywhere in the
        // window: files go to SubscriptionParser via
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
            List {
                ForEach(MacSection.allCases) { item in
                    NavigationLink(destination: sectionPage(item),
                                   tag: item, selection: $section) {
                        HStack(spacing: DesignTokens.Space.xs) {
                            Image(systemName: item.systemImage)
                                .accessibilityHidden(true)
                            Text(item.title)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .accessibilityLabel(item.title)
                    .accessibilityAddTraits(section == item ? [.isSelected] : [])
                }
            }
            .listStyle(SidebarListStyle())
        }
        .frame(width: DesignTokens.Space.sidebarWidth)
        .background(DesignTokens.surface(scheme))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(tr("mac.sidebar", "Sections"))
    }

    // MARK: Section page (header + banner + content)

    private func sectionPage(_ item: MacSection) -> some View {
        VStack(spacing: 0) {
            connectionHeader
            SystemStateBanner()
            content(for: item)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(DesignTokens.background(scheme))
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
            .buttonStyle(.bordered)
            .disabled(state.servers.isEmpty && !tunnel.phase.isConnected)
            .accessibilityLabel(tunnel.phase.isConnected
                                 ? tr("mac.disconnect", "Disconnect")
                                 : tr("mac.connect", "Connect"))
        }
        .padding(DesignTokens.Space.md)
    }

    // MARK: Content

    @ViewBuilder private func content(for item: MacSection) -> some View {
        switch item {
        case .servers: ServersView()
        case .subscriptions: SubscriptionsView()
        case .settings: SettingsView()
        case .statistics: StatisticsView()
        case .about: AboutView()
        }
    }

    // MARK: Drop handling (identical to the original)

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
