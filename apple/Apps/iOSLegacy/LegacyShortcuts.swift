import Foundation
import UIKit

/// Shortcuts on iOS 13–14 — the LIMITED rung of the ARCHITECTURE §5.2
/// ladder for this segment. AppIntents does not exist before iOS 16,
/// and the main app's `SoraIntents.swift` (AppIntents, iOS 16+) is
/// therefore not part of this target at all.
///
/// What the limited mode honestly provides on iOS 13:
///  * Donated `NSUserActivity` shortcuts (the pre-AppIntents Siri
///    Shortcuts mechanism, available since iOS 12): Connect /
///    Disconnect / Status appear in Shortcuts and Siri Suggestions
///    after the user performs the action in the app, and the user can
///    bind their own phrase to them. Invocation comes back through
///    the scene delegate's `continue` callback.
///  * Home-screen quick actions (long-press the app icon):
///    Connect / Disconnect, registered dynamically at launch.
/// What it does NOT provide (and the Settings screen says so with the
/// `state.shortcutsLimitedMode` state instead of pretending):
/// parameterised intents, background execution guarantees, and the
/// Shortcuts gallery entries AppIntents generates on iOS 16+.
/// A custom `INIntent` surface would need an `.intentdefinition`
/// file + generated classes; that is listed in TARGET-NOTES.md as a
/// coordinator decision, not silently faked here.
enum LegacyShortcuts {
    static let connectAction = "io.github.levvs-one.sora.action.connect"
    static let disconnectAction = "io.github.levvs-one.sora.action.disconnect"
    static let statusAction = "io.github.levvs-one.sora.action.status"
    /// userInfo key carrying the action id inside a donated activity.
    static let activityActionKey = "sora.action"

    // MARK: Donated activities (Siri / Shortcuts, iOS 12+ mechanism)

    /// Donates an activity for an action the user just performed, so
    /// Siri can suggest it and Shortcuts can list it. Titles are
    /// localization keys resolved through the same strings as the
    /// main app's intents (`intentConnectTitle` etc.).
    static func donate(action: String) {
        let titleKey: String
        switch action {
        case connectAction: titleKey = "intentConnectTitle"
        case disconnectAction: titleKey = "intentDisconnectTitle"
        default: titleKey = "intentStatusTitle"
        }
        let activity = NSUserActivity(activityType: action)
        activity.title = NSLocalizedString(titleKey, comment: "")
        activity.userInfo = [activityActionKey: action]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.becomeCurrent()
    }

    // MARK: Home-screen quick actions

    static func registerQuickActions() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: connectAction,
                localizedTitle: NSLocalizedString("intentConnectTitle", comment: ""),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "lock.shield"),
                userInfo: nil),
            UIApplicationShortcutItem(
                type: disconnectAction,
                localizedTitle: NSLocalizedString("intentDisconnectTitle", comment: ""),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "shield.slash"),
                userInfo: nil),
        ]
    }

    /// Whether any shortcut surface exists on this system. On the
    /// legacy target this is always the limited mode; the Settings
    /// screen renders the honest limited-mode state from this probe
    /// rather than from a version check (capability-probe standard,
    /// ARCHITECTURE §5.1).
    static var modeDescriptionKey: String { "state.shortcutsLimitedMode" }
}
