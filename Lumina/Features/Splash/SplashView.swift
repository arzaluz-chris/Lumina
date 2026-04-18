import SwiftUI

/// Launch splash screen with a random bear mascot and the Lumina brand.
/// Fades out automatically after a brief animated reveal.
///
/// Redesign (2026-04-17): hero gradient backdrop, layered glow behind the
/// bear, shimmer delegated to ``ShimmerModifier``.
struct SplashView: View {
    @Binding var isFinished: Bool

    @State private var bearScale: CGFloat = 0.82
    @State private var bearOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.6
    @State private var glowOpacity: Double = 0

    private let bearAsset = "bear_\(String(format: "%02d", Int.random(in: 1...48)))"

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()

            VStack(spacing: Theme.spacingXL) {
                ZStack {
                    // Soft radial glow behind the bear.
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.accent.opacity(0.35), Theme.accent.opacity(0.0)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 220
                            )
                        )
                        .frame(width: 360, height: 360)
                        .scaleEffect(glowScale)
                        .opacity(glowOpacity)
                        .blur(radius: 8)

                    BearImage(name: bearAsset)
                        .frame(maxHeight: 240)
                        .scaleEffect(bearScale)
                        .opacity(bearOpacity)
                        .luminaShadow(Theme.shadowElevated)
                }

                VStack(spacing: Theme.spacingS) {
                    Text("Lumina")
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.accent)
                        .opacity(titleOpacity)
                        .shimmerOnce(duration: 1.4)

                    Text("Descubre tus fortalezas")
                        .font(Theme.subheadFont)
                        .foregroundStyle(Theme.secondaryText)
                        .opacity(titleOpacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.68)) {
                bearScale = 1.0
                bearOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.9).delay(0.1)) {
                glowScale = 1.0
                glowOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.35)) {
                titleOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    isFinished = true
                }
            }
        }
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
