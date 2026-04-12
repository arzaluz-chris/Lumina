import Foundation

/// The contract for generating personalized insights from a completed
/// test result.
///
/// Exposed as a protocol so the app has three concrete implementations:
///
/// 1. ``FoundationModelsInsightsProvider`` — the real on-device model
///    used in production when Apple Intelligence is available.
/// 2. ``MockInsightsProvider`` — deterministic canned data for SwiftUI
///    previews and unit tests.
/// 3. (future) any server-backed fallback — not shipped in v1.
///
/// ``isAvailable`` is surfaced to the UI so the Insights screen can
/// render a graceful empty state on devices without Apple Intelligence
/// (iPhone 14 and earlier, non-M-series iPads, Macs without Apple silicon
/// running Catalyst, etc.) rather than crashing mid-generation.
protocol AIInsightsProviding: Sendable {
    /// Whether the provider can produce insights right now. The UI is
    /// expected to check this before showing a "generate" CTA.
    var isAvailable: Bool { get }

    /// A localized reason the provider is unavailable, suitable for
    /// display directly to the user. `nil` when `isAvailable == true`.
    var unavailableReason: String? { get }

    /// Generates a fresh insight for the given test snapshot.
    ///
    /// Callers on the main actor should convert their `TestResult` into
    /// a `TestSnapshot` (see `TestResult.snapshot()`) before invoking
    /// this method — snapshots are `Sendable` and cross actor boundaries
    /// safely, while SwiftData `@Model` values cannot.
    ///
    /// Callers should cache the returned value on `AIInsight` so repeat
    /// visits to the Insights screen don't re-pay the generation latency.
    /// Errors bubble up to the UI which should show a non-fatal banner
    /// and keep the raw ranking visible.
    func generateInsight(for snapshot: TestSnapshot) async throws -> StrengthInsight
}
