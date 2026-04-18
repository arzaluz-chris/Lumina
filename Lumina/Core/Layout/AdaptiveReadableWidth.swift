import SwiftUI

/// Clamps content to a readable column width on regular size classes
/// (iPad, landscape iPhone in some split modes) while letting it span
/// the full width on compact size classes (standard iPhone).
///
/// Applied to hero views, scroll content, and forms across the app so
/// the app feels at home on an iPad without stretching Likert scales,
/// chart tooltips, or chat bubbles across 12 inches of screen.
struct AdaptiveReadableWidth: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Maximum column width when the size class is regular. Matches
    /// Apple's `.readableContentWidth` target at typical iPad sizes.
    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        if sizeClass == .regular {
            HStack {
                Spacer(minLength: 0)
                content
                    .frame(maxWidth: maxWidth)
                Spacer(minLength: 0)
            }
        } else {
            content
        }
    }
}

extension View {
    /// Clamps the view to a readable column width on iPad / regular
    /// size class. On compact size class it's a no-op.
    func adaptiveReadableWidth(maxWidth: CGFloat = 680) -> some View {
        modifier(AdaptiveReadableWidth(maxWidth: maxWidth))
    }
}
