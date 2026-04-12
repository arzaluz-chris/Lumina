import SwiftUI

/// A single row in the ranked results list. Shows the rank, icon,
/// strength name, and a visual score bar filled proportional to the
/// score's position in the theoretical range `[2, 10]`.
struct StrengthRowView: View {
    let rank: Int
    let strength: Strength
    let points: Int

    /// Score normalized to `[0, 1]` for the progress bar.
    private var fill: Double {
        let minScore = Double(QuestionsCatalog.minScorePerStrength)
        let maxScore = Double(QuestionsCatalog.maxScorePerStrength)
        let normalized = (Double(points) - minScore) / (maxScore - minScore)
        return max(0, min(1, normalized))
    }

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Text("\(rank)")
                .font(Theme.subheadFont.monospacedDigit())
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 28, alignment: .trailing)

            Image(systemName: strength.iconSF)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text(strength.nameES)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.accent.opacity(0.12))
                        Capsule()
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * fill)
                    }
                }
                .frame(height: 6)
            }

            Text("\(points)")
                .font(Theme.subheadFont.monospacedDigit())
                .foregroundStyle(Theme.primaryText)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.vertical, Theme.spacingS)
        .contentShape(Rectangle())
    }
}
