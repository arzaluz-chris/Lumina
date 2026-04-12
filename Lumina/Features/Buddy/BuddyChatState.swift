import Foundation
import Observation
import FoundationModels
import os

/// Chat-tab view state backed by `LuminaBuddyChatService`.
@MainActor
@Observable
final class BuddyChatState {
    var messages: [BuddyChatMessage] = []
    var input: String = ""
    var isThinking: Bool = false
    var errorMessage: String?

    private let service: LuminaBuddyChatService
    private var hasStarted: Bool = false
    private var messageCount: Int = 0

    init() {
        self.service = LuminaBuddyChatService()
        Logger.buddy.info("BuddyChatState initialized (default service)")
    }

    init(service: LuminaBuddyChatService) {
        self.service = service
        Logger.buddy.info("BuddyChatState initialized (injected service)")
    }

    var isAvailable: Bool { service.isAvailable }

    func start(with snapshot: TestSnapshot?, force: Bool = false) {
        if !force && hasStarted {
            Logger.buddy.debug("start() skipped — already started (force=false)")
            return
        }
        Logger.buddy.info("BuddyChatState.start(force: \(force), hasSnapshot: \(snapshot != nil))")
        service.startSession(with: snapshot)
        hasStarted = true
        messageCount = 0
        messages.removeAll()
        let greeting = snapshot == nil
            ? "Hola, soy Lumina Buddy. ¿En qué te ayudo hoy?"
            : "Hola, soy Lumina Buddy. Ya conozco tus fortalezas — pregúntame lo que quieras sobre ellas."
        messages.append(BuddyChatMessage(role: .assistant, content: greeting))
        Logger.buddy.info("Chat session started, greeting appended")
    }

    func send() async {
        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isThinking else {
            Logger.buddy.debug("send() skipped — empty prompt or already thinking")
            return
        }
        messageCount += 1
        let msgNum = messageCount
        Logger.buddy.info("=== USER MESSAGE #\(msgNum) ===")
        Logger.buddy.debug("Prompt (\(prompt.count) chars): \(prompt)")

        input = ""
        errorMessage = nil

        messages.append(BuddyChatMessage(role: .user, content: prompt))
        let assistantMessage = BuddyChatMessage(role: .assistant, content: "", isStreaming: true)
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1

        isThinking = true
        defer { isThinking = false }

        let startTime = CFAbsoluteTimeGetCurrent()
        do {
            Logger.buddy.debug("Starting stream for message #\(msgNum)...")
            let stream = service.streamResponse(to: prompt)
            var chunkCount = 0
            for try await partial in stream {
                chunkCount += 1
                if messages.indices.contains(assistantIndex) {
                    messages[assistantIndex].content = partial
                }
            }
            if messages.indices.contains(assistantIndex) {
                messages[assistantIndex].isStreaming = false
            }
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            let finalLength = messages[assistantIndex].content.count
            Logger.buddy.info("=== ASSISTANT REPLY #\(msgNum) COMPLETE ===")
            Logger.buddy.info("Chunks: \(chunkCount), chars: \(finalLength), time: \(elapsed, format: .fixed(precision: 2)) sec")
            Logger.buddy.debug("Reply preview: \(String(self.messages[assistantIndex].content.prefix(100)))...")
        } catch {
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            Logger.buddy.error("=== ASSISTANT REPLY #\(msgNum) FAILED (\(elapsed, format: .fixed(precision: 2)) sec) ===")
            Logger.buddy.error("Error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            if messages.indices.contains(assistantIndex) {
                messages[assistantIndex].content = "No pude generar una respuesta. Inténtalo de nuevo."
                messages[assistantIndex].isStreaming = false
            }
        }
    }
}
