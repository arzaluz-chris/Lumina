import SwiftUI

/// A single chat message bubble with role-specific alignment and color.
/// Renders markdown formatting for completed assistant messages.
///
/// Redesign (2026-04-17): assistant bubbles get an asymmetric bottom-left
/// tail corner, user bubbles get an asymmetric bottom-right tail and a
/// gradient fill. Streaming indicator animates with a wave.
struct ChatBubble: View {
    let message: BuddyChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.spacingS) {
            if message.role == .assistant {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    bubble
                        .background(
                            bubbleShape(tail: .bottomLeading)
                                .fill(Theme.cardBackground)
                        )
                        .overlay(
                            bubbleShape(tail: .bottomLeading)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        .foregroundStyle(Theme.primaryText)
                        .luminaShadow(Theme.shadowCard)
                    // Only offer read-aloud once the message has finished
                    // streaming — partial tokens make the voice stutter
                    // and mispronounce truncated words.
                    if !message.isStreaming && !message.content.isEmpty {
                        ReadAloudButton(text: message.content, size: .small)
                            .padding(.leading, Theme.spacingS)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Buddy dice: \(message.content)")
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
                    .background(
                        bubbleShape(tail: .bottomTrailing)
                            .fill(Theme.accentGradient)
                    )
                    .foregroundStyle(.white)
                    .luminaShadow(Theme.shadowCard)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Tú dijiste: \(message.content)")
            }
        }
    }

    private func bubbleShape(tail: UnitPoint) -> some Shape {
        let big = Theme.cardRadius
        let small: CGFloat = 8
        return UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: big,
                bottomLeading: tail == .bottomLeading ? small : big,
                bottomTrailing: tail == .bottomTrailing ? small : big,
                topTrailing: big
            ),
            style: .continuous
        )
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
                StreamingDotsIndicator()
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

/// Three dots that bounce in a wave to indicate streaming.
private struct StreamingDotsIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .frame(width: 6, height: 6)
                    .opacity(phase == i ? 0.95 : 0.35)
                    .scaleEffect(phase == i ? 1.15 : 1.0)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: phase)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000)
                await MainActor.run { phase = (phase + 1) % 3 }
            }
        }
    }
}
