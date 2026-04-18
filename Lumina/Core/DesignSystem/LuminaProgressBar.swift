import SwiftUI

/// Animated progress bar used for the quiz progress indicator, strength rows,
/// and loading phases. Fills smoothly when `progress` changes.
struct LuminaProgressBar: View {
    /// Progress value in 0.0...1.0. Clamped at render time.
    let progress: Double
    /// Bar color. Defaults to the brand accent.
    var tint: Color = Theme.accent
    /// Track background opacity (tint-based).
    var trackOpacity: Double = 0.14
    /// Bar thickness.
    var height: CGFloat = 10
    /// Whether to render a subtle glossy highlight on top of the fill.
    var showsGloss: Bool = true

    private var clamped: Double { max(0, min(1, progress)) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(tint.opacity(trackOpacity))

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(height, geo.size.width * clamped))
                    .animation(Theme.AnimationStyle.smooth, value: clamped)

                if showsGloss {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: max(height, geo.size.width * clamped), height: height * 0.45)
                        .offset(y: -height * 0.2)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: Theme.spacingL) {
        LuminaProgressBar(progress: 0.25)
        LuminaProgressBar(progress: 0.6, tint: Theme.gold, height: 14)
        LuminaProgressBar(progress: 1.0, tint: Theme.success, height: 6)
    }
    .padding()
    .background(Theme.background)
}
