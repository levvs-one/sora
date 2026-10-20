import Foundation
import UserNotifications

/// Local notifications for connection changes.
///
/// Rules: category `sora.connection`; every text is a localization key
/// (never a literal, never a raw error); notifications are attributed to
/// Sora by the app bundle (system behaviour for local notifications) and
/// carry no server address beyond the display name the user chose.
public enum NotificationService {
    public static let categoryIdentifier = "sora.connection"
    public static let connectedAction = "sora.connection.connected"
    public static let disconnectedAction = "sora.connection.disconnected"

    /// Registers the category once at launch. Authorization is requested
    /// lazily from Settings (a toggle), not at first launch — asking for
    /// notification permission before the user connects is a dark
    /// pattern the Flutter app avoids too.
    public static func registerCategories() {
        let center = UNUserNotificationCenter.current()
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction])
        center.setNotificationCategories([category])
    }

    public static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])) ?? false
    }

    public static func postConnectionChanged(connected: Bool, serverName: String?) {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = categoryIdentifier
        content.sound = nil // state changes are informational, not alarms
        if connected {
            content.title = NSLocalizedString("notif.connectedTitle", comment: "")
            content.body = serverName.map {
                String(format: NSLocalizedString("notif.connectedBody", comment: ""), $0)
            } ?? NSLocalizedString("notif.connectedBodyGeneric", comment: "")
            content.threadIdentifier = categoryIdentifier
        } else {
            content.title = NSLocalizedString("notif.disconnectedTitle", comment: "")
            content.body = NSLocalizedString("notif.disconnectedBody", comment: "")
            content.threadIdentifier = categoryIdentifier
        }
        let request = UNNotificationRequest(
            identifier: "sora.connection.\(connected ? "up" : "down")",
            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
