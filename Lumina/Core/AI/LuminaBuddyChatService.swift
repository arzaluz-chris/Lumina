import Foundation
import FoundationModels

/// Conversational wrapper around Foundation Models for the Lumina Buddy
/// chat tab.
///
/// Unlike ``FoundationModelsInsightsProvider`` — which generates a
/// one-shot structured result — this service holds a persistent
/// `LanguageModelSession` so the model remembers the conversation and
/// can reference earlier turns naturally.
///
/// The session is seeded with (a) the Lumina coach persona and
/// (b) the user's top and bottom strengths, so the buddy can speak in
/// the user's specific language without having to be reminded each turn.
@MainActor
final class LuminaBuddyChatService {
    private var session: LanguageModelSession?
    private let model: SystemLanguageModel

    init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    /// Whether the underlying on-device model is available right now.
    var isAvailable: Bool {
        if case .available = model.availability { return true }
        return false
    }

    /// Starts a brand-new session with the user's current strength context.
    /// Call after a new test result is saved to make the buddy aware of
    /// the latest ranking.
    func startSession(with snapshot: TestSnapshot?) {
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

        let instructions = Instructions("""
        Eres Lumina Buddy, un coach experto en las 24 fortalezas de carácter VIA \
        de Peterson y Seligman. Acompañas al usuario con calidez, respeto y enfoque \
        científico. Escribes en español neutral, en segunda persona (tú), con tono \
        cercano pero profesional. Evitas clichés de autoayuda y consejos genéricos. \
        Tus respuestas son breves (máximo 3 párrafos cortos) y específicas a las \
        fortalezas del usuario. No haces diagnósticos psicológicos.

        \(contextLine)
        """)

        session = LanguageModelSession(model: model, instructions: instructions)
    }

    /// Streams a response to `prompt`, yielding progressively longer
    /// accumulated strings as the model generates tokens.
    ///
    /// The view observes this stream and re-renders the last bubble on
    /// each update. Throws if the session hasn't been started or the
    /// model errors out.
    func streamResponse(to prompt: String) -> AsyncThrowingStream<String, Swift.Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
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
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    enum BuddyError: Swift.Error {
        case noSession
    }
}
