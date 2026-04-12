import Foundation
import SwiftData
import os

extension ModelContainer {
    /// The SwiftData schema for Lumina: test results, strength scores,
    /// stories, and cached AI insights.
    static let luminaSchema = Schema([
        TestResult.self,
        StrengthScore.self,
        Story.self,
        AIInsight.self,
    ])

    /// Returns the app-wide `ModelContainer` that backs `@Query` and
    /// `@Environment(\.modelContext)` throughout the app. Falls back to
    /// an in-memory store if the on-disk container cannot be opened —
    /// preventing first-launch crashes in favor of a (very rare)
    /// ephemeral session that the user can report.
    static func luminaContainer() -> ModelContainer {
        Logger.persistence.info("Creating Lumina SwiftData container (on-disk)...")
        let config = ModelConfiguration(
            "Lumina",
            schema: luminaSchema,
            isStoredInMemoryOnly: false
        )
        do {
            let container = try ModelContainer(for: luminaSchema, configurations: config)
            Logger.persistence.info("SwiftData container opened successfully (on-disk)")
            return container
        } catch {
            Logger.persistence.error("FAILED to open on-disk SwiftData store: \(error.localizedDescription)")
            Logger.persistence.warning("Falling back to in-memory store — data will NOT persist across launches")
            let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: luminaSchema, configurations: fallback)
        }
    }

    /// A fresh in-memory container used by previews and unit tests.
    static func luminaPreviewContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: luminaSchema, configurations: config)
    }
}
