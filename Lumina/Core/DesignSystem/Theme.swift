import SwiftUI

/// Central design tokens for Lumina — colors, typography, spacing, radius.
///
/// Using a namespace enum (rather than scattered `Color.init` calls) means
/// a rebrand is a one-file change. All colors are backed by Asset Catalog
/// entries with explicit light/dark appearances so dark mode works without
/// per-view conditionals.
enum Theme {
    // MARK: - Primary Colors

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

    // MARK: - Secondary Colors

    /// Warm amber/gold — used for achievements, highlights, top strengths.
    static let gold = Color("LuminaGold")

    /// Soft lavender — used for growth areas, reflective/secondary cards.
    static let lavender = Color("LuminaLavender")

    // MARK: - Gradients

    /// Primary accent gradient for premium headers and CTAs.
    static let accentGradient = LinearGradient(
        colors: [accent, accent.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Warm gradient for achievement cards and signature strengths.
    static let warmGradient = LinearGradient(
        colors: [gold, accent],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Subtle background gradient for premium screens.
    static let subtleGradient = LinearGradient(
        colors: [background, accent.opacity(0.04)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - VIA Virtue Category Colors

    /// The six VIA virtues, each with a distinct hue for visual grouping.
    enum VirtueCategory: String, CaseIterable, Sendable {
        case wisdom
        case courage
        case humanity
        case justice
        case temperance
        case transcendence

        var color: Color {
            switch self {
            case .wisdom:        Color(red: 0.33, green: 0.38, blue: 0.72)  // indigo
            case .courage:       Color(red: 0.85, green: 0.42, blue: 0.38)  // coral
            case .humanity:      Color(red: 0.84, green: 0.44, blue: 0.58)  // rose
            case .justice:       Color(red: 0.80, green: 0.62, blue: 0.27)  // amber
            case .temperance:    Color(red: 0.42, green: 0.64, blue: 0.49)  // sage
            case .transcendence: Color(red: 0.58, green: 0.44, blue: 0.76)  // violet
            }
        }

        var nameES: String {
            switch self {
            case .wisdom:        "Sabiduría"
            case .courage:       "Coraje"
            case .humanity:      "Humanidad"
            case .justice:       "Justicia"
            case .temperance:    "Templanza"
            case .transcendence: "Trascendencia"
            }
        }
    }

    /// Maps a strength ID to its VIA virtue category.
    static func virtueCategory(for strengthID: String) -> VirtueCategory {
        switch strengthID {
        // Sabiduría
        case "creatividad", "curiosidad", "juicio", "amor_aprendizaje", "perspectiva":
            return .wisdom
        // Coraje
        case "valentia", "perseverancia", "honestidad", "coraje":
            return .courage
        // Humanidad
        case "amor", "bondad", "inteligencia_social", "humanidad":
            return .humanity
        // Justicia
        case "trabajo_equipo", "justicia", "liderazgo":
            return .justice
        // Templanza
        case "perdon", "prudencia", "autorregulacion":
            return .temperance
        // Trascendencia
        case "apreciacion_belleza", "gratitud", "esperanza", "humor", "espiritualidad":
            return .transcendence
        default:
            return .wisdom
        }
    }

    /// Convenience: returns the color for a given strength's VIA category.
    static func categoryColor(for strengthID: String) -> Color {
        virtueCategory(for: strengthID).color
    }

    // MARK: - Typography

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

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: - Radius

    static let cardRadius: CGFloat = 24
    static let buttonRadius: CGFloat = 18
    static let chipRadius: CGFloat = 14
}
