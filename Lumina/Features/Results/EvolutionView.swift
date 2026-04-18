import SwiftUI
import SwiftData
import FoundationModels
import os

/// Top-level Evolution screen. Reached from the "Mis 24" tab's
/// "Ver evolución" card once the user has completed two or more tests.
///
/// Stitches together the three chart components (top-over-time, delta,
/// per-strength trend), an AI-written commentary (gated on Apple
/// Intelligence availability), and a signature-consistency chip.
struct EvolutionView: View {
    let results: [TestResult]

    @State private var selectedStrengthID: String
    @State private var aiCommentary: String?
    @State private var isGeneratingCommentary = false

    init(results: [TestResult]) {
        self.results = results
        let initial = results.first?.rankedStrengths.first?.strength.id
            ?? StrengthsCatalog.all.first?.id
            ?? ""
        _selectedStrengthID = State(initialValue: initial)
    }

    private var stats: StrengthEvolutionStats {
        // results come sorted descending; StrengthEvolutionStats sorts
        // ascending internally.
        StrengthEvolutionStats(from: results)
    }

    private var deltas: [StrengthEvolutionStats.Delta] {
        guard results.count >= 2 else { return [] }
        let current = stats.samples.last!
        let previous = stats.samples[stats.samples.count - 2]
        return StrengthEvolutionStats.deltas(previous: previous, current: current)
    }

    private var selectedStrength: Strength? {
        StrengthsCatalog.strength(id: selectedStrengthID)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                header

                consistencyBadge

                CardContainer {
                    EvolutionTopOverTimeChart(stats: stats)
                }

                CardContainer {
                    EvolutionDeltaChart(deltas: deltas)
                }

                CardContainer {
                    VStack(alignment: .leading, spacing: Theme.spacingM) {
                        strengthPicker
                        if let strength = selectedStrength {
                            EvolutionTrendChart(
                                strength: strength,
                                series: stats.trendSeries(for: strength.id)
                            )
                        }
                    }
                }

                if AICapabilityGate.shared.isAvailable {
                    aiCommentaryCard
                }
            }
            .padding(Theme.spacingL)
            .adaptiveReadableWidth()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Evolución")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: results.count) {
            if AICapabilityGate.shared.isAvailable, aiCommentary == nil, results.count >= 2 {
                await generateCommentary()
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Cómo has cambiado")
                .font(Theme.titleFont)
                .foregroundStyle(Theme.primaryText)
            Text("\(results.count) tests completados desde el \(firstTestDateFormatted).")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var firstTestDateFormatted: String {
        guard let first = results.last?.completedAt else { return "—" }
        return first.formatted(.dateTime.day().month(.wide).year())
    }

    private var consistencyBadge: some View {
        let consistency = stats.signatureConsistency()
        let percent = Int((consistency * 100).rounded())
        let caption: LocalizedStringKey = {
            switch percent {
            case 80...: return "Tus fortalezas signature son muy consistentes."
            case 50..<80: return "Hay cambios visibles pero tu núcleo se mantiene."
            default: return "Estás en una etapa de transición de fortalezas."
            }
        }()
        return CardContainer {
            HStack(spacing: Theme.spacingM) {
                ZStack {
                    Circle()
                        .stroke(Theme.accent.opacity(0.15), lineWidth: 6)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: consistency)
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    Text("\(percent)%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.accent)
                        .monospacedDigit()
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Consistencia de tu top 5")
                        .font(Theme.subheadFont)
                        .foregroundStyle(Theme.primaryText)
                    Text(caption)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var strengthPicker: some View {
        Menu {
            Picker("Fortaleza", selection: $selectedStrengthID) {
                ForEach(StrengthsCatalog.all) { strength in
                    Label(strength.nameES, systemImage: strength.iconSF)
                        .tag(strength.id)
                }
            }
        } label: {
            HStack(spacing: Theme.spacingS) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Theme.accent)
                Text("Tendencia por fortaleza")
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                if let strength = selectedStrength {
                    Text(strength.nameES)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.accent)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var aiCommentaryCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                LuminaSectionHeader(
                    title: "¿Qué cambió?",
                    subtitle: "Lectura de tu evolución",
                    systemImage: "sparkles",
                    iconTint: Theme.gold
                )

                if let aiCommentary {
                    Text(aiCommentary)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                } else if isGeneratingCommentary {
                    HStack(spacing: Theme.spacingM) {
                        ProgressView()
                            .tint(Theme.gold)
                        Text("Analizando tu evolución…")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .aiGlow(isActive: true)
                } else {
                    Text("No se pudo generar el análisis en este momento.")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
    }

    private func generateCommentary() async {
        guard results.count >= 2 else { return }
        guard let current = results.first?.snapshot(),
              let previous = results.dropFirst().first?.snapshot() else { return }

        isGeneratingCommentary = true
        defer { isGeneratingCommentary = false }

        let currentTop = current.top(5).map { "\($0.strengthName) (\($0.points))" }.joined(separator: ", ")
        let previousTop = previous.top(5).map { "\($0.strengthName) (\($0.points))" }.joined(separator: ", ")

        do {
            let session = LanguageModelSession(
                model: .default,
                instructions: Instructions(
                    "Eres un coach de fortalezas VIA. Compara dos tests del mismo usuario y escribe una " +
                    "lectura breve de su evolución (2-3 párrafos) en español. Destaca una fortaleza que creció, " +
                    "una que bajó y qué podría significar. Sé cálido, específico y evita clichés."
                )
            )
            let prompt = """
            Test anterior: \(previousTop)
            Test actual: \(currentTop)
            Escribe la lectura de evolución.
            """
            let response = try await session.respond(to: prompt)
            aiCommentary = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            Logger.ai.error("Evolution commentary failed: \(error.localizedDescription)")
        }
    }
}
