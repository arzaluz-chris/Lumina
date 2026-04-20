import Foundation
import SwiftUI

/// DEBUG-only mode used to populate the app with realistic demo data and
/// bypass Apple Intelligence gates so App Store screenshots can be captured
/// in the iOS Simulator (where Foundation Models is unavailable).
///
/// The flag is consulted by:
///   • ``AICapabilityGate`` — returns `isAvailable == true` when on.
///   • ``LuminaBuddyChatService`` — returns `isAvailable == true` and
///     short-circuits any real `LanguageModelSession` calls.
///   • ``LuminaApp`` — injects ``MockInsightsProvider`` instead of the
///     Foundation Models provider.
///
/// The flag can be enabled two ways:
///   • Persisted toggle under Ajustes › Screenshots (DEBUG-only section).
///   • Launch argument `-ScreenshotMode 1` for automated capture runs.
enum ScreenshotMode {
    static let storageKey = "screenshotMode"

    /// Whether screenshot mode is active *right now*. Cheap to read.
    static var isActive: Bool {
        #if DEBUG
        if CommandLine.arguments.contains("-ScreenshotMode") {
            return true
        }
        return UserDefaults.standard.bool(forKey: storageKey)
        #else
        return false
        #endif
    }
}
