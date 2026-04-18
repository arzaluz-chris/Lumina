import SwiftUI

/// Visual variants for ``CardContainer``.
enum CardContainerStyle: Sendable {
    /// Solid card background with subtle border + soft shadow. Default.
    case elevated
    /// Transparent fill, accent stroke — used for info blocks and inline CTAs.
    case outlined
    /// Liquid Glass material (iOS 26 `.ultraThinMaterial`), used for floating
    /// input bars and premium overlays.
    case glass
}

/// Elevated card surface used to group related content (question, story,
/// strength detail, chat bubble, etc.).
struct CardContainer<Inner: View>: View {
    var style: CardContainerStyle = .elevated
    var padding: CGFloat = Theme.spacingL
    var cornerRadius: CGFloat = Theme.cardRadius
    @ViewBuilder var content: Inner

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(border)
            .modifier(CardShadowModifier(style: style))
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .elevated:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
        case .outlined:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.clear)
        case .glass:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private var border: some View {
        switch style {
        case .elevated:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        case .outlined:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1.2)
        case .glass:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

private struct CardShadowModifier: ViewModifier {
    let style: CardContainerStyle

    func body(content: Content) -> some View {
        switch style {
        case .elevated:
            content.luminaShadow(Theme.shadowCard)
        case .outlined:
            content
        case .glass:
            content.luminaShadow(Theme.shadowElevated)
        }
    }
}

#Preview {
    VStack(spacing: Theme.spacingM) {
        CardContainer {
            Text("Elevated")
                .font(Theme.headlineFont)
        }
        CardContainer(style: .outlined) {
            Text("Outlined")
                .font(Theme.headlineFont)
        }
        CardContainer(style: .glass) {
            Text("Glass")
                .font(Theme.headlineFont)
        }
    }
    .padding()
    .background(Theme.heroGradient.ignoresSafeArea())
}
