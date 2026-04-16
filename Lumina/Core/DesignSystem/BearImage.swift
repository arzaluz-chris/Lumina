import SwiftUI

/// Renders one of the 48 teddy bear illustrations from the asset catalog.
///
/// Bears ship with transparent backgrounds (processed via remove.bg so
/// shadows, props, and secondary elements are preserved with soft alpha)
/// and are displayed directly over the screen background in both light
/// and dark mode.
struct BearImage: View {
    let name: String

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}

#Preview("bear_07 light") {
    BearImage(name: "bear_07")
        .padding()
        .background(Theme.background)
}

#Preview("bear_07 dark") {
    BearImage(name: "bear_07")
        .padding()
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
