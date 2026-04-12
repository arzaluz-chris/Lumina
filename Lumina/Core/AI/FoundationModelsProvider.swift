import Foundation
import FoundationModels
import os

/// The real, on-device Foundation Models insights provider.
///
/// Wraps Apple's on-device `SystemLanguageModel` with a Spanish-language
/// system prompt and guided generation against ``StrengthInsight``.
/// Available only on Apple Intelligence-capable hardware with the
/// feature enabled in Settings.
struct FoundationModelsInsightsProvider: AIInsightsProviding {
    private let model: SystemLanguageModel

    init(model: SystemLanguageModel = .default) {
        self.model = model
        Logger.ai.info("FoundationModelsInsightsProvider initialized")
        Logger.ai.debug("Model availability: \(String(describing: model.availability))")
    }

    var isAvailable: Bool {
        if case .available = model.availability {
            Logger.ai.debug("AI availability check: AVAILABLE")
            return true
        }
        Logger.ai.info("AI availability check: NOT AVAILABLE")
        return false
    }

    var unavailableReason: String? {
        switch model.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                Logger.ai.warning("AI unavailable: device not eligible for Apple Intelligence")
                return "Tu dispositivo no soporta Apple Intelligence, así que no puedo generar el análisis personalizado. Tus resultados siguen disponibles."
            case .appleIntelligenceNotEnabled:
                Logger.ai.warning("AI unavailable: Apple Intelligence not enabled in Settings")
                return "Activa Apple Intelligence en Ajustes para recibir tu análisis personalizado."
            case .modelNotReady:
                Logger.ai.warning("AI unavailable: model not ready (downloading or preparing)")
                return "Apple Intelligence se está preparando. Inténtalo de nuevo en unos minutos."
            @unknown default:
                Logger.ai.warning("AI unavailable: unknown reason")
                return "Apple Intelligence no está disponible en este momento."
            }
        @unknown default:
            Logger.ai.warning("AI unavailable: unknown availability case")
            return "Apple Intelligence no está disponible en este momento."
        }
    }

    func generateInsight(for snapshot: TestSnapshot) async throws -> StrengthInsight {
        Logger.ai.info("=== INSIGHT GENERATION START ===")
        Logger.ai.info("Snapshot has \(snapshot.rankedEntries.count) entries")
        Logger.ai.debug("Top 5: \(snapshot.top(5).map { "\($0.strengthName)=\($0.points)" }.joined(separator: ", "))")
        Logger.ai.debug("Bottom 2: \(snapshot.bottom(2).map { "\($0.strengthName)=\($0.points)" }.joined(separator: ", "))")

        Logger.ai.info("Creating LanguageModelSession with system instructions...")
        let session = LanguageModelSession(
            model: model,
            instructions: Self.systemInstructions
        )
        Logger.ai.debug("Session created successfully")

        let userPrompt = Self.buildUserPrompt(for: snapshot)
        Logger.ai.debug("User prompt built (\(userPrompt.count) chars):\n\(userPrompt)")

        Logger.ai.info("Calling session.respond(to:generating: StrengthInsight.self)...")
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let response = try await session.respond(
                to: userPrompt,
                generating: StrengthInsight.self
            )
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            Logger.ai.info("=== INSIGHT GENERATION COMPLETE (\(elapsed, format: .fixed(precision: 2)) seconds) ===")
            Logger.ai.debug("Summary preview: \(String(response.content.summary.prefix(100)))...")
            Logger.ai.debug("Signature strengths returned: \(response.content.signatureStrengths.map(\.strengthName).joined(separator: ", "))")
            Logger.ai.debug("Growth areas returned: \(response.content.growthAreas.map(\.strengthName).joined(separator: ", "))")
            Logger.ai.debug("Encouragement preview: \(String(response.content.encouragement.prefix(80)))...")
            return response.content
        } catch {
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            Logger.ai.error("=== INSIGHT GENERATION FAILED (\(elapsed, format: .fixed(precision: 2)) seconds) ===")
            Logger.ai.error("Error type: \(type(of: error))")
            Logger.ai.error("Error description: \(error.localizedDescription)")
            Logger.ai.error("Full error: \(String(describing: error))")
            throw error
        }
    }

    // MARK: - Prompt construction

    private static let systemInstructions: Instructions = Instructions("""
    Eres un coach experto en las 24 fortalezas de carácter VIA de Peterson y Seligman. \
    Ayudas al usuario a entender e integrar sus fortalezas con calidez, respeto y enfoque científico. \
    Escribes en español neutral, en segunda persona (tú), con tono cercano pero profesional. \
    Evitas clichés de autoayuda y frases genéricas. \
    Tus recomendaciones son concretas, accionables y específicas a las fortalezas del usuario, \
    nunca consejos generales. \
    No haces diagnósticos psicológicos. \
    Las fortalezas con puntuación baja las enmarcas como oportunidades de crecimiento, \
    nunca como déficit.
    """)

    /// Builds the user prompt with only the top 5 and bottom 2 strengths —
    /// the model gives more focused output when working with a subset.
    private static func buildUserPrompt(for snapshot: TestSnapshot) -> String {
        let top = snapshot.top(5)
        let bottom = snapshot.bottom(2)

        var lines: [String] = []
        lines.append("Fortalezas principales del usuario (signature):")
        for (index, entry) in top.enumerated() {
            lines.append("\(index + 1). \(entry.strengthName) (\(entry.points)/10)")
        }
        lines.append("")
        lines.append("Áreas de crecimiento (menor puntuación):")
        for (index, entry) in bottom.enumerated() {
            lines.append("\(index + 1). \(entry.strengthName) (\(entry.points)/10)")
        }
        lines.append("")
        lines.append("Genera el análisis personalizado siguiendo el esquema solicitado.")
        return lines.joined(separator: "\n")
    }
}
