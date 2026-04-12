import Foundation
import Observation

/// Ephemeral state of an in-progress quiz run.
///
/// Owns the shuffled question order, the current index, and the raw
/// Likert answers keyed by canonical question ID. On completion, produces
/// the per-strength score aggregation that a `TestResult` will store.
///
/// The shuffle is seeded once per instance so navigating back and forth
/// within a run doesn't reorder questions, but each new test gets a
/// fresh order to avoid priming.
@Observable
final class QuizState {
    /// Questions in presentation order (shuffled).
    private(set) var shuffledQuestions: [Question]

    /// Index into `shuffledQuestions` of the question currently displayed.
    /// Equals `shuffledQuestions.count` when the quiz is complete.
    private(set) var currentIndex: Int = 0

    /// Likert points (1...5) keyed by canonical `Question.id`.
    private(set) var answers: [Int: Int] = [:]

    init() {
        self.shuffledQuestions = QuestionsCatalog.all.shuffled()
    }

    /// The question currently being presented, or `nil` if the quiz is
    /// complete.
    var currentQuestion: Question? {
        guard currentIndex < shuffledQuestions.count else { return nil }
        return shuffledQuestions[currentIndex]
    }

    /// True when every question has been answered.
    var isComplete: Bool {
        answers.count == shuffledQuestions.count
    }

    /// Progress in `[0, 1]` for the quiz progress bar.
    var progress: Double {
        guard !shuffledQuestions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(shuffledQuestions.count)
    }

    /// Records an answer for the current question and advances the index.
    /// No-ops when the quiz is already complete.
    func answer(points: Int) {
        guard let question = currentQuestion else { return }
        answers[question.id] = points
        currentIndex += 1
    }

    /// Aggregates raw answers into per-strength scores. Every strength
    /// is present in the output (strengths without answered questions
    /// map to 0) so `TestResult.scores` is always exhaustive.
    func computeScores() -> [String: Int] {
        var scores: [String: Int] = Dictionary(
            uniqueKeysWithValues: StrengthsCatalog.all.map { ($0.id, 0) }
        )
        for (questionID, points) in answers {
            guard let question = QuestionsCatalog.all.first(where: { $0.id == questionID }) else {
                continue
            }
            scores[question.strengthID, default: 0] += points
        }
        return scores
    }

    /// Resets to a brand-new shuffled run. Used by the "retake test" button.
    func restart() {
        shuffledQuestions = QuestionsCatalog.all.shuffled()
        currentIndex = 0
        answers = [:]
    }
}
