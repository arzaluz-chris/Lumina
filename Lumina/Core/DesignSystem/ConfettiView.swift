import SwiftUI

/// A lightweight, dependency-free confetti celebration rendered with SwiftUI
/// `Canvas` + `TimelineView`. Play when the user completes a milestone
/// (quiz completion, saving their first story, etc.).
///
/// Each particle is a small colored rounded rectangle that falls with gravity
/// and spins. When `trigger` changes, a fresh burst is spawned. The view
/// fills its container (use inside a ZStack behind the celebration content).
struct ConfettiView: View {
    /// Toggling this value spawns a new burst of particles.
    let trigger: Int
    /// How many particles per burst.
    var particleCount: Int = 90
    /// How long the effect lasts before fading out, in seconds.
    var duration: Double = 2.2
    /// Palette of particle colors.
    var colors: [Color] = [
        Theme.gold,
        Theme.accent,
        Theme.lavender,
        Theme.success,
        Theme.warning,
        Color.pink,
        Color.mint
    ]

    @State private var particles: [Particle] = []
    @State private var burstStartedAt: Date = .distantPast
    @State private var containerWidth: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Particle: Identifiable {
        let id = UUID()
        var origin: CGPoint
        var velocity: CGVector
        var angularVelocity: Double
        var rotation: Double
        var size: CGFloat
        var color: Color
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, _ in
                    guard !particles.isEmpty else { return }
                    let elapsed = timeline.date.timeIntervalSince(burstStartedAt)
                    let life = max(0, 1 - elapsed / duration)
                    guard life > 0 else { return }

                    for particle in particles {
                        let dx = particle.velocity.dx * CGFloat(elapsed)
                        // Gravity accelerates downward over time.
                        let dy = particle.velocity.dy * CGFloat(elapsed) + 0.5 * 700 * CGFloat(elapsed * elapsed)
                        let x = particle.origin.x + dx
                        let y = particle.origin.y + dy
                        let rotation = particle.rotation + particle.angularVelocity * elapsed

                        var transform = context
                        transform.translateBy(x: x, y: y)
                        transform.rotate(by: .radians(rotation))
                        transform.opacity = life
                        let rect = CGRect(
                            x: -particle.size / 2,
                            y: -particle.size / 2,
                            width: particle.size,
                            height: particle.size * 0.45
                        )
                        let path = Path(roundedRect: rect, cornerRadius: 2, style: .continuous)
                        transform.fill(path, with: .color(particle.color))
                    }
                }
            }
            .onAppear { containerWidth = geo.size.width }
            .onChange(of: geo.size.width) { _, new in containerWidth = new }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            guard !reduceMotion, trigger > 0 else { return }
            spawnBurst()
        }
    }

    private func spawnBurst() {
        let width = max(containerWidth, 320)
        let originY: CGFloat = -20
        particles = (0..<particleCount).map { _ in
            let angle = Double.random(in: (-.pi * 0.85)...(-.pi * 0.15)) // upward-ish
            let speed = Double.random(in: 180...380)
            return Particle(
                origin: CGPoint(x: .random(in: 0...width), y: originY),
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                angularVelocity: .random(in: -6...6),
                rotation: .random(in: 0...(.pi * 2)),
                size: .random(in: 8...14),
                color: colors.randomElement() ?? Theme.accent
            )
        }
        burstStartedAt = Date()

        // Clear after duration so the view doesn't keep redrawing invisible particles.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            particles.removeAll()
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        Text("Tap to celebrate")
            .font(Theme.headlineFont)
        ConfettiView(trigger: 1)
    }
}
