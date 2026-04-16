import SwiftUI

/// The "Ajustes" tab. Provides AI personality customization,
/// data management, and app information.
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
            .background(Theme.background.ignoresSafeArea())
        }
    }
}

#Preview {
    SettingsView()
}
