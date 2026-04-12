import SwiftUI

/// A single chat message bubble with role-specific alignment and color.
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
            Text(message.content.isEmpty ? " " : message.content)
                .font(Theme.bodyFont)
                .fixedSize(horizontal: false, vertical: true)
            if message.isStreaming && !message.content.isEmpty {
                HStack(spacing: 4) {
                    ForEach(0..<3) { _ in
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
}
