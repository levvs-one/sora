import Foundation
#if canImport(AppKit)
import AppKit

/// Legacy menu-bar backend for macOS 11–12 (task §2): an
/// `NSStatusItem` with an `NSMenu` that mirrors `MenuBarContent`
/// item-for-item — status line (disabled), current server,
/// Connect/Disconnect, quick-switch submenu, Import… (also when the
/// server list is empty — the menu is never dead, §3), Open Sora,
/// Quit.
///
/// §5: the button image is a TEMPLATE image (`isTemplate = true`), so
/// the menu bar draws it correctly in light, dark and tinted styles.
/// §2: the status button and every menu item carry accessibility
/// labels; the status item's label always reflects the phase.
public final class StatusItemController: NSObject {
    private var statusItem: NSStatusItem?
    private var observers: [NSObjectProtocol] = []

    public override init() { super.init() }

    public func install() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(named: DesignTokens.statusItemIconName)
                ?? NSImage(systemSymbolName: "shield", accessibilityDescription: nil)
            image?.isTemplate = true // template: correct in both themes + tinted menu bar
            button.image = image
            button.toolTip = "Sora"
            button.setAccessibilityLabel(TunnelManager.shared.phase.localizedTitle)
            button.setAccessibilityRole(.menuButton)
        }
        item.menu = buildMenu()
        statusItem = item

        // Rebuild on state changes so the menu is never stale.
        let names: [Notification.Name] = [.NEVPNStatusDidChange]
        for name in names {
            observers.append(NotificationCenter.default.addObserver(
                forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.statusItem?.menu = self?.buildMenu()
                    self?.statusItem?.button?.setAccessibilityLabel(
                        TunnelManager.shared.phase.localizedTitle)
                }
            })
        }
    }

    public func uninstall() {
        if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
        statusItem = nil
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
    }

    // MARK: Menu construction (mirrors MenuBarContent)

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        let tunnel = TunnelManager.shared
        let state = AppState.shared

        let status = NSMenuItem(title: tunnel.phase.localizedTitle, action: nil, keyEquivalent: "")
        status.isEnabled = false
        status.setAccessibilityLabel(tunnel.phase.localizedTitle)
        menu.addItem(status)

        if let server = tunnel.currentServer ?? state.selectedServer {
            let current = NSMenuItem(
                title: "\(tr("currentServer", "Current server")): \(server.name)",
                action: nil, keyEquivalent: "")
            current.isEnabled = false
            current.setAccessibilityLabel("\(tr("currentServer", "Current server")): \(server.name)")
            menu.addItem(current)
        }
        menu.addItem(.separator())

        if state.servers.isEmpty {
            let hint = NSMenuItem(title: tr("mac.menu.noServersShort", "No servers yet"),
                                  action: nil, keyEquivalent: "")
            hint.isEnabled = false
            menu.addItem(hint)
            menu.addItem(actionItem(tr("mac.servers.import", "Import…"),
                                    #selector(openImport),
                                    label: tr("mac.servers.import", "Import servers")))
            menu.addItem(actionItem(tr("qrFromClipboard", "Paste from clipboard"),
                                    #selector(importFromClipboard),
                                    label: tr("qrFromClipboard", "Paste from clipboard")))
        } else {
            let toggleTitle = tunnel.phase.isConnected ? tr("mac.disconnect", "Disconnect")
                                                        : tr("mac.connect", "Connect")
            menu.addItem(actionItem(toggleTitle, #selector(toggleConnection), label: toggleTitle))

            let switchMenu = NSMenu()
            for server in state.servers.prefix(8) {
                let item = NSMenuItem(title: server.name,
                                      action: #selector(quickSwitch(_:)),
                                      keyEquivalent: "")
                item.target = self
                item.representedObject = server.id
                item.state = (tunnel.currentServer?.id == server.id && tunnel.phase.isConnected) ? .on : .off
                item.setAccessibilityLabel(
                    String(format: tr("mac.a11y.connectTo", "Connect to %@"), server.name))
                switchMenu.addItem(item)
            }
            let switchItem = NSMenuItem(title: tr("mac.menu.switchServer", "Switch server"),
                                        action: nil, keyEquivalent: "")
            switchItem.submenu = switchMenu
            switchItem.setAccessibilityLabel(tr("mac.menu.switchServer", "Switch server"))
            menu.addItem(switchItem)
        }

        menu.addItem(.separator())
        menu.addItem(actionItem(tr("mac.menu.open", "Open Sora"), #selector(openApp),
                                label: tr("mac.menu.open", "Open Sora")))
        let quit = actionItem(tr("mac.menu.quit", "Quit Sora"), #selector(quitApp),
                              label: tr("mac.menu.quit", "Quit Sora"))
        quit.keyEquivalent = "q"
        menu.addItem(quit)
        return menu
    }

    private func actionItem(_ title: String, _ action: Selector, label: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.setAccessibilityLabel(label)
        return item
    }

    // MARK: Actions

    @objc private func toggleConnection() {
        Task { await TunnelManager.shared.toggle() }
    }

    @objc private func quickSwitch(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let server = AppState.shared.servers.first(where: { $0.id == id }) else { return }
        AppState.shared.select(server)
        Task { await TunnelManager.shared.connect(to: server) }
    }

    @objc private func openImport() {
        openApp()
        NotificationCenter.default.post(name: .soraOpenImport, object: nil)
    }

    @objc private func importFromClipboard() {
        Task { @MainActor in AppState.shared.importClipboard() }
    }

    @objc private func openApp() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApp() { NSApp.terminate(nil) }
}
#endif
