import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

/// User notifications for tunnel events (task §5).
///
/// Rule from the main app: notifications are human sentences, never raw
/// error text. Failures are classified into a small set of reasons and
/// each reason has its own localised `notify.*` string; the raw error
/// goes to the log only.
public final class NotificationManager: NSObject {
    public static let shared = NotificationManager()

    public enum FailureKind {
        case networkUnreachable, serverUnreachable, authentication, configuration, systemExtension, unknown
        var key: String {
            switch self {
            case .networkUnreachable: return "notify.failed.network"
            case .serverUnreachable: return "notify.failed.server"
            case .authentication: return "notify.failed.auth"
            case .configuration: return "notify.failed.config"
            case .systemExtension: return "notify.failed.extension"
            case .unknown: return "notify.failed.generic"
            }
        }
        /// Best-effort classification from an NE/OS error domain —
        /// deliberately coarse: the user needs a next step, not a code.
        static func classify(_ error: Error) -> FailureKind {
            let ns = error as NSError
            if ns.domain == "NEVPNConnectionErrorDomain" || ns.domain.contains("NetworkExtension") {
                return .systemExtension
            }
            if ns.domain == NSURLErrorDomain {
                switch ns.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost: return .networkUnreachable
                case NSURLErrorCannotConnectToHost, NSURLErrorTimedOut: return .serverUnreachable
                default: return .unknown
                }
            }
            return .unknown
        }
    }

    public func requestAuthorization() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        #endif
    }

    public func connected(to serverName: String) { post(key: "notify.connected", arg: serverName) }
    public func disconnected() { post(key: "notify.disconnected", arg: nil) }
    public func reconnecting() { post(key: "notify.reconnecting", arg: nil) }
    public func reconnected(to serverName: String) { post(key: "notify.reconnected", arg: serverName) }
    public func failed(kind: FailureKind) { post(key: kind.key, arg: nil) }
    public func failed(error: Error) { failed(kind: FailureKind.classify(error)) }

    private func post(key: String, arg: String?) {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = tr("app.name", "Sora")
        let format = tr(key, key)
        content.body = arg.map { String(format: format, $0) } ?? format
        content.sound = .default
        let request = UNNotificationRequest(identifier: "sora.tunnel.\(key).\(Date().timeIntervalSince1970)",
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        #endif
    }
}
