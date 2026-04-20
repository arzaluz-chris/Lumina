import Foundation
import FoundationModels
import SwiftUI

/// Single source of truth for "can this device run Lumina's AI features?".
///
/// Previously the `SystemLanguageModel.default.availability` check was
/// duplicated across 7 call sites. Centralizing it here:
///
/// * lets us render a Buddy-free variant of the app (no tab, no CTA) on
///   devices where Apple Intelligence is structurally unsupported
///   (`.deviceNotEligible`), while keeping a user-actionable CTA on
///   devices where it's just disabled in Settings
///   (`.appleIntelligenceNotEnabled`);
/// * gives Previews and tests a seam to inject a mock result, so we can
///   visualize the "non-AI" variant without a second device.
///
/// The gate is a thin value wrapper around `SystemLanguageModel.Availability`;
/// it does NOT cache. Apple's framework already returns a fast, local
/// availability value, and re-checking ensures we react if the user
/// flips the Apple Intelligence setting while Lumina is in the background.
@MainActor
@Observable
final class AICapabilityGate {
    /// Shared instance used across the app.
    static let shared = AICapabilityGate()

    /// Internal override used by SwiftUI previews and tests to simulate
    /// a device without Apple Intelligence.
    private var override: SystemLanguageModel.Availability?

    init(override: SystemLanguageModel.Availability? = nil) {
        self.override = override
    }

    var availability: SystemLanguageModel.Availability {
        override ?? SystemLanguageModel.default.availability
    }

    /// True when we can open a `LanguageModelSession` right now.
    var isAvailable: Bool {
        if ScreenshotMode.isActive { return true }
        if case .available = availability { return true }
        return false
    }

    /// `true` on devices that can never run Apple Intelligence (older
    /// hardware). We use this to fully hide AI-only UI so those users
    /// aren't nagged with "upgrade your phone" CTAs they can't act on.
    var shouldHideAIEntirely: Bool {
        if ScreenshotMode.isActive { return false }
        if case .unavailable(.deviceNotEligible) = availability { return true }
        return false
    }

    /// `true` when the user can fix the state themselves (toggle Apple
    /// Intelligence in Settings). In that case we show a CTA instead of
    /// hiding the feature outright.
    var canUserEnable: Bool {
        if case .unavailable(.appleIntelligenceNotEnabled) = availability { return true }
        return false
    }

    /// Short, user-facing, localized reason the provider is unavailable.
    /// `nil` when `isAvailable == true`.
    var unavailableReason: LocalizedStringResource? {
        switch availability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return LocalizedStringResource("Tu dispositivo no soporta Apple Intelligence, así que no puedo generar el análisis personalizado. Tus resultados siguen disponibles.")
            case .appleIntelligenceNotEnabled:
                return LocalizedStringResource("Activa Apple Intelligence en Ajustes para recibir tu análisis personalizado.")
            case .modelNotReady:
                return LocalizedStringResource("Apple Intelligence se está preparando. Inténtalo de nuevo en unos minutos.")
            @unknown default:
                return LocalizedStringResource("Apple Intelligence no está disponible en este momento.")
            }
        @unknown default:
            return LocalizedStringResource("Apple Intelligence no está disponible en este momento.")
        }
    }

    /// Non-localized String variant for places that still take plain strings.
    var unavailableReasonString: String? {
        guard let resource = unavailableReason else { return nil }
        return String(localized: resource)
    }
}

