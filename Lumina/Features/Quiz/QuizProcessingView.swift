import SwiftUI

/// Intermediate "processing" screen shown after the quiz completes.
/// Creates anticipation by displaying a pulsing bear mascot and rotating
/// motivational text before revealing the results.
///
/// Redesign (2026-04-17): the bear is wrapped in a soft radial glow, the
/// progress bar uses ``LuminaProgressBar`` in gold, and the backdrop uses
/// the hero gradient so this transitions smoothly from the quiz.
struct QuizProcessingView: View {
    let onFinished: () -> Void

    @State private var bearScale: CGFloat = 0.9
    @State private var textIndex = 0
    @State private var progressValue: Double = 0
    @State private var appeared = false
    @State private var glowOpacity: Double = 0

    private let bearAsset = "bear_\(String(format: "%02d", Int.random(in: 1...48)))"

    private let messages = [
        "Analizando tus respuestas…",
        "Calculando tus fortalezas…",
        "Preparando tu perfil…",
        "Casi listo…",
    ]

    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.gold.opacity(0.35), Theme.gold.opacity(0)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 200
                        )
                    )
                    .frame(width: 340, height: 340)
                    .opacity(glowOpacity)

                BearImage(name: bearAsset)
                    .frame(maxHeight: 220)
                    .scaleEffect(bearScale)
                    .luminaShadow(Theme.shadowElevated)
            }

            VStack(spacing: Theme.spacingM) {
                Text(messages[textIndex])
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: textIndex)

                LuminaProgressBar(progress: progressValue, tint: Theme.gold, height: 12)
                    .padding(.horizontal, Theme.spacingXL)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.heroGradient.ignoresSafeArea())
        .onAppear {
            guard !appeared else { return }
            appeared = true
            startAnimations()
        }
    }

    private func startAnimations() {
        // Glow fade-in
        withAnimation(.easeOut(duration: 0.7)) {
            glowOpacity = 1.0
        }

        // Bear pulse
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            bearScale = 1.05
        }

        // Progress bar
        withAnimation(.easeInOut(duration: 2.5)) {
            progressValue = 1.0
        }

        // Rotate text
        for i in 1..<messages.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.7) {
                textIndex = i
            }
        }

        // Finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onFinished()
        }
    }
}

#Preview {
    QuizProcessingView(onFinished: {})
}
