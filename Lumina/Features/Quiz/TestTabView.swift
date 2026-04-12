import SwiftUI
import SwiftData

/// The root view of the Test tab.
///
/// Routes between three states:
/// 1. No test completed and not taking one → auto-start a new quiz.
/// 2. Taking a quiz → `QuizFlowView`.
/// 3. Already completed at least one quiz (and not in progress) →
///    `QuizHomeView` summarizing the latest result.
struct TestTabView: View {
    @Query(sort: \TestResult.completedAt, order: .reverse) private var results: [TestResult]
    @State private var isTakingQuiz: Bool = false

    /// Called when the user just finished a quiz, so the parent can
    /// switch to the Results tab.
    var onQuizComplete: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if isTakingQuiz || results.isEmpty {
                    QuizFlowView { _ in
                        isTakingQuiz = false
                        onQuizComplete()
                    }
                } else if let latest = results.first {
                    QuizHomeView(
                        result: latest,
                        onRetake: { isTakingQuiz = true },
                        onViewResults: onQuizComplete
                    )
                }
            }
            .navigationTitle("Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
