import SwiftUI

/// Detail screen for a single strength. Shows its icon, description,
/// the user's score, and the two questions that contributed to it.
///
/// Redesign (2026-04-17): full-color hero band with large icon, score
/// card with gradient-tinted numeric badge and progress bar, questions
/// laid out as individual mini-cards.
struct StrengthDetailView: View {
    let strength: Strength
    let points: Int

    @State private var animatedFill: Double = 0

    private var fill: Double {
        let minScore = Double(QuestionsCatalog.minScorePerStrength)
        let maxScore = Double(QuestionsCatalog.maxScorePerStrength)
        return max(0, min(1, (Double(points) - minScore) / (maxScore - minScore)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                heroBand

                scoreCard

                questionsCard
            }
            .padding(.horizontal, Theme.spacingL)
            .padding(.top, Theme.spacingM)
            .padding(.bottom, Theme.spacingL)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(strength.nameES)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(Theme.AnimationStyle.smooth.delay(0.1)) {
                animatedFill = fill
            }
        }
    }

    // MARK: - Hero band

    private var heroBand: some View {
        let color = strength.categoryColor
        return VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack(alignment: .center, spacing: Theme.spacingL) {
                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(color.gradient)
                        .frame(width: 96, height: 96)
                        .luminaShadow(Theme.shadowElevated)
                    Image(systemName: strength.iconSF)
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(Theme.virtueCategory(for: strength.id).nameES)
                        .font(Theme.captionFont.weight(.heavy))
                        .foregroundStyle(color)
                        .textCase(.uppercase)
                    Text(strength.nameES)
                        .font(Theme.heroFont)
                        .foregroundStyle(Theme.primaryText)
                    Text("Fortaleza VIA")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
            }
        }
    }

    // MARK: - Score card

    private var scoreCard: some View {
        let color = strength.categoryColor
        return CardContainer {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Text("Tu puntaje")
                    .font(Theme.captionFont.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .textCase(.uppercase)

                HStack(alignment: .firstTextBaseline, spacing: Theme.spacingXS) {
                    Text("\(points)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(color)
                        .contentTransition(.numericText())
                    Text("/ \(QuestionsCatalog.maxScorePerStrength)")
                        .font(Theme.subheadFont)
                        .foregroundStyle(Theme.secondaryText)
                }

                LuminaProgressBar(progress: animatedFill, tint: color, height: 10)
            }
        }
    }

    // MARK: - Questions card

    private var questionsCard: some View {
        CardContainer(padding: Theme.spacingM) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                LuminaSectionHeader(
                    title: "Las preguntas de esta fortaleza",
                    subtitle: "Las que sumaron a tu puntaje",
                    systemImage: "text.alignleft",
                    iconTint: strength.categoryColor
                )

                VStack(spacing: Theme.spacingS) {
                    ForEach(relatedQuestions) { question in
                        HStack(alignment: .top, spacing: Theme.spacingM) {
                            Image(systemName: "quote.opening")
                                .foregroundStyle(strength.categoryColor)
                            Text(question.textES)
                                .font(Theme.bodyFont)
                                .foregroundStyle(Theme.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(Theme.spacingM)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.chipRadius + 2, style: .continuous)
                                .fill(strength.categoryColor.opacity(0.08))
                        )
                    }
                }
            }
        }
    }

    private var relatedQuestions: [Question] {
        QuestionsCatalog.all.filter { $0.strengthID == strength.id }
    }
}
