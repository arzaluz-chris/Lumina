import os

/// Centralized loggers for Lumina, one per subsystem area.
///
/// Uses Apple's structured `os.Logger` so messages show up in Console.app
/// with filterable subsystem + category. Levels:
///   .debug   → verbose, stripped in Release
///   .info    → notable events (session start, generation complete)
///   .error   → failures that need attention
///   .fault   → programmer errors / impossible states
extension Logger {
    private static let subsystem = "com.christian-arzaluz.Lumina"

    /// Foundation Models insights + Generable schema.
    static let ai = Logger(subsystem: subsystem, category: "AI")

    /// Lumina Buddy chat service + streaming.
    static let buddy = Logger(subsystem: subsystem, category: "Buddy")

    /// Quiz flow: answers, scoring, test completion.
    static let quiz = Logger(subsystem: subsystem, category: "Quiz")

    /// SwiftData container + model operations.
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")

    /// PhotoStore: save / load / delete.
    static let photos = Logger(subsystem: subsystem, category: "Photos")

    /// Stories feature: create, detail, delete.
    static let stories = Logger(subsystem: subsystem, category: "Stories")

    /// Insights view: cache, generation, UI state.
    static let insights = Logger(subsystem: subsystem, category: "Insights")

    /// App lifecycle, onboarding, tab navigation.
    static let app = Logger(subsystem: subsystem, category: "App")
}
