import Foundation
import SwiftData
import Observation
import FoundationModels
import os

/// Chat-tab view state backed by `LuminaBuddyChatService`.
/// Manages conversation persistence, auto-rename, and smart suggestions.
@MainActor
@Observable
final class BuddyChatState {
    var messages: [BuddyChatMessage] = []
    var input: String = ""
    var isThinking: Bool = false
    var errorMessage: String?
    var suggestions: [String] = []
    var streamingChunkCount: Int = 0
    var currentConversation: Conversation?

    private let service: LuminaBuddyChatService
    private var hasStarted: Bool = false
    private var messageCount: Int = 0
    private var modelContext: ModelContext?

    init() {
        self.service = LuminaBuddyChatService()
        Logger.buddy.info("BuddyChatState initialized (default service)")
    }

    init(service: LuminaBuddyChatService) {
        self.service = service
        Logger.buddy.info("BuddyChatState initialized (injected service)")
    }

    var isAvailable: Bool { service.isAvailable }

    /// Configure the model context for persistence. Call once from the view.
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func start(with snapshot: TestSnapshot?, force: Bool = false) {
        if !force && hasStarted {
            Logger.buddy.debug("start() skipped — already started (force=false)")
            return
        }
        Logger.buddy.info("BuddyChatState.start(force: \(force), hasSnapshot: \(snapshot != nil))")
        let tone = UserDefaults.standard.string(forKey: "aiTone") ?? "calida"
        let length = UserDefaults.standard.string(forKey: "aiLength") ?? "media"
        service.startSession(with: snapshot, tone: tone, length: length)
        hasStarted = true
        messageCount = 0

        // If there's an existing conversation loaded, keep it
        if currentConversation == nil {
            startNewConversation()
        }

        if messages.isEmpty {
            let greeting = snapshot == nil
                ? "Hola, soy Lumina Buddy. ¿En qué te ayudo hoy?"
                : "Hola, soy Lumina Buddy. Ya conozco tus fortalezas — pregúntame lo que quieras sobre ellas."
            messages.append(BuddyChatMessage(role: .assistant, content: greeting))
        }
        Logger.buddy.info("Chat session started, greeting appended")

        // Generate smart suggestions
        Task {
            suggestions = await service.generateSuggestions(for: snapshot)
        }
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
        suggestions = [] // hide suggestions after first message

        messages.append(BuddyChatMessage(role: .user, content: prompt))
        let assistantMessage = BuddyChatMessage(role: .assistant, content: "", isStreaming: true)
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1

        isThinking = true
        streamingChunkCount = 0
        defer { isThinking = false }

        let startTime = CFAbsoluteTimeGetCurrent()
        do {
            Logger.buddy.debug("Starting stream for message #\(msgNum)...")
            let stream = service.streamResponse(to: prompt)
            var chunkCount = 0
            for try await partial in stream {
                chunkCount += 1
                streamingChunkCount += 1
                if messages.indices.contains(assistantIndex) {
                    messages[assistantIndex].content = partial
                }
            }
            if messages.indices.contains(assistantIndex) {
                messages[assistantIndex].isStreaming = false
            }
            streamingChunkCount = 0
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            let finalLength = messages[assistantIndex].content.count
            Logger.buddy.info("=== ASSISTANT REPLY #\(msgNum) COMPLETE ===")
            Logger.buddy.info("Chunks: \(chunkCount), chars: \(finalLength), time: \(elapsed, format: .fixed(precision: 2)) sec")
            Logger.buddy.debug("Reply preview: \(String(self.messages[assistantIndex].content.prefix(100)))...")

            // Persist messages
            persistMessage(role: "user", content: prompt)
            persistMessage(role: "assistant", content: messages[assistantIndex].content)

            // Auto-rename after enough messages
            await autoRenameIfNeeded()
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

    /// Start a new conversation, resetting the UI.
    func startNewConversation() {
        let conversation = Conversation()
        modelContext?.insert(conversation)
        try? modelContext?.save()
        currentConversation = conversation
        messages.removeAll()
        messageCount = 0
        Logger.conversations.info("New conversation created: \(conversation.id)")
    }

    /// Load a past conversation into the chat.
    func loadConversation(_ conversation: Conversation) {
        currentConversation = conversation
        messages = conversation.sortedMessages.map { record in
            BuddyChatMessage(
                role: record.role == "assistant" ? .assistant : .user,
                content: record.content
            )
        }
        messageCount = messages.filter { $0.role == .user }.count
        suggestions = []

        // Restart the service session so it has context
        service.startSession(with: nil)
        let msgCount = self.messages.count
        Logger.conversations.info("Loaded conversation '\(conversation.title)' with \(msgCount) messages")
    }

    // MARK: - Private

    private func persistMessage(role: String, content: String) {
        guard let conversation = currentConversation, let ctx = modelContext else { return }
        let record = ChatMessageRecord(role: role, content: content)
        record.conversation = conversation
        conversation.messages.append(record)
        conversation.updatedAt = Date()
        try? ctx.save()
        Logger.conversations.debug("Persisted \(role) message (\(content.count) chars)")
    }

    private func autoRenameIfNeeded() async {
        guard let conversation = currentConversation,
              conversation.title == "Nueva conversación",
              messageCount >= 2 else { return }

        let context = messages.prefix(6)
            .map { "\($0.role == .user ? "Usuario" : "Buddy"): \($0.content)" }
            .joined(separator: "\n")

        do {
            let title = try await service.generateTitle(for: context)
            conversation.title = title
            try? modelContext?.save()
            Logger.conversations.info("Auto-renamed conversation to: \(title)")
        } catch {
            Logger.conversations.error("Auto-rename AI failed: \(error.localizedDescription)")
            // Fallback: use the first user message truncated as title
            if let firstUserMsg = messages.first(where: { $0.role == .user }) {
                let fallback = String(firstUserMsg.content.prefix(40))
                conversation.title = fallback.count < firstUserMsg.content.count ? fallback + "…" : fallback
                try? modelContext?.save()
                Logger.conversations.info("Auto-renamed with fallback: \(conversation.title)")
            }
        }
    }
}
