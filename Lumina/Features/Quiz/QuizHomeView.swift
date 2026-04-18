import SwiftUI

/// The Test tab's "home" state shown when the user has already completed
/// a test at least once. Summarizes when they took it, highlights the
/// top 3 strengths, and lets them retake the test.
///
/// Redesign (2026-04-17): Duolingo-style podium card for the top 3, each
/// entry colored by VIA virtue; CTAs use the expanded ``LuminaButton`` with
/// large sizing for a premium feel.
struct QuizHomeView: View {
    let result: TestResult
    let onRetake: () -> Void
    let onViewResults: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                header

                podiumCard

                VStack(spacing: Theme.spacingS) {
                    LuminaButton(title: "Ver mis 24 fortalezas", systemImage: "chart.bar.fill", size: .large) {
                        onViewResults()
                    }
                    LuminaSecondaryButton(title: "Hacer el test de nuevo", systemImage: "arrow.clockwise") {
                        onRetake()
                    }
                }
            }
            .padding(Theme.spacingL)
        }
        .background(Theme.heroGradient.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.spacingM) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.accent.opacity(0.25), Theme.accent.opacity(0)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 180
                        )
                    )
                    .frame(width: 280, height: 280)

                BearImage(name: "bear_07")
                    .frame(maxHeight: 180)
                    .luminaShadow(Theme.shadowCard)
            }

            Text("¡Ya completaste tu test!")
                .font(Theme.heroFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.primaryText)

            LuminaChip(
                title: result.completedAt.formatted(date: .long, time: .omitted),
                systemImage: "calendar",
                style: .accent
            )
        }
    }

    // MARK: - Podium

    private var podiumCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                LuminaSectionHeader(
                    title: "Tus 3 fortalezas principales",
                    subtitle: "Tu podio de fortalezas VIA",
                    systemImage: "star.fill",
                    iconTint: Theme.gold
                )

                VStack(spacing: Theme.spacingS) {
                    ForEach(Array(result.rankedStrengths.prefix(3).enumerated()), id: \.offset) { index, entry in
                        podiumRow(index: index, strength: entry.strength, points: entry.points)
                    }
                }
            }
        }
    }

    private func podiumRow(index: Int, strength: Strength, points: Int) -> some View {
        let color = Theme.categoryColor(for: strength.id)
        let medal: String = switch index {
        case 0: "medal.fill"
        case 1: "medal"
        default: "rosette"
        }
        let medalColor: Color = switch index {
        case 0: Theme.gold
        case 1: Color(white: 0.72)
        default: Color(red: 0.72, green: 0.45, blue: 0.20) // bronze
        }
        return HStack(spacing: Theme.spacingM) {
            Image(systemName: medal)
                .font(.title2.weight(.semibold))
                .foregroundStyle(medalColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(medalColor.opacity(0.14)))

            Image(systemName: strength.iconSF)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color.gradient)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(strength.nameES)
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.primaryText)
                Text(Theme.virtueCategory(for: strength.id).nameES)
                    .font(Theme.captionFont)
                    .foregroundStyle(color)
            }

            Spacer(minLength: 0)

            Text("\(points)")
                .font(Theme.numericFont)
                .foregroundStyle(Theme.primaryText)
        }
        .padding(Theme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: Theme.chipRadius + 4, style: .continuous)
                .fill(color.opacity(0.06))
        )
    }
}
