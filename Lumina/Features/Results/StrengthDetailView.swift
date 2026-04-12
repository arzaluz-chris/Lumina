import SwiftUI

/// Detail screen for a single strength. Shows its icon, description,
/// the user's score, and the two questions that contributed to it.
struct StrengthDetailView: View {
    let strength: Strength
    let points: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                header

                CardContainer {
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Tu puntaje")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.secondaryText)
                        HStack(alignment: .firstTextBaseline, spacing: Theme.spacingXS) {
                            Text("\(points)")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(Theme.accent)
                            Text("/ \(QuestionsCatalog.maxScorePerStrength)")
                                .font(Theme.subheadFont)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }

                CardContainer {
                    VStack(alignment: .leading, spacing: Theme.spacingM) {
                        Text("Las preguntas de esta fortaleza")
                            .font(Theme.subheadFont)
                        Divider()
                        ForEach(relatedQuestions) { question in
                            HStack(alignment: .top, spacing: Theme.spacingM) {
                                Image(systemName: "quote.opening")
                                    .foregroundStyle(Theme.accent)
                                Text(question.textES)
                                    .font(Theme.bodyFont)
                                    .foregroundStyle(Theme.primaryText)
                            }
                        }
                    }
                }
            }
            .padding(Theme.spacingL)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(strength.nameES)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: Theme.spacingL) {
            Image(systemName: strength.iconSF)
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)
                .frame(width: 80, height: 80)
                .background(
                    Circle().fill(Theme.accent.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text(strength.nameES)
                    .font(Theme.titleFont)
                Text("Fortaleza VIA")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
        }
    }

    private var relatedQuestions: [Question] {
        QuestionsCatalog.all.filter { $0.strengthID == strength.id }
    }
}
