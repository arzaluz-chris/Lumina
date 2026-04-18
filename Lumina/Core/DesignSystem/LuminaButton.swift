import SwiftUI

/// Standardised button size tokens.
enum LuminaButtonSize {
    case compact
    case regular
    case large

    var verticalPadding: CGFloat {
        switch self {
        case .compact: return Theme.spacingS + 2   // 10
        case .regular: return Theme.spacingM        // 16
        case .large:   return Theme.spacingM + 4    // 20
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: return Theme.spacingM        // 16
        case .regular: return Theme.spacingL        // 24
        case .large:   return Theme.spacingL + 4    // 28
        }
    }

    var font: Font {
        switch self {
        case .compact: return .system(.subheadline, design: .rounded, weight: .semibold)
        case .regular: return Theme.subheadFont
        case .large:   return .system(.title3, design: .rounded, weight: .semibold)
        }
    }

    var radius: CGFloat {
        switch self {
        case .compact: return Theme.chipRadius + 2
        case .regular: return Theme.buttonRadius
        case .large:   return Theme.buttonRadius + 4
        }
    }
}

/// Primary call-to-action button — used on Welcome, at the end of the
/// quiz, in empty states, etc.
///
/// Adapts its height for Dynamic Type so the title never truncates.
struct LuminaButton: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled: Bool = true
    var size: LuminaButtonSize = .regular
    let action: () -> Void

    @State private var tapCount = 0

    var body: some View {
        Button {
            tapCount += 1
            action()
        } label: {
            HStack(spacing: Theme.spacingS) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(size.font)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                        .fill(isEnabled ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Color.secondary.opacity(0.3)))
                    // Glossy highlight for a premium feel.
                    if isEnabled {
                        RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.28), Color.white.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                }
            )
            .luminaShadow(isEnabled ? Theme.shadowCard : Theme.ShadowStyle(color: .clear, radius: 0, x: 0, y: 0))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .sensoryFeedback(.impact(weight: .medium), trigger: tapCount)
    }
}

/// Secondary button style — outlined, subtler, used for "skip", "regenerate",
/// etc.
struct LuminaSecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var size: LuminaButtonSize = .regular
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spacingS) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(size.font)
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                    .stroke(Theme.accent, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Low-emphasis "ghost" button used for inline text actions.
struct LuminaGhostButton: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = Theme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spacingXS) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(Theme.captionFont.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: Theme.spacingM) {
        LuminaButton(title: "Empezar el test", systemImage: "sparkles") {}
        LuminaButton(title: "Grande", systemImage: "play.fill", size: .large) {}
        LuminaSecondaryButton(title: "Regenerar análisis", systemImage: "arrow.clockwise") {}
        LuminaGhostButton(title: "Saltar", action: {})
        LuminaButton(title: "Desactivado", isEnabled: false) {}
    }
    .padding()
    .background(Theme.background)
}
