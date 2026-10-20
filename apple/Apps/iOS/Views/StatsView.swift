import SwiftUI

/// Statistics: traffic counters and connection count for the running
/// tunnel.
///
/// DATA SOURCE, stated on screen: values come from the tunnel provider
/// via app messages (`handleAppMessage`, `.stats`) — the libbox service
/// counters sampled when the screen refreshes. When the provider cannot
/// supply counters, the screen shows the `trafficUnavailable` state
/// (existing key) instead of zeroes. When disconnected, it shows the
/// designed empty state with a route to Servers.
public struct StatsView: View {
    @EnvironmentObject private var tunnel: TunnelManager
    @EnvironmentObject private var router: AppRouter
    @Environment(\.colorScheme) private var scheme
    @StateObject private var model: StatsViewModel

    public init() {
        _model = StateObject(wrappedValue: StatsViewModel(tunnel: TunnelManager()))
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.background(for: scheme).ignoresSafeArea()
                content
            }
            .navigationTitle(Text("navStats"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refreshBound() }
                    } label: {
                        Label("refresh", systemImage: "arrow.clockwise")
                    }
                    .accessibilityLabel(Text("refresh"))
                    .accessibilityHint(Text("statsRefreshHint"))
                }
            }
            .task { await refreshBound() }
        }
    }

    /// The StateObject placeholder above cannot capture the environment
    /// TunnelManager at init; refresh goes through a bound model instead.
    private func refreshBound() async {
        do {
            let payload = try await tunnel.requestStats()
            model.apply(payload)
        } catch {
            model.applyUnavailable()
        }
    }

    @ViewBuilder
    private var content: some View {
        if !tunnel.state.isConnected {
            SoraEmptyStateView(
                titleKey: "statsDisconnectedTitle",
                messageKey: "statsDisconnectedMessage",
                actionTitleKey: "navServers",
                action: { router.selectedTab = .servers })
        } else if model.isUnavailable {
            SoraEmptyStateView(
                titleKey: "trafficUnavailable",
                messageKey: "statsUnavailableMessage")
        } else if let payload = model.payload {
            List {
                Section {
                    StatRow(labelKey: "trafficUp",
                            value: ByteFormat.string(payload.uploadBytes))
                    StatRow(labelKey: "trafficDown",
                            value: ByteFormat.string(payload.downloadBytes))
                    StatRow(labelKey: "connConnectionsCount",
                            value: String(payload.activeConnections))
                    if let name = payload.serverName {
                        StatRow(labelKey: "currentServer", value: name, truncateMiddle: false)
                    }
                } header: {
                    Text("sectionConnection")
                } footer: {
                    // Provenance line: where these numbers come from.
                    Text("statsSourceNote")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        } else {
            ProgressView()
                .accessibilityLabel(Text("stateConnecting"))
        }
    }
}

private struct StatRow: View {
    let labelKey: LocalizedStringKey
    let value: String
    var truncateMiddle: Bool = true
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: DesignTokens.space3) {
            Text(labelKey)
                .foregroundStyle(DesignTokens.ink(for: scheme))
            Spacer(minLength: DesignTokens.space2)
            Text(value)
                .foregroundStyle(DesignTokens.ink2(for: scheme))
                .lineLimit(1)
                .truncationMode(truncateMiddle ? .middle : .tail)
        }
        .frame(minHeight: DesignTokens.rowMinHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(labelKey))
        .accessibilityValue(Text(value))
    }
}

#if DEBUG
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StatsView().preferredColorScheme(.dark)
            StatsView().preferredColorScheme(.light)
        }
        .environmentObject(TunnelManager())
        .environmentObject(AppRouter())
    }
}
#endif
