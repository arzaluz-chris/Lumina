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
    }

    var isAvailable: Bool {
        if case .available = model.availability { return true }
        return false
    }

    var unavailableReason: String? {
        switch model.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "Tu dispositivo no soporta Apple Intelligence, así que no puedo generar el análisis personalizado. Tus resultados siguen disponibles."
            case .appleIntelligenceNotEnabled:
                return "Activa Apple Intelligence en Ajustes para recibir tu análisis personalizado."
            case .modelNotReady:
                return "Apple Intelligence se está preparando. Inténtalo de nuevo en unos minutos."
            @unknown default:
                return "Apple Intelligence no está disponible en este momento."
            }
        @unknown default:
            return "Apple Intelligence no está disponible en este momento."
        }
    }

    func generateInsight(for snapshot: TestSnapshot) async throws -> StrengthInsight {
        let session = LanguageModelSession(
            model: model,
            instructions: Self.systemInstructions
        )

        let userPrompt = Self.buildUserPrompt(for: snapshot)

        do {
            let response = try await session.respond(
                to: userPrompt,
                generating: StrengthInsight.self
            )
            return response.content
        } catch {
            Logger.ai.error("Insight generation failed: \(error.localizedDescription)")
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
