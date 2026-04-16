import SwiftUI

/// Horizontal five-pill Likert response selector with a red→green color
/// scale so the polarity of each answer reads at a glance (1 = Nada in
/// soft red, 5 = Totalmente in green).
///
/// Pills can be tapped directly; the parent view also drives a swipe
/// gesture that previews a value in `hoveredValue` and the matching pill
/// scales up to full saturation so the drag feels coupled to the row.
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

    // A muted red → green scale. Calibrated so all five pills read well
    // on the warm cream light background and the dark mode background.
    private let options: [Option] = [
        Option(id: 1, labelES: "Nada",       color: Color(red: 0.91, green: 0.39, blue: 0.40)),
        Option(id: 2, labelES: "Poco",       color: Color(red: 0.94, green: 0.58, blue: 0.30)),
        Option(id: 3, labelES: "Neutral",    color: Color(red: 0.79, green: 0.70, blue: 0.33)),
        Option(id: 4, labelES: "Bastante",   color: Color(red: 0.53, green: 0.75, blue: 0.43)),
        Option(id: 5, labelES: "Totalmente", color: Color(red: 0.34, green: 0.69, blue: 0.42)),
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options) { option in
                Button {
                    lastSelected = option.id
                    onSelect(option.id)
                } label: {
                    pill(for: option)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Respuesta \(option.id) de 5: \(option.labelES)")
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
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(isActive ? .white : option.color)
            Text(option.labelES)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(isActive ? .white : option.color.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(.horizontal, 4)
        .background(
            Capsule(style: .continuous)
                .fill(isActive ? option.color : option.color.opacity(0.16))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(option.color.opacity(isActive ? 0 : 0.45), lineWidth: 1.5)
        )
        .shadow(
            color: option.color.opacity(isActive ? 0.45 : 0),
            radius: isActive ? 10 : 0,
            x: 0,
            y: isActive ? 4 : 0
        )
        .scaleEffect(isActive ? 1.12 : 1.0)
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

/// Shared lookup so other views match the pill colors exactly.
enum LikertColorScale {
    static let colors: [Color] = [
        Color(red: 0.91, green: 0.39, blue: 0.40),
        Color(red: 0.94, green: 0.58, blue: 0.30),
        Color(red: 0.79, green: 0.70, blue: 0.33),
        Color(red: 0.53, green: 0.75, blue: 0.43),
        Color(red: 0.34, green: 0.69, blue: 0.42),
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
