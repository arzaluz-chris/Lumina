import SwiftUI

/// Launch splash screen with a random bear mascot and the Lumina brand.
/// Fades out automatically after a brief animated reveal.
struct SplashView: View {
    @Binding var isFinished: Bool

    @State private var bearScale: CGFloat = 0.8
    @State private var bearOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    private let bearAsset = "bear_\(String(format: "%02d", Int.random(in: 1...48)))"

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: Theme.spacingL) {
                BearImage(name: bearAsset)
                    .frame(maxHeight: 220)
                    .scaleEffect(bearScale)
                    .opacity(bearOpacity)

                Text("Lumina")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.accent)
                    .opacity(titleOpacity)
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 80)
                        .offset(x: shimmerOffset)
                        .mask(
                            Text("Lumina")
                                .font(.system(size: 52, weight: .black, design: .rounded))
                        )
                    )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                bearScale = 1.0
                bearOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                titleOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.2).delay(0.5)) {
                shimmerOffset = 200
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
