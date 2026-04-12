import SwiftUI

/// A single quiz question: mascot illustration, question text, and the
/// Likert scale beneath.
struct QuestionCardView: View {
    let question: Question
    let onAnswer: (Int) -> Void

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            BearImage(name: question.bearAsset)
                .frame(maxHeight: 180)
                .padding(.horizontal, Theme.spacingL)

            Text(question.textES)
                .font(Theme.subheadFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.primaryText)
                .padding(.horizontal, Theme.spacingL)
                .fixedSize(horizontal: false, vertical: true)

            LikertScaleView(onSelect: onAnswer)
                .padding(.horizontal, Theme.spacingL)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    QuestionCardView(
        question: QuestionsCatalog.all[0],
        onAnswer: { _ in }
    )
    .padding()
    .background(Theme.background)
}
