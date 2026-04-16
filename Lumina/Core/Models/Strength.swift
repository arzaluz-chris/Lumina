import Foundation
import SwiftUI

/// A VIA Character Strength.
///
/// The 24 strengths are statically defined in ``StrengthsCatalog`` and
/// referenced across the app by their stable `id`. Persisted data
/// (`StrengthScore`, `Story`) stores these IDs as foreign keys so renaming
/// a display label never breaks historical results.
struct Strength: Identifiable, Hashable, Sendable {
    /// Stable snake_case identifier, e.g. `"creatividad"`.
    let id: String

    /// Display name in Spanish.
    let nameES: String

    /// SF Symbol system name rendered in list rows and detail headers.
    let iconSF: String

    /// The VIA virtue category color for this strength.
    var categoryColor: Color { Theme.categoryColor(for: id) }

    /// The VIA virtue category for this strength.
    var virtueCategory: Theme.VirtueCategory { Theme.virtueCategory(for: id) }
}
