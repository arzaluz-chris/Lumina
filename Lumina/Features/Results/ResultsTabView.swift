import SwiftUI
import SwiftData
import FoundationModels

/// Root of the "Mis 24" tab. Renders the 24 ranked strengths from the
/// latest `TestResult`, a CTA to open the AI-generated insight, a daily
/// AI reflection, and an evolution card when multiple tests exist.
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

                // Daily AI reflection
                DailyReflectionCard(result: result)

                // Evolution card (if multiple tests)
                if results.count > 1, let previous = results.dropFirst().first {
                    EvolutionCard(current: result, previous: previous)
                }

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
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(Theme.accentGradient))

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.spacingL)
    }
}

// MARK: - Daily AI Reflection

/// Auto-generates a short daily micro-reflection based on the user's top
/// strengths using Foundation Models. Cached per day.
private struct DailyReflectionCard: View {
    let result: TestResult

    @AppStorage("dailyReflectionDate") private var cachedDate: String = ""
    @AppStorage("dailyReflectionText") private var cachedText: String = ""
    @State private var isLoading = false

    private var markdownReflection: AttributedString {
        (try? AttributedString(
            markdown: cachedText,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(cachedText)
    }

    private var isToday: Bool {
        cachedDate == todayKey
    }

    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        if !cachedText.isEmpty && isToday {
            CardContainer {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    HStack(spacing: Theme.spacingS) {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(Theme.gold)
                        Text("Reflexión del día")
                            .font(Theme.subheadFont)
                    }
                    Text(markdownReflection)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } else if isLoading {
            CardContainer {
                HStack(spacing: Theme.spacingM) {
                    ProgressView()
                    Text("Generando reflexión...")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                }
            }
        } else {
            // Generate on appear
            Color.clear.frame(height: 0)
                .task { await generateReflection() }
        }
    }

    private func generateReflection() async {
        guard !isToday else { return }
        guard case .available = SystemLanguageModel.default.availability else { return }

        isLoading = true
        defer { isLoading = false }

        let snapshot = result.snapshot()
        let top3 = snapshot.top(3).map(\.strengthName).joined(separator: ", ")

        do {
            let session = LanguageModelSession(
                model: .default,
                instructions: Instructions(
                    "Genera una micro-reflexión diaria de 1-2 oraciones en español " +
                    "para alguien cuyas fortalezas principales son: \(top3). " +
                    "Sé específico, cálido y evita clichés. Solo responde con la reflexión."
                )
            )
            let response = try await session.respond(to: "Reflexión para hoy.")
            cachedText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            cachedDate = todayKey
        } catch {
            // Silently fail — this is a nice-to-have feature
        }
    }
}

// MARK: - Evolution Card

/// Shows a comparison between the current and previous test when the
/// user has taken the quiz more than once. Uses Foundation Models to
/// generate a brief evolution analysis.
private struct EvolutionCard: View {
    let current: TestResult
    let previous: TestResult

    @State private var analysis: String?
    @State private var isLoading = false

    private func markdownAnalysis(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }

    var body: some View {
        if let analysis {
            NavigationLink {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingL) {
                        Text("Tu evolución")
                            .font(Theme.titleFont)
                        Text(markdownAnalysis(analysis))
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Theme.spacingL)
                }
                .background(Theme.background.ignoresSafeArea())
                .navigationTitle("Evolución")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                CardContainer {
                    HStack(spacing: Theme.spacingM) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundStyle(Theme.lavender)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Theme.lavender.opacity(0.12)))
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            Text("Cómo has cambiado")
                                .font(Theme.subheadFont)
                                .foregroundStyle(Theme.primaryText)
                            Text("Comparado con tu test anterior")
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
        } else if isLoading {
            CardContainer {
                HStack(spacing: Theme.spacingM) {
                    ProgressView()
                    Text("Analizando evolución...")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                }
            }
        } else {
            Color.clear.frame(height: 0)
                .task { await generateEvolution() }
        }
    }

    private func generateEvolution() async {
        guard case .available = SystemLanguageModel.default.availability else { return }

        isLoading = true
        defer { isLoading = false }

        let currentSnap = current.snapshot()
        let previousSnap = previous.snapshot()

        let currentTop = currentSnap.top(5).map { "\($0.strengthName) (\($0.points))" }.joined(separator: ", ")
        let previousTop = previousSnap.top(5).map { "\($0.strengthName) (\($0.points))" }.joined(separator: ", ")

        do {
            let session = LanguageModelSession(
                model: .default,
                instructions: Instructions(
                    "Eres un coach de fortalezas VIA. Compara dos resultados de test del mismo usuario " +
                    "y genera un breve análisis de evolución (3-4 párrafos) en español. " +
                    "Destaca qué fortalezas crecieron, cuáles bajaron y qué significa. " +
                    "Sé específico, cálido y evita clichés."
                )
            )
            let prompt = """
            Test anterior: \(previousTop)
            Test actual: \(currentTop)
            Genera el análisis de evolución.
            """
            let response = try await session.respond(to: prompt)
            analysis = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            // Silently fail
        }
    }
}
