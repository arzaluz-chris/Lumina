import SwiftUI
import FoundationModels

/// Premium multi-page onboarding flow. Introduces Lumina's features with
/// glassmorphic pages and animated transitions, including a conditional
/// Apple Intelligence step on compatible devices.
struct OnboardingFlowView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var shimmerOffset: CGFloat = -200

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

    var body: some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                colors: [Theme.background, Theme.accent.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(for: page, isLast: index == pages.count - 1)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom page indicators
                pageIndicators
                    .padding(.bottom, Theme.spacingM)

                // Bottom navigation
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
                    .fill(index == currentPage ? Theme.accent : Theme.accent.opacity(0.2))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
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
                ]
            )

        case .strengths:
            OnboardingPageView(
                bearAsset: "bear_12",
                title: "Tus 24 fortalezas",
                subtitle: "Basado en la clasificación VIA de Peterson y Seligman.",
                features: [
                    (icon: "chart.bar.fill", title: "Ranking personal", description: "De la más fuerte a la menos expresada."),
                    (icon: "star.fill", title: "Fortalezas signature", description: "Las 5 que más te representan."),
                ]
            )

        case .appleIntelligence(let availability):
            appleIntelligencePage(availability: availability)

        case .getStarted:
            OnboardingPageView(
                bearAsset: "bear_44",
                title: "Todo listo",
                subtitle: "Estás a punto de descubrir lo mejor de ti.",
                isLastPage: true
            )
        }
    }

    // MARK: - Apple Intelligence Page

    private func appleIntelligencePage(availability: SystemLanguageModel.Availability) -> some View {
        VStack(spacing: 0) {
            Spacer()

            BearImage(name: "bear_10")
                .frame(maxHeight: 200)

            Spacer()
                .frame(height: Theme.spacingL)

            VStack(spacing: Theme.spacingM) {
                HStack(spacing: Theme.spacingS) {
                    Image(systemName: "apple.intelligence")
                        .font(.title2)
                    Text("Apple Intelligence")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Theme.accent)

                aiStatusText(availability: availability)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)

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
                            .foregroundStyle(.green)
                        Text("Apple Intelligence está activa")
                            .font(Theme.subheadFont)
                    }
                    .padding(Theme.spacingM)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
            .padding(Theme.spacingL)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
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

    private var bottomBar: some View {
        Group {
            if !isLastPage {
                HStack {
                    Button("Saltar") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            currentPage = pages.count - 1
                        }
                    }
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.secondaryText)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
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
                            Capsule().fill(Theme.accent)
                        )
                    }
                }
            } else {
                // Final CTA with shimmer effect
                Button {
                    onComplete()
                } label: {
                    HStack(spacing: Theme.spacingS) {
                        Image(systemName: "arrow.right")
                        Text("Comenzar")
                    }
                    .font(Theme.subheadFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacingM)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                            .fill(Theme.accentGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.25), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: shimmerOffset)
                            .mask(
                                RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                            )
                    )
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(weight: .heavy), trigger: isLastPage)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
                        shimmerOffset = 400
                    }
                }
            }
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
