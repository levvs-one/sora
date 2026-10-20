import Foundation
#if canImport(AppKit)
import AppKit

/// AppKit bridge for the SwiftUI app (task §1): owns everything
/// SwiftUI scenes cannot —
///  * the legacy `NSStatusItem` backend (macOS 11–12), chosen through
///    `FeatureAvailability`, never by a bare version check in a view;
///  * URL-scheme delivery via Apple events (`sora://…`, protocol
///    schemes) — SwiftUI's `onOpenURL` also fires; both funnel into
///    `DeepLinkExecutor`, and delivery is de-duplicated by timestamp;
///  * `NSUserActivity` (Handoff) continuation;
///  * the global hot key wiring;
///  * bootstrap of `TunnelManager` / extension status.
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var lastDeliveredURL: (url: URL, at: Date)?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // URL schemes delivered by Apple events (also covers launch-
        // by-link, where onOpenURL may not be installed yet).
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(handleGetURL(event:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL))

        if FeatureAvailability.menuBarBackend == .statusItemController {
            let controller = StatusItemController()
            controller.install()
            statusItemController = controller
        }

        HotKeyManager.shared.onToggle = {
            Task { await TunnelManager.shared.toggle() }
        }
        if HotKeyManager.shared.isEnabled { HotKeyManager.shared.register() }

        LaunchAtLogin.shared.refresh()
        Task { await TunnelManager.shared.bootstrap() }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        statusItemController?.uninstall()
        HotKeyManager.shared.unregister()
        // The tunnel is NOT stopped on quit: the extension outlives
        // the app by design (state is re-read on next launch).
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication,
                                              hasVisibleWindows flag: Bool) -> Bool {
        if !flag { sender.windows.first?.makeKeyAndOrderFront(nil) }
        return true
    }

    // MARK: URL delivery (Apple events)

    @objc private func handleGetURL(event: NSAppleEventDescriptor,
                                    withReplyEvent reply: NSAppleEventDescriptor) {
        guard let string = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: string) else { return }
        // De-duplicate the onOpenURL double-delivery.
        if let last = lastDeliveredURL, last.url == url,
           Date().timeIntervalSince(last.at) < 1.0 { return }
        lastDeliveredURL = (url, Date())
        Task { @MainActor in
            DeepLinkExecutor.execute(DeepLink.parse(url), state: AppState.shared)
        }
    }

    // MARK: Handoff

    public func application(_ application: NSApplication,
                            continue userActivity: NSUserActivity,
                            restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void) -> Bool {
        if let serverID = HandoffManager.shared.handleIncoming(userActivity),
           let server = AppState.shared.servers.first(where: { $0.id == serverID }) {
            AppState.shared.select(server, connectIfActive: false)
            Task { await TunnelManager.shared.connect(to: server) }
            return true
        }
        return false
    }

    public func application(_ application: NSApplication,
                            didFailToContinueUserActivityWithType activityType: String,
                            error: Error) {
        // Handoff is best-effort by design; a failure is logged, never
        // surfaced as a user error (nothing the user did failed).
        NSLog("[sora] handoff failed for %@: %@", activityType, error.localizedDescription)
    }
}
#endif
