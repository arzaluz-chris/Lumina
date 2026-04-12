import Foundation
import SwiftData

/// A single strength score within a `TestResult`.
///
/// Points accumulate from the Likert answers of the questions mapped to
/// this strength. With 2 questions per strength and a 1..5 scale, the
/// stored value is in `[2, 10]`.
@Model
final class StrengthScore {
    /// Stable ID matching `Strength.id` in `StrengthsCatalog`. Acts as a
    /// foreign key — the `Strength` itself is not persisted because the
    /// catalog is compiled into the app binary.
    var strengthID: String = ""

    /// Summed Likert points for this strength in a single test run.
    var points: Int = 0

    /// Back-pointer to the enclosing test result. SwiftData manages the
    /// inverse relationship declared on `TestResult.scores`.
    var testResult: TestResult?

    init(strengthID: String, points: Int) {
        self.strengthID = strengthID
        self.points = points
    }
}
