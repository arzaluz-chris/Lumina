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

#Preview {
    SettingsView()
}
