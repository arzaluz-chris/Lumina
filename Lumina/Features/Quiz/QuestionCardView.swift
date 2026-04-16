import SwiftUI

/// A quiz question laid out Tinder-style: the bear sits inside a large
/// draggable card that dominates the screen, the question sits below it,
/// and the Likert pill row is pinned at the bottom. A horizontal swipe
/// on the card previews a Likert value on the pill row AND on a floating
/// colored callout above the card, so the user always sees the current
/// answer clearly — even in light mode. Tap on a pill also commits, with
/// a brief highlight so the user sees their pick before the fly-away.
struct QuestionCardView: View {
    let question: Question
    let onAnswer: (Int) -> Void

    @State private var offset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var cardOpacity: Double = 1
    @State private var cardScale: Double = 1
    @State private var hoveredValue: Int?

    // Horizontal drag geometry. Each `stepWidth` of horizontal
    // translation advances the hovered Likert value by one step from the
    // neutral midpoint (3). Once the user has dragged past
    // `hoverActivation`, the matching pill lights up and releasing on any
    // non-neutral value commits the answer.
    private let stepWidth: CGFloat = 36
    private let hoverActivation: CGFloat = 20

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            Spacer(minLength: 0)

            stickerCard
                .padding(.horizontal, Theme.spacingM)
                .overlay(alignment: .top) {
                    callout
                        .offset(y: -28)
                }

            Text(question.textES)
                .font(Theme.subheadFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.primaryText)
                .padding(.horizontal, Theme.spacingL)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            LikertScaleView(hoveredValue: $hoveredValue) { points in
                // Brief highlight so the user sees their pick before the
                // card flies away.
                hoveredValue = points
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                    flyAway(then: points)
                }
            }
            .padding(.horizontal, Theme.spacingL)
            .padding(.bottom, Theme.spacingM)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.impact(weight: .light), trigger: hoveredValue)
    }

    // A soft elevated card behind the bear gives a visual handle the
    // user can grab, and its edges rotate with the drag for rich
    // tactile feedback.
    private var stickerCard: some View {
        BearImage(name: question.bearAsset)
            .padding(Theme.spacingL)
            .frame(maxWidth: .infinity)
            .aspectRatio(0.82, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
            .offset(offset)
            .rotationEffect(.degrees(cardRotation))
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .gesture(dragGesture)
    }

    // Floating colored callout that appears above the card while the
    // user drags, showing which answer they're currently about to pick.
    // Uses the same color scale as the pills, so the drag feedback is
    // legible in both light and dark mode regardless of card position.
    @ViewBuilder
    private var callout: some View {
        if let value = hoveredValue {
            let color = LikertColorScale.colors[max(0, min(4, value - 1))]
            Text(LikertScaleView.label(for: value))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(color)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: color.opacity(0.45), radius: 14, x: 0, y: 6)
                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                .transition(.scale(scale: 0.5).combined(with: .opacity))
                .id(value)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
                cardRotation = Double(value.translation.width / 28)
                let newValue = computeHoveredValue(for: value.translation.width)
                if newValue != hoveredValue {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        hoveredValue = newValue
                    }
                }
            }
            .onEnded { _ in
                if let committed = hoveredValue, committed != 3 {
                    flyAway(then: committed)
                    return
                }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    offset = .zero
                    cardRotation = 0
                    hoveredValue = nil
                }
            }
    }

    private func computeHoveredValue(for dx: CGFloat) -> Int? {
        guard abs(dx) > hoverActivation else { return nil }
        let rawStep = (dx / stepWidth).rounded()
        let clampedStep = max(-2, min(2, Int(rawStep)))
        return 3 + clampedStep
    }

    private func flyAway(then points: Int) {
        let direction: CGFloat = points >= 4 ? 1 : (points <= 2 ? -1 : 0)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            offset = CGSize(width: direction * 500, height: -200)
            cardScale = 0.8
            cardOpacity = 0
            cardRotation = Double(direction) * 12 + Double.random(in: -4...4)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onAnswer(points)
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        QuestionCardView(
            question: QuestionsCatalog.all[0],
            onAnswer: { _ in }
        )
    }
}
