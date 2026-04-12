import SwiftUI

/// The five Likert response buttons used for every question.
///
/// Uses progressively stronger accent tint from "Nada" (1) to "Totalmente"
/// (5) so the user gets a visual hint of the scale even without reading
/// the labels. Each button has an explicit accessibility label for
/// VoiceOver users.
struct LikertScaleView: View {
    let onSelect: (Int) -> Void

    private struct Option {
        let points: Int
        let labelES: String
    }

    private let options: [Option] = [
        Option(points: 1, labelES: "Nada"),
        Option(points: 2, labelES: "Poco"),
        Option(points: 3, labelES: "Neutral"),
        Option(points: 4, labelES: "Bastante"),
        Option(points: 5, labelES: "Totalmente"),
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(options, id: \.points) { option in
                Button {
                    onSelect(option.points)
                } label: {
                    HStack {
                        Text(option.labelES)
                            .font(Theme.bodyFont.weight(.medium))
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, Theme.spacingL)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                            .fill(Theme.accent.opacity(0.06 + 0.06 * Double(option.points)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                            .stroke(Theme.accent.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Respuesta \(option.points) de 5: \(option.labelES)")
                .sensoryFeedback(.selection, trigger: option.points)
            }
        }
    }
}

#Preview {
    LikertScaleView { _ in }
        .padding()
        .background(Theme.background)
}
