import os

/// Centralized loggers for Lumina — error-level only to avoid
/// os.Logger quarantining due to high volume.
extension Logger {
    private static let subsystem = "com.christian-arzaluz.Lumina"

    /// Foundation Models insights + daily reflection.
    static let ai = Logger(subsystem: subsystem, category: "AI")

    /// Lumina Buddy chat service.
    static let buddy = Logger(subsystem: subsystem, category: "Buddy")

    /// Quiz flow and test persistence.
    static let quiz = Logger(subsystem: subsystem, category: "Quiz")

    /// SwiftData container.
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")

    /// Insights view: cache + generation.
    static let insights = Logger(subsystem: subsystem, category: "Insights")

    /// Notification scheduling.
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")

    /// App Store review prompt coordinator.
    static let review = Logger(subsystem: subsystem, category: "Review")

    /// Home Screen Quick Actions routing.
    static let quickActions = Logger(subsystem: subsystem, category: "QuickActions")
}
