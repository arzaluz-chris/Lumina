import SwiftUI
import SwiftData
import StoreKit
import os

/// Orchestrates one complete test run: shows the current question,
/// records answers, persists a `TestResult` on completion, shows a
/// processing animation, and hands control back via `onComplete`.
///
/// Redesign (2026-04-17): progress header uses a pill-based counter and
/// the new ``LuminaProgressBar``; backdrop is the soft hero gradient.
struct QuizFlowView: View {
    @State private var state = QuizState()
    @State private var isProcessing = false
    @State private var savedResult: TestResult?
    @AppStorage("hasSeenSwipeTutorial") private var hasSeenSwipeTutorial = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview

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
        .background(Theme.heroGradient.ignoresSafeArea())
        .sensoryFeedback(.success, trigger: state.isComplete)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: state.currentIndex)
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS + 2) {
            HStack(spacing: Theme.spacingS) {
                LuminaChip(
                    title: "Pregunta \(min(state.currentIndex + 1, state.shuffledQuestions.count)) de \(state.shuffledQuestions.count)",
                    systemImage: "list.number",
                    style: .accent
                )
                Spacer()
                Text(progressPercentString)
                    .font(Theme.captionFont.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: state.progress)
            }
            LuminaProgressBar(progress: state.progress, height: 10)
        }
    }

    private var progressPercentString: String {
        "\(Int(round(state.progress * 100)))%"
    }

    private func handleAnswer(points: Int) {
        state.answer(points: points)
        if state.isComplete {
            save()
        }
    }

    private func save() {
        let result = TestResult()
        let allScores = state.computeScores()
        for (strengthID, points) in allScores {
            let score = StrengthScore(strengthID: strengthID, points: points)
            result.scores.append(score)
        }
        modelContext.insert(result)
        do {
            try modelContext.save()
        } catch {
            Logger.quiz.error("Failed to save TestResult: \(error.localizedDescription)")
        }
        savedResult = result
        // Schedule quiz re-test reminder if enabled
        if UserDefaults.standard.bool(forKey: "quizReminderEnabled") {
            NotificationManager.shared.scheduleQuizReminder(lastCompletedAt: result.completedAt)
        }
        // Completing a test is the strongest signal the user is
        // engaged; record it for the App Store review coordinator.
        ReviewRequestCoordinator.shared.recordMilestone(.completedQuiz) {
            requestReview()
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            isProcessing = true
        }
    }
}
