import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(ServiceManagement)
import ServiceManagement
#endif

/// Unified capability ladder for every OS-dependent feature in the Mac
/// app (mandate: "capability probes at runtime instead of bare version
/// branches wherever possible").
///
/// Design rules:
///  * A probe answers "can this process use the API *right now*?", not
///    "is the OS new enough?". Version checks (`#available`) remain only
///    where the compiler needs them to reference a symbol at all; the
///    *decision* always goes through a probe here so both code paths
///    (modern + fallback) are selected in exactly one place.
///  * Probes are cheap, side-effect free and re-evaluated on demand —
///    availability can change while the app runs (system extension
///    approved in Settings, helper registered, …).
public enum FeatureAvailability {

    // MARK: Menu bar

    /// How the status item in the menu bar is implemented.
    public enum MenuBarBackend: Equatable {
        /// SwiftUI `MenuBarExtra` scene (macOS 13+).
        case menuBarExtra
        /// Hand-rolled `NSStatusItem` controller (macOS 11–12).
        case statusItemController
    }

    /// MenuBarExtra exists only where the SwiftUI scene type is present
    /// in the running OS. `NSClassFromString` on the scene's backing is
    /// unreliable, so the probe is: OS floor *and* the app was linked
    /// against a SwiftUI that exports the scene (compile-time flag set by
    /// the Xcode target deployment target ≥ 13 for the modern slice).
    /// On 11–12 the fallback controller is used — both implementations
    /// render the same `MenuBarContent` model, so behaviour is identical.
    public static var menuBarBackend: MenuBarBackend {
        if #available(macOS 13.0, *) { return .menuBarExtra }
        return .statusItemController
    }

    // MARK: Launch at login

    public enum LaunchAtLoginBackend: Equatable {
        /// `SMAppService.mainApp` (macOS 13+).
        case smAppService
        /// Login Item helper bundle + `SMLoginItemSetEnabled` (11–12).
        case loginItemHelper
    }

    public static var launchAtLoginBackend: LaunchAtLoginBackend {
        if #available(macOS 13.0, *) {
            // Probe, not just version: SMAppService is unusable when the
            // app runs translocated / unsigned during development.
            #if canImport(ServiceManagement)
            if Bundle.main.bundleURL.path.hasPrefix("/private/var/folders") == false {
                return .smAppService
            }
            #endif
        }
        return .loginItemHelper
    }

    /// Whether the login-item helper bundle is actually present inside
    /// the app (Contents/Library/LoginItems). False in a bare
    /// `swift build` run — the UI must then disable the toggle with an
    /// honest explanation instead of failing silently.
    public static var loginItemHelperInstalled: Bool {
        let url = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/LoginItems/SoraLoginItemHelper.app")
        return FileManager.default.fileExists(atPath: url.path)
    }

    // MARK: System extension

    /// OSSystemExtensionRequest exists since macOS 10.15; on any
    /// supported macOS (≥11) the probe that matters is whether the
    /// extension bundle is embedded in the app at all.
    public static var systemExtensionEmbedded: Bool {
        let url = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/SystemExtensions")
        guard let items = try? FileManager.default.contentsOfDirectory(atPath: url.path) else {
            return false
        }
        return items.contains { $0.hasSuffix(".systemextension") }
    }

    // MARK: Widgets / Intents / Handoff

    /// WidgetKit is available on all supported macOS versions (11+);
    /// the probe is whether our widget extension is embedded.
    public static var widgetEmbedded: Bool {
        let url = Bundle.main.bundleURL.appendingPathComponent("Contents/PlugIns")
        guard let items = try? FileManager.default.contentsOfDirectory(atPath: url.path) else {
            return false
        }
        return items.contains { $0.localizedCaseInsensitiveContains("widget") }
    }

    /// AppIntents (Shortcuts) requires macOS 13+; below that the intents
    /// are *designed but unavailable* — Settings shows that honestly.
    public static var appIntentsAvailable: Bool {
        if #available(macOS 13.0, *) { return true }
        return false
    }

    /// Handoff needs a signed app with the activity type declared in
    /// Info.plist; probe the plist instead of assuming.
    public static var handoffDeclared: Bool {
        guard let types = Bundle.main.object(forInfoDictionaryKey: "NSUserActivityTypes") as? [String] else {
            return false
        }
        return types.contains(AppIdentifiers.handoffActivityType)
    }

    // MARK: Notifications

    /// Global hot key via Carbon needs no probe (works since 10.0 and in
    /// the sandbox); kept here so the choice is discoverable in one file.
    public static var carbonHotKeyAvailable: Bool { true }
}
