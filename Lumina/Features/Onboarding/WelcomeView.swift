import SwiftUI

/// First-launch onboarding. Introduces Lumina, sets expectations for the
/// 48-question test, and funnels the user into the quiz flow.
struct WelcomeView: View {
    let onStart: () -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: Theme.spacingL) {
                Spacer()

                BearImage(name: "bear_07")
                    .frame(maxHeight: 220)
                    .accessibilityHidden(true)

                VStack(spacing: Theme.spacingS) {
                    Text("Lumina")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.accent)

                    Text("Descubre tus fortalezas de carácter")
                        .font(Theme.subheadFont)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }

                CardContainer {
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

                LuminaButton(title: "Empezar", systemImage: "arrow.right") {
                    onStart()
                }
            }
            .padding(Theme.spacingL)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacingM) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: 32)
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
