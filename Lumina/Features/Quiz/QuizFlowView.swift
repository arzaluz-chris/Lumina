import SwiftUI
import SwiftData

/// Orchestrates one complete test run: shows the current question,
/// records answers, persists a `TestResult` on completion, and hands
/// control back to the caller via `onComplete`.
struct QuizFlowView: View {
    @State private var state = QuizState()
    @Environment(\.modelContext) private var modelContext

    /// Called once the quiz is finished and the `TestResult` has been
    /// saved. The caller typically switches to the Results tab.
    var onComplete: (TestResult) -> Void

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            progressHeader
                .padding(.horizontal, Theme.spacingL)
                .padding(.top, Theme.spacingM)

            if let question = state.currentQuestion {
                ScrollView {
                    QuestionCardView(question: question) { points in
                        handleAnswer(points: points)
                    }
                    .padding(.vertical, Theme.spacingL)
                    .id(state.currentIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            } else {
                // Briefly visible when the last answer has been recorded
                // but `onComplete` hasn't been invoked yet.
                Spacer()
                ProgressView()
                    .controlSize(.large)
                Spacer()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: state.currentIndex)
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Text("Pregunta \(min(state.currentIndex + 1, state.shuffledQuestions.count))")
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.primaryText)
                Text("de \(state.shuffledQuestions.count)")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
            }
            ProgressView(value: state.progress)
                .tint(Theme.accent)
        }
    }

    private func handleAnswer(points: Int) {
        state.answer(points: points)
        if state.isComplete {
            save()
        }
    }

    private func save() {
        let result = TestResult()
        for (strengthID, points) in state.computeScores() {
            let score = StrengthScore(strengthID: strengthID, points: points)
            result.scores.append(score)
        }
        modelContext.insert(result)
        do {
            try modelContext.save()
        } catch {
            // Saving should be safe; if it isn't, we still surface the
            // completion so the user isn't trapped on the last question.
            assertionFailure("Failed to save TestResult: \(error)")
        }
        onComplete(result)
    }
}
