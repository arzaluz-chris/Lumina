import SwiftUI

/// Central design tokens for Lumina — colors, typography, spacing, radius.
///
/// Using a namespace enum (rather than scattered `Color.init` calls) means
/// a rebrand is a one-file change. All colors are backed by Asset Catalog
/// entries with explicit light/dark appearances so dark mode works without
/// per-view conditionals.
enum Theme {
    // MARK: Colors

    /// Brand accent — used for primary buttons, selected states, progress
    /// bars, and strength icons. Warm teal in light mode, brighter cyan
    /// in dark mode to maintain contrast.
    static let accent = Color.accentColor

    /// Screen background. Warm cream in light mode, deep blue-black in dark.
    static let background = Color("LuminaBackground")

    /// Elevated card/surface background. White in light, dark gray in dark.
    static let cardBackground = Color("LuminaCard")

    /// Primary text — always uses the system label color so Dynamic Type
    /// and accessibility appearance settings kick in automatically.
    static let primaryText = Color.primary

    /// Secondary text for descriptions, metadata, etc.
    static let secondaryText = Color.secondary

    // MARK: Typography

    /// Prominent screen titles.
    static let titleFont: Font = .system(.largeTitle, design: .rounded, weight: .bold)

    /// Section headers.
    static let headlineFont: Font = .system(.title2, design: .rounded, weight: .semibold)

    /// Rounded subheads used in question cards and labels.
    static let subheadFont: Font = .system(.headline, design: .rounded, weight: .medium)

    /// Default body copy.
    static let bodyFont: Font = .system(.body, design: .rounded)

    /// Metadata / footnote.
    static let captionFont: Font = .system(.caption, design: .rounded)

    // MARK: Spacing

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: Radius

    static let cardRadius: CGFloat = 24
    static let buttonRadius: CGFloat = 18
    static let chipRadius: CGFloat = 14
}
