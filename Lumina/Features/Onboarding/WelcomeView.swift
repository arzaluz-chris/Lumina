import SwiftUI

/// First-launch onboarding. Introduces Lumina, sets expectations for the
/// 48-question test, and funnels the user into the quiz flow.
///
/// Note: superseded by ``OnboardingFlowView`` in the current runtime, kept
/// as a standalone simple variant for previews and possible reuse.
struct WelcomeView: View {
    let onStart: () -> Void

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()

            VStack(spacing: Theme.spacingL) {
                Spacer()

                BearImage(name: "bear_07")
                    .frame(maxHeight: 220)
                    .luminaShadow(Theme.shadowElevated)

                VStack(spacing: Theme.spacingS) {
                    Text("Lumina")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.accent)

                    Text("Descubre tus fortalezas de carácter")
                        .font(Theme.subheadFont)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }

                CardContainer(style: .glass, cornerRadius: Theme.heroRadius) {
                    VStack(alignment: .leading, spacing: Theme.spacingM) {
                        FeatureRow(
                            icon: "pencil.and.list.clipboard",
                            title: "Un test breve",
                            description: "48 preguntas sobre cómo vives el día a día."
                        )
                        FeatureRow(
                            icon: "chart.bar.fill",
                            title: "Tus 24 fortalezas",
                            description: "Descubre cómo se ordenan tus fortalezas VIA."
                        )
                        FeatureRow(
                            icon: "sparkles",
                            title: "Análisis personalizado",
                            description: "Una lectura privada generada en tu dispositivo con Apple Intelligence."
                        )
                    }
                }

                Spacer()

                LuminaButton(title: "Empezar", systemImage: "arrow.right", size: .large) {
                    onStart()
                }
            }
            .padding(Theme.spacingL)
        }
        // Hero wordmark uses a fixed 52pt display size. Cap Dynamic Type
        // so the layout stays readable at the largest accessibility sizes.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: Theme.spacingM) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Theme.accent.opacity(0.14)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.subheadFont)
                Text(description)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}

#Preview {
    WelcomeView(onStart: {})
}
