import SwiftUI

/// Visible AI-content disclaimer shown beneath any surface that renders
/// output from Apple Foundation Models (personalized analysis, daily
/// reflection, etc.).
///
/// App Review Guideline 1.4.1 (health/medical) requires medical-adjacent
/// apps to (a) disclose that the content is not professional advice and
/// (b) make citations easy to find. This banner does both: it states the
/// disclaimer and, by default, links to the in-app References screen.
///
/// Must live inside a `NavigationStack` when `showsReferencesLink` is
/// true (the default) — it wraps its content in a ``NavigationLink``.
struct AIDisclaimerBanner: View {
    var showsReferencesLink: Bool = true

    var body: some View {
        if showsReferencesLink {
            NavigationLink {
                BibliographyView()
            } label: {
                rowContent
            }
            .buttonStyle(.plain)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: Theme.spacingS) {
            Image(systemName: "info.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text("Contenido generado con IA. No sustituye asesoría profesional.")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if showsReferencesLink {
                    Text("Ver referencias")
                        .font(Theme.captionFont.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }

            Spacer(minLength: 0)

            if showsReferencesLink {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(Theme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(Theme.accent.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.accent.opacity(0.22), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityHint(showsReferencesLink ? Text("Abre las referencias científicas") : Text(""))
    }
}

#Preview {
    NavigationStack {
        VStack(spacing: Theme.spacingL) {
            AIDisclaimerBanner()
            AIDisclaimerBanner(showsReferencesLink: false)
        }
        .padding()
        .background(Theme.background.ignoresSafeArea())
    }
}
