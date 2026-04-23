import SwiftUI

/// A speaker-icon button that reads the provided text aloud via
/// ``SpeechService``. Designed for kids and anyone who can't yet read —
/// drop one next to any text block that should be narratable.
///
/// The button renders three visually distinct states:
/// - **Disabled** (dimmed): the user has turned off "Leer en voz alta"
///   from Settings → Accesibilidad. Tap has no effect.
/// - **Idle**: tinted outline, speaker icon. Tap starts playback.
/// - **Playing**: filled pill in the tint color, a stop-in-circle glyph.
///   Tap cancels playback.
struct ReadAloudButton: View {
    let text: String
    var tint: Color = Theme.accent
    var size: Size = .regular

    @State private var utteranceID = UUID()
    private let service = SpeechService.shared

    enum Size {
        case small
        case regular
        case large

        var iconSize: CGFloat {
            switch self {
            case .small:   14
            case .regular: 18
            case .large:   22
            }
        }

        var container: CGFloat {
            switch self {
            case .small:   32
            case .regular: 40
            case .large:   48
            }
        }
    }

    private var isActive: Bool { service.isSpeaking(id: utteranceID) }

    var body: some View {
        Button {
            if isActive {
                service.stop()
            } else {
                service.speak(text, id: utteranceID)
            }
        } label: {
            Image(systemName: isActive ? "stop.circle.fill" : "speaker.wave.2.fill")
                .font(.system(size: size.iconSize, weight: .semibold, design: .rounded))
                .foregroundStyle(iconForeground)
                .frame(width: size.container, height: size.container)
                .background(
                    Circle().fill(backgroundStyle)
                )
                .overlay(
                    Circle().stroke(tint.opacity(service.isEnabled ? 0.28 : 0.14), lineWidth: 1)
                )
                .contentTransition(.symbolEffect(.replace))
                // HIG minimum tap target is 44×44pt. For the `.small` visual
                // size (32pt), we expand the hit area transparently so kids
                // with imprecise taps — and everyone else — reliably hit the
                // button without enlarging the glyph itself.
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!service.isEnabled || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .accessibilityLabel(isActive ? "Detener lectura" : "Leer en voz alta")
        .accessibilityHint("Lee el texto con la voz del sistema.")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    private var iconForeground: Color {
        guard service.isEnabled else { return tint.opacity(0.35) }
        return isActive ? .white : tint
    }

    private var backgroundStyle: AnyShapeStyle {
        if isActive {
            AnyShapeStyle(tint.gradient)
        } else if service.isEnabled {
            AnyShapeStyle(tint.opacity(0.14))
        } else {
            AnyShapeStyle(tint.opacity(0.06))
        }
    }
}
