import Foundation

/// The canonical list of VIA character strengths used throughout Lumina.
///
/// The 24 strengths are hardcoded (they never change) and looked up by
/// stable `id`. Each `StrengthScore` persisted in SwiftData references
/// one of these IDs as a foreign key.
enum StrengthsCatalog {
    static let all: [Strength] = [
        Strength(id: "creatividad",         nameES: "Creatividad",               iconSF: "lightbulb.fill"),
        Strength(id: "curiosidad",          nameES: "Curiosidad",                iconSF: "magnifyingglass"),
        Strength(id: "juicio",              nameES: "Juicio",                    iconSF: "brain.head.profile"),
        Strength(id: "amor_aprendizaje",    nameES: "Amor por el aprendizaje",   iconSF: "book.fill"),
        Strength(id: "perspectiva",         nameES: "Perspectiva",               iconSF: "eye.fill"),
        Strength(id: "valentia",            nameES: "Valentía",                  iconSF: "shield.fill"),
        Strength(id: "perseverancia",       nameES: "Perseverancia",             iconSF: "figure.walk"),
        Strength(id: "honestidad",          nameES: "Honestidad",                iconSF: "checkmark.seal.fill"),
        Strength(id: "coraje",              nameES: "Coraje",                    iconSF: "flame.fill"),
        Strength(id: "amor",                nameES: "Amor",                      iconSF: "heart.fill"),
        Strength(id: "bondad",              nameES: "Bondad",                    iconSF: "hand.raised.fill"),
        Strength(id: "inteligencia_social", nameES: "Inteligencia Social",       iconSF: "bubble.left.and.bubble.right.fill"),
        Strength(id: "humanidad",           nameES: "Humanidad",                 iconSF: "figure.arms.open"),
        Strength(id: "trabajo_equipo",      nameES: "Trabajo en equipo",         iconSF: "person.3.fill"),
        Strength(id: "justicia",            nameES: "Justicia",                  iconSF: "scalemass.fill"),
        Strength(id: "liderazgo",           nameES: "Liderazgo",                 iconSF: "crown.fill"),
        Strength(id: "perdon",              nameES: "Perdón",                    iconSF: "hand.point.up.fill"),
        Strength(id: "prudencia",           nameES: "Prudencia",                 iconSF: "lock.shield.fill"),
        Strength(id: "autorregulacion",     nameES: "Autorregulación",           iconSF: "slider.horizontal.3"),
        Strength(id: "apreciacion_belleza", nameES: "Apreciación de la belleza", iconSF: "camera.fill"),
        Strength(id: "gratitud",            nameES: "Gratitud",                  iconSF: "hands.sparkles.fill"),
        Strength(id: "esperanza",           nameES: "Esperanza",                 iconSF: "sunrise.fill"),
        Strength(id: "humor",               nameES: "Humor",                     iconSF: "face.smiling.fill"),
        Strength(id: "espiritualidad",      nameES: "Espiritualidad",            iconSF: "sparkles"),
    ]

    private static let byID: [String: Strength] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    /// Looks up a strength by its stable `id`. Returns `nil` if no such
    /// strength exists — only possible if persisted data references a
    /// strength that has been removed from the catalog.
    static func strength(id: String) -> Strength? { byID[id] }
}
