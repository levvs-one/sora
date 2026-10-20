import Foundation
#if canImport(AppKit)
import AppKit

/// Login Item helper (macOS 11–12 launch-at-login fallback, task §4).
///
/// Structure: this tiny background-only app is bundled at
/// `Sora.app/Contents/Library/LoginItems/SoraLoginItemHelper.app` and
/// registered by the main app with `SMLoginItemSetEnabled`
/// (`LaunchAtLogin` legacy backend). At login macOS launches the
/// helper; the helper opens the main app (unless it is already
/// running) and exits immediately. It contains no logic of its own —
/// no networking, no tunnel code, nothing to audit beyond this file.
///
/// On macOS 13+ the helper is not used: `SMAppService.mainApp`
/// registers the main app itself (same `LaunchAtLogin`, modern
/// backend, chosen by `FeatureAvailability`).
final class HelperDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let mainBundleID = "io.github.levvs-one.sora"
        let alreadyRunning = NSWorkspace.shared.runningApplications
            .contains { $0.bundleIdentifier == mainBundleID }
        if !alreadyRunning {
            // The main app is three levels up:
            // Helper.app/Contents/Library/LoginItems <- app bundle root.
            var url = Bundle.main.bundleURL
            for _ in 0..<3 { url.deleteLastPathComponent() }
            NSWorkspace.shared.openApplication(at: url, configuration: .init()) { _, _ in
                NSApp.terminate(nil)
            }
        } else {
            NSApp.terminate(nil)
        }
    }
}

let delegate = HelperDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
#endif
