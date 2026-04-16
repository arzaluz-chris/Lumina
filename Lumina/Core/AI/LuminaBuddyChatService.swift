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
        Logger.buddy.info("LuminaBuddyChatService initialized")
        Logger.buddy.debug("Model availability: \(String(describing: model.availability))")
    }

    var isAvailable: Bool {
        let available = model.availability
        if case .available = available {
            Logger.buddy.debug("Buddy availability check: AVAILABLE")
            return true
        }
        Logger.buddy.info("Buddy availability check: NOT AVAILABLE (\(String(describing: available)))")
        return false
    }

    func startSession(with snapshot: TestSnapshot?, tone: String = "calida", length: String = "media") {
        Logger.buddy.info("=== BUDDY SESSION START (tone: \(tone), length: \(length)) ===")
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
            Logger.buddy.info("Session seeded with user strengths — top: \(top)")
            Logger.buddy.debug("Growth areas: \(bottom)")
        } else {
            contextLine = "El usuario aún no ha completado el test."
            Logger.buddy.info("Session started WITHOUT test results (user hasn't completed quiz)")
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
        Tus respuestas son específicas a las fortalezas del usuario. \
        No haces diagnósticos psicológicos.

        \(contextLine)
        """)

        session = LanguageModelSession(model: model, instructions: instructions)
        Logger.buddy.info("LanguageModelSession created successfully")
        Logger.buddy.debug("Instructions length: \(String(describing: instructions).count) chars")
    }

    func streamResponse(to prompt: String) -> AsyncThrowingStream<String, Swift.Error> {
        turnCount += 1
        let currentTurn = turnCount
        Logger.buddy.info("=== BUDDY STREAM START (turn \(currentTurn)) ===")
        Logger.buddy.debug("User prompt (\(prompt.count) chars): \(prompt)")

        return AsyncThrowingStream { continuation in
            Task { @MainActor in
                guard let session else {
                    Logger.buddy.error("STREAM FAILED: no session — call startSession() first")
                    continuation.finish(throwing: BuddyError.noSession)
                    return
                }

                let startTime = CFAbsoluteTimeGetCurrent()
                var tokenCount = 0
                var lastContent = ""

                do {
                    Logger.buddy.debug("Calling session.streamResponse(to:)...")
                    let stream = session.streamResponse(to: prompt)
                    for try await partial in stream {
                        tokenCount += 1
                        lastContent = partial.content
                        continuation.yield(partial.content)
                        if tokenCount == 1 {
                            let ttft = CFAbsoluteTimeGetCurrent() - startTime
                            Logger.buddy.info("First token received after \(ttft, format: .fixed(precision: 2)) seconds")
                        }
                        if tokenCount % 20 == 0 {
                            Logger.buddy.debug("Streaming... \(tokenCount) chunks, \(lastContent.count) chars so far")
                        }
                    }
                    let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                    Logger.buddy.info("=== BUDDY STREAM COMPLETE (turn \(currentTurn)) ===")
                    Logger.buddy.info("Total: \(tokenCount) chunks, \(lastContent.count) chars, \(elapsed, format: .fixed(precision: 2)) seconds")
                    Logger.buddy.debug("Response preview: \(String(lastContent.prefix(120)))...")
                    continuation.finish()
                } catch {
                    let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                    Logger.buddy.error("=== BUDDY STREAM FAILED (turn \(currentTurn), \(elapsed, format: .fixed(precision: 2)) seconds) ===")
                    Logger.buddy.error("Error: \(error.localizedDescription)")
                    Logger.buddy.error("Tokens received before failure: \(tokenCount)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Generates a short title for a conversation based on its content.
    func generateTitle(for context: String) async throws -> String {
        Logger.buddy.info("Generating conversation title...")
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
        let title = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        Logger.buddy.info("Generated title: \(title)")
        return title
    }

    /// Generates contextual prompt suggestions based on user strengths.
    func generateSuggestions(for snapshot: TestSnapshot?) async -> [String] {
        Logger.buddy.info("Generating smart suggestions...")
        let fallback = [
            "¿Qué son las fortalezas VIA?",
            "¿Cómo puedo usar mis fortalezas en el día a día?",
            "¿Qué fortaleza debería desarrollar?",
            "Dame un ejercicio para esta semana",
        ]

        guard let snapshot, !snapshot.rankedEntries.isEmpty else {
            Logger.buddy.debug("No snapshot available — returning static suggestions")
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
            Logger.buddy.info("Generated \(suggestions.count) suggestions")
            return suggestions.isEmpty ? fallback : suggestions
        } catch {
            Logger.buddy.error("Failed to generate suggestions: \(error.localizedDescription)")
            return fallback
        }
    }

    enum BuddyError: Swift.Error {
        case noSession
    }
}
