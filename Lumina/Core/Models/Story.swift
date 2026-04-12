import Foundation
import SwiftData

/// A user-authored narrative tied to a single character strength.
///
/// "Historias" is the journaling feature that lets the user record
/// moments where a strength showed up in their life. Optional photo
/// attachment lives on disk (see `PhotoStore`); only the relative
/// filename is stored here so the SwiftData store stays lean and
/// iCloud-ready.
@Model
final class Story {
    var id: UUID = UUID()

    /// When the story was first saved.
    var createdAt: Date = Date()

    /// Free-form body in Spanish.
    var body: String = ""

    /// The `Strength.id` this story is about.
    var strengthID: String = ""

    /// Filename of the attached photo under `Application Support/Photos/`.
    /// `nil` means no photo. Store only the filename — never an absolute
    /// path — so the app survives iCloud restores and TestFlight reinstalls
    /// where the sandbox root URL changes.
    var photoFilename: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        body: String = "",
        strengthID: String,
        photoFilename: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.body = body
        self.strengthID = strengthID
        self.photoFilename = photoFilename
    }
}
