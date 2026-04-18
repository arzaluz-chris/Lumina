import SwiftUI
import FoundationModels

/// Premium multi-page onboarding flow. Introduces Lumina's features with
/// glassmorphic pages and animated transitions, including a conditional
/// Apple Intelligence step on compatible devices.
///
/// Redesign (2026-04-17): per-page hero gradient backdrop, cleaner page
/// indicators, CTA driven by the standard ``LuminaButton`` with shimmer.
struct OnboardingFlowView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private var pages: [OnboardingPage] {
        var result: [OnboardingPage] = [
            .welcome,
            .quiz,
            .strengths,
        ]
        let availability = SystemLanguageModel.default.availability
        if case .unavailable(let reason) = availability {
            if case .deviceNotEligible = reason {
                // Skip — device can't run Apple Intelligence
            } else {
                result.append(.appleIntelligence(availability))
            }
        } else {
            result.append(.appleIntelligence(availability))
        }
        result.append(.getStarted)
        return result
    }

    private var isLastPage: Bool { currentPage == pages.count - 1 }

    /// Per-page accent tint used for the backdrop gradient and page accent.
    private var currentAccent: Color {
        guard currentPage < pages.count else { return Theme.accent }
        switch pages[currentPage] {
        case .welcome:             return Theme.accent
        case .quiz:                return Theme.VirtueCategory.wisdom.color
        case .strengths:           return Theme.VirtueCategory.humanity.color
        case .appleIntelligence:   return Theme.VirtueCategory.transcendence.color
        case .getStarted:          return Theme.gold
        }
    }

    var body: some View {
        ZStack {
            // Animated per-page backdrop.
            LinearGradient(
                colors: [currentAccent.opacity(0.14), Theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(Theme.AnimationStyle.smooth, value: currentPage)

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(for: page, isLast: index == pages.count - 1)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicators
                    .padding(.bottom, Theme.spacingM)

                bottomBar
                    .padding(.horizontal, Theme.spacingL)
                    .padding(.bottom, Theme.spacingL)
            }
        }
        .sensoryFeedback(.selection, trigger: currentPage)
    }

    // MARK: - Page Indicators

    private var pageIndicators: some View {
        HStack(spacing: Theme.spacingS) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? currentAccent : currentAccent.opacity(0.2))
                    .frame(width: index == currentPage ? 26 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentPage)
            }
        }
    }

    // MARK: - Page Content

    @ViewBuilder
    private func pageView(for page: OnboardingPage, isLast: Bool) -> some View {
        switch page {
        case .welcome:
            OnboardingPageView(
                bearAsset: "bear_07",
                title: "Lumina",
                subtitle: "Descubre tus fortalezas de carácter y aprende a integrarlas en tu vida diaria."
            )

        case .quiz:
            OnboardingPageView(
                bearAsset: "bear_01",
                title: "A continuación, tu test",
                subtitle: "48 preguntas sobre cómo vives el día a día. Sin respuestas correctas ni incorrectas — sólo tú.",
                features: [
                    (icon: "clock.fill", title: "~10 minutos", description: "Lo harás ahora para desbloquear la app."),
                    (icon: "lock.fill", title: "100% privado", description: "Tus respuestas nunca salen de tu dispositivo."),
                ],
                accentOverride: Theme.VirtueCategory.wisdom.color
            )

        case .strengths:
            OnboardingPageView(
                bearAsset: "bear_12",
                title: "Tus 24 fortalezas",
                subtitle: "Basado en la clasificación VIA de Peterson y Seligman.",
                features: [
                    (icon: "chart.bar.fill", title: "Ranking personal", description: "De la más fuerte a la menos expresada."),
                    (icon: "star.fill", title: "Fortalezas signature", description: "Las 5 que más te representan."),
                ],
                accentOverride: Theme.VirtueCategory.humanity.color
            )

        case .appleIntelligence(let availability):
            appleIntelligencePage(availability: availability)

        case .getStarted:
            OnboardingPageView(
                bearAsset: "bear_44",
                title: "Todo listo",
                subtitle: "Estás a punto de descubrir lo mejor de ti.",
                accentOverride: Theme.gold,
                isLastPage: true
            )
        }
    }

    // MARK: - Apple Intelligence Page

    private func appleIntelligencePage(availability: SystemLanguageModel.Availability) -> some View {
        VStack(spacing: 0) {
            Spacer()

            BearImage(name: "bear_10")
                .frame(maxHeight: 220)
                .luminaShadow(Theme.shadowElevated)

            Spacer().frame(height: Theme.spacingL)

            CardContainer(style: .glass, cornerRadius: Theme.heroRadius) {
                VStack(spacing: Theme.spacingM) {
                    HStack(spacing: Theme.spacingS) {
                        Image(systemName: "apple.intelligence")
                            .font(.title2)
                        Text("Apple Intelligence")
                            .font(Theme.heroFont)
                    }
                    .foregroundStyle(Theme.VirtueCategory.transcendence.color)

                    aiStatusText(availability: availability)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    if case .unavailable(let reason) = availability {
                        if case .appleIntelligenceNotEnabled = reason {
                            LuminaButton(title: "Abrir Ajustes", systemImage: "gear") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    } else {
                        HStack(spacing: Theme.spacingS) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.success)
                            Text("Apple Intelligence está activa")
                                .font(Theme.subheadFont)
                        }
                        .padding(Theme.spacingM)
                        .background(
                            Capsule().fill(Theme.success.opacity(0.12))
                        )
                    }
                }
            }
            .padding(.horizontal, Theme.spacingL)

            Spacer()
        }
    }

    @ViewBuilder
    private func aiStatusText(availability: SystemLanguageModel.Availability) -> some View {
        switch availability {
        case .available:
            Text("Lumina usa Apple Intelligence en tu dispositivo para generar un análisis personalizado y conversar con Buddy. Todo queda en tu iPhone.")
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                Text("Activa Apple Intelligence en los ajustes de tu dispositivo para desbloquear el análisis personalizado y Buddy.")
            case .modelNotReady:
                Text("Apple Intelligence se está preparando. Podrás usar el análisis y Buddy cuando esté lista.")
            default:
                Text("Algunas funciones de IA no están disponibles en este dispositivo.")
            }
        @unknown default:
            Text("Lumina funciona mejor con Apple Intelligence activado.")
        }
    }

    // MARK: - Bottom Bar

    @ViewBuilder
    private var bottomBar: some View {
        if !isLastPage {
            HStack {
                LuminaGhostButton(title: "Saltar", tint: Theme.secondaryText) {
                    withAnimation(Theme.AnimationStyle.smooth) {
                        currentPage = pages.count - 1
                    }
                }

                Spacer()

                Button {
                    withAnimation(Theme.AnimationStyle.smooth) {
                        currentPage += 1
                    }
                } label: {
                    HStack(spacing: Theme.spacingXS) {
                        Text("Siguiente")
                        Image(systemName: "arrow.right")
                    }
                    .font(Theme.subheadFont)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.spacingL)
                    .padding(.vertical, Theme.spacingS + 2)
                    .background(
                        Capsule().fill(currentAccent)
                    )
                    .luminaShadow(Theme.shadowCard)
                }
                .buttonStyle(.plain)
            }
        } else {
            LuminaButton(
                title: "Comenzar",
                systemImage: "sparkles",
                size: .large,
                action: onComplete
            )
            .shimmerRepeating(duration: 1.6, restBetweenSweeps: 1.4)
            .sensoryFeedback(.impact(weight: .heavy), trigger: isLastPage)
        }
    }
}

// MARK: - Page Model

private enum OnboardingPage {
    case welcome
    case quiz
    case strengths
    case appleIntelligence(SystemLanguageModel.Availability)
    case getStarted
}

#Preview {
    OnboardingFlowView(onComplete: {})
}
