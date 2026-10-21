import SwiftUI

/// Statistics for iOS 13–14 — same data contract as the main app's
/// StatsView: values come from the tunnel provider via app messages,
/// sampled at refresh; when the provider cannot supply counters the
/// screen shows the `trafficUnavailable` state instead of zeroes;
/// when disconnected it shows the designed empty state with a route
/// to Servers. SwiftUI-1 deltas: refresh on `onAppear` (no `.task`),
/// the model is `@ObservedObject`, list style is the grouped style
/// available on iOS 13.
struct LegacyStatsView: View {
    @EnvironmentObject private var tunnel: TunnelManager
    @EnvironmentObject private var router: LegacyRouter
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var model: StatsViewModel

    init() {
        // Same placeholder pattern as the main app: StatsViewModel's
        // own tunnel reference exists for previews/tests; refresh
        // here goes through the environment's TunnelManager and the
        // model's apply methods.
        _model = ObservedObject(wrappedValue: StatsViewModel(
            tunnel: TunnelManager(store: JSONFileProfileStore.sharedContainer())))
    }

    var body: some View {
        NavigationView {
            ZStack {
                LegacyDesignTokens.background(for: scheme).edgesIgnoringSafeArea(.all)
                content
            }
            .navigationBarTitle(Text("navStats"), displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: { LegacyTask.run { await refreshBound() } }) {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibility(label: Text("refresh"))
                .accessibility(hint: Text("statsRefreshHint")))
            .onAppear { LegacyTask.run { await refreshBound() } }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func refreshBound() async {
        do {
            let payload = try await tunnel.requestStats()
            model.apply(payload)
        } catch {
            model.applyUnavailable()
        }
    }

    private var content: some View {
        Group {
            if !tunnel.state.isConnected {
                LegacyEmptyStateView(
                    titleKey: "statsDisconnectedTitle",
                    messageKey: "statsDisconnectedMessage",
                    actionTitleKey: "navServers",
                    action: { router.selectedTab = .servers })
            } else if model.isUnavailable {
                LegacyEmptyStateView(
                    titleKey: "trafficUnavailable",
                    messageKey: "statsUnavailableMessage")
            } else if model.payload != nil {
                statsList(payload: model.payload!)
            } else {
                LegacyActivityIndicator()
                    .accessibility(label: Text("stateConnecting"))
            }
        }
    }

    private func statsList(payload: TunnelStatusPayload) -> some View {
        List {
            Section(header: Text("sectionConnection"),
                    footer: Text("statsSourceNote")
                        .fixedSize(horizontal: false, vertical: true)) {
                LegacyStatRow(labelKey: "trafficUp",
                              value: LegacyByteFormat.string(payload.uploadBytes))
                LegacyStatRow(labelKey: "trafficDown",
                              value: LegacyByteFormat.string(payload.downloadBytes))
                LegacyStatRow(labelKey: "connConnectionsCount",
                              value: String(payload.activeConnections))
                if payload.serverName != nil {
                    LegacyStatRow(labelKey: "currentServer",
                                  value: payload.serverName!, truncateMiddle: false)
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}

private struct LegacyStatRow: View {
    let labelKey: LocalizedStringKey
    let value: String
    var truncateMiddle: Bool = true
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: LegacyDesignTokens.space3) {
            Text(labelKey)
                .foregroundColor(LegacyDesignTokens.ink(for: scheme))
            Spacer(minLength: LegacyDesignTokens.space2)
            Text(value)
                .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                .lineLimit(1)
                .truncationMode(truncateMiddle ? .middle : .tail)
        }
        .frame(minHeight: LegacyDesignTokens.rowMinHeight)
        .accessibilityElement(children: .combine)
        .accessibility(label: Text(labelKey))
        .accessibility(value: Text(value))
    }
}
