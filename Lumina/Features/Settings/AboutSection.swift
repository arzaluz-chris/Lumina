import SwiftUI

/// Settings section with app info, privacy, and credits.
///
/// Redesign (2026-04-17): adds a bear mascot cameo and a small Walden
/// Dos attribution band at the bottom of the section.
struct AboutSection: View {
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        Section {
            HStack {
                Label("Versión", systemImage: "number")
                Spacer()
                Text(appVersion)
                    .font(.system(.body, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
            }

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Label("Privacidad", systemImage: "lock.shield.fill")
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.accent)
                Text("Lumina procesa todo en tu dispositivo usando Apple Intelligence. Ningún dato personal sale de tu iPhone.")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Theme.spacingXS)

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Label("Créditos", systemImage: "info.circle.fill")
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.gold)
                Text("Basado en la clasificación VIA de fortalezas de carácter de Christopher Peterson y Martin Seligman. Desarrollado por Walden Dos.")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Theme.spacingXS)

            // Bear cameo
            HStack(spacing: Theme.spacingM) {
                BearImage(name: "bear_07")
                    .frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hecho con cariño")
                        .font(Theme.subheadFont)
                        .foregroundStyle(Theme.primaryText)
                    Text("para Walden Dos")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
            }
            .padding(.vertical, Theme.spacingXS)
        } header: {
            Label("Acerca de", systemImage: "info.circle")
        }
    }
}
