import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(ServiceManagement)
import ServiceManagement
#endif

/// LEGACY REPLACEMENT — macOSLegacy target (deployment target 11.0).
///
/// Replaces: `Apps/macOS/SoraMac/Core/LaunchAtLogin.swift`
/// (same type name, same `Status` enum, same public surface —
/// `shared`, `status`, `backend`, `refresh()`, `setEnabled(_:)`,
/// `openApprovalSettings()` — and the same free `NSWorkspaceOpen`
/// helper that reused views call).
///
/// Why a replacement exists: the original is a two-backend ladder.
/// On macOS 11–12 only one backend can ever run — the Login Item
/// helper (`Apps/macOS/LoginItemHelper`, an existing target) enabled
/// through the classic login-item registration call — so this version
/// implements exactly that path and references no macOS 13 API at
/// all. Settings marks the row as the legacy mechanism
/// (ARCHITECTURE.md §5.1), in words, next to the toggle.
///
/// State is probed, not assumed. The classic registration call has no
/// getter, so `refresh()` layers three factual sources, in order:
///  1. the helper bundle must be embedded in this app at all
///     (`FeatureAvailability.loginItemHelperInstalled`) — otherwise
///     the status is `.unavailable`, never a pretend toggle;
///  2. the user launchd domain is asked for the helper's job
///     (`SMCopyAllJobDictionaries`): a login item the system has
///     actually registered shows up there under the helper's bundle
///     id as its label;
///  3. only if the job list cannot be read does the status fall back
///     to the last value this app requested (the same UserDefaults
///     key the main client uses, so state survives target switches).
/// A failed registration call is therefore never papered over: if the
/// system did not take it, the probe does not report `.enabled`.
public final class LaunchAtLogin: ObservableObject {
    public static let shared = LaunchAtLogin()

    public enum Status: Equatable {
        case enabled, disabled, requiresApproval, unavailable
        var key: String { "settings.launchAtLogin.\(self)" }
    }

    @Published public private(set) var status: Status = .disabled
    public var backend: FeatureAvailability.LaunchAtLoginBackend { FeatureAvailability.launchAtLoginBackend }

    private init() { refresh() }

    public func refresh() {
        // Probe 1: without the embedded helper there is nothing to
        // register — report the honest unavailable state.
        guard FeatureAvailability.loginItemHelperInstalled else {
            status = .unavailable
            return
        }
        // Probe 2: ask launchd what is actually registered.
        if let jobPresent = Self.loginItemJobPresent {
            status = jobPresent ? .enabled : .disabled
            return
        }
        // Fallback: the last requested value (see the header note —
        // reached only when the job list itself is unreadable).
        status = Self.helperRequestedEnabled ? .enabled : .disabled
    }

    public func setEnabled(_ enabled: Bool) {
        Self.setHelperEnabled(enabled)
        refresh()
    }

    public func openApprovalSettings() {
        // On macOS 11–12 login items live in System Preferences →
        // Users & Groups → Login Items (there is no approval pane for
        // them; the pane is where the user can inspect and remove the
        // item by hand). TODO(verify-on-mac): confirm the pane anchor
        // opens Users & Groups on both 11 and 12.
        NSWorkspaceOpen(URL(string: "x-apple.systempreferences:com.apple.preference.users")!)
    }

    // MARK: Login Item helper backend (the only backend on 11–12)

    private static let helperDefaultsKey = "launchAtLoginHelperEnabled"
    private static var helperRequestedEnabled: Bool {
        UserDefaults.standard.bool(forKey: helperDefaultsKey)
    }

    /// Factual probe: is the helper's job present in the user launchd
    /// domain? Returns nil when the job list cannot be read at all,
    /// so the caller can fall back explicitly instead of guessing.
    /// TODO(verify-on-mac): confirm the exact Swift bridging spelling
    /// of the job-dictionary call against the macOS 11/12 SDK headers
    /// on the build machine (the call itself is a macOS 10.6-era
    /// ServiceManagement API, present on both target systems).
    private static var loginItemJobPresent: Bool? {
        #if canImport(ServiceManagement)
        guard let jobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd)?
            .takeRetainedValue() as? [[String: Any]] else { return nil }
        return jobs.contains { ($0["Label"] as? String) == AppIdentifiers.loginItemHelperBundleID }
        #else
        return nil
        #endif
    }

    private static func setHelperEnabled(_ enabled: Bool) {
        #if canImport(ServiceManagement)
        // The classic login-item registration call (deprecated only
        // from macOS 13, where this target never runs). Its Boolean
        // result is kept with the requested value: refresh() trusts
        // the launchd probe first, so a refused registration cannot
        // surface as "enabled".
        let accepted = SMLoginItemSetEnabled(AppIdentifiers.loginItemHelperBundleID as CFString, enabled)
        UserDefaults.standard.set(enabled && accepted, forKey: helperDefaultsKey)
        #else
        UserDefaults.standard.set(false, forKey: helperDefaultsKey)
        #endif
    }
}

/// Tiny indirection so this file stays testable without AppKit.
/// (Same helper, same name as in the original file: reused views —
/// `SystemStateViews` among them — call it.)
func NSWorkspaceOpen(_ url: URL) {
    #if canImport(AppKit)
    _ = NSWorkspace.shared.open(url)
    #endif
}
