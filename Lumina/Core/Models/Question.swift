import Foundation

/// A single quiz item presented to the user.
///
/// Questions are statically defined in ``QuestionsCatalog`` in the exact
/// order the client specified (1..48). Each question is paired with a
/// dedicated mascot illustration stored in `Assets.xcassets/Bears/`.
struct Question: Identifiable, Hashable, Sendable {
    /// Canonical position in the client's question document (1...48).
    ///
    /// This is **not** the presentation order — the quiz shuffles questions
    /// at runtime — but it is the stable identifier used when storing
    /// answers so that results remain meaningful across sessions.
    let id: Int

    /// The question text in Spanish, exactly as the client authored it.
    let textES: String

    /// The `Strength.id` this question contributes to.
    let strengthID: String

    /// The image set name in `Assets.xcassets/Bears/` (e.g. `"bear_01"`).
    let bearAsset: String
}
