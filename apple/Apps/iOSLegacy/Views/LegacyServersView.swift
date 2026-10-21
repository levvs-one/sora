import SwiftUI
import SoraCore

/// Servers screen for iOS 13–14 — same content and honest states as
/// the main app's ServersView (glossary: сервер / подписка /
/// подключение), rebuilt on SwiftUI 1/2-common APIs:
///  * `NavigationView` instead of `NavigationStack` (iOS 16),
///  * a manual search field instead of `.searchable` (iOS 15),
///  * `ForEach.onDelete` instead of `.swipeActions` (iOS 15),
///  * no `@StateObject` (iOS 14): shared models come through the
///    environment (SwiftUI 1), view-owned models use `@ObservedObject`.
/// Selecting a row while connected switches the tunnel to that
/// server, exactly like the main app.
struct LegacyServersView: View {
    // Environment objects exist since SwiftUI 1, so — exactly like the
    // main app — the shared models arrive through the environment;
    // @ObservedObject is used in this target only where a view owns a
    // model outright (Import, Stats). The scene delegate injects
    // AppState's instances at the root.
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var tunnel: TunnelManager
    @EnvironmentObject private var servers: ServersViewModel
    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.colorScheme) private var scheme
    @State private var selectedID: String?
    @State private var showImport = false
    @State private var showEditor = false
    @State private var shareProfile: ServerProfile?

    private var selectedProfile: ServerProfile? {
        servers.profiles.first { $0.id == selectedID } ?? servers.profiles.first
    }

    var body: some View {
        NavigationView {
            ZStack {
                LegacyDesignTokens.background(for: scheme).edgesIgnoringSafeArea(.all)
                content
            }
            .navigationBarTitle(Text("navServers"), displayMode: .inline)
            .navigationBarItems(trailing: trailingBarItems)
            .sheet(isPresented: $showImport) {
                LegacyImportView(prefill: "")
                    .environmentObject(servers)
            }
            .sheet(isPresented: $showEditor) {
                LegacyServerEditView()
                    .environmentObject(servers)
            }
            .sheet(isPresented: shareSheetBinding) {
                Group {
                    if shareProfile != nil {
                        LegacyQRShareView(profile: shareProfile!)
                    }
                }
            }
            .alert(isPresented: alertBinding) { alert }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var trailingBarItems: some View {
        HStack(spacing: LegacyDesignTokens.space4) {
            Button(action: { showImport = true }) {
                Image(systemName: "square.and.arrow.down")
            }
            .accessibility(label: Text("importTitle"))
            .accessibility(hint: Text("serversImportHint"))
            Button(action: { showEditor = true }) {
                Image(systemName: "plus")
            }
            .accessibility(label: Text("customServerAdd"))
            .accessibility(hint: Text("serversAddHint"))
        }
    }

    // MARK: Content

    private var content: some View {
        VStack(spacing: LegacyDesignTokens.space4) {
            statusHeader
                .padding(.horizontal, LegacyDesignTokens.pageMargin)
                .padding(.top, LegacyDesignTokens.space3)
            searchField
                .padding(.horizontal, LegacyDesignTokens.pageMargin)
            if servers.profiles.isEmpty {
                LegacyEmptyStateView(
                    titleKey: "profilesEmpty",
                    messageKey: "serversEmptyMessage",
                    actionTitleKey: "importTitle",
                    action: { showImport = true })
                Spacer()
            } else if servers.filtered.isEmpty {
                LegacyEmptyStateView(
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

    /// Manual search field (the `.searchable` replacement): same
    /// model binding the main app searches through.
    private var searchField: some View {
        HStack(spacing: LegacyDesignTokens.space2) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                .accessibility(hidden: true)
            TextField("search", text: $servers.searchText)
                .accessibility(label: Text("search"))
            if !servers.searchText.isEmpty {
                Button(action: { servers.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .accessibility(label: Text("clear"))
            }
        }
        .padding(LegacyDesignTokens.space2)
        .background(LegacyDesignTokens.field(for: scheme))
        .cornerRadius(LegacyDesignTokens.radiusMedium)
    }

    // MARK: Header: honest state + the connect action

    private var statusHeader: some View {
        VStack(spacing: LegacyDesignTokens.space3) {
            HStack(spacing: LegacyDesignTokens.space2) {
                Circle()
                    .fill(statusColor)
                    .frame(width: LegacyDesignTokens.space2,
                           height: LegacyDesignTokens.space2)
                    .accessibility(hidden: true)
                Text(LocalizedStringKey(tunnel.state.localizationKey))
                    .font(Font.subheadline.weight(.medium))
                    .foregroundColor(LegacyDesignTokens.ink(for: scheme))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibility(label: Text(LocalizedStringKey(tunnel.state.localizationKey)))

            if tunnel.state == .profileNotApproved || tunnel.state == .extensionNotApproved {
                // The fix lives in iOS Settings; say where, plainly —
                // same hint key as the main app.
                Text("state.vpnProfileApprovalPathIos")
                    .font(.footnote)
                    .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                    .frame(maxWidth: CGFloat.infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if tunnel.state.isConnected {
                if let name = tunnel.activeServerName {
                    Text(name)
                        .font(.footnote)
                        .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: CGFloat.infinity, alignment: .leading)
                        .accessibility(label: Text("currentServer"))
                        .accessibility(value: Text(name))
                }
            }

            Button(action: toggleConnection) {
                Text(tunnel.state.isConnected ? "disconnect" : "connect")
                    .frame(maxWidth: CGFloat.infinity,
                           minHeight: LegacyDesignTokens.hitTarget)
            }
            .buttonStyle(LegacyProminentButtonStyle())
            .disabled(selectedProfile == nil || tunnel.state.isTransitional)
            .animation(LegacyDesignTokens.easeStandard)
            .accessibility(label: Text(tunnel.state.isConnected ? "disconnect" : "connect"))
            .accessibility(hint: Text(tunnel.state.isConnected
                ? "serversDisconnectHint" : "serversConnectHint"))
        }
        .padding(LegacyDesignTokens.space4)
        .background(
            RoundedRectangle(cornerRadius: LegacyDesignTokens.radiusCard)
                .fill(LegacyDesignTokens.surface(for: scheme)))
    }

    private var statusColor: Color {
        switch tunnel.state {
        case .connected: return LegacyDesignTokens.statusOn
        case .connecting, .disconnecting, .reconnectingAfterNetworkChange:
            return LegacyDesignTokens.statusBusy
        default: return LegacyDesignTokens.statusOff
        }
    }

    private func toggleConnection() {
        if tunnel.state.isConnected {
            appState.disconnect()
            LegacyShortcuts.donate(action: LegacyShortcuts.disconnectAction)
        } else if let profile = selectedProfile {
            selectedID = profile.id
            appState.connect(profile: profile)
            LegacyShortcuts.donate(action: LegacyShortcuts.connectAction)
        }
    }

    // MARK: List

    private var serverList: some View {
        List {
            ForEach(servers.groups, id: \.subscriptionID) { group in
                Section(header: groupHeader(group.subscriptionID)) {
                    ForEach(group.profiles) { profile in
                        LegacyServerRow(profile: profile,
                                        isSelected: profile.id == selectedProfile?.id,
                                        isActive: tunnel.state.isConnected
                                            && tunnel.activeServerName == profile.name) {
                            select(profile)
                        }
                        .contextMenu {
                            Button(action: { shareProfile = profile }) {
                                LegacyLabel(titleKey: "qrShareTitle", systemImage: "qrcode")
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { servers.delete(group.profiles[index]) }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .animation(LegacyDesignTokens.easeFast)
    }

    private func groupHeader(_ subscriptionID: String?) -> some View {
        Text(subscriptionID == nil ? "customServers" : "subscriptionGroupTitle")
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private func select(_ profile: ServerProfile) {
        selectedID = profile.id
        if tunnel.state.isConnected {
            appState.switchServer(to: profile)
        }
    }

    // MARK: Sheets / alert plumbing

    private var shareSheetBinding: Binding<Bool> {
        Binding(get: { shareProfile != nil && selectedProfile != nil },
                set: { if !$0 { shareProfile = nil } })
    }

    private var alertBinding: Binding<Bool> {
        Binding(get: { servers.alertKey != nil },
                set: { if !$0 { servers.alertKey = nil } })
    }

    private var alert: Alert {
        Alert(title: Text("alertTitle"),
              message: Text(LocalizedStringKey(servers.alertKey ?? "alert.importFailed")),
              dismissButton: .cancel(Text("close")) { servers.alertKey = nil })
    }
}

/// One server row (mirror of the main app's ServerRow). Long names
/// truncate at the tail; addresses truncate in the middle — the row
/// layout never stretches (§8.5).
struct LegacyServerRow: View {
    let profile: ServerProfile
    let isSelected: Bool
    let isActive: Bool
    let onSelect: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: LegacyDesignTokens.space3) {
                VStack(alignment: .leading, spacing: LegacyDesignTokens.space1) {
                    Text(profile.name.isEmpty ? profile.address : profile.name)
                        .font(isSelected ? Font.body.weight(.semibold) : .body)
                        .foregroundColor(LegacyDesignTokens.ink(for: scheme))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("\(profile.protocol.rawValue.uppercased()) · \(profile.address):\(profile.port)")
                        .font(.footnote)
                        .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: LegacyDesignTokens.space2)
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(LegacyDesignTokens.statusOn)
                        .accessibility(hidden: true)
                } else if isSelected {
                    Image(systemName: "circle.circle")
                        .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                        .accessibility(hidden: true)
                }
            }
            .frame(minHeight: LegacyDesignTokens.rowMinHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibility(label: Text(profile.name.isEmpty ? profile.address : profile.name))
        .accessibility(value: Text("\(profile.protocol.rawValue) \(profile.address) \(String(profile.port))"))
        .accessibility(hint: Text(isActive ? "serversRowActiveHint" : "serversRowHint"))
        .accessibility(addTraits: isSelected ? .isSelected : [])
    }
}
