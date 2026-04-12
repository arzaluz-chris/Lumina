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
                                .foregroundStyle(.orange)
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
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Análisis")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadCached)
    }

    // MARK: - States

    private var header: some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text("Tu análisis personalizado")
                    .font(Theme.headlineFont)
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

                LuminaButton(title: "Generar análisis", systemImage: "sparkles") {
                    Task { await generate(force: false) }
                }
            }
        }
    }

    private var loadingCard: some View {
        CardContainer {
            HStack(spacing: Theme.spacingM) {
                ProgressView()
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
        CardContainer {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Label("Apple Intelligence no disponible", systemImage: "info.circle.fill")
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.accent)
                Text(reason)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.primaryText)
                Text("Tus resultados siguen visibles en Mis 24.")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    @ViewBuilder
    private func rendered(insight: StrengthInsight) -> some View {
        CardContainer {
            Text(insight.summary)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }

        sectionTitle("Tus fortalezas signature")
        ForEach(Array(insight.signatureStrengths.enumerated()), id: \.offset) { _, item in
            signatureCard(item)
        }

        sectionTitle("Áreas de crecimiento")
        ForEach(Array(insight.growthAreas.enumerated()), id: \.offset) { _, item in
            growthCard(item)
        }

        sectionTitle("Para llevarte")
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
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(Theme.subheadFont)
            .foregroundStyle(Theme.primaryText)
            .padding(.top, Theme.spacingS)
    }

    private func signatureCard(_ item: SignatureStrengthItem) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text(item.strengthName)
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.accent)
                Text(item.howItShows)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.primaryText)
                Divider()
                Label(item.weeklyAction, systemImage: "sparkles")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private func growthCard(_ item: GrowthAreaItem) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text(item.strengthName)
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.accent)
                Text(item.whyItMatters)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.primaryText)
                Divider()
                Label(item.firstStep, systemImage: "arrow.forward.circle.fill")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    // MARK: - Actions

    private func loadCached() {
        Logger.insights.info("loadCached() — checking for existing insight...")
        guard loadedInsight == nil, let cached = result.insight else {
            Logger.insights.debug("loadCached() — \(loadedInsight != nil ? "already loaded" : "no cached insight found")")
            return
        }
        Logger.insights.info("Found cached insight (generated: \(cached.generatedAt.formatted()), \(cached.summaryJSON.count) bytes)")
        if let decoded = try? JSONDecoder().decode(StrengthInsight.self, from: cached.summaryJSON) {
            loadedInsight = decoded
            Logger.insights.info("Cached insight decoded successfully")
            Logger.insights.debug("Summary preview: \(String(decoded.summary.prefix(80)))...")
        } else {
            Logger.insights.error("Failed to decode cached insight JSON")
        }
    }

    private func generate(force: Bool) async {
        if !force, loadedInsight != nil {
            Logger.insights.debug("generate() skipped — already loaded and force=false")
            return
        }
        Logger.insights.info("=== INSIGHTS GENERATION START (force: \(force)) ===")
        Logger.insights.info("Provider type: \(type(of: provider))")
        Logger.insights.info("Provider available: \(provider.isAvailable)")

        error = nil
        isGenerating = true
        defer { isGenerating = false }

        let snapshot = result.snapshot()
        Logger.insights.debug("Snapshot created with \(snapshot.rankedEntries.count) entries")

        let startTime = CFAbsoluteTimeGetCurrent()
        do {
            let generated = try await provider.generateInsight(for: snapshot)
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            Logger.insights.info("Insight generated in \(elapsed, format: .fixed(precision: 2)) seconds")

            let data = try JSONEncoder().encode(generated)
            Logger.insights.debug("Encoded to \(data.count) bytes JSON")

            if let existing = result.insight {
                existing.summaryJSON = data
                existing.generatedAt = Date()
                Logger.insights.info("Updated existing AIInsight cache")
            } else {
                let insight = AIInsight(summaryJSON: data)
                insight.testResult = result
                result.insight = insight
                modelContext.insert(insight)
                Logger.insights.info("Created new AIInsight and inserted into modelContext")
            }
            try? modelContext.save()
            Logger.insights.info("modelContext saved")
            loadedInsight = generated
            Logger.insights.info("=== INSIGHTS GENERATION COMPLETE ===")
        } catch {
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            Logger.insights.error("=== INSIGHTS GENERATION FAILED (\(elapsed, format: .fixed(precision: 2)) seconds) ===")
            Logger.insights.error("Error: \(error.localizedDescription)")
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
