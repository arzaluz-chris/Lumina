//
//  LuminaApp.swift
//  Lumina
//
//  Created by Christian Arzaluz on 11/04/26.
//

import SwiftUI
import SwiftData

@main
struct LuminaApp: App {
    /// Shared SwiftData container. Built once at app launch and injected
    /// into every view via `.modelContainer(_:)`.
    private let container: ModelContainer = .luminaContainer()

    /// Bridges UIKit's scene/shortcut lifecycle into SwiftUI so Home
    /// Screen Quick Actions (long-press the app icon) can route into
    /// the correct tab on both cold and warm launch.
    @UIApplicationDelegateAdaptor(LuminaAppDelegate.self) private var appDelegate

    init() { }

    /// Chooses the insights provider at launch. In screenshot mode the
    /// Foundation Models provider is swapped for the deterministic mock
    /// so the "Mis 24" analysis screen renders in the simulator too.
    private var insightsProvider: any AIInsightsProviding {
        #if DEBUG
        if ScreenshotMode.isActive { return MockInsightsProvider() }
        #endif
        return FoundationModelsInsightsProvider()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.aiInsightsProvider, insightsProvider)
                .task {
                    // Re-arm Story reminders on every launch. A cheap
                    // no-op when the user hasn't enabled the feature;
                    // when they have, it catches any state iOS may have
                    // dropped (e.g., after a device restore).
                    await rehydrateStoryReminders()
                }
        }
        .modelContainer(container)
    }

    @MainActor
    private func rehydrateStoryReminders() async {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Story>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let stories = try? context.fetch(descriptor) else { return }
        StoryReminderScheduler.rehydrate(from: stories)
    }
}
