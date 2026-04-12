import SwiftUI

/// The Test tab's "home" state shown when the user has already completed
/// a test at least once. Summarizes when they took it, highlights the
/// top 3 strengths, and lets them retake the test.
struct QuizHomeView: View {
    let result: TestResult
    let onRetake: () -> Void
    let onViewResults: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                header

                CardContainer {
                    VStack(alignment: .leading, spacing: Theme.spacingM) {
                        Label {
                            Text("Tus 3 fortalezas principales")
                                .font(Theme.subheadFont)
                        } icon: {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Theme.accent)
                        }

                        Divider()

                        ForEach(Array(result.rankedStrengths.prefix(3).enumerated()), id: \.offset) { index, entry in
                            HStack(spacing: Theme.spacingM) {
                                Text("\(index + 1)")
                                    .font(Theme.headlineFont)
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 28)
                                Image(systemName: entry.strength.iconSF)
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 28)
                                Text(entry.strength.nameES)
                                    .font(Theme.bodyFont)
                                Spacer()
                                Text("\(entry.points)")
                                    .font(Theme.subheadFont)
                                    .foregroundStyle(Theme.secondaryText)
                                    .monospacedDigit()
                            }
                        }
                    }
                }

                VStack(spacing: Theme.spacingS) {
                    LuminaButton(title: "Ver mis 24 fortalezas", systemImage: "chart.bar.fill") {
                        onViewResults()
                    }
                    LuminaSecondaryButton(title: "Hacer el test de nuevo", systemImage: "arrow.clockwise") {
                        onRetake()
                    }
                }
            }
            .padding(Theme.spacingL)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: Theme.spacingS) {
            BearImage(name: "bear_07")
                .frame(maxHeight: 160)

            Text("¡Ya completaste tu test!")
                .font(Theme.titleFont)
                .multilineTextAlignment(.center)

            Text("Completado el \(result.completedAt.formatted(date: .long, time: .omitted))")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
        }
    }
}
