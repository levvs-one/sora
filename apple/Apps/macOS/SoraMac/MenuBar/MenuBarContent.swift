import SwiftUI

/// Content of the menu-bar popover (modern backend) and the model the
/// legacy status-item menu mirrors item-for-item. One source of
/// behaviour for both backends (task §2): status line, current server,
/// Connect/Disconnect, quick server switch, Open Sora, Quit.
///
/// Detail standard §3: with ZERO servers the menu is not dead — it
/// offers "Import…" and "Add subscription…" and explains the state.
/// §4: server names truncate at the tail, one line, fixed popover
/// width from tokens. §2: every item has an accessibility label.
public struct MenuBarContent: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject private var tunnel = TunnelManager.shared
    @Environment(\.colorScheme) private var scheme
    var openMainWindow: () -> Void = {}

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.xs) {
            // Status line
            HStack(spacing: DesignTokens.Space.xs) {
                Circle()
                    .fill(tunnel.phase.isConnected ? DesignTokens.Palette.spectrum[2] : DesignTokens.ink3(scheme))
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(tunnel.phase.localizedTitle)
                        .font(.headline)
                        .foregroundColor(DesignTokens.ink(scheme))
                        .lineLimit(1).truncationMode(.tail)
                    Text(tunnel.currentServer?.name ?? state.selectedServer?.name
                         ?? tr("alert.noProfileSelected", "No server is selected. Pick a server first, then connect."))
                        .font(.caption)
                        .foregroundColor(DesignTokens.ink2(scheme))
                        .lineLimit(1).truncationMode(.tail)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(tunnel.phase.localizedTitle), \(tunnel.currentServer?.name ?? state.selectedServer?.name ?? "")")

            Divider()

            if state.servers.isEmpty {
                // Not a dead menu (§3): explain + offer import paths.
                Text(tr("mac.menu.noServers", "No servers yet. Import a subscription or paste a server link to get started."))
                    .font(.caption)
                    .foregroundColor(DesignTokens.ink2(scheme))
                    .fixedSize(horizontal: false, vertical: true)
                Button(tr("mac.servers.import", "Import…")) {
                    openMainWindow()
                    NotificationCenter.default.post(name: .soraOpenImport, object: nil)
                }
                .accessibilityLabel(tr("mac.servers.import", "Import servers"))
                Button(tr("qrFromClipboard", "Paste from clipboard")) { state.importClipboard() }
                    .accessibilityLabel(tr("qrFromClipboard", "Paste from clipboard"))
            } else {
                Button(tunnel.phase.isConnected ? tr("mac.disconnect", "Disconnect")
                                                : tr("mac.connect", "Connect")) {
                    Task { await tunnel.toggle() }
                }
                .accessibilityLabel(tunnel.phase.isConnected ? tr("mac.disconnect", "Disconnect")
                                                             : tr("mac.connect", "Connect"))

                Divider()

                // Quick switch: first 8 servers, current one ticked.
                ForEach(Array(state.servers.prefix(8))) { server in
                    Button {
                        state.select(server)
                        Task { await tunnel.connect(to: server) }
                    } label: {
                        HStack {
                            Text(server.name).lineLimit(1).truncationMode(.tail)
                            Spacer()
                            if tunnel.currentServer?.id == server.id, tunnel.phase.isConnected {
                                Image(systemName: "checkmark").accessibilityHidden(true)
                            }
                        }
                    }
                    .accessibilityLabel(String(format: tr("mac.a11y.connectTo", "Connect to %@"), server.name))
                    .accessibilityAddTraits(tunnel.currentServer?.id == server.id ? [.isSelected] : [])
                }
            }

            Divider()

            Button(tr("mac.menu.open", "Open Sora")) { openMainWindow() }
                .accessibilityLabel(tr("mac.menu.open", "Open Sora"))
            Button(tr("mac.menu.quit", "Quit Sora")) {
                #if canImport(AppKit)
                NSApp.terminate(nil)
                #endif
            }
            .keyboardShortcut("q")
            .accessibilityLabel(tr("mac.menu.quit", "Quit Sora"))
        }
        .padding(DesignTokens.Space.sm)
        .frame(width: DesignTokens.Space.menuPopoverWidth)
        .background(DesignTokens.background(scheme))
    }
}

public extension Notification.Name {
    /// Posted by the menu bar / status item when the user picks
    /// "Import…" with no main window focused; MainWindowView's scene
    /// opens the servers section in response (AppDelegate forwards).
    static let soraOpenImport = Notification.Name("io.github.levvs-one.sora.macos.openImport")
}

/// MenuBarExtra scene (macOS 13+ backend). The `@available` wrapper
/// is what lets the app target keep an 11.0 floor: the scene type is
/// only referenced inside this gate, and `SoraMacApp` only installs
/// it when `FeatureAvailability.menuBarBackend == .menuBarExtra`.
@available(macOS 13.0, *)
public struct SoraMenuBarScene: Scene {
    @ObservedObject private var tunnel = TunnelManager.shared
    public init() {}
    public var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(AppState.shared)
        } label: {
            // Template rendering: the asset is a template image, so
            // light/dark/tinted menu bars all draw correctly (§5).
            Image(DesignTokens.statusItemIconName)
                .renderingMode(.template)
                .accessibilityLabel(tunnel.phase.localizedTitle)
        }
        .menuBarExtraStyle(.window)
    }
}
