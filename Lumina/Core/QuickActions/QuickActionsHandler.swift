import Foundation
import UIKit
import SwiftUI
import Combine
import os

/// Receives Home Screen Quick Actions from UIKit's SceneDelegate and
/// publishes them to SwiftUI via a Combine subject.
///
/// The bridge is needed because SwiftUI has no first-class Quick Action
/// hook — iOS still delivers them to the UIScene lifecycle. `RootView`
/// subscribes with `.onReceive` and routes to the correct tab/sheet.
@MainActor
final class QuickActionsHandler: ObservableObject {
    static let shared = QuickActionsHandler()

    /// Identifier strings used by `UIApplicationShortcutItem` entries.
    /// Kept in sync with the `UIApplicationShortcutItems` array in the
    /// project's generated Info.plist.
    enum Action: String, CaseIterable {
        case test    = "com.eduardo-garcia.Lumina.shortcut.test"
        case buddy   = "com.eduardo-garcia.Lumina.shortcut.buddy"
        case story   = "com.eduardo-garcia.Lumina.shortcut.story"
        case results = "com.eduardo-garcia.Lumina.shortcut.results"
    }

    /// Stream of actions triggered by Quick Actions. Hot; values only
    /// delivered while someone is subscribed.
    let actions = PassthroughSubject<Action, Never>()

    /// Cold-launch buffer: if the app is cold-launched with a shortcut,
    /// SceneDelegate stores it here until RootView finishes mounting.
    /// Consumed by `consumePending()`.
    var pending: Action?

    private init() {}

    /// Called by the SceneDelegate with the raw `UIApplicationShortcutItem`.
    func handle(_ shortcut: UIApplicationShortcutItem, isColdLaunch: Bool) {
        guard let action = Action(rawValue: shortcut.type) else {
            Logger.quickActions.debug("Unknown shortcut type: \(shortcut.type, privacy: .public)")
            return
        }
        if isColdLaunch {
            pending = action
        } else {
            actions.send(action)
        }
    }

    /// Drains any cold-launch-buffered action. Called by `RootView` on
    /// appear, once the tab structure exists and can actually navigate.
    func consumePending() -> Action? {
        let action = pending
        pending = nil
        return action
    }
}

// MARK: - AppDelegate + SceneDelegate

/// Minimal `UIApplicationDelegate` that:
/// 1. Vends a `UISceneConfiguration` wired to our `SceneDelegate` so
///    Home Screen Quick Actions get routed through `LuminaSceneDelegate`.
/// 2. Registers our four Quick Actions dynamically at launch. Done
///    programmatically (rather than via a static Info.plist entry)
///    because `GENERATE_INFOPLIST_FILE = YES` doesn't accept complex
///    nested dictionaries; dynamic shortcuts are persistent across
///    relaunches once set, so in practice they behave identically.
final class LuminaAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        application.shortcutItems = Self.buildShortcuts()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
        config.delegateClass = LuminaSceneDelegate.self
        return config
    }

    private static func buildShortcuts() -> [UIApplicationShortcutItem] {
        [
            UIApplicationShortcutItem(
                type: QuickActionsHandler.Action.test.rawValue,
                localizedTitle: String(localized: "Hacer el test"),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "pencil.and.list.clipboard"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickActionsHandler.Action.buddy.rawValue,
                localizedTitle: String(localized: "Hablar con Buddy"),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "bubble.left.and.bubble.right.fill"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickActionsHandler.Action.story.rawValue,
                localizedTitle: String(localized: "Nueva historia"),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "plus.bubble.fill"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickActionsHandler.Action.results.rawValue,
                localizedTitle: String(localized: "Ver mis fortalezas"),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "chart.bar.fill"),
                userInfo: nil
            ),
        ]
    }
}

/// Routes Home Screen Quick Actions into the SwiftUI layer.
final class LuminaSceneDelegate: NSObject, UIWindowSceneDelegate {
    // Retained by UIKit on our behalf; we don't construct the window
    // ourselves (SwiftUI does).
    var window: UIWindow?

    /// Cold-launch entry: called once when a UIScene connects. If the
    /// app was launched by tapping a Quick Action, `options.shortcutItem`
    /// will be non-nil.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let shortcut = connectionOptions.shortcutItem {
            Task { @MainActor in
                QuickActionsHandler.shared.handle(shortcut, isColdLaunch: true)
            }
        }
    }

    /// Warm-launch entry: called when the app is already running
    /// (foreground or suspended) and the user taps a Quick Action.
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        Task { @MainActor in
            QuickActionsHandler.shared.handle(shortcutItem, isColdLaunch: false)
            completionHandler(true)
        }
    }
}
