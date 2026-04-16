import Foundation
import SwiftData

/// A persisted chat message within a ``Conversation``.
@Model
final class ChatMessageRecord {
    var id: UUID = UUID()
    var role: String = "user"
    var content: String = ""
    var createdAt: Date = Date()
    var conversation: Conversation?

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.createdAt = Date()
    }
}
