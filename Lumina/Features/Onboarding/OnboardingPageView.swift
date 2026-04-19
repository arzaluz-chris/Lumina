import SwiftUI

/// A single page in the premium onboarding flow.
/// Displays a bear mascot with glassmorphic content card and staggered
/// entrance animations for a premium feel.
///
/// Redesign (2026-04-17): features use ``CardContainer`` with outlined style,
/// glass content card powered by ``CardContainer/.glass``, and Duolingo-style
/// big rounded title.
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

    private var accent: Color { accentOverride ?? Theme.accent }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Theme.spacingL)

            // Bear mascot — large and prominent, with a soft glow halo.
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.22), accent.opacity(0)],
                            center: .center,
                            startRadius: 8,
                            endRadius: 200
                        )
                    )
                    .frame(width: 340, height: 340)
                    .blur(radius: 4)
                    .opacity(bearAppeared ? 1 : 0)

                BearImage(name: bearAsset)
                    .frame(maxHeight: 280)
                    .scaleEffect(bearAppeared ? 1.0 : 0.6)
                    .opacity(bearAppeared ? 1.0 : 0)
                    .scaleEffect(isLastPage ? pulseScale : 1.0)
                    .luminaShadow(Theme.shadowElevated)
            }

            Spacer(minLength: Theme.spacingL)

            // Glassmorphic content card
            CardContainer(style: .glass, cornerRadius: Theme.heroRadius) {
                VStack(spacing: Theme.spacingM) {
                    Text(title)
                        .font(Theme.heroFont)
                        .foregroundStyle(accent)
                        .multilineTextAlignment(.center)
                        .opacity(textAppeared ? 1.0 : 0)
                        .offset(y: textAppeared ? 0 : 16)
                        .frame(maxWidth: .infinity)

                    Text(subtitle)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .opacity(textAppeared ? 1.0 : 0)
                        .offset(y: textAppeared ? 0 : 10)
                        .frame(maxWidth: .infinity)

                    ReadAloudButton(text: "\(title). \(subtitle)", tint: accent, size: .small)
                        .opacity(textAppeared ? 1.0 : 0)

                    if !features.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.spacingM) {
                            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                                featureRow(feature, index: index)
                            }
                        }
                        .padding(.top, Theme.spacingS)
                    }
                }
            }
            .padding(.horizontal, Theme.spacingL)
            .shadow(color: accent.opacity(0.08), radius: 24, x: 0, y: 12)

            Spacer(minLength: Theme.spacingL)
        }
        .onAppear(perform: animateIn)
        .onDisappear(perform: resetAppearance)
    }

    @ViewBuilder
    private func featureRow(_ feature: (icon: String, title: String, description: String), index: Int) -> some View {
        HStack(alignment: .center, spacing: Theme.spacingM) {
            Image(systemName: feature.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(accent.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.primaryText)
                Text(feature.description)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .opacity(featuresAppeared ? 1.0 : 0)
        .offset(y: featuresAppeared ? 0 : 14)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08 + 0.15),
            value: featuresAppeared
        )
    }

    private func animateIn() {
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

    private func resetAppearance() {
        bearAppeared = false
        textAppeared = false
        featuresAppeared = false
        pulseScale = 1.0
    }
}
