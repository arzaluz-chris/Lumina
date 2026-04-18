import SwiftUI

/// Consistent empty-state layout used throughout the app (Stories, Quiz home
/// before first completion, Buddy conversation list, etc.).
///
/// Pairs a bear mascot with a headline, body copy, and an optional primary CTA.
struct LuminaEmptyState: View {
    let bearName: String
    let title: String
    let message: String
    var primaryActionTitle: String? = nil
    var primaryActionIcon: String? = nil
    var primaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            BearImage(name: bearName)
                .frame(maxWidth: 220, maxHeight: 220)
                .luminaShadow(Theme.shadowCard)

            VStack(spacing: Theme.spacingS) {
                Text(title)
                    .font(Theme.heroFont)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.primaryText)

                Text(message)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.spacingL)

            if let primaryActionTitle, let primaryAction {
                LuminaButton(title: primaryActionTitle, systemImage: primaryActionIcon, action: primaryAction)
                    .padding(.horizontal, Theme.spacingL)
                    .padding(.top, Theme.spacingS)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.spacingL)
    }
}

#Preview {
    LuminaEmptyState(
        bearName: "bear_07",
        title: "Sin historias aún",
        message: "Registra un momento que muestre una de tus fortalezas.",
        primaryActionTitle: "Crear historia",
        primaryActionIcon: "plus",
        primaryAction: {}
    )
    .background(Theme.background)
}
