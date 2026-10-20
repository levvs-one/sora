import Foundation

/// Handoff (mandate §6): the live connection is advertised as an
/// `NSUserActivity` so a nearby iPhone running sora sees "Connection
/// from Mac" and can open the same server. Only non-secret data crosses:
/// server id + name + phase — never links, credentials or config JSON.
///
/// Availability is probed via `FeatureAvailability.handoffDeclared`
/// (the activity type must be in Info.plist and the app signed); when
/// unavailable this object is simply inert.
public final class HandoffManager: NSObject {
    public static let shared = HandoffManager()

    private var activity: NSUserActivity?

    public func updateActivity(snapshot: SharedTunnelSnapshot, server: ServerRow?) {
        guard FeatureAvailability.handoffDeclared else { return }
        guard snapshot.state == .connected, let server else {
            activity?.invalidate(); activity = nil; return
        }
        let act = NSUserActivity(activityType: AppIdentifiers.handoffActivityType)
        act.title = tr("mac.handoff.title", "Sora connection")
        act.userInfo = [
            "serverID": server.id,
            "serverName": server.name,
            "phase": snapshot.state.rawValue,
            "since": snapshot.updatedAt.timeIntervalSince1970,
        ]
        act.isEligibleForHandoff = true
        act.becomeCurrent()
        activity = act
    }

    /// Handles an incoming activity (Mac ↔ iPhone in either direction,
    /// and Mac ↔ Mac). Returns the server id to select, if known.
    public func handleIncoming(_ userActivity: NSUserActivity) -> String? {
        guard userActivity.activityType == AppIdentifiers.handoffActivityType else { return nil }
        return userActivity.userInfo?["serverID"] as? String
    }
}
