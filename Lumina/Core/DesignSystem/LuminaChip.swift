import SwiftUI

/// Pill-shaped tag / suggestion chip used throughout Lumina.
///
/// Three styles are provided:
/// - `.accent` — translucent accent background with accent text (default).
/// - `.filled(Color)` — solid fill with contrast text, used for category tags.
/// - `.outlined(Color)` — just a tinted border.
struct LuminaChip: View {
    enum Style {
        case accent
        case filled(Color)
        case outlined(Color)
    }

    let title: String
    var systemImage: String? = nil
    var style: Style = .accent
    var action: (() -> Void)? = nil

    var body: some View {
        if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
        } else {
            label
        }
    }

    private var label: some View {
        HStack(spacing: Theme.spacingXS) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
        }
        .font(Theme.captionFont.weight(.semibold))
        .foregroundStyle(foreground)
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
        .background(background)
        .overlay(border)
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .accent:
            Capsule(style: .continuous).fill(Theme.primarySoft)
        case .filled(let color):
            Capsule(style: .continuous).fill(color)
        case .outlined:
            Capsule(style: .continuous).fill(Color.clear)
        }
    }

    @ViewBuilder
    private var border: some View {
        switch style {
        case .accent:
            Capsule(style: .continuous).stroke(Theme.accent.opacity(0.25), lineWidth: 1)
        case .filled:
            Capsule(style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1)
        case .outlined(let color):
            Capsule(style: .continuous).stroke(color, lineWidth: 1.3)
        }
    }

    private var foreground: Color {
        switch style {
        case .accent:          return Theme.accent
        case .filled:          return .white
        case .outlined(let c): return c
        }
    }
}

#Preview {
    VStack(spacing: Theme.spacingM) {
        LuminaChip(title: "Curiosidad", systemImage: "sparkles")
        LuminaChip(title: "Tu top 3", style: .filled(Theme.gold))
        LuminaChip(title: "Nuevo", style: .outlined(Theme.accent))
    }
    .padding()
    .background(Theme.background)
}
