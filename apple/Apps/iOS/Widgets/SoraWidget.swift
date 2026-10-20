import SwiftUI
import WidgetKit

/// Status widget (small + medium): connection state, server name and
/// session traffic.
///
/// Data rule: the widget reads ONLY the App Group snapshot the app
/// publishes (`SharedTunnelSnapshot`). It never claims live data: the
/// snapshot carries `updatedAt`, and a snapshot older than the stale
/// threshold renders the `state.widgetStaleData` line (existing key).
/// Timeline refresh is driven by the app (`WidgetCenter.reloadTimelines`
/// in TunnelManager) plus a conservative 15-minute policy refresh.
public struct SoraStatusEntry: TimelineEntry {
    public let date: Date
    public let snapshot: SharedTunnelSnapshot?
    public init(date: Date, snapshot: SharedTunnelSnapshot?) {
        self.date = date; self.snapshot = snapshot
    }
    public var isStale: Bool {
        guard let snapshot else { return true }
        return date.timeIntervalSince(snapshot.updatedAt) > 15 * 60
    }
}

public struct SoraStatusProvider: TimelineProvider {
    public init() {}

    private func currentSnapshot() -> SharedTunnelSnapshot? {
        SharedTunnelSnapshot.load(from: UserDefaults(suiteName: SoraIdentifiers.appGroup))
    }

    public func placeholder(in context: Context) -> SoraStatusEntry {
        SoraStatusEntry(date: Date(), snapshot: SharedTunnelSnapshot(state: .disconnected))
    }

    public func getSnapshot(in context: Context,
                            completion: @escaping (SoraStatusEntry) -> Void) {
        completion(SoraStatusEntry(date: Date(), snapshot: currentSnapshot()))
    }

    public func getTimeline(in context: Context,
                            completion: @escaping (Timeline<SoraStatusEntry>) -> Void) {
        let entry = SoraStatusEntry(date: Date(), snapshot: currentSnapshot())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

public struct SoraStatusWidgetView: View {
    public let entry: SoraStatusEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme

    public init(entry: SoraStatusEntry) { self.entry = entry }

    private var stateKey: String {
        switch entry.snapshot?.state {
        case .connected: return "stateConnected"
        case .connecting: return "stateConnecting"
        case .reconnecting: return "stateReconnecting"
        case .disconnecting: return "stateDisconnecting"
        case .unavailable: return "state.tunnelUnavailable"
        default: return "stateOff"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.space2) {
            HStack(spacing: DesignTokens.space2) {
                SoraMarkView(size: DesignTokens.iconSize,
                             color: DesignTokens.ink(for: scheme))
                Text(LocalizedStringKey(stateKey))
                    .font(.headline)
                    .foregroundStyle(DesignTokens.ink(for: scheme))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(LocalizedStringKey(stateKey)))

            if let name = entry.snapshot?.serverName {
                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.ink2(for: scheme))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .accessibilityLabel(Text("currentServer"))
                    .accessibilityValue(Text(name))
            }

            if family == .systemMedium, let snapshot = entry.snapshot,
               snapshot.state == .connected {
                HStack(spacing: DesignTokens.space4) {
                    Label(ByteFormat.string(snapshot.downloadBytes),
                          systemImage: "arrow.down")
                    Label(ByteFormat.string(snapshot.uploadBytes),
                          systemImage: "arrow.up")
                }
                .font(.footnote)
                .foregroundStyle(DesignTokens.ink2(for: scheme))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("navStats"))
            }

            if entry.isStale {
                Text("state.widgetStaleData")
                    .font(.caption2)
                    .foregroundStyle(DesignTokens.ink2(for: scheme))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(DesignTokens.space3)
        .background(DesignTokens.background(for: scheme))
        .widgetURL(URL(string: "sora://connect"))
    }
}

public struct SoraStatusWidget: Widget {
    public init() {}
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SoraStatusWidget", provider: SoraStatusProvider()) { entry in
            SoraStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("widgetDisplayName")
        .description("widgetDescription")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Widget extension entry point. This target also links Design.swift,
/// Design/DesignTokens.swift and PacketTunnel/TunnelConfigExchange.swift
/// (shared files — see Apps/iOS/README.md target table).
@main
public struct SoraWidgetsBundle: WidgetBundle {
    public init() {}
    public var body: some Widget {
        SoraStatusWidget()
    }
}

#if DEBUG
struct SoraWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SoraStatusWidgetView(entry: SoraStatusEntry(
                date: Date(),
                snapshot: SharedTunnelSnapshot(state: .connected, serverName: "Preview",
                                               uploadBytes: 12_000_000,
                                               downloadBytes: 48_000_000)))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .preferredColorScheme(.dark)
            SoraStatusWidgetView(entry: SoraStatusEntry(
                date: Date(), snapshot: SharedTunnelSnapshot(state: .disconnected)))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .preferredColorScheme(.light)
        }
    }
}
#endif
