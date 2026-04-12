import SwiftUI

/// Renders one of the 48 teddy bear illustrations from the asset catalog.
///
/// Thin wrapper so view code doesn't have to repeat the `.resizable()` /
/// `.scaledToFit()` pair and so we have one place to add (for example)
/// a subtle drop shadow or a placeholder if the asset ever fails to load.
struct BearImage: View {
    let name: String

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}

#Preview("bear_01") {
    BearImage(name: "bear_01")
        .padding()
        .background(Theme.background)
}
