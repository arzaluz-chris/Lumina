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
                Label("Créditos", systemImage: "info.circle.fill")
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.gold)
                Text("Hecho por Colegio Walden Dos de México.")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Theme.spacingXS)

            // Bear cameo
            HStack(spacing: Theme.spacingM) {
                BearImage(name: "bear_07")
                    .frame(width: 64, height: 64)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lumina")
                        .font(Theme.subheadFont)
                        .foregroundStyle(Theme.primaryText)
                    Text("Colegio Walden Dos de México")
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
