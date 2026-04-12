import Foundation
import SwiftData

/// A completed run of the Lumina character strengths test.
///
/// Each result aggregates 24 `StrengthScore` children (one per strength)
/// and optionally an `AIInsight` generated after completion. Stored in
/// SwiftData so users can see their history and compare results over time.
@Model
final class TestResult {
    /// Unique identifier. Stable across migrations.
    var id: UUID = UUID()

    /// When the user tapped "finish" on the last question.
    var completedAt: Date = Date()

    /// 24 scores, one per strength.
    @Relationship(deleteRule: .cascade, inverse: \StrengthScore.testResult)
    var scores: [StrengthScore] = []

    /// The personalized AI-generated analysis, if one has been generated.
    /// Regenerated on demand and cached here to avoid repeated latency.
    @Relationship(deleteRule: .cascade, inverse: \AIInsight.testResult)
    var insight: AIInsight?

    init(id: UUID = UUID(), completedAt: Date = Date()) {
        self.id = id
        self.completedAt = completedAt
    }

    /// Strengths sorted from highest to lowest score, resolved against
    /// `StrengthsCatalog`. Entries whose strength ID is missing from the
    /// catalog are dropped — this can only happen if persisted data
    /// references a removed strength.
    var rankedStrengths: [(strength: Strength, points: Int)] {
        scores
            .compactMap { score -> (Strength, Int)? in
                guard let strength = StrengthsCatalog.strength(id: score.strengthID) else {
                    return nil
                }
                return (strength, score.points)
            }
            .sorted { $0.1 > $1.1 }
    }
}
