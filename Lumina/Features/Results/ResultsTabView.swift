import SwiftUI
import SwiftData

/// Root of the "Mis 24" tab. Renders the 24 ranked strengths from the
/// latest `TestResult`, a CTA to open the AI-generated insight, and an
/// empty state when the user hasn't completed the test yet.
struct ResultsTabView: View {
    @Query(sort: \TestResult.completedAt, order: .reverse) private var results: [TestResult]

    var body: some View {
        NavigationStack {
            Group {
                if let latest = results.first {
                    content(for: latest)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Mis 24")
            .navigationBarTitleDisplayMode(.large)
            .background(Theme.background.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private func content(for result: TestResult) -> some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                insightCTA(for: result)

                CardContainer(padding: Theme.spacingM) {
                    VStack(spacing: 0) {
                        ForEach(Array(result.rankedStrengths.enumerated()), id: \.offset) { index, entry in
                            NavigationLink {
                                StrengthDetailView(
                                    strength: entry.strength,
                                    points: entry.points
                                )
                            } label: {
                                StrengthRowView(
                                    rank: index + 1,
                                    strength: entry.strength,
                                    points: entry.points
                                )
                            }
                            .buttonStyle(.plain)

                            if index < result.rankedStrengths.count - 1 {
                                Divider()
                                    .padding(.leading, 68)
                            }
                        }
                    }
                }
            }
            .padding(Theme.spacingL)
        }
    }

    private func insightCTA(for result: TestResult) -> some View {
        NavigationLink {
            InsightsView(result: result)
        } label: {
            CardContainer {
                HStack(spacing: Theme.spacingM) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(Theme.accent.opacity(0.12)))

                    VStack(alignment: .leading, spacing: Theme.spacingXS) {
                        Text("Tu análisis personalizado")
                            .font(Theme.subheadFont)
                            .foregroundStyle(Theme.primaryText)
                        Text(result.insight == nil ? "Generado en tu dispositivo" : "Ver de nuevo")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.spacingL) {
            BearImage(name: "bear_01")
                .frame(maxHeight: 220)
            Text("Aún no has hecho el test")
                .font(Theme.headlineFont)
            Text("Ve a la pestaña Test para descubrir tus 24 fortalezas.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.spacingL)
    }
}
