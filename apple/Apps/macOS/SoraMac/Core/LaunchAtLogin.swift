import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(ServiceManagement)
import ServiceManagement
#endif

/// Launch-at-login with the same capability ladder as the menu bar
/// (mandate §1): modern `SMAppService` where the probe in
/// `FeatureAvailability` allows it, Login Item helper otherwise.
/// Both backends expose the same `isEnabled` surface to Settings, and
/// both can report "needs approval in System Settings" (Ventura+
/// SMAppService status `.requiresApproval`) — never a silent failure.
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
        switch backend {
        case .smAppService:
            #if canImport(ServiceManagement)
            if #available(macOS 13.0, *) {
                switch SMAppService.mainApp.status {
                case .enabled: status = .enabled
                case .requiresApproval: status = .requiresApproval
                case .notFound, .notRegistered: status = .disabled
                @unknown default: status = .disabled
                }
                return
            }
            #endif
            status = .unavailable
        case .loginItemHelper:
            status = FeatureAvailability.loginItemHelperInstalled
                ? (Self.helperEnabled ? .enabled : .disabled)
                : .unavailable
        }
    }

    public func setEnabled(_ enabled: Bool) {
        switch backend {
        case .smAppService:
            #if canImport(ServiceManagement)
            if #available(macOS 13.0, *) {
                do {
                    if enabled { try SMAppService.mainApp.register() }
                    else { try SMAppService.mainApp.unregister() }
                } catch {
                    // Most common: requiresApproval. Reflected by refresh().
                    NSLog("[sora] SMAppService toggle failed: %@", error.localizedDescription)
                }
            }
            #endif
        case .loginItemHelper:
            Self.setHelperEnabled(enabled)
        }
        refresh()
    }

    public func openApprovalSettings() {
        #if canImport(ServiceManagement)
        if #available(macOS 13.0, *), backend == .smAppService {
            SMAppService.openSystemSettingsLoginItems()
            return
        }
        #endif
        NSWorkspaceOpen(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
    }

    // MARK: Login Item helper backend (macOS 11–12)

    private static let helperDefaultsKey = "launchAtLoginHelperEnabled"
    private static var helperEnabled: Bool {
        // The helper itself records that it was launched by login items;
        // the app-side source of truth is SMLoginItemSetEnabled's last
        // requested value, mirrored here because the legacy API has no
        // getter.
        UserDefaults.standard.bool(forKey: helperDefaultsKey)
    }
    private static func setHelperEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: helperDefaultsKey)
        #if canImport(ServiceManagement)
        // Legacy API (deprecated in 13, which is exactly why it is only
        // reached on 11–12). The helper bundle id is the registration key.
        _ = SMLoginItemSetEnabled(AppIdentifiers.loginItemHelperBundleID as CFString, enabled)
        #endif
    }
}

/// Tiny indirection so this file stays testable without AppKit.
func NSWorkspaceOpen(_ url: URL) {
    #if canImport(AppKit)
    _ = NSWorkspace.shared.open(url)
    #endif
}
