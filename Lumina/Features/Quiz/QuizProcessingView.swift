import SwiftUI

/// Intermediate "processing" screen shown after the quiz completes.
/// Creates anticipation by displaying a pulsing bear mascot and rotating
/// motivational text before revealing the results.
struct QuizProcessingView: View {
    let onFinished: () -> Void

    @State private var bearScale: CGFloat = 0.9
    @State private var textIndex = 0
    @State private var progressValue: Double = 0
    @State private var appeared = false

    private let bearAsset = "bear_\(String(format: "%02d", Int.random(in: 1...48)))"

    private let messages = [
        "Analizando tus respuestas...",
        "Calculando tus fortalezas...",
        "Preparando tu perfil...",
        "Casi listo...",
    ]

    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()

            BearImage(name: bearAsset)
                .frame(maxHeight: 200)
                .scaleEffect(bearScale)

            VStack(spacing: Theme.spacingS) {
                Text(messages[textIndex])
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.primaryText)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: textIndex)

                ProgressView(value: progressValue)
                    .tint(Theme.accent)
                    .padding(.horizontal, Theme.spacingXL * 2)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            guard !appeared else { return }
            appeared = true
            startAnimations()
        }
    }

    private func startAnimations() {
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
