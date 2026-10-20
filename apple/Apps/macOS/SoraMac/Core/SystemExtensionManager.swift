import Foundation
#if canImport(SystemExtensions)
import SystemExtensions
#endif

/// Installs / activates / removes the packet-tunnel SYSTEM EXTENSION
/// (macOS path; on iOS the same provider ships as an app extension).
///
/// Activation is a user-mediated flow: `OSSystemExtensionRequest`
/// → delegate callbacks → the user approves in System Settings.
/// Every outcome is folded into `ActivationState`, which the UI renders
/// as a designed banner (`state.extension*` keys) — the raw
/// `OSSystemExtensionRequest.Result` / error text never reaches a view.
public final class SystemExtensionManager: NSObject, ObservableObject {
    public static let shared = SystemExtensionManager()

    public enum ActivationState: Equatable {
        case unknown
        case notInstalled
        case activating
        /// Installed, waiting for the user to approve it in Settings.
        case awaitingUserApproval
        case active
        /// A newer extension is queued; the old one keeps running until
        /// reboot / explicit restart — surfaced as "needs restart".
        case needsRestart
        case failed
    }

    @Published public private(set) var state: ActivationState = .unknown

    private override init() { super.init() }

    // MARK: Requests

    public func refreshStatus() {
        guard FeatureAvailability.systemExtensionEmbedded else {
            state = .notInstalled
            return
        }
        // There is no synchronous "is it active?" API; listing the
        // discovered extensions via a properties request is the probe.
        #if canImport(SystemExtensions)
        let req = OSSystemExtensionRequest.propertiesRequest(
            forExtensionIdentifiers: [AppIdentifiers.tunnelExtensionBundleID],
            queue: .main)
        req.delegate = self
        OSSystemExtensionManager.shared.submitRequest(req)
        #else
        state = .notInstalled
        #endif
    }

    public func activate() {
        guard FeatureAvailability.systemExtensionEmbedded else {
            state = .notInstalled
            return
        }
        state = .activating
        #if canImport(SystemExtensions)
        let req = OSSystemExtensionRequest.activationRequest(
            forExtensionIdentifier: AppIdentifiers.tunnelExtensionBundleID, queue: .main)
        req.delegate = self
        OSSystemExtensionManager.shared.submitRequest(req)
        #endif
    }

    /// Used on update: `.replace` semantics — if the system decides the
    /// running extension must be swapped, the delegate reports
    /// `.willCompleteAfterReboot`, which we surface as `needsRestart`
    /// instead of pretending the update already took effect.
    public func replaceWithBundledVersion() { activate() }

    public func deactivate() {
        #if canImport(SystemExtensions)
        let req = OSSystemExtensionRequest.deactivationRequest(
            forExtensionIdentifier: AppIdentifiers.tunnelExtensionBundleID, queue: .main)
        req.delegate = self
        OSSystemExtensionManager.shared.submitRequest(req)
        #endif
    }

    /// Deep link into the right System Settings pane for approval.
    public var approvalSettingsURL: URL {
        // Ventura+ Settings, pre-Ventura Preferences — same anchor.
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
    }
}

#if canImport(SystemExtensions)
extension SystemExtensionManager: OSSystemExtensionRequestDelegate {
    public func request(_ request: OSSystemExtensionRequest,
                          actionForReplacingExtension existing: OSSystemExtensionProperties,
                          withExtension replacement: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        // Always take the bundled (newer, signed) copy.
        return .replace
    }

    public func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        DispatchQueue.main.async { self.state = .awaitingUserApproval }
    }

    public func request(_ request: OSSystemExtensionRequest,
                          didFinishWithResult result: OSSystemExtensionRequest.Result) {
        DispatchQueue.main.async {
            switch result {
            case .completed: self.state = .active
            case .willCompleteAfterReboot: self.state = .needsRestart
            @unknown default: self.state = .failed
            }
        }
    }

    public func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        // Diagnostics only; UI shows the designed `state.extensionFailed`.
        NSLog("[sora] system extension request failed: %@", error.localizedDescription)
        DispatchQueue.main.async { self.state = .failed }
    }

    // Properties request callback (used by refreshStatus).
    public func request(_ request: OSSystemExtensionRequest,
                          foundProperties properties: [OSSystemExtensionProperties]) {
        DispatchQueue.main.async {
            guard let prop = properties.first else { self.state = .notInstalled; return }
            self.state = prop.isAwaitingUserApproval ? .awaitingUserApproval
                : (prop.isEnabled ? .active : .notInstalled)
        }
    }
}
#endif
