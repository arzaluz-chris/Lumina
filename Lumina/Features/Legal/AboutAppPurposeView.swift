import SwiftUI

/// "Sobre esta app" — educational-nature disclosure screen reachable from
/// Settings → Legal y fuentes.
///
/// App Review Guideline 1.4.1 asks apps that reference health/psychology
/// frameworks to clearly disclose that the content is educational and not
/// medical advice, and to surface citations. This screen states both the
/// purpose of the app and the "not a substitute for a professional" line,
/// and jumps to References and Privacy for the full picture.
struct AboutAppPurposeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                hero

                bulletsCard

                linksCard

                footnote
            }
            .padding(Theme.spacingL)
            .adaptiveReadableWidth()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Sobre esta app")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var hero: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Una herramienta educativa")
                .font(Theme.titleFont)
                .foregroundStyle(Theme.primaryText)
            Text("Lumina es una app de autoconocimiento para explorar las 24 fortalezas de carácter de la clasificación VIA. Está pensada para estudiantes, familias y docentes del Colegio Walden Dos de México.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bulletsCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                bulletRow(
                    icon: "stethoscope",
                    tint: Theme.danger,
                    title: "No es diagnóstico ni terapia",
                    body: "Lumina no ofrece diagnóstico, tratamiento ni consejo médico o psicológico. Para decisiones relacionadas con tu salud mental o la de alguien a tu cuidado, consulta a un profesional calificado."
                )

                bulletRow(
                    icon: "sparkles",
                    tint: Theme.accent,
                    title: "Contenido generado por IA",
                    body: "El análisis personalizado, la reflexión del día y las respuestas de Buddy se generan con Apple Intelligence en tu dispositivo. Como toda IA, puede equivocarse; úsala como punto de partida para tu reflexión, no como fuente definitiva."
                )

                bulletRow(
                    icon: "book.closed.fill",
                    tint: Theme.lavender,
                    title: "Basada en VIA",
                    body: "La estructura de 24 fortalezas es la clasificación de Peterson y Seligman (2004) desarrollada por el VIA Institute on Character. Lumina no está afiliada al VIA Institute; el uso es educativo."
                )

                bulletRow(
                    icon: "lock.shield.fill",
                    tint: Theme.success,
                    title: "Tus datos no salen de tu dispositivo",
                    body: "Tus respuestas, historias y conversaciones se procesan y guardan localmente. No hay cuentas, servidores ni analíticas."
                )
            }
        }
    }

    private var linksCard: some View {
        CardContainer(style: .outlined) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Text("Saber más")
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.primaryText)

                NavigationLink {
                    BibliographyView()
                } label: {
                    linkRow(icon: "book.pages.fill", title: "Referencias", subtitle: "Fuentes científicas citadas")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    linkRow(icon: "lock.shield.fill", title: "Aviso de privacidad", subtitle: "Qué datos usa Lumina")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footnote: some View {
        Text("Si estás en una situación de crisis o necesitas atención urgente, contacta a un profesional de la salud o a un servicio de emergencia de tu país.")
            .font(Theme.captionFont)
            .italic()
            .foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Helpers

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

    private func linkRow(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: icon)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Theme.accent.opacity(0.14)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.primaryText)
                Text(subtitle)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
        }
    }
}

#Preview {
    NavigationStack {
        AboutAppPurposeView()
    }
}
