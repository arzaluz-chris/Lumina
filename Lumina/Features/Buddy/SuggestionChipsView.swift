import SwiftUI

/// Horizontally scrolling chips showing AI-generated prompt suggestions.
/// Tapping a chip fills the input and sends the message.
struct SuggestionChipsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        onSelect(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, Theme.spacingM)
                            .padding(.vertical, Theme.spacingS)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                                    .fill(Theme.accent.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                                    .stroke(Theme.accent.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.spacingL)
        }
        .sensoryFeedback(.selection, trigger: suggestions.count)
    }
}
