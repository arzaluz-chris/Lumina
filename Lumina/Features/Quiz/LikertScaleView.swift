import SwiftUI

/// Horizontal five-pill Likert response selector with a red→green color
/// scale so the polarity of each answer reads at a glance (1 = Nada in
/// soft red, 5 = Totalmente in green).
///
/// Pills can be tapped directly; the parent view also drives a swipe
/// gesture that previews a value in `hoveredValue` and the matching pill
/// scales up to full saturation so the drag feels coupled to the row.
///
/// Redesign (2026-04-17): pills are larger and more Duolingo-like, colors
/// come from the shared ``Theme`` semantic tokens so the hue is consistent
/// with the rest of the app.
struct LikertScaleView: View {
    let onSelect: (Int) -> Void
    @Binding var hoveredValue: Int?

    @State private var lastSelected: Int?

    init(hoveredValue: Binding<Int?> = .constant(nil), onSelect: @escaping (Int) -> Void) {
        self._hoveredValue = hoveredValue
        self.onSelect = onSelect
    }

    private struct Option: Identifiable {
        let id: Int
        let labelES: String
        let color: Color
    }

    private let options: [Option] = [
        Option(id: 1, labelES: "Nada",       color: Theme.danger),
        Option(id: 2, labelES: "Poco",       color: Theme.warning),
        Option(id: 3, labelES: "Neutral",    color: Theme.neutral),
        Option(id: 4, labelES: "Bastante",   color: Theme.successSoft),
        Option(id: 5, labelES: "Totalmente", color: Theme.success),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options) { option in
                Button {
                    lastSelected = option.id
                    onSelect(option.id)
                } label: {
                    pill(for: option)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.labelES)")
                .accessibilityValue("Opción \(option.id) de 5")
                .accessibilityHint("Toca para responder con \(option.labelES)")
            }
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.selection, trigger: lastSelected)
    }

    @ViewBuilder
    private func pill(for option: Option) -> some View {
        let isActive = hoveredValue == option.id
        VStack(spacing: 2) {
            Text("\(option.id)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(isActive ? .white : option.color)
            Text(option.labelES)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(isActive ? .white.opacity(0.95) : option.color.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isActive ? AnyShapeStyle(option.color.gradient) : AnyShapeStyle(option.color.opacity(0.14)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(option.color.opacity(isActive ? 0 : 0.45), lineWidth: 1.5)
        )
        .shadow(
            color: option.color.opacity(isActive ? 0.45 : 0),
            radius: isActive ? 12 : 0,
            x: 0,
            y: isActive ? 6 : 0
        )
        .scaleEffect(isActive ? 1.10 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isActive)
    }

    /// Exposes the color scale so siblings (question card callout,
    /// tutorial) can render the same per-value hue.
    static func color(for value: Int) -> Color {
        let i = max(1, min(5, value)) - 1
        return LikertColorScale.colors[i]
    }

    static func label(for value: Int) -> String {
        switch value {
        case 1: return "Nada"
        case 2: return "Poco"
        case 3: return "Neutral"
        case 4: return "Bastante"
        case 5: return "Totalmente"
        default: return ""
        }
    }
}

/// Shared lookup so other views match the pill colors exactly. Colors are
/// sourced from ``Theme`` so the red→green scale matches the rest of the app.
enum LikertColorScale {
    static let colors: [Color] = [
        Theme.danger,
        Theme.warning,
        Theme.neutral,
        Theme.successSoft,
        Theme.success,
    ]
}

#Preview {
    VStack(spacing: 20) {
        LikertScaleView { _ in }
        LikertScaleView(hoveredValue: .constant(4)) { _ in }
        LikertScaleView(hoveredValue: .constant(1)) { _ in }
    }
    .padding()
    .background(Theme.background)
}
