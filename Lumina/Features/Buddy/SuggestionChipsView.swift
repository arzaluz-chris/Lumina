import SwiftUI

/// Horizontally scrolling chips showing AI-generated prompt suggestions.
/// Tapping a chip fills the input and sends the message.
///
/// Redesign (2026-04-17): delegates styling to the shared ``LuminaChip``
/// component for visual consistency with the rest of the app.
struct SuggestionChipsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                ForEach(suggestions, id: \.self) { suggestion in
                    LuminaChip(
                        title: suggestion,
                        systemImage: "sparkles",
                        style: .accent,
                        action: { onSelect(suggestion) }
                    )
                }
            }
            .padding(.horizontal, Theme.spacingL)
        }
        .sensoryFeedback(.selection, trigger: suggestions.count)
    }
}
