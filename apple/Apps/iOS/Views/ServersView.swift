import SwiftUI
import SoraCore

/// Servers screen (glossary: сервер / подписка / подключение).
/// Header: connection state + connect/disconnect for the selected
/// server. Body: profiles grouped by subscription with search and
/// swipe-to-delete. Selecting a row while connected switches the
/// tunnel to that server.
public struct ServersView: View {
    @EnvironmentObject private var tunnel: TunnelManager
    @EnvironmentObject private var servers: ServersViewModel
    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.colorScheme) private var scheme
    @State private var selectedID: String?
    @State private var showImport = false
    @State private var showEditor = false

    public init() {}

    private var selectedProfile: ServerProfile? {
        servers.profiles.first { $0.id == selectedID } ?? servers.profiles.first
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.background(for: scheme).ignoresSafeArea()
                content
            }
            .navigationTitle(Text("navServers"))
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showImport = true } label: {
                        Label("importTitle", systemImage: "square.and.arrow.down")
                    }
                    .accessibilityLabel(Text("importTitle"))
                    .accessibilityHint(Text("serversImportHint"))
                    Button { showEditor = true } label: {
                        Label("add", systemImage: "plus")
                    }
                    .accessibilityLabel(Text("customServerAdd"))
                    .accessibilityHint(Text("serversAddHint"))
                }
            }
            .searchable(text: $servers.searchText, prompt: Text("search"))
            .sheet(isPresented: $showImport) { ImportView(prefill: "") }
            .sheet(isPresented: $showEditor) { ServerEditView() }
            .alert("alertTitle", isPresented: alertPresented) {
                Button("close", role: .cancel) { servers.alertKey = nil }
            } message: {
                Text(LocalizedStringKey(servers.alertKey ?? "alert.importFailed"))
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: DesignTokens.space4) {
            statusHeader
                .padding(.horizontal, DesignTokens.pageMargin)
                .padding(.top, DesignTokens.space3)
            if servers.profiles.isEmpty {
                SoraEmptyStateView(
                    titleKey: "profilesEmpty",
                    messageKey: "serversEmptyMessage",
                    actionTitleKey: "importTitle",
                    action: { showImport = true })
                Spacer()
            } else if servers.filtered.isEmpty {
                SoraEmptyStateView(
                    titleKey: "serversSearchEmptyTitle",
                    messageKey: "serversSearchEmptyMessage",
                    actionTitleKey: "clear",
                    action: { servers.searchText = "" })
                Spacer()
            } else {
                serverList
            }
        }
    }

    // MARK: Header: honest state + the connect action

    private var statusHeader: some View {
        VStack(spacing: DesignTokens.space3) {
            HStack(spacing: DesignTokens.space2) {
                Circle()
                    .fill(statusColor)
                    .frame(width: DesignTokens.space2, height: DesignTokens.space2)
                    .accessibilityHidden(true)
                Text(LocalizedStringKey(tunnel.state.localizationKey))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DesignTokens.ink(for: scheme))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(LocalizedStringKey(tunnel.state.localizationKey)))

            if tunnel.state == .profileNotApproved || tunnel.state == .extensionNotApproved {
                // The fix lives in iOS Settings; say where, plainly.
                Text("state.vpnProfileApprovalPathIos")
                    .font(.footnote)
                    .foregroundStyle(DesignTokens.ink2(for: scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let name = tunnel.activeServerName, tunnel.state.isConnected {
                Text(name)
                    .font(.footnote)
                    .foregroundStyle(DesignTokens.ink2(for: scheme))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(Text("currentServer"))
                    .accessibilityValue(Text(name))
            }

            Button {
                toggleConnection()
            } label: {
                Text(tunnel.state.isConnected ? "disconnect" : "connect")
                    .frame(maxWidth: .infinity, minHeight: DesignTokens.hitTarget)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedProfile == nil || tunnel.state.isTransitional)
            .animation(DesignTokens.easeStandard, value: tunnel.state)
            .accessibilityLabel(Text(tunnel.state.isConnected ? "disconnect" : "connect"))
            .accessibilityHint(Text(tunnel.state.isConnected
                ? "serversDisconnectHint" : "serversConnectHint"))
        }
        .padding(DesignTokens.space4)
        .background(DesignTokens.surface(for: scheme),
                    in: RoundedRectangle(cornerRadius: DesignTokens.radiusCard))
    }

    private var statusColor: Color {
        switch tunnel.state {
        case .connected: return DesignTokens.statusOn
        case .connecting, .disconnecting, .reconnectingAfterNetworkChange:
            return DesignTokens.statusBusy
        default: return DesignTokens.statusOff
        }
    }

    private func toggleConnection() {
        if tunnel.state.isConnected {
            tunnel.disconnect()
        } else if let profile = selectedProfile {
            Task { try? await tunnel.connect(profile: profile, settings: settings.settings) }
        }
    }

    // MARK: List

    private var serverList: some View {
        List {
            ForEach(servers.groups, id: \.subscriptionID) { group in
                Section {
                    ForEach(group.profiles) { profile in
                        ServerRow(profile: profile,
                                  isSelected: profile.id == selectedProfile?.id,
                                  isActive: tunnel.state.isConnected
                                    && tunnel.activeServerName == profile.name) {
                            select(profile)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                servers.delete(profile)
                            } label: {
                                Label("delete", systemImage: "trash")
                            }
                            .accessibilityLabel(Text("delete"))
                            .accessibilityHint(Text("serversDeleteHint"))
                        }
                    }
                } header: {
                    Text(group.subscriptionID == nil
                         ? "customServers" : "subscriptionGroupTitle")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .animation(DesignTokens.easeFast, value: servers.filtered.count)
    }

    private func select(_ profile: ServerProfile) {
        selectedID = profile.id
        if tunnel.state.isConnected {
            Task { try? await tunnel.switchServer(to: profile, settings: settings.settings) }
        }
    }

    private var alertPresented: Binding<Bool> {
        Binding(get: { servers.alertKey != nil },
                set: { if !$0 { servers.alertKey = nil } })
    }
}

/// One server row. Long names truncate at the tail; addresses and keys
/// truncate in the middle — the row layout never stretches.
public struct ServerRow: View {
    public let profile: ServerProfile
    public let isSelected: Bool
    public let isActive: Bool
    public let onSelect: () -> Void
    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DesignTokens.space3) {
                VStack(alignment: .leading, spacing: DesignTokens.space1) {
                    Text(profile.name.isEmpty ? profile.address : profile.name)
                        .font(.body.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(DesignTokens.ink(for: scheme))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("\(profile.protocol.rawValue.uppercased()) · \(profile.address):\(profile.port)")
                        .font(.footnote)
                        .foregroundStyle(DesignTokens.ink2(for: scheme))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: DesignTokens.space2)
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DesignTokens.statusOn)
                        .accessibilityHidden(true)
                } else if isSelected {
                    Image(systemName: "circle.circle")
                        .foregroundStyle(DesignTokens.ink2(for: scheme))
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: DesignTokens.rowMinHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(profile.name.isEmpty ? profile.address : profile.name))
        .accessibilityValue(Text("\(profile.protocol.rawValue) \(profile.address) \(String(profile.port))"))
        .accessibilityHint(Text(isActive ? "serversRowActiveHint" : "serversRowHint"))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#if DEBUG
struct ServersView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ServersView().preferredColorScheme(.dark)
            ServersView().preferredColorScheme(.light)
        }
        .environmentObject(TunnelManager())
        .environmentObject(ServersViewModel(store: JSONFileProfileStore(directory: FileManager.default.temporaryDirectory)))
        .environmentObject(SettingsViewModel(store: JSONFileProfileStore(directory: FileManager.default.temporaryDirectory)))
    }
}
#endif
