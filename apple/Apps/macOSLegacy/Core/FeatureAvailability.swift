import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// LEGACY REPLACEMENT — macOSLegacy target (deployment target 11.0).
///
/// Replaces: `Apps/macOS/SoraMac/Core/FeatureAvailability.swift`
/// (same type name, same probe surface, so every reused original file
/// compiles unchanged against this version).
///
/// Why a replacement exists: in the legacy composition the fallback
/// backends are not fallbacks — they are the ONLY backends. The
/// original answers its probes with a runtime version check and can
/// vend the macOS 13 menu-bar scene backend and the macOS 13
/// ServiceManagement login-item backend. Neither of those API
/// surfaces exists on macOS 11–12, so this version does not reference
/// them at all (not even behind an availability guard): the probes
/// below return the legacy answer as a constant, which IS the probe
/// result on this floor — a process whose deployment target is 11.0
/// and which runs on 11–12 can never take the modern path.
///
/// The modern enum cases are renamed (`modernScene` /
/// `modernService`) and are never vended here; reused original files
/// reference only the legacy cases (verified by grep: `AppDelegate`
/// compares against `.statusItemController` only). The shortcuts
/// probe is renamed `shortcutsActionsAvailable` for the same reason:
/// the framework it names after in the original arrives with
/// macOS 13, and nothing reused references the old name.
///
/// Probes that depend on the actual bundle on disk (helper embedded?
/// extension embedded? widget embedded? Handoff declared?) stay real
/// filesystem/plist probes, exactly as in the original — availability
/// is read from the system, never assumed from the version number.
public enum FeatureAvailability {

    // MARK: Legacy-target marker

    /// True only in the legacy composition. Reused code does not
    /// branch on this; it exists so diagnostics and the settings
    /// surface can state plainly which target is running.
    public static let isLegacyTarget = true

    // MARK: Menu bar

    /// How the status item in the menu bar is implemented.
    public enum MenuBarBackend: Equatable {
        /// The macOS 13 SwiftUI menu-bar scene. Never vended by the
        /// legacy target: the scene type does not exist on 11–12 and
        /// is not referenced anywhere in this composition.
        case modernScene
        /// Hand-rolled `NSStatusItem` controller — the main (and
        /// only) menu-bar path of the legacy target.
        case statusItemController
    }

    /// On macOS 11–12 the answer is structural, not a guess: the
    /// `StatusItemController` (reused unchanged from the main client)
    /// is installed by `AppDelegate` at launch.
    public static var menuBarBackend: MenuBarBackend { .statusItemController }

    // MARK: Launch at login

    public enum LaunchAtLoginBackend: Equatable {
        /// The macOS 13 ServiceManagement app-service registration.
        /// Never vended by the legacy target and not referenced here.
        case modernService
        /// Login Item helper bundle + the classic login-item
        /// registration call — the main (and only) path on 11–12.
        case loginItemHelper
    }

    public static var launchAtLoginBackend: LaunchAtLoginBackend { .loginItemHelper }

    /// Whether the login-item helper bundle is actually present inside
    /// the app (Contents/Library/LoginItems). False in a bare
    /// `swift build` run — the UI must then disable the toggle with an
    /// honest explanation instead of failing silently. (Same probe as
    /// the original.)
    public static var loginItemHelperInstalled: Bool {
        let url = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/LoginItems/SoraLoginItemHelper.app")
        return FileManager.default.fileExists(atPath: url.path)
    }

    // MARK: System extension

    /// The system-extension request API exists since macOS 10.15; on
    /// any system this target runs on (11–12) the probe that matters
    /// is whether the extension bundle is embedded in the app at all.
    /// (Same probe as the original.)
    public static var systemExtensionEmbedded: Bool {
        let url = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/SystemExtensions")
        guard let items = try? FileManager.default.contentsOfDirectory(atPath: url.path) else {
            return false
        }
        return items.contains { $0.hasSuffix(".systemextension") }
    }

    // MARK: Widgets / Shortcuts / Handoff

    /// Whether a widget extension is embedded in THIS bundle. The
    /// legacy composition embeds none (the widget targets are not part
    /// of it), so on a real legacy build this probe honestly returns
    /// false and Settings says the widget is not available on this
    /// system — it is a filesystem probe, not a hard-coded answer:
    /// if a widget were ever embedded, the probe would say so.
    public static var widgetEmbedded: Bool {
        let url = Bundle.main.bundleURL.appendingPathComponent("Contents/PlugIns")
        guard let items = try? FileManager.default.contentsOfDirectory(atPath: url.path) else {
            return false
        }
        return items.contains { $0.localizedCaseInsensitiveContains("widget") }
    }

    /// Shortcuts actions built on the intents framework that arrived
    /// with macOS 13 do not exist on 11–12, and the legacy composition
    /// ships no substitute surface. Constant false is the probe
    /// result on this floor; Settings renders it as the designed
    /// "not available on this system" state (ARCHITECTURE.md §5.2),
    /// never as a dead toggle or an empty screen.
    public static var shortcutsActionsAvailable: Bool { false }

    /// Handoff needs a signed app with the activity type declared in
    /// Info.plist; probe the plist instead of assuming. Handoff
    /// itself predates macOS 11, so this probe is live on the legacy
    /// target exactly as in the main client. (Same probe as the
    /// original.)
    public static var handoffDeclared: Bool {
        guard let types = Bundle.main.object(forInfoDictionaryKey: "NSUserActivityTypes") as? [String] else {
            return false
        }
        return types.contains(AppIdentifiers.handoffActivityType)
    }

    // MARK: Notifications

    /// Global hot key via Carbon needs no probe (works since 10.0 and
    /// in the sandbox); kept here so the choice is discoverable in one
    /// file. (Same as the original.)
    public static var carbonHotKeyAvailable: Bool { true }
}
