import Foundation
import SwiftData
import Observation
import FoundationModels
import os

/// Chat-tab view state backed by `LuminaBuddyChatService`.
/// Manages conversation persistence, auto-rename, and smart suggestions.
///
/// Persistence model (ChatGPT-style): a `Conversation` is only inserted
/// into SwiftData after the user sends the first message. Until then it
/// lives in memory as a draft. This prevents the history from filling
/// with empty "Nueva conversación" rows every time Buddy is opened.
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
    /// True when `currentConversation` has not been inserted into the
    /// model context yet (i.e., it's a fresh draft with no messages).
    /// Flips to false the first time a message gets persisted.
    private var currentIsDraft: Bool = false

    init() {
        self.service = LuminaBuddyChatService()
    }

    init(service: LuminaBuddyChatService) {
        self.service = service
    }

    var isAvailable: Bool { service.isAvailable }

    /// Configure the model context for persistence. Call once from the view.
    /// Also sweeps any lingering empty conversations (defensive cleanup —
    /// older app versions could create them on every tab open).
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        cleanupEmptyConversations()
    }

    func start(with snapshot: TestSnapshot?, force: Bool = false) {
        if !force && hasStarted { return }
        let tone = UserDefaults.standard.string(forKey: "aiTone") ?? "calida"
        let length = UserDefaults.standard.string(forKey: "aiLength") ?? "media"
        service.startSession(with: snapshot, tone: tone, length: length)
        hasStarted = true
        messageCount = 0

        // If there's an existing conversation loaded, keep it. Otherwise
        // create a fresh draft — not yet persisted.
        if currentConversation == nil {
            startNewConversation()
        }

        if messages.isEmpty {
            let greeting = snapshot == nil
                ? "Hola, soy Lumina Buddy. ¿En qué te ayudo hoy?"
                : "Hola, soy Lumina Buddy. Ya conozco tus fortalezas — pregúntame lo que quieras sobre ellas."
            messages.append(BuddyChatMessage(role: .assistant, content: greeting))
        }

        // Generate smart suggestions
        Task {
            suggestions = await service.generateSuggestions(for: snapshot)
        }
    }

    func send() async {
        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isThinking else { return }
        messageCount += 1

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

        do {
            let stream = service.streamResponse(to: prompt)
            for try await partial in stream {
                streamingChunkCount += 1
                if messages.indices.contains(assistantIndex) {
                    messages[assistantIndex].content = partial
                }
            }
            if messages.indices.contains(assistantIndex) {
                messages[assistantIndex].isStreaming = false
            }
            streamingChunkCount = 0

            // Persist messages (inserts the draft conversation on first call).
            persistMessage(role: "user", content: prompt)
            persistMessage(role: "assistant", content: messages[assistantIndex].content)

            // Auto-rename after the first complete exchange.
            await autoRenameIfNeeded()
        } catch {
            Logger.buddy.error("Chat reply failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            if messages.indices.contains(assistantIndex) {
                messages[assistantIndex].content = "No pude generar una respuesta. Inténtalo de nuevo."
                messages[assistantIndex].isStreaming = false
            }
        }
    }

    /// Start a new conversation, resetting the UI. The new `Conversation`
    /// is held in memory and is NOT inserted into SwiftData until the
    /// first message is persisted. This matches the ChatGPT/Claude model
    /// where a draft chat has no sidebar entry until you send something.
    func startNewConversation() {
        currentConversation = Conversation()
        currentIsDraft = true
        messages.removeAll()
        messageCount = 0
    }

    /// Resets the chat to a fresh draft if the deleted conversation was
    /// the one currently loaded. Call this after a deletion in the history
    /// sheet so the UI doesn't keep showing messages from a conversation
    /// that no longer exists in the store.
    func handleDeletedConversation(_ deleted: Conversation) {
        guard let current = currentConversation, current.id == deleted.id else { return }
        startNewConversation()
        let greeting = "Hola, soy Lumina Buddy. ¿En qué te ayudo hoy?"
        messages.append(BuddyChatMessage(role: .assistant, content: greeting))
    }

    /// Load a past conversation into the chat.
    func loadConversation(_ conversation: Conversation) {
        currentConversation = conversation
        currentIsDraft = false
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
    }

    // MARK: - Private

    private func persistMessage(role: String, content: String) {
        guard let conversation = currentConversation, let ctx = modelContext else { return }
        // Promote draft → persisted on the first message.
        if currentIsDraft {
            ctx.insert(conversation)
            currentIsDraft = false
        }
        let record = ChatMessageRecord(role: role, content: content)
        record.conversation = conversation
        conversation.messages.append(record)
        conversation.updatedAt = Date()
        try? ctx.save()
    }

    /// Auto-rename the conversation after the first full user+assistant
    /// exchange — matches the behavior users expect from ChatGPT/Claude.
    /// No-op if the user has already renamed it or a prior rename succeeded
    /// (we only touch the default "Nueva conversación" placeholder).
    private func autoRenameIfNeeded() async {
        guard let conversation = currentConversation,
              conversation.title == "Nueva conversación",
              messageCount >= 1 else { return }

        let context = messages.prefix(6)
            .map { "\($0.role == .user ? "Usuario" : "Buddy"): \($0.content)" }
            .joined(separator: "\n")

        do {
            let raw = try await service.generateTitle(for: context)
            let sanitized = Self.sanitizeTitle(raw)
            guard !sanitized.isEmpty else {
                throw LuminaBuddyChatService.BuddyError.noSession
            }
            conversation.title = sanitized
            try? modelContext?.save()
        } catch {
            // Fallback: truncate the first user message.
            if let firstUserMsg = messages.first(where: { $0.role == .user }) {
                let fallback = Self.sanitizeTitle(firstUserMsg.content)
                conversation.title = fallback.isEmpty ? "Conversación" : fallback
                try? modelContext?.save()
            }
        }
    }

    /// Deletes any `Conversation` rows that have no messages. Fixes the
    /// legacy bug where every tab open persisted a fresh empty conversation,
    /// and acts as a safety net for any future code path that might leak one.
    /// The in-memory draft is not affected because it hasn't been inserted.
    private func cleanupEmptyConversations() {
        guard let ctx = modelContext else { return }
        let descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate { $0.messages.isEmpty }
        )
        guard let empties = try? ctx.fetch(descriptor), !empties.isEmpty else { return }
        for conv in empties {
            ctx.delete(conv)
        }
        try? ctx.save()
    }

    /// Normalizes a model-generated (or fallback) title: trims whitespace,
    /// strips enclosing quotes and trailing sentence punctuation, caps at
    /// 40 characters with an ellipsis if longer.
    private static func sanitizeTitle(_ input: String) -> String {
        var t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        // Keep only the first line (the model occasionally adds commentary).
        t = t.components(separatedBy: .newlines).first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? t
        // Strip enclosing quotes (straight, curly, guillemets).
        let quotes: Set<Character> = ["\"", "'", "\u{201C}", "\u{201D}", "\u{2018}", "\u{2019}", "«", "»"]
        while let first = t.first, quotes.contains(first) { t.removeFirst() }
        while let last = t.last, quotes.contains(last) { t.removeLast() }
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip trailing sentence punctuation.
        while let last = t.last, ".!?:;,".contains(last) { t.removeLast() }
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        // Cap length at 40 characters.
        if t.count > 40 {
            let idx = t.index(t.startIndex, offsetBy: 40)
            t = String(t[..<idx]).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
        }
        return t
    }
}
