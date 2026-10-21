import UIKit
import SwiftUI

/// Hosts the SwiftUI root in a `UIHostingController` inside the
/// scene's window — the only way to run SwiftUI on iOS 13, where the
/// `App`/`Scene` protocols do not exist yet.
///
/// Deep links arrive through the scene callbacks (`openURLContexts`,
/// `continue`) rather than SwiftUI's `onOpenURL` (iOS 14+); both feed
/// the same `LegacyRouter` the main app feeds from its modifiers, so
/// routing semantics are identical across targets. Foregrounding after
/// sleep sends the provider the same `.wake` message the main app
/// sends from its `scenePhase` observer.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var appState: AppState? {
        (UIApplication.shared.delegate as? AppDelegate)?.appState
    }

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene, let appState = appState else { return }

        let root = LegacyContentView()
            .environmentObject(appState)
            .environmentObject(appState.tunnel)
            .environmentObject(appState.servers)
            .environmentObject(appState.settingsModel)
            .environmentObject(appState.router)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: root)
        window.overrideUserInterfaceStyle = appState.interfaceStyle
        self.window = window
        window.makeKeyAndVisible()

        // Cold start through a link: the scene delivers it in the
        // connection options, before any `openURLContexts` call.
        for context in connectionOptions.urlContexts {
            appState.router.route(context.url)
        }
        if let activity = connectionOptions.userActivities.first {
            route(userActivity: activity)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            appState?.router.route(context.url)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        route(userActivity: userActivity)
    }

    private func route(userActivity: NSUserActivity) {
        // Donated Siri activities (LegacyShortcuts) carry the action in
        // `userInfo`; browsable-web activities carry a URL.
        if let url = userActivity.webpageURL {
            appState?.router.route(url)
        } else if let action = userActivity.userInfo?[LegacyShortcuts.activityActionKey] as? String {
            appState?.handleShortcutAction(action)
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let appState = appState else { return }
        window?.overrideUserInterfaceStyle = appState.interfaceStyle
        // Same foreground contract as the main app: reload the VPN
        // configuration state and ask the provider to re-assert its
        // network settings after sleep / network changes.
        LegacyTask.run {
            await appState.tunnel.load()
            await appState.tunnel.notifyWake()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        window = nil
    }
}

/// Era shim for fire-and-forget structured concurrency from UIKit
/// callbacks. `Task` itself back-deploys to iOS 13 when the app is
/// built with a Swift 5.5+ compiler, so this is only a named seam:
/// if the Mac build ever has to target an older toolchain, the shim
/// is the one place that changes (dispatch to the main queue there).
enum LegacyTask {
    static func run(_ operation: @escaping () async -> Void) {
        Task { await operation() }
    }
}
