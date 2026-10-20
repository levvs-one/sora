import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Servers (task §1): searchable list, import from file / clipboard /
/// link, one-click connect/switch, delete. Detail standard §4:
/// names truncate at the TAIL, addresses in the MIDDLE, column widths
/// are fixed by tokens so a long name can never reflow the table.
public struct ServersView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject private var tunnel = TunnelManager.shared
    @Environment(\.colorScheme) private var scheme
    @State private var showingImportSheet = false
    @State private var importDraft = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            if let message = state.importMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(DesignTokens.ink2(scheme))
                    .lineLimit(2).truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.Space.md)
                    .padding(.bottom, DesignTokens.Space.xs)
                    .accessibilityLabel(message)
            }
            if state.servers.isEmpty {
                EmptyStateView(
                    titleKey: "mac.servers.emptyTitle", titleFallback: "No servers yet",
                    bodyKey: "mac.servers.emptyBody",
                    bodyFallback: "Import a subscription or paste a server link — it takes one step.",
                    actionKey: "mac.servers.import", actionFallback: "Import…",
                    action: { showingImportSheet = true })
            } else if state.filteredServers.isEmpty {
                EmptyStateView(
                    titleKey: "speedtestEmpty", titleFallback: "No matches. Change the search.",
                    bodyKey: "mac.servers.noMatchBody",
                    bodyFallback: "No server matches the search. Clear the search to see all servers.",
                    actionKey: "mac.servers.clearSearch", actionFallback: "Clear search",
                    action: { state.searchText = "" })
            } else {
                List {
                    ForEach(state.filteredServers) { server in
                        row(for: server)
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showingImportSheet) { importSheet }
        .animation(DesignTokens.Motion.respectingSystem(DesignTokens.Motion.mediumAnimation),
                   value: state.servers.count)
    }

    // MARK: Toolbar

    private var toolbar: some View {
        HStack(spacing: DesignTokens.Space.xs) {
            HStack(spacing: DesignTokens.Space.xxs) {
                Image(systemName: "magnifyingglass").accessibilityHidden(true)
                TextField(tr("search", "Search"), text: $state.searchText)
                    .textFieldStyle(.plain)
                    .accessibilityLabel(tr("search", "Search"))
            }
            .padding(DesignTokens.Space.xs)
            .background(DesignTokens.field(scheme))
            .cornerRadius(DesignTokens.Radius.sm)

            Menu {
                Button(tr("mac.import.fromFile", "From file…")) { pickFile() }
                    .accessibilityLabel(tr("mac.import.fromFile", "Import from file"))
                Button(tr("qrFromClipboard", "Paste from clipboard")) { state.importClipboard() }
                    .accessibilityLabel(tr("qrFromClipboard", "Paste from clipboard"))
                Button(tr("mac.import.fromText", "From link or text…")) { showingImportSheet = true }
                    .accessibilityLabel(tr("mac.import.fromText", "Import from link or text"))
            } label: {
                Label(tr("mac.servers.import", "Import…"), systemImage: "plus")
            }
            .accessibilityLabel(tr("mac.servers.import", "Import servers"))
        }
        .padding(DesignTokens.Space.md)
    }

    // MARK: Row

    private func row(for server: ServerRow) -> some View {
        let isCurrent = tunnel.currentServer?.id == server.id && tunnel.phase.isConnected
        let isSelected = state.selectedServerID == server.id
        return HStack(spacing: DesignTokens.Space.xs) {
            Image(systemName: isCurrent ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCurrent ? DesignTokens.ink(scheme) : DesignTokens.ink3(scheme))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.body)
                    .foregroundColor(DesignTokens.ink(scheme))
                    .lineLimit(1)
                    .truncationMode(.tail) // names: tail (§4)
                Text(server.endpointLabel)
                    .font(.caption)
                    .foregroundColor(DesignTokens.ink2(scheme))
                    .lineLimit(1)
                    .truncationMode(.middle) // addresses: middle (§4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(server.protoLabel)
                .font(.caption).bold()
                .foregroundColor(DesignTokens.ink2(scheme))
                .lineLimit(1)
                .frame(width: 92, alignment: .trailing) // fixed column (§4)
            Button(isCurrent ? tr("mac.disconnect", "Disconnect") : tr("mac.connect", "Connect")) {
                if isCurrent { tunnel.disconnect() }
                else { Task { await tunnel.connect(to: server) } }
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(isCurrent
                                 ? String(format: tr("mac.a11y.disconnectFrom", "Disconnect from %@"), server.name)
                                 : String(format: tr("mac.a11y.connectTo", "Connect to %@"), server.name))
        }
        .frame(height: DesignTokens.Space.serverRowHeight)
        .contentShape(Rectangle())
        .onTapGesture { state.select(server) } // one-click select/switch
        .background(isSelected ? DesignTokens.field(scheme) : Color.clear)
        .cornerRadius(DesignTokens.Radius.sm)
        .contextMenu {
            Button(tr("mac.connect", "Connect")) { Task { await tunnel.connect(to: server) } }
            Button(tr("delete", "Delete"), role: .destructive) { state.deleteServer(server) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(server.name), \(server.protoLabel), \(server.endpointLabel)")
        .accessibilityHint(isCurrent ? tr("mac.disconnect", "Disconnect") : tr("mac.connect", "Connect"))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: Import

    private var importSheet: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.sm) {
            Text(tr("mac.import.title", "Import servers or a subscription"))
                .font(.headline)
                .foregroundColor(DesignTokens.ink(scheme))
            TextEditor(text: $importDraft)
                .frame(minHeight: 120)
                .font(.body)
                .accessibilityLabel(tr("mac.import.title", "Import servers or a subscription"))
            Text(tr("mac.import.hint",
                    "Paste one or more server links, a subscription URL, or a config. Nothing is sent anywhere — parsing happens on this Mac."))
                .font(.caption)
                .foregroundColor(DesignTokens.ink2(scheme))
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button(tr("cancel", "Cancel")) { showingImportSheet = false }
                    .accessibilityLabel(tr("cancel", "Cancel"))
                Button(tr("add", "Add")) {
                    state.importText(importDraft)
                    importDraft = ""
                    showingImportSheet = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(importDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel(tr("add", "Add"))
            }
        }
        .padding(DesignTokens.Space.md)
        .frame(width: 460)
        .background(DesignTokens.background(scheme))
    }

    private func pickFile() {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = tr("mac.import.pickFile", "Choose a subscription or config file")
        if panel.runModal() == .OK, let url = panel.url {
            state.importFile(at: url)
        }
        #endif
    }
}
