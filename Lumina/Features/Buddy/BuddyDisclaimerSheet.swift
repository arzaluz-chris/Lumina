import SwiftUI

/// One-time sheet shown the first time the user opens Lumina Buddy.
///
/// Apple's App Review guidelines, the Foundation Models acceptable-use
/// policy, and common sense all ask that AI-generated content not be
/// presented as professional advice. This sheet is a quick contract
/// with the user that the chat is assistive — not diagnostic.
struct BuddyDisclaimerSheet: View {
    let onAcknowledge: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    hero

                    VStack(alignment: .leading, spacing: Theme.spacingM) {
                        bulletRow(
                            icon: "sparkles",
                            tint: Theme.accent,
                            title: "Respuestas generadas por IA",
                            body: "Buddy usa Apple Intelligence en tu dispositivo para escribir respuestas a partir de tus fortalezas. Nada se envía a un servidor."
                        )

                        bulletRow(
                            icon: "exclamationmark.bubble.fill",
                            tint: Theme.warning,
                            title: "Puede equivocarse",
                            body: "Como toda IA, Buddy puede decir cosas imprecisas o salirse del tema. Cuestiona sus respuestas y contrástalas si algo te hace ruido."
                        )

                        bulletRow(
                            icon: "stethoscope",
                            tint: Theme.danger,
                            title: "No sustituye a un profesional",
                            body: "Buddy no es psicólogo, médico ni orientador. Úsalo como compañero de reflexión; para decisiones importantes busca a un experto de confianza."
                        )

                        bulletRow(
                            icon: "hand.raised.fill",
                            tint: Theme.lavender,
                            title: "Tu privacidad",
                            body: "Tus preguntas y respuestas se quedan en tu dispositivo. Puedes borrarlas en cualquier momento desde la lista de conversaciones."
                        )
                    }
                    .padding(Theme.spacingL)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .fill(Theme.cardBackground)
                    )
                    .luminaShadow(Theme.shadowCard)
                }
                .padding(Theme.spacingL)
                .adaptiveReadableWidth()
            }
            .background(Theme.heroGradient.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button {
                    onAcknowledge()
                    dismiss()
                } label: {
                    Text("Entendido")
                        .font(Theme.subheadFont)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacingM)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                                .fill(Theme.accentGradient)
                        )
                        .luminaShadow(Theme.shadowCard)
                }
                .buttonStyle(.plain)
                .padding(Theme.spacingL)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Antes de comenzar")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Subviews

    private var hero: some View {
        VStack(spacing: Theme.spacingM) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.accent.opacity(0.28), Theme.accent.opacity(0)],
                            center: .center,
                            startRadius: 8,
                            endRadius: 120
                        )
                    )
                    .frame(width: 180, height: 180)
                BearImage(name: "bear_10")
                    .frame(maxHeight: 120)
            }
            Text("Buddy puede equivocarse")
                .font(Theme.heroFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.primaryText)
            Text("Úsalo como punto de partida para tu reflexión, no como una fuente definitiva.")
                .font(Theme.bodyFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.secondaryText)
                .padding(.horizontal, Theme.spacingL)
        }
    }

    private func bulletRow(
        icon: String,
        tint: Color,
        title: LocalizedStringKey,
        body: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: Theme.spacingM) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(tint.gradient))
            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text(title)
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.primaryText)
                Text(body)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    Text("host").sheet(isPresented: .constant(true)) {
        BuddyDisclaimerSheet(onAcknowledge: {})
    }
}
