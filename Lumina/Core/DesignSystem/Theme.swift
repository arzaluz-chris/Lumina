import SwiftUI

/// Central design tokens for Lumina — colors, typography, spacing, radius,
/// animations, shadows.
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

    /// Alias used across the redesigned UI. Points at the same accent color
    /// so existing call sites keep working.
    static let primary = Color.accentColor

    /// Soft accent tint for chip backgrounds and informational cards.
    static let primarySoft = Color.accentColor.opacity(0.12)

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

    // MARK: - Semantic State Colors

    /// Positive / highest Likert step / completion.
    static let success = Color(red: 0.34, green: 0.69, blue: 0.42)

    /// Positive-leaning Likert step.
    static let successSoft = Color(red: 0.53, green: 0.75, blue: 0.43)

    /// Neutral Likert step.
    static let neutral = Color(red: 0.79, green: 0.70, blue: 0.33)

    /// Cautious / low-confidence Likert step.
    static let warning = Color(red: 0.94, green: 0.58, blue: 0.30)

    /// Negative Likert step / destructive confirmation accent.
    static let danger = Color(red: 0.91, green: 0.39, blue: 0.40)

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

    /// Hero gradient used behind splash / onboarding heroes.
    static let heroGradient = LinearGradient(
        colors: [accent.opacity(0.18), gold.opacity(0.08), background],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
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

        /// A softer tint for card backgrounds where the virtue color would be too saturated.
        var softColor: Color { color.opacity(0.14) }

        /// A linear gradient built from the virtue color, going lighter to darker.
        var gradient: LinearGradient {
            LinearGradient(
                colors: [color.opacity(0.85), color],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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

    /// Hero display text for splash and big achievement moments (34pt rounded heavy).
    static let displayFont: Font = .system(size: 34, weight: .heavy, design: .rounded)

    /// Second-tier hero used on home-style screens (28pt rounded bold).
    static let heroFont: Font = .system(size: 28, weight: .bold, design: .rounded)

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

    /// Monospaced rounded digits for scores and progress numbers.
    static let numericFont: Font = .system(size: 22, weight: .bold, design: .rounded).monospacedDigit()

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Radius

    static let chipRadius: CGFloat = 14
    static let buttonRadius: CGFloat = 18
    static let cardRadius: CGFloat = 24
    static let heroRadius: CGFloat = 32

    // MARK: - Animation presets

    enum AnimationStyle {
        /// Short, crisp interactions (taps, toggles).
        static let snappy: Animation = .spring(response: 0.32, dampingFraction: 0.82)
        /// Standard UI transitions (page changes, card reveals).
        static let smooth: Animation = .spring(response: 0.45, dampingFraction: 0.85)
        /// Playful, with a little overshoot — for celebrations and CTAs.
        static let bouncy: Animation = .spring(response: 0.55, dampingFraction: 0.65)
        /// Subtle fade for content swaps.
        static let fade: Animation = .easeInOut(duration: 0.25)
    }

    // MARK: - Shadows

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    /// Tight card-level shadow.
    static let shadowCard = ShadowStyle(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
    /// Medium elevation for hero/floating elements.
    static let shadowElevated = ShadowStyle(color: .black.opacity(0.10), radius: 20, x: 0, y: 10)
    /// Strong, dramatic shadow for modals and sheets.
    static let shadowDramatic = ShadowStyle(color: .black.opacity(0.18), radius: 30, x: 0, y: 16)
}

// MARK: - Shadow modifier

extension View {
    /// Applies one of the semantic shadow tokens from ``Theme``.
    func luminaShadow(_ style: Theme.ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
