import Foundation
import SwiftUI
#if canImport(WidgetKit)
import WidgetKit

/// Status widget for macOS (mandate §3; ARCHITECTURE.md §4.4).
///
/// Data source: ONLY the App Group snapshot (`sora.tunnel.snapshot.v1`,
/// the `SharedTunnelSnapshot` shape from
/// `apple/PacketTunnel/TunnelConfigExchange.swift`, mirrored in the
/// widget target below). The widget never talks to the provider and
/// never goes to the network; interactive connect/disconnect is not
/// promised on widget surfaces that cannot do it — a tap opens the
/// app, on every supported macOS version.
///
/// Stale data is honest: if the snapshot is older than the freshness
/// window, the widget shows the stale notice (`state.widgetStaleData`)
/// instead of presenting old state as live.
public struct SoraStatusEntry: TimelineEntry {
    public var date: Date
    public var snapshot: SharedTunnelSnapshotMirror?
    public var isStale: Bool { snapshot.map { Date().timeIntervalSince($0.updatedAt) > 300 } ?? true }
}

public struct SharedTunnelSnapshotMirror: Codable, Equatable, Sendable {
    public enum State: String, Codable, Sendable {
        case disconnected, connecting, connected, reconnecting, disconnecting, unavailable
    }
    public var state: State
    public var serverName: String?
    public var uploadBytes: Int64
    public var downloadBytes: Int64
    public var updatedAt: Date
}

public struct SoraStatusProvider: TimelineProvider {
    public init() {}
    private func load() -> SharedTunnelSnapshotMirror? {
        guard let defaults = UserDefaults(suiteName: "group.io.github.levvs-one.sora"),
              let data = defaults.data(forKey: "sora.tunnel.snapshot.v1")
        else { return nil }
        return try? JSONDecoder().decode(SharedTunnelSnapshotMirror.self, from: data)
    }
    public func placeholder(in context: Context) -> SoraStatusEntry {
        SoraStatusEntry(date: Date(), snapshot: nil)
    }
    public func getSnapshot(in context: Context, completion: @escaping (SoraStatusEntry) -> Void) {
        completion(SoraStatusEntry(date: Date(), snapshot: load()))
    }
    public func getTimeline(in context: Context, completion: @escaping (Timeline<SoraStatusEntry>) -> Void) {
        let entry = SoraStatusEntry(date: Date(), snapshot: load())
        // The app reloads timelines on every state change
        // (WidgetCenter.reloadTimelines); the 15-minute policy is
        // only a safety net, never the freshness mechanism.
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

public struct SoraStatusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme
    public var entry: SoraStatusEntry
    public init(entry: SoraStatusEntry) { self.entry = entry }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sora").font(.headline).lineLimit(1).truncationMode(.tail)
            Text(statusText)
                .font(.subheadline)
                .lineLimit(1).truncationMode(.tail)
            if let name = entry.snapshot?.serverName {
                Text(name).font(.caption)
                    .lineLimit(1).truncationMode(.tail)
            }
            if family != .systemSmall, let snap = entry.snapshot, snap.state == .connected {
                Text("\(byteText(snap.downloadBytes)) ↓  \(byteText(snap.uploadBytes)) ↑")
                    .font(.caption)
                    .lineLimit(1).truncationMode(.middle)
            }
            if entry.isStale {
                Text(NSLocalizedString("state.widgetStaleData", comment: ""))
                    .font(.caption2)
                    .lineLimit(2).truncationMode(.tail)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var statusText: String {
        switch entry.snapshot?.state {
        case .connected: return NSLocalizedString("stateConnected", comment: "")
        case .connecting: return NSLocalizedString("stateConnecting", comment: "")
        case .reconnecting: return NSLocalizedString("stateReconnecting", comment: "")
        case .disconnecting: return NSLocalizedString("stateDisconnecting", comment: "")
        case .unavailable: return NSLocalizedString("state.tunnelUnavailable", comment: "")
        default: return NSLocalizedString("stateOff", comment: "")
        }
    }
    private var accessibilityText: String {
        var text = "Sora: \(statusText)"
        if let name = entry.snapshot?.serverName { text += ", \(name)" }
        return text
    }
    private func byteText(_ bytes: Int64) -> String {
        let f = ByteCountFormatter(); f.countStyle = .binary
        return f.string(fromByteCount: bytes)
    }
}

public struct SoraStatusWidget: Widget {
    public init() {}
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SoraStatusWidget", provider: SoraStatusProvider()) { entry in
            SoraStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Sora")
        .description(NSLocalizedString("mac.widget.description", comment: ""))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
public struct SoraWidgetsMacBundle: WidgetBundle {
    public init() {}
    public var body: some Widget {
        SoraStatusWidget()
    }
}
#endif
