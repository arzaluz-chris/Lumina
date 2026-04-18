import SwiftUI

/// A reusable shimmer highlight that sweeps across a view once or repeatedly.
///
/// Use for splash/hero titles, "new" badges, and loading skeletons. Respects
/// `accessibilityReduceMotion` — when enabled, shimmer is skipped and the
/// base view is shown unchanged.
struct ShimmerModifier: ViewModifier {
    /// Total duration of a single shimmer sweep (seconds).
    var duration: Double = 1.4
    /// Seconds between sweeps when `repeats` is true.
    var restBetweenSweeps: Double = 1.2
    /// Whether to loop indefinitely.
    var repeats: Bool = false
    /// Tint of the shimmer streak. Use white for dark backgrounds and
    /// accent-tinted white for light backgrounds.
    var highlight: Color = Color.white.opacity(0.75)

    @State private var phase: CGFloat = -1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .overlay(
                    GeometryReader { geo in
                        let width = geo.size.width
                        LinearGradient(
                            colors: [
                                .clear,
                                highlight.opacity(0.0),
                                highlight.opacity(0.55),
                                highlight.opacity(0.0),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: width * 2)
                        .offset(x: phase * width)
                        .blendMode(.plusLighter)
                    }
                )
                .mask(content)
                .task {
                    await runShimmer()
                }
        }
    }

    private func runShimmer() async {
        if repeats {
            while !Task.isCancelled {
                phase = -1.0
                withAnimation(.easeInOut(duration: duration)) { phase = 1.0 }
                let nsec = UInt64((duration + restBetweenSweeps) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nsec)
            }
        } else {
            phase = -1.0
            withAnimation(.easeInOut(duration: duration)) { phase = 1.0 }
        }
    }
}

extension View {
    /// Adds a single-sweep shimmer effect (fires once on appear).
    func shimmerOnce(duration: Double = 1.4, highlight: Color = Color.white.opacity(0.75)) -> some View {
        modifier(ShimmerModifier(duration: duration, repeats: false, highlight: highlight))
    }

    /// Adds a repeating shimmer effect that continues indefinitely.
    func shimmerRepeating(duration: Double = 1.4, restBetweenSweeps: Double = 1.2, highlight: Color = Color.white.opacity(0.75)) -> some View {
        modifier(ShimmerModifier(duration: duration, restBetweenSweeps: restBetweenSweeps, repeats: true, highlight: highlight))
    }
}
