import Foundation
import SwiftData

/// A persisted Buddy chat conversation. Contains an ordered list of
/// messages and an auto-generated title.
@Model
final class Conversation {
    var id: UUID = UUID()
    var title: String = "Nueva conversación"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \ChatMessageRecord.conversation)
    var messages: [ChatMessageRecord] = []

    init(title: String = "Nueva conversación") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Messages sorted chronologically.
    var sortedMessages: [ChatMessageRecord] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }
}
