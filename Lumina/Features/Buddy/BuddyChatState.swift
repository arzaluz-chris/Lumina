import Foundation
import Observation
import FoundationModels

/// Chat-tab view state backed by `LuminaBuddyChatService`.
///
/// Owns the message list, the input draft, and the "thinking" flag.
/// Starts a fresh session with the user's current strength snapshot on
/// first load so the buddy always has context.
@MainActor
@Observable
final class BuddyChatState {
    var messages: [BuddyChatMessage] = []
    var input: String = ""
    var isThinking: Bool = false
    var errorMessage: String?

    private let service: LuminaBuddyChatService
    private var hasStarted: Bool = false

    init() {
        self.service = LuminaBuddyChatService()
    }

    init(service: LuminaBuddyChatService) {
        self.service = service
    }

    /// True when the underlying model is usable on this device.
    var isAvailable: Bool { service.isAvailable }

    /// Seeds a new session with the user's strength snapshot. Safe to
    /// call repeatedly — subsequent calls are no-ops unless `force` is
    /// set (e.g. after a new test result is saved).
    func start(with snapshot: TestSnapshot?, force: Bool = false) {
        guard force || !hasStarted else { return }
        service.startSession(with: snapshot)
        hasStarted = true
        messages.removeAll()
        messages.append(
            BuddyChatMessage(
                role: .assistant,
                content: snapshot == nil
                    ? "Hola, soy Lumina Buddy. ¿En qué te ayudo hoy?"
                    : "Hola, soy Lumina Buddy. Ya conozco tus fortalezas — pregúntame lo que quieras sobre ellas."
            )
        )
    }

    /// Sends the current draft to the model and streams the reply into
    /// a new assistant message. Clears the draft before awaiting.
    func send() async {
        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isThinking else { return }
        input = ""
        errorMessage = nil

        messages.append(BuddyChatMessage(role: .user, content: prompt))
        let assistantMessage = BuddyChatMessage(role: .assistant, content: "", isStreaming: true)
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1

        isThinking = true
        defer { isThinking = false }

        do {
            let stream = service.streamResponse(to: prompt)
            for try await partial in stream {
                if messages.indices.contains(assistantIndex) {
                    messages[assistantIndex].content = partial
                }
            }
            if messages.indices.contains(assistantIndex) {
                messages[assistantIndex].isStreaming = false
            }
        } catch {
            errorMessage = error.localizedDescription
            if messages.indices.contains(assistantIndex) {
                messages[assistantIndex].content = "No pude generar una respuesta. Inténtalo de nuevo."
                messages[assistantIndex].isStreaming = false
            }
        }
    }
}
