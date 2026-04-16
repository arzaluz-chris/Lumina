import SwiftUI
import SwiftData
import os

/// Orchestrates one complete test run: shows the current question,
/// records answers, persists a `TestResult` on completion, shows a
/// processing animation, and hands control back via `onComplete`.
struct QuizFlowView: View {
    @State private var state = QuizState()
    @State private var isProcessing = false
    @State private var savedResult: TestResult?
    @AppStorage("hasSeenSwipeTutorial") private var hasSeenSwipeTutorial = false
    @Environment(\.modelContext) private var modelContext

    /// Called once the quiz is finished and the `TestResult` has been
    /// saved. The caller typically switches to the Results tab.
    var onComplete: (TestResult) -> Void

    var body: some View {
        if isProcessing {
            QuizProcessingView {
                if let result = savedResult {
                    onComplete(result)
                }
            }
            .transition(.opacity)
        } else {
            if !hasSeenSwipeTutorial {
                SwipeTutorialView {
                    hasSeenSwipeTutorial = true
                }
            } else {
                quizContent
            }
        }
    }

    private var quizContent: some View {
        VStack(spacing: Theme.spacingL) {
            progressHeader
                .padding(.horizontal, Theme.spacingL)
                .padding(.top, Theme.spacingM)

            if let question = state.currentQuestion {
                QuestionCardView(question: question) { points in
                    handleAnswer(points: points)
                }
                .id(state.currentIndex)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                Spacer()
                ProgressView()
                    .controlSize(.large)
                Spacer()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .sensoryFeedback(.success, trigger: state.isComplete)
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
        Logger.quiz.info("=== SAVING TEST RESULT ===")
        let result = TestResult()
        let allScores = state.computeScores()
        for (strengthID, points) in allScores {
            let score = StrengthScore(strengthID: strengthID, points: points)
            result.scores.append(score)
        }
        Logger.quiz.info("TestResult created with \(result.scores.count) scores")
        modelContext.insert(result)
        do {
            try modelContext.save()
            Logger.quiz.info("TestResult saved to SwiftData successfully (id: \(result.id))")
        } catch {
            Logger.quiz.error("FAILED to save TestResult: \(error.localizedDescription)")
        }
        savedResult = result
        // Schedule quiz re-test reminder if enabled
        if UserDefaults.standard.bool(forKey: "quizReminderEnabled") {
            NotificationManager.shared.scheduleQuizReminder(lastCompletedAt: result.completedAt)
        }
        Logger.quiz.info("Quiz complete → showing processing animation")
        withAnimation(.easeInOut(duration: 0.3)) {
            isProcessing = true
        }
    }
}
