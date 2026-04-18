import SwiftUI

/// Reusable section header with optional icon and subtitle.
/// Standardises the look of "Tus 24 fortalezas", "Reflexión del día", etc.
struct LuminaSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var iconTint: Color = Theme.accent

    var body: some View {
        HStack(alignment: .center, spacing: Theme.spacingS) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(iconTint)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle().fill(iconTint.opacity(0.12))
                    )
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.primaryText)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    VStack(spacing: Theme.spacingM) {
        LuminaSectionHeader(title: "Tus 24 fortalezas", subtitle: "Ordenadas por puntaje", systemImage: "chart.bar.fill")
        LuminaSectionHeader(title: "Sin icono")
    }
    .padding()
    .background(Theme.background)
}
