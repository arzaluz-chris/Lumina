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

    init() { }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.aiInsightsProvider, FoundationModelsInsightsProvider())
        }
        .modelContainer(container)
    }
}
