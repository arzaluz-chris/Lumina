import SwiftUI
import SwiftData
import FoundationModels
import os

/// Root of the "Mis 24" tab. Renders the 24 ranked strengths from the
/// latest `TestResult`, a CTA to open the AI-generated insight, a daily
/// AI reflection, and an evolution card when multiple tests exist.
///
/// Redesign (2026-04-17): hero top-3 preview above the scroll, insight and
/// evolution CTAs get richer iconography and gradient fills, empty state
/// uses ``LuminaEmptyState``. All business logic (queries, LLM calls,
/// AppStorage keys) is preserved.
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
                topThreeHero(for: result)

                if AICapabilityGate.shared.isAvailable {
                    insightCTA(for: result)

                    DailyReflectionCard(result: result)
                }

                if results.count > 1 {
                    evolutionCTA
                }

                allStrengthsCard(for: result)
            }
            .padding(Theme.spacingL)
            .adaptiveReadableWidth()
        }
    }

    /// Entry point for the full Evolution screen with charts.
    /// Only rendered when the user has ≥ 2 completed tests.
    private var evolutionCTA: some View {
        NavigationLink {
            EvolutionView(results: results)
        } label: {
            CardContainer {
                HStack(spacing: Theme.spacingM) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(Theme.lavender.gradient))
                        .luminaShadow(Theme.shadowCard)

                    VStack(alignment: .leading, spacing: Theme.spacingXS) {
                        Text("Ver evolución")
                            .font(Theme.subheadFont)
                            .foregroundStyle(Theme.primaryText)
                        Text("\(results.count) tests · gráficas interactivas")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func topThreeHero(for result: TestResult) -> some View {
        let top = Array(result.rankedStrengths.prefix(3))
        return CardContainer(style: .glass, cornerRadius: Theme.heroRadius) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                LuminaSectionHeader(
                    title: "Tu top 3",
                    subtitle: "Tus fortalezas más expresadas",
                    systemImage: "star.fill",
                    iconTint: Theme.gold
                )

                HStack(alignment: .top, spacing: Theme.spacingS) {
                    ForEach(Array(top.enumerated()), id: \.offset) { index, entry in
                        topThreeTile(index: index, strength: entry.strength, points: entry.points)
                    }
                }
            }
        }
    }

    private func topThreeTile(index: Int, strength: Strength, points: Int) -> some View {
        let color = Theme.categoryColor(for: strength.id)
        return VStack(spacing: Theme.spacingS) {
            ZStack {
                Circle()
                    .fill(color.gradient)
                    .frame(width: 56, height: 56)
                    .luminaShadow(Theme.shadowCard)
                Image(systemName: strength.iconSF)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Text("#\(index + 1)")
                .font(Theme.captionFont.weight(.heavy))
                .foregroundStyle(color)
            Text(strength.nameES)
                .font(Theme.captionFont.weight(.semibold))
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text("\(points) pts")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color.opacity(0.08))
        )
    }

    private func allStrengthsCard(for result: TestResult) -> some View {
        CardContainer(padding: Theme.spacingM) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                LuminaSectionHeader(
                    title: "Todas tus 24 fortalezas",
                    subtitle: "De la más fuerte a la menos expresada",
                    systemImage: "chart.bar.fill"
                )
                .padding(.horizontal, Theme.spacingXS)

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
                                .padding(.leading, 72)
                        }
                    }
                }
            }
        }
    }

    private func insightCTA(for result: TestResult) -> some View {
        NavigationLink {
            InsightsView(result: result)
        } label: {
            CardContainer {
                HStack(spacing: Theme.spacingM) {
                    Image(systemName: "sparkles")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(Theme.accentGradient))
                        .luminaShadow(Theme.shadowCard)

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
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        LuminaEmptyState(
            bearName: "bear_01",
            title: "Aún no has hecho el test",
            message: "Ve a la pestaña Test para descubrir tus 24 fortalezas."
        )
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
        cardContent
            .onAppear {
                guard !isLoading, !isToday else { return }
                guard case .available = SystemLanguageModel.default.availability else { return }
                isLoading = true
                Task { await generateReflection() }
            }
    }

    @ViewBuilder
    private var cardContent: some View {
        if !cachedText.isEmpty && isToday {
            CardContainer {
                VStack(alignment: .leading, spacing: Theme.spacingM) {
                    LuminaSectionHeader(
                        title: "Reflexión del día",
                        subtitle: "Inspirada en tus top 3 fortalezas",
                        systemImage: "sun.max.fill",
                        iconTint: Theme.gold
                    )
                    Text(markdownReflection)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    AIDisclaimerBanner()
                }
            }
        } else if isLoading {
            CardContainer {
                HStack(spacing: Theme.spacingM) {
                    ProgressView()
                        .tint(Theme.gold)
                    Text("Generando reflexión…")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                }
            }
            .aiGlow(isActive: isLoading)
        } else {
            Color.clear.frame(height: 0)
        }
    }

    private func generateReflection() async {
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
            Logger.ai.error("Daily reflection failed: \(error.localizedDescription)")
        }

        isLoading = false
    }
}

