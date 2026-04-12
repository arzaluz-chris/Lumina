//
//  LuminaApp.swift
//  Lumina
//
//  Created by Christian Arzaluz on 11/04/26.
//

import SwiftUI
import SwiftData
import os

@main
struct LuminaApp: App {
    /// Shared SwiftData container. Built once at app launch and injected
    /// into every view via `.modelContainer(_:)`.
    private let container: ModelContainer = .luminaContainer()

    init() {
        Logger.app.info("=== LUMINA APP LAUNCH ===")
        Logger.app.info("Bundle: \(Bundle.main.bundleIdentifier ?? "unknown")")
        Logger.app.info("Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")")
        Logger.app.debug("SwiftData container ready")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.aiInsightsProvider, FoundationModelsInsightsProvider())
        }
        .modelContainer(container)
    }
}
