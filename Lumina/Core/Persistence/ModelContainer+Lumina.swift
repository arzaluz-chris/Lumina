import Foundation
import SwiftData

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
        let config = ModelConfiguration(
            "Lumina",
            schema: luminaSchema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: luminaSchema, configurations: config)
        } catch {
            assertionFailure("Failed to open Lumina SwiftData store: \(error)")
            let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
            // Force-try because an in-memory container cannot fail in practice;
            // if it does, there is nothing we can recover to.
            return try! ModelContainer(for: luminaSchema, configurations: fallback)
        }
    }

    /// A fresh in-memory container used by previews and unit tests.
    static func luminaPreviewContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: luminaSchema, configurations: config)
    }
}
