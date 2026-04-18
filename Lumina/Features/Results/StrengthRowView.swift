import SwiftUI

/// A single row in the ranked results list. Shows the rank, icon,
/// strength name, and a visual score bar filled proportional to the
/// score's position in the theoretical range `[2, 10]`.
///
/// Redesign (2026-04-17): Duolingo-style leaderboard look with a
/// virtue-colored icon badge, animated ``LuminaProgressBar`` fill, and
/// numeric-text transition for the score. Fill math preserved verbatim.
struct StrengthRowView: View {
    let rank: Int
    let strength: Strength
    let points: Int

    @State private var animatedFill: Double = 0

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
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(strength.categoryColor.gradient)
                )
                .luminaShadow(Theme.shadowCard)

            VStack(alignment: .leading, spacing: Theme.spacingXS + 2) {
                Text(strength.nameES)
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)

                LuminaProgressBar(progress: animatedFill, tint: strength.categoryColor, height: 8)
            }

            Text("\(points)")
                .font(Theme.numericFont)
                .foregroundStyle(Theme.primaryText)
                .contentTransition(.numericText())
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.vertical, Theme.spacingS + 2)
        .contentShape(Rectangle())
        .onAppear {
            withAnimation(Theme.AnimationStyle.smooth.delay(0.05)) {
                animatedFill = fill
            }
        }
    }
}
