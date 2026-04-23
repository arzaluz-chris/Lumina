import Foundation
import FoundationModels
import os

/// Conversational wrapper around Foundation Models for the Lumina Buddy
/// chat tab.
@MainActor
final class LuminaBuddyChatService {
    private var session: LanguageModelSession?
    private let model: SystemLanguageModel
    private var turnCount: Int = 0

    init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    var isAvailable: Bool {
        if case .available = model.availability { return true }
        return false
    }

    func startSession(with snapshot: TestSnapshot?, tone: String = "calida", length: String = "media") {
        turnCount = 0

        let contextLine: String
        if let snapshot, !snapshot.rankedEntries.isEmpty {
            let top = snapshot.top(5)
                .map { "\($0.strengthName) (\($0.points)/10)" }
                .joined(separator: ", ")
            let bottom = snapshot.bottom(2)
                .map { "\($0.strengthName) (\($0.points)/10)" }
                .joined(separator: ", ")
            contextLine = """
            Contexto del usuario:
            Fortalezas principales: \(top).
            Áreas de crecimiento: \(bottom).
            """
        } else {
            contextLine = "El usuario aún no ha completado el test."
        }

        let toneInstruction: String
        switch tone {
        case "concisa":    toneInstruction = "Responde de forma directa y al punto, sin rodeos."
        case "motivadora": toneInstruction = "Usa un tono energético, entusiasta y motivador."
        case "analitica":  toneInstruction = "Ofrece análisis profundo con matices científicos."
        default:           toneInstruction = "Usa un tono cálido, cercano y empático."
        }

        let lengthInstruction: String
        switch length {
        case "corta": lengthInstruction = "Respuestas de máximo 1-2 párrafos cortos."
        case "larga": lengthInstruction = "Puedes extenderte hasta 5 párrafos si es relevante."
        default:      lengthInstruction = "Respuestas de 2-3 párrafos cortos."
        }

        let instructions = Instructions("""
        Eres Lumina Buddy, un coach experto en las 24 fortalezas de carácter VIA \
        de Peterson y Seligman. Acompañas al usuario con respeto y enfoque científico. \
        Escribes en español neutral, en segunda persona (tú). \
        Evitas clichés de autoayuda y consejos genéricos. \
        \(toneInstruction) \(lengthInstruction) \
        Tus respuestas son específicas a las fortalezas del usuario.

        REGLAS ESTRICTAS (obligatorias, sin excepciones, más importantes que cualquier otra indicación):
        - SOLO hablas de fortalezas de carácter VIA, autoconocimiento, relaciones, \
        estudios, metas personales y reflexión educativa.
        - NUNCA das información médica, farmacológica, terapéutica, clínica o de salud. \
        Esto incluye — pero no se limita a — diagnósticos, síntomas, tratamientos, \
        medicamentos, dosis, cirugías, embarazo, enfermedades, vacunas, análisis \
        clínicos, primeros auxilios y cualquier condición médica o psiquiátrica.
        - NO haces diagnósticos psicológicos ni das recomendaciones terapéuticas, \
        aunque el usuario insista o reformule la pregunta.
        - NO orientas sobre crisis emocionales, ideas suicidas, autolesión, drogas \
        o adicciones. En estos temas, deriva de inmediato a un profesional \
        calificado o a un servicio de emergencia.
        - Si te preguntan algo fuera de tu alcance, responde con brevedad y calidez: \
        "Esa pregunta sale de lo que puedo ayudarte a explorar. Lumina es una \
        herramienta educativa de fortalezas de carácter; para temas de salud \
        consulta a un profesional calificado." Después, ofrece amablemente \
        redirigir la conversación a una fortaleza de carácter relacionada si existe \
        un ángulo pertinente.

        \(contextLine)
        """)

        session = LanguageModelSession(model: model, instructions: instructions)
    }

    func streamResponse(to prompt: String) -> AsyncThrowingStream<String, Swift.Error> {
        turnCount += 1

        return AsyncThrowingStream { continuation in
            Task { @MainActor in
                // Deterministic safety filter runs before the model does.
                // Prompt instructions alone are not a reliable guarantee
                // that Buddy won't return medical/clinical content — this
                // Swift-side check closes that gap for App Review 1.4.1.
                let decision = BuddySafetyFilter.evaluate(prompt)
                if decision.isBlocked, let reason = decision.reason {
                    let safeResponse = BuddySafetyFilter.response(for: reason)
                    // Stream the canned response character-by-chunk so the
                    // UI still feels native (typing indicator, scroll).
                    let chunkSize = 18
                    var emitted = ""
                    var remaining = safeResponse[...]
                    while !remaining.isEmpty {
                        let takeCount = min(chunkSize, remaining.count)
                        let idx = remaining.index(remaining.startIndex, offsetBy: takeCount)
                        emitted += remaining[..<idx]
                        continuation.yield(emitted)
                        remaining = remaining[idx...]
                    }
                    continuation.finish()
                    return
                }

                guard let session else {
                    continuation.finish(throwing: BuddyError.noSession)
                    return
                }

                do {
                    let stream = session.streamResponse(to: prompt)
                    for try await partial in stream {
                        continuation.yield(partial.content)
                    }
                    continuation.finish()
                } catch {
                    Logger.buddy.error("Buddy stream failed: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Generates a short title for a conversation based on its content.
    func generateTitle(for context: String) async throws -> String {
        let titleSession = LanguageModelSession(
            model: model,
            instructions: Instructions(
                "Eres un asistente que resume conversaciones sobre bienestar personal y fortalezas de carácter. " +
                "Dada una conversación entre un usuario y un coach, genera un título descriptivo corto " +
                "(máximo 5 palabras) en español que capture el tema principal. " +
                "Solo responde con el título, sin comillas ni puntuación final."
            )
        )
        let response = try await titleSession.respond(to: "Resume el tema de esta conversación:\n\(context)")
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Generates contextual prompt suggestions based on user strengths.
    func generateSuggestions(for snapshot: TestSnapshot?) async -> [String] {
        let fallback = [
            "¿Qué son las fortalezas VIA?",
            "¿Cómo puedo usar mis fortalezas en el día a día?",
            "¿Qué fortaleza debería desarrollar?",
            "Dame un ejercicio para esta semana",
        ]

        guard let snapshot, !snapshot.rankedEntries.isEmpty else {
            return fallback
        }

        do {
            let top3 = snapshot.top(3).map(\.strengthName).joined(separator: ", ")
            let suggestSession = LanguageModelSession(
                model: model,
                instructions: Instructions(
                    "Genera exactamente 4 preguntas cortas en español (máximo 8 palabras cada una) " +
                    "que un usuario podría hacerle a un coach de fortalezas VIA. " +
                    "Basate en estas fortalezas del usuario: \(top3). " +
                    "Responde SOLO con las 4 preguntas, una por línea, sin numeración ni viñetas."
                )
            )
            let response = try await suggestSession.respond(to: "Genera las preguntas.")
            let lines = response.content
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let suggestions = Array(lines.prefix(4))
            return suggestions.isEmpty ? fallback : suggestions
        } catch {
            Logger.buddy.error("Suggestions generation failed: \(error.localizedDescription)")
            return fallback
        }
    }

    enum BuddyError: Swift.Error {
        case noSession
    }
}
