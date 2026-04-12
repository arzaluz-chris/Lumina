import SwiftUI

/// Elevated card surface used to group related content (question, story,
/// strength detail, chat bubble, etc.).
struct CardContainer<Content: View>: View {
    var padding: CGFloat = Theme.spacingL
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    VStack {
        CardContainer {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Curiosidad")
                    .font(Theme.headlineFont)
                Text("Haces preguntas donde otros dan por hecho las cosas.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
    .padding()
    .background(Theme.background)
}
