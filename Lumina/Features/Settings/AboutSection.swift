import SwiftUI

/// Settings section with app info, privacy, and credits.
struct AboutSection: View {
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        Section {
            HStack {
                Text("Versión")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(Theme.secondaryText)
            }

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Label("Privacidad", systemImage: "lock.shield.fill")
                    .font(Theme.subheadFont)
                Text("Lumina procesa todo en tu dispositivo usando Apple Intelligence. Ningún dato personal sale de tu iPhone.")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.vertical, Theme.spacingXS)

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Label("Créditos", systemImage: "info.circle.fill")
                    .font(Theme.subheadFont)
                Text("Basado en la clasificación VIA de fortalezas de carácter de Christopher Peterson y Martin Seligman. Desarrollado por Walden Dos.")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.vertical, Theme.spacingXS)
        } header: {
            Label("Acerca de", systemImage: "info.circle")
        }
    }
}
