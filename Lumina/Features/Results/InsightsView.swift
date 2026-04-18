import SwiftUI
import SwiftData
import os

/// AI-generated personalized analysis of a `TestResult`.
///
/// Displays four states:
/// 1. **Cached** — insight already exists on the result, render it.
/// 2. **Idle** — no cached insight, show "Generate" CTA.
/// 3. **Loading** — call in flight, show spinner.
/// 4. **Unavailable** — device doesn't support Apple Intelligence, show
///    friendly explanation and keep the user unblocked.
///
/// Redesign (2026-04-17): premium header with sparkles in gradient badge,
/// cards gain stronger typographic hierarchy and virtue-colored chips
/// for each signature strength / growth area. AIGlowOverlay (line ~56)
/// is preserved exactly.
struct InsightsView: View {
    let result: TestResult

    @Environment(\.modelContext) private var modelContext
    @Environment(\.aiInsightsProvider) private var provider

    @State private var loadedInsight: StrengthInsight?
    @State private var isGenerating: Bool = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                header

                if let insight = loadedInsight {
                    rendered(insight: insight)
                } else if let reason = provider.unavailableReason {
                    unavailable(reason: reason)
                } else if isGenerating {
                    loadingCard
                } else {
                    idleCard
                }

                if let error {
                    CardContainer {
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Label("No se pudo generar el análisis", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(Theme.warning)
                                .font(Theme.subheadFont)
                            Text(error)
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
            }
            .padding(Theme.spacingL)
        }
        .background(Theme.heroGradient.ignoresSafeArea())
        .aiGlow(isActive: isGenerating)
        .navigationTitle("Análisis")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: loadedInsight != nil)
        .onAppear(perform: loadCached)
    }

    // MARK: - States

    private var header: some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: "sparkles")
                .font(.title.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Theme.accentGradient))
                .luminaShadow(Theme.shadowCard)
            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text("Tu análisis personalizado")
                    .font(Theme.heroFont)
                    .foregroundStyle(Theme.primaryText)
                Text("Generado en tu dispositivo")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private var idleCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Text("Tu análisis te espera")
                    .font(Theme.subheadFont)
                Text("Usamos Apple Intelligence en tu dispositivo para redactar una lectura basada en tus respuestas. Ningún dato sale de tu iPhone.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                LuminaButton(title: "Generar análisis", systemImage: "sparkles", size: .large) {
                    Task { await generate(force: false) }
                }
            }
        }
    }

    private var loadingCard: some View {
        CardContainer {
            HStack(spacing: Theme.spacingM) {
                ProgressView()
                    .tint(Theme.accent)
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Generando tu análisis…")
                        .font(Theme.subheadFont)
                    Text("Esto toma unos segundos.")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
            }
        }
    }

    private func unavailable(reason: String) -> some View {
        CardContainer(style: .outlined) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Label("Apple Intelligence no disponible", systemImage: "info.circle.fill")
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.accent)
                Text(reason)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tus resultados siguen visibles en Mis 24.")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    @ViewBuilder
    private func rendered(insight: StrengthInsight) -> some View {
        CardContainer {
            HStack(alignment: .top, spacing: Theme.spacingM) {
                Image(systemName: "text.alignleft")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.accent.opacity(0.14)))
                Text(insight.summary)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        sectionTitle(
            "Tus fortalezas signature",
            subtitle: "Las 5 que más te representan",
            icon: "star.fill",
            tint: Theme.gold
        )
        ForEach(Array(insight.signatureStrengths.enumerated()), id: \.offset) { _, item in
            signatureCard(item)
        }

        sectionTitle(
            "Áreas de crecimiento",
            subtitle: "Oportunidades para expandirte",
            icon: "arrow.up.forward.circle.fill",
            tint: Theme.lavender
        )
        ForEach(Array(insight.growthAreas.enumerated()), id: \.offset) { _, item in
            growthCard(item)
        }

        sectionTitle(
            "Para llevarte",
            subtitle: nil,
            icon: "heart.fill",
            tint: Theme.danger
        )
        CardContainer {
            Text(insight.encouragement)
                .font(Theme.bodyFont)
                .italic()
                .foregroundStyle(Theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }

        LuminaSecondaryButton(title: "Regenerar análisis", systemImage: "arrow.clockwise") {
            Task { await generate(force: true) }
        }
        .padding(.top, Theme.spacingS)
    }

    private func sectionTitle(_ text: String, subtitle: String?, icon: String, tint: Color) -> some View {
        LuminaSectionHeader(title: text, subtitle: subtitle, systemImage: icon, iconTint: tint)
            .padding(.top, Theme.spacingS)
    }

    private func signatureCard(_ item: SignatureStrengthItem) -> some View {
        let color = Theme.categoryColor(for: strengthID(named: item.strengthName))
        return CardContainer {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                LuminaChip(title: item.strengthName, style: .filled(color))
                Text(item.howItShows)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Divider().padding(.vertical, 2)
                Label(item.weeklyAction, systemImage: "sparkles")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private func growthCard(_ item: GrowthAreaItem) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                LuminaChip(title: item.strengthName, style: .filled(Theme.lavender))
                Text(item.whyItMatters)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Divider().padding(.vertical, 2)
                Label(item.firstStep, systemImage: "arrow.forward.circle.fill")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    /// Looks up the strength ID from a display name. Falls back to empty
    /// string so `categoryColor` returns the default.
    private func strengthID(named name: String) -> String {
        StrengthsCatalog.all.first { $0.nameES.localizedCaseInsensitiveCompare(name) == .orderedSame }?.id ?? ""
    }

    // MARK: - Actions

    private func loadCached() {
        guard loadedInsight == nil, let cached = result.insight else { return }
        if let decoded = try? JSONDecoder().decode(StrengthInsight.self, from: cached.summaryJSON) {
            loadedInsight = decoded
        } else {
            Logger.insights.error("Failed to decode cached insight JSON")
        }
    }

    private func generate(force: Bool) async {
        if !force, loadedInsight != nil { return }

        error = nil
        isGenerating = true
        defer { isGenerating = false }

        let snapshot = result.snapshot()

        do {
            let generated = try await provider.generateInsight(for: snapshot)

            let data = try JSONEncoder().encode(generated)

            if let existing = result.insight {
                existing.summaryJSON = data
                existing.generatedAt = Date()
            } else {
                let insight = AIInsight(summaryJSON: data)
                insight.testResult = result
                result.insight = insight
                modelContext.insert(insight)
            }
            try? modelContext.save()
            loadedInsight = generated
        } catch {
            Logger.insights.error("Insight generation failed: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Environment

private struct AIInsightsProviderKey: EnvironmentKey {
    static let defaultValue: any AIInsightsProviding = MockInsightsProvider()
}

extension EnvironmentValues {
    var aiInsightsProvider: any AIInsightsProviding {
        get { self[AIInsightsProviderKey.self] }
        set { self[AIInsightsProviderKey.self] = newValue }
    }
}
