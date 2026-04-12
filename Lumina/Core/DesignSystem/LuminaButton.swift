import SwiftUI

/// Primary call-to-action button — used on Welcome, at the end of the
/// quiz, in empty states, etc.
///
/// Adapts its height for Dynamic Type so the title never truncates.
struct LuminaButton: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spacingS) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(Theme.subheadFont)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacingM)
            .padding(.horizontal, Theme.spacingL)
            .background(
                RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                    .fill(isEnabled ? Theme.accent : Color.secondary.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .sensoryFeedback(.impact(weight: .medium), trigger: isEnabled)
    }
}

/// Secondary button style — outlined, subtler, used for "skip", "regenerate",
/// etc.
struct LuminaSecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spacingS) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(Theme.subheadFont)
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacingM)
            .padding(.horizontal, Theme.spacingL)
            .background(
                RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                    .stroke(Theme.accent, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: Theme.spacingM) {
        LuminaButton(title: "Empezar el test", systemImage: "sparkles") {}
        LuminaSecondaryButton(title: "Regenerar análisis", systemImage: "arrow.clockwise") {}
        LuminaButton(title: "Desactivado", isEnabled: false) {}
    }
    .padding()
    .background(Theme.background)
}
