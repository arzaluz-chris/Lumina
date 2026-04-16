import SwiftUI

/// A single page in the premium onboarding flow.
/// Displays a bear mascot with glassmorphic content card and staggered
/// entrance animations for a premium feel.
struct OnboardingPageView: View {
    let bearAsset: String
    let title: String
    let subtitle: String
    var features: [(icon: String, title: String, description: String)] = []
    var accentOverride: Color? = nil
    var isLastPage: Bool = false

    @State private var bearAppeared = false
    @State private var textAppeared = false
    @State private var featuresAppeared = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Bear mascot — large and prominent
            BearImage(name: bearAsset)
                .frame(maxHeight: 280)
                .scaleEffect(bearAppeared ? 1.0 : 0.6)
                .opacity(bearAppeared ? 1.0 : 0)
                .scaleEffect(isLastPage ? pulseScale : 1.0)

            Spacer()
                .frame(height: Theme.spacingL)

            // Glassmorphic content card
            VStack(spacing: Theme.spacingM) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(accentOverride ?? Theme.accent)
                    .multilineTextAlignment(.center)
                    .opacity(textAppeared ? 1.0 : 0)
                    .offset(y: textAppeared ? 0 : 16)

                Text(subtitle)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .opacity(textAppeared ? 1.0 : 0)
                    .offset(y: textAppeared ? 0 : 10)

                if !features.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.spacingS + 2) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            HStack(alignment: .center, spacing: Theme.spacingM) {
                                Image(systemName: feature.icon)
                                    .font(.title3)
                                    .foregroundStyle(accentOverride ?? Theme.accent)
                                    .frame(width: 28, height: 28)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(feature.title)
                                        .font(Theme.subheadFont)
                                    Text(feature.description)
                                        .font(Theme.captionFont)
                                        .foregroundStyle(Theme.secondaryText)
                                }
                            }
                            .opacity(featuresAppeared ? 1.0 : 0)
                            .offset(y: featuresAppeared ? 0 : 14)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1 + 0.15),
                                value: featuresAppeared
                            )
                        }
                    }
                    .padding(.top, Theme.spacingXS)
                }
            }
            .padding(Theme.spacingL)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: (accentOverride ?? Theme.accent).opacity(0.06), radius: 24, x: 0, y: 12)
            .padding(.horizontal, Theme.spacingL)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.05)) {
                bearAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25)) {
                textAppeared = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) {
                featuresAppeared = true
            }
            if isLastPage {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
                    pulseScale = 1.06
                }
            }
        }
        .onDisappear {
            bearAppeared = false
            textAppeared = false
            featuresAppeared = false
            pulseScale = 1.0
        }
    }
}
