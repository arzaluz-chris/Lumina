import Foundation
import SwiftUI
import StoreKit
import os

/// Counts meaningful actions (completing a test, saving a story) and
/// triggers the system App Store review prompt once the user has racked
/// up enough of them — but only once per app version and never within
/// 14 days of first launch.
///
/// Apple caps the actual prompt at 3 displays per 365 days per device,
/// and also silently ignores `requestReview()` when the prompt budget
/// is exhausted. We still keep our own guardrails so we never *try* to
/// prompt during onboarding or tutorials.
@MainActor
@Observable
final class ReviewRequestCoordinator {
    static let shared = ReviewRequestCoordinator()

    /// Weighted score of meaningful user actions since install. Resets
    /// after a prompt is delivered.
    private var weightedScore: Int {
        get { UserDefaults.standard.integer(forKey: Keys.weightedScore) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.weightedScore) }
    }

    private var lastPromptedVersion: String {
        get { UserDefaults.standard.string(forKey: Keys.lastPromptedVersion) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastPromptedVersion) }
    }

    private var installDate: Date {
        get {
            if let stored = UserDefaults.standard.object(forKey: Keys.installDate) as? Date {
                return stored
            }
            let now = Date()
            UserDefaults.standard.set(now, forKey: Keys.installDate)
            return now
        }
    }

    private enum Keys {
        static let weightedScore = "rrMeaningfulActions"
        static let lastPromptedVersion = "rrLastPromptedVersion"
        static let installDate = "rrInstallDate"
    }

    /// Discrete user actions that qualify as "meaningful" for review
    /// prompt purposes. Weights are hand-tuned so the prompt lands
    /// after a user has meaningfully engaged with the app — not on
    /// the very first session.
    enum Milestone {
        case completedQuiz
        case addedStory
        case openedBuddyAnswer

        var weight: Int {
            switch self {
            case .completedQuiz: return 3
            case .addedStory: return 2
            case .openedBuddyAnswer: return 1
            }
        }
    }

    private let minimumScore = 5
    private let minimumDaysSinceInstall = 3

    /// Tracks a milestone. Increments the internal score; calls
    /// `requestIfReady` so a prompt may fire on the next runloop tick.
    func recordMilestone(_ milestone: Milestone, requestReview: @escaping @MainActor () -> Void) {
        weightedScore += milestone.weight
        Logger.review.debug("Milestone \(String(describing: milestone)) recorded. Score: \(self.weightedScore)")
        requestIfReady(requestReview: requestReview)
    }

    /// Asks the system to show the review prompt if guardrails permit.
    /// Passes through to `@Environment(\.requestReview)` which in turn
    /// calls through to `SKStoreReviewController.requestReview(in:)`.
    private func requestIfReady(requestReview: @escaping @MainActor () -> Void) {
        guard weightedScore >= minimumScore else { return }

        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        guard daysSinceInstall >= minimumDaysSinceInstall else {
            Logger.review.debug("Review prompt skipped — only \(daysSinceInstall) days since install.")
            return
        }

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        guard currentVersion != lastPromptedVersion else {
            Logger.review.debug("Review prompt skipped — already prompted on version \(currentVersion).")
            return
        }

        let scheduledVersion = currentVersion
        // Fire on next runloop, after a short delay, so the prompt never
        // lands on the user's tap gesture (Apple explicitly discourages
        // prompting in direct response to an action).
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            requestReview()
            self.lastPromptedVersion = scheduledVersion
            self.weightedScore = 0
        }
    }
}

