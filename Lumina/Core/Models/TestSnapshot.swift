import Foundation

/// A `Sendable` value-type view of a `TestResult` used to shuttle the
/// ranking across actor boundaries.
///
/// SwiftData `@Model` instances are reference types that are not
/// `Sendable` — passing them into `nonisolated` or background contexts
/// is a Swift 6 error. The AI services consume a `TestSnapshot` instead,
/// which contains everything needed to build a prompt (ranked strength
/// names + scores) and can safely cross actor boundaries.
struct TestSnapshot: Sendable, Equatable {
    struct Entry: Sendable, Equatable, Hashable {
        /// The matching `Strength.id`.
        let strengthID: String

        /// Localized display name, pre-resolved so the AI provider
        /// doesn't need to touch the catalog.
        let strengthName: String

        /// Summed Likert points in `[2, 10]`.
        let points: Int
    }

    /// Entries sorted from highest to lowest score. The caller guarantees
    /// this ordering so downstream consumers can trust `prefix` / `suffix`.
    let rankedEntries: [Entry]

    /// The top `n` entries (signature strengths).
    func top(_ n: Int) -> [Entry] { Array(rankedEntries.prefix(n)) }

    /// The bottom `n` entries (growth areas).
    func bottom(_ n: Int) -> [Entry] { Array(rankedEntries.suffix(n)) }
}

extension TestResult {
    /// Converts the persisted result into a Sendable value snapshot.
    /// Must be called on the main actor because `TestResult` is bound
    /// to the main actor's `ModelContext`.
    @MainActor
    func snapshot() -> TestSnapshot {
        let entries = rankedStrengths.map { ranked in
            TestSnapshot.Entry(
                strengthID: ranked.strength.id,
                strengthName: ranked.strength.nameES,
                points: ranked.points
            )
        }
        return TestSnapshot(rankedEntries: entries)
    }
}
