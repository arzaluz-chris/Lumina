import SwiftUI

/// The "Ajustes" tab. Provides AI personality customization,
/// data management, and app information.
///
/// Redesign (2026-04-17): keeps the Form structure (preferred for iOS
/// settings ergonomics and accessibility) but layers the hero gradient
/// behind and tints Form accents so it feels of a piece with the rest
/// of the redesigned app.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                AIPersonalitySection()
                NotificationsSection()
                DataSection()
                LegalSection()
                AboutSection()
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
            .scrollContentBackground(.hidden)
            .background(Theme.heroGradient.ignoresSafeArea())
            .tint(Theme.accent)
        }
    }
}

/// Settings section grouping legal and scientific-sources screens.
/// Added in 2026-04-18 to pre-empt App Store review friction around
/// (a) privacy policy access from inside the app and (b) attribution of
/// the VIA character-strengths framework used as the test's basis.
private struct LegalSection: View {
    var body: some View {
        Section {
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("Aviso de privacidad", systemImage: "lock.shield.fill")
            }

            NavigationLink {
                BibliographyView()
            } label: {
                Label("Referencias", systemImage: "book.pages.fill")
            }
        } header: {
            Label("Legal y fuentes", systemImage: "checkmark.seal.fill")
                .foregroundStyle(Theme.lavender)
        } footer: {
            Text("Todo el procesamiento de Lumina ocurre en tu dispositivo. Ningún dato personal sale de tu iPhone o iPad.")
        }
    }
}

#Preview {
    SettingsView()
}
