import SwiftUI

/// Full-screen tutorial shown before the first quiz question. Not an
/// overlay — it's a proper opaque view with its own background that
/// mirrors the live quiz UI (real bear sticker in its card, real pill
/// row with the same color scale) and plays a looping swipe animation
/// with an animated finger, so kids learn by watching.
///
/// Redesign (2026-04-17): hero gradient backdrop, glass instruction card,
/// start button uses the shared ``LuminaButton`` (large). Animation loop
/// and phase math are unchanged.
struct SwipeTutorialView: View {
    let onDismiss: () -> Void

    @State private var cycle: Double = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()

            VStack(spacing: Theme.spacingL) {
                header
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Spacer(minLength: 0)

                demoStage
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)

                instructions
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Spacer(minLength: 0)

                startButton
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
            .padding(.horizontal, Theme.spacingL)
            .padding(.top, Theme.spacingXL)
            .padding(.bottom, Theme.spacingL)
        }
        .onAppear {
            startLoop()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.spacingXS) {
            Text("¿Cómo respondo?")
                .font(Theme.heroFont)
                .foregroundStyle(Theme.primaryText)

            Text("Te enseño — es súper fácil")
                .font(Theme.subheadFont)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Demo stage

    private var demoStage: some View {
        VStack(spacing: Theme.spacingM) {
            ZStack(alignment: .top) {
                stickerCard
                    .overlay(alignment: .top) {
                        calloutTag
                            .offset(y: -24)
                    }

                fingerHint
                    .offset(x: cardOffsetX, y: 160)
                    .opacity(fingerOpacity)
            }

            demoPillRow
        }
    }

    private var stickerCard: some View {
        BearImage(name: "bear_07")
            .padding(Theme.spacingM)
            .frame(width: 220, height: 260)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Theme.accent.opacity(0.25), lineWidth: 1.2)
            )
            .shadow(color: Theme.accent.opacity(0.18), radius: 18, x: 0, y: 10)
            .offset(x: cardOffsetX)
            .rotationEffect(.degrees(cardOffsetX / 14))
    }

    @ViewBuilder
    private var calloutTag: some View {
        if let value = highlightedValue {
            let color = LikertColorScale.colors[max(0, min(4, value - 1))]
            Text(LikertScaleView.label(for: value))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Capsule().fill(color.gradient))
                .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 4)
                .transition(.scale.combined(with: .opacity))
                .id(value)
        }
    }

    private var fingerHint: some View {
        Image(systemName: "hand.draw.fill")
            .font(.system(size: 38, weight: .bold))
            .foregroundStyle(.white)
            .padding(10)
            .background(Circle().fill(Theme.accent.gradient))
            .shadow(color: Theme.accent.opacity(0.5), radius: 12, x: 0, y: 6)
            .rotationEffect(.degrees(-10))
    }

    // A miniature replica of the real pill row, driven by the same
    // hoveredValue logic so the demo syncs perfectly with the swipe.
    private var demoPillRow: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { value in
                let isActive = highlightedValue == value
                let color = LikertColorScale.colors[value - 1]
                VStack(spacing: 1) {
                    Text("\(value)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isActive ? .white : color)
                    Text(LikertScaleView.label(for: value))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(isActive ? .white : color.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isActive ? AnyShapeStyle(color.gradient) : AnyShapeStyle(color.opacity(0.16)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(isActive ? 0 : 0.45), lineWidth: 1.5)
                )
                .shadow(color: color.opacity(isActive ? 0.45 : 0), radius: isActive ? 8 : 0, x: 0, y: 3)
                .scaleEffect(isActive ? 1.10 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isActive)
            }
        }
        .padding(.horizontal, Theme.spacingM)
    }

    // MARK: - Instructions

    private var instructions: some View {
        CardContainer(style: .glass, padding: Theme.spacingM) {
            VStack(spacing: Theme.spacingS) {
                instructionRow(emoji: "👉", text: "Arrastra al osito a la derecha si te describe")
                instructionRow(emoji: "👈", text: "Arrástralo a la izquierda si no")
                instructionRow(emoji: "☝️", text: "O toca una respuesta del 1 al 5")
            }
        }
    }

    private func instructionRow(emoji: String, text: String) -> some View {
        HStack(spacing: Theme.spacingM) {
            Text(emoji).font(.system(size: 22))
            Text(text)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - CTA

    private var startButton: some View {
        LuminaButton(title: "¡Empezar!", systemImage: "arrow.right", size: .large) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onDismiss()
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: cycle > 0.5)
    }

    // MARK: - Loop math

    private func startLoop() {
        withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: false)) {
            cycle = 1
        }
    }

    // Phase sweep: right → centre → left → centre.
    private var cardOffsetX: CGFloat {
        let p = cycle.truncatingRemainder(dividingBy: 1)
        switch p {
        case ..<0.25: return CGFloat(p / 0.25) * 90
        case ..<0.5:  return 90 - CGFloat((p - 0.25) / 0.25) * 90
        case ..<0.75: return -CGFloat((p - 0.5) / 0.25) * 90
        default:      return -90 + CGFloat((p - 0.75) / 0.25) * 90
        }
    }

    private var fingerOpacity: Double {
        abs(cardOffsetX) < 12 ? 0.0 : 1.0
    }

    private var highlightedValue: Int? {
        let dx = cardOffsetX
        guard abs(dx) > 20 else { return nil }
        let rawStep = (dx / 36).rounded()
        let clampedStep = max(-2, min(2, Int(rawStep)))
        return 3 + clampedStep
    }
}

#Preview {
    SwipeTutorialView {}
}
