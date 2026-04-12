import Foundation

/// A single message in a Lumina Buddy chat session.
///
/// Ephemeral — chat history does not currently persist across app
/// launches. The session is reset each time the Buddy tab is opened so
/// the model always gets fresh strength context via its instructions.
struct BuddyChatMessage: Identifiable, Equatable {
    enum Role: Equatable {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    var content: String
    var isStreaming: Bool = false
}
