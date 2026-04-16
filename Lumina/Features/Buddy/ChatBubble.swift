import SwiftUI

/// A single chat message bubble with role-specific alignment and color.
/// Renders markdown formatting for completed assistant messages.
struct ChatBubble: View {
    let message: BuddyChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.spacingS) {
            if message.role == .assistant {
                bubble
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .fill(Theme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .foregroundStyle(Theme.primaryText)
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .fill(Theme.accent)
                    )
                    .foregroundStyle(.white)
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            if message.content.isEmpty {
                Text(" ")
                    .font(Theme.bodyFont)
            } else if message.isStreaming {
                Text(sanitizedMarkdown(message.content))
                    .font(Theme.bodyFont)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // Parsed markdown for completed messages
                Text(markdownContent)
                    .font(Theme.bodyFont)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if message.isStreaming && !message.content.isEmpty {
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Circle()
                            .frame(width: 5, height: 5)
                            .opacity(0.4)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS + 2)
    }

    /// Sanitizes incomplete markdown for safe rendering during streaming.
    /// Counts `**` and `*` markers — if any are unclosed, appends a
    /// closing marker so AttributedString doesn't choke on partial markup.
    private func sanitizedMarkdown(_ text: String) -> AttributedString {
        var sanitized = text
        let boldCount = sanitized.components(separatedBy: "**").count - 1
        if boldCount % 2 != 0 {
            sanitized += "**"
        }
        let withoutBold = sanitized.replacingOccurrences(of: "**", with: "")
        let italicCount = withoutBold.filter { $0 == "*" }.count
        if italicCount % 2 != 0 {
            sanitized += "*"
        }
        return (try? AttributedString(
            markdown: sanitized,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }

    /// Converts the message content from markdown to an `AttributedString`.
    /// Falls back to plain text if parsing fails.
    private var markdownContent: AttributedString {
        (try? AttributedString(
            markdown: message.content,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(message.content)
    }
}
