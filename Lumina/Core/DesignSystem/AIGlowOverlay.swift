import SwiftUI

/// Animated multicolor border glow reminiscent of Siri, shown during
/// AI generation. Apply with `.aiGlow(isActive:)`.
/// Adapts intensity for light/dark mode for consistent visibility.
struct AIGlowModifier: ViewModifier {
    let isActive: Bool
    @State private var rotation: Double = 0
    @Environment(\.colorScheme) private var colorScheme

    private var glowColors: [Color] {
        if colorScheme == .dark {
            return [.blue, .purple, .pink, .orange, .yellow, .green, .blue]
        } else {
            // Vivid, bright colors that glow visibly on warm cream
            return [
                Color(red: 0.30, green: 0.50, blue: 1.00),
                Color(red: 0.65, green: 0.35, blue: 0.95),
                Color(red: 0.95, green: 0.35, blue: 0.60),
                Color(red: 0.98, green: 0.55, blue: 0.20),
                Color(red: 0.95, green: 0.80, blue: 0.15),
                Color(red: 0.30, green: 0.80, blue: 0.50),
                Color(red: 0.30, green: 0.50, blue: 1.00),
            ]
        }
    }

    private var lineWidth: CGFloat { colorScheme == .dark ? 3 : 4 }
    private var blurRadius: CGFloat { colorScheme == .dark ? 8 : 6 }
    private var innerLineWidth: CGFloat { colorScheme == .dark ? 1.5 : 3.0 }

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    glowBorder
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isActive)
    }

    private var glowBorder: some View {
        let gradient = AngularGradient(
            colors: glowColors,
            center: .center,
            angle: .degrees(rotation)
        )
        return ZStack {
            // Outer soft glow
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(gradient, lineWidth: lineWidth)
                .blur(radius: blurRadius)

            // Colored shadow for extra light-mode presence
            if colorScheme == .light {
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(gradient, lineWidth: lineWidth)
                    .blur(radius: 20)
                    .opacity(0.7)
            }

            // Inner crisp border
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(gradient, lineWidth: innerLineWidth)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        .transition(.opacity)
    }
}

extension View {
    /// Adds an animated Siri-like multicolor glow border when active.
    func aiGlow(isActive: Bool) -> some View {
        modifier(AIGlowModifier(isActive: isActive))
    }
}
