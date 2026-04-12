import Foundation
import SwiftData

/// A cached Foundation Models response analyzing a `TestResult`.
///
/// The structured `StrengthInsight` value is serialized to JSON and stored
/// so subsequent visits to the Insights screen don't re-run the model.
/// The user can force regeneration from the UI, which replaces this row.
@Model
final class AIInsight {
    var id: UUID = UUID()

    /// When the model finished generating this insight.
    var generatedAt: Date = Date()

    /// `StrengthInsight` encoded with `JSONEncoder`. Decoded on read in
    /// `InsightsView` to render the structured sections.
    var summaryJSON: Data = Data()

    /// Back-pointer to the test run this insight analyzes. SwiftData
    /// manages the inverse declared on `TestResult.insight`.
    var testResult: TestResult?

    init(id: UUID = UUID(), generatedAt: Date = Date(), summaryJSON: Data) {
        self.id = id
        self.generatedAt = generatedAt
        self.summaryJSON = summaryJSON
    }
}
