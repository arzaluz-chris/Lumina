import SwiftUI

/// Bibliographic references shown in Settings → Referencias.
///
/// Apple's App Review team flags apps that reference academic frameworks
/// (VIA Character Strengths is published by the VIA Institute on Character
/// and based on Peterson & Seligman's book) without attributing them
/// clearly. Surfacing a dedicated References page with APA-7 citations —
/// and making source URLs tappable — is the cleanest way to satisfy
/// Guideline 1.4.1 ("include citations… such as links to those sources").
struct BibliographyView: View {
    /// APA-7 citations. Using structured entries (rather than a single
    /// `Text` block) so each reference can be VoiceOver-labeled and
    /// rendered with a proper hanging indent. The optional `url` is
    /// rendered as a tappable link below the citation when present.
    private struct Reference: Identifiable {
        let id: String
        let authors: String
        let year: String
        let title: AttributedString
        let source: String
        let url: URL?
    }

    private let references: [Reference] = [
        Reference(
            id: "peterson-seligman",
            authors: "Peterson, C., & Seligman, M. E. P.",
            year: "2004",
            title: {
                var s = AttributedString("Character strengths and virtues: A handbook and classification.")
                s.inlinePresentationIntent = .emphasized
                return s
            }(),
            source: "Oxford University Press.",
            url: URL(string: "https://global.oup.com/academic/product/character-strengths-and-virtues-9780195167016")
        ),
        Reference(
            id: "niemiec",
            authors: "Niemiec, R. M.",
            year: "2018",
            title: {
                var s = AttributedString("Character strengths interventions: A field guide for practitioners.")
                s.inlinePresentationIntent = .emphasized
                return s
            }(),
            source: "Hogrefe Publishing.",
            url: URL(string: "https://www.hogrefe.com/us/shop/character-strengths-interventions.html")
        ),
        Reference(
            id: "park-peterson-seligman",
            authors: "Park, N., Peterson, C., & Seligman, M. E. P.",
            year: "2004",
            title: AttributedString("Strengths of character and well-being."),
            source: {
                var s = AttributedString("Journal of Social and Clinical Psychology")
                s.inlinePresentationIntent = .emphasized
                return String(s.characters) + ", 23(5), 603–619."
            }(),
            url: URL(string: "https://doi.org/10.1521/jscp.23.5.603.50748")
        ),
        Reference(
            id: "via-institute",
            authors: "VIA Institute on Character.",
            year: "s. f.",
            title: {
                var s = AttributedString("The 24 character strengths.")
                s.inlinePresentationIntent = .emphasized
                return s
            }(),
            source: "viacharacter.org",
            url: URL(string: "https://www.viacharacter.org/character-strengths")
        ),
        Reference(
            id: "skinner",
            authors: "Skinner, B. F.",
            year: "1948",
            title: {
                var s = AttributedString("Walden Two.")
                s.inlinePresentationIntent = .emphasized
                return s
            }(),
            source: "Macmillan.",
            url: nil
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                header

                VStack(alignment: .leading, spacing: Theme.spacingM) {
                    ForEach(references) { reference in
                        referenceRow(reference)
                        if reference.id != references.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(Theme.spacingL)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                        .fill(Theme.cardBackground)
                )
                .luminaShadow(Theme.shadowCard)

                footnote
            }
            .padding(Theme.spacingL)
            .adaptiveReadableWidth()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Referencias")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Bases científicas")
                .font(Theme.titleFont)
                .foregroundStyle(Theme.primaryText)
            Text("Lumina se apoya en la clasificación VIA de fortalezas de carácter, desarrollada por la Dra. Nansook Park, Christopher Peterson y Martin E. P. Seligman. Tocá cualquier enlace para abrir la fuente en Safari.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Renders one APA entry with a hanging indent so continuation
    /// lines align under the first character of the authors block.
    /// When the reference has a URL, a tappable `Link` is shown beneath.
    private func referenceRow(_ reference: Reference) -> some View {
        let citation: AttributedString = {
            var s = AttributedString("\(reference.authors) (\(reference.year)). ")
            s.append(reference.title)
            s.append(AttributedString(" \(reference.source)"))
            return s
        }()

        return VStack(alignment: .leading, spacing: Theme.spacingXS) {
            Text(citation)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(Text(citation))

            if let url = reference.url {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption.weight(.semibold))
                        Text(url.host ?? url.absoluteString)
                            .font(Theme.captionFont.weight(.semibold))
                    }
                    .foregroundStyle(Theme.accent)
                }
                .accessibilityHint(Text("Abre la fuente en Safari"))
            }
        }
        .padding(.leading, Theme.spacingM)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Theme.accent.opacity(0.5))
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        }
    }

    private var footnote: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Lumina no está afiliada al VIA Institute on Character. Esta app usa la clasificación de fortalezas de carácter con fines educativos.")
                .font(Theme.captionFont)
                .italic()
                .foregroundStyle(Theme.secondaryText)

            if let url = URL(string: "https://www.viacharacter.org/research") {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption.weight(.semibold))
                        Text("Más investigación: viacharacter.org/research")
                            .font(Theme.captionFont.weight(.semibold))
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BibliographyView()
    }
}
