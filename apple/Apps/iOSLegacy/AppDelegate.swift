import UIKit

/// Legacy app entry point for the iOS 13–14 target.
///
/// There is no SwiftUI `App` protocol on iOS 13 (it arrives with
/// SwiftUI 2 / iOS 14), so the lifecycle is the era's own:
/// `UIApplicationMain` + this delegate + a `SceneDelegate` per window
/// scene. The object graph the main app builds in `SoraApp.init`
/// (one tunnel manager, one profile store in the App Group container,
/// per-screen view models) is built here, once, in `AppState`, and the
/// scene delegate only hosts it — cold-start deep links therefore land
/// on a router that already exists (see SceneDelegate).
@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    /// The single object graph for the whole process. Created before
    /// any scene connects so a cold-start URL is never dropped.
    let appState = AppState()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        NotificationService.registerCategories()
        LegacyShortcuts.registerQuickActions()
        return true
    }

    // MARK: Scene sessions (iOS 13 lifecycle)

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration",
                                                 sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Single-window app: nothing per-scene to release beyond what
        // the scene delegate already dropped in `sceneDidDisconnect`.
    }

    // MARK: Home-screen quick actions (the Shortcuts ladder's
    // always-available rung on iOS 13 — see LegacyShortcuts.swift)

    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        completionHandler(appState.handleQuickAction(shortcutItem.type))
    }
}
