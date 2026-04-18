import Foundation
import UIKit

/// File-based storage for Story photo attachments.
///
/// Photos live as JPEGs under `Application Support/Photos/<uuid>.jpg`.
/// SwiftData stores only the relative filename so the SwiftData blob
/// stays lean and the app survives iCloud/TestFlight re-installs where
/// the sandbox root URL changes.
enum PhotoStore {
    /// Persisted error surface. Kept minimal on purpose — callers just
    /// need to know the operation failed.
    enum Error: Swift.Error {
        case directoryUnavailable
        case encodingFailed
    }

    /// The `Photos/` directory inside the app's Application Support
    /// container. Created on first access.
    private static func photosDirectory() throws -> URL {
        let fm = FileManager.default
        guard let appSupport = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            throw Error.directoryUnavailable
        }
        let photosURL = appSupport.appendingPathComponent("Photos", isDirectory: true)
        if !fm.fileExists(atPath: photosURL.path) {
            try fm.createDirectory(at: photosURL, withIntermediateDirectories: true)
        }
        return photosURL
    }

    /// Re-encodes `image` as a reasonable-quality JPEG and writes it to
    /// disk. Returns the filename (not the absolute URL) to be stored
    /// on `Story.photoFilename`.
    @discardableResult
    static func save(_ image: UIImage) throws -> String {
        let scaled = image.downscaled(maxDimension: 2048)
        guard let data = scaled.jpegData(compressionQuality: 0.85) else {
            throw Error.encodingFailed
        }
        let filename = "\(UUID().uuidString).jpg"
        let url = try photosDirectory().appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return filename
    }

    static func loadImage(filename: String) -> UIImage? {
        guard let dir = try? photosDirectory() else { return nil }
        let url = dir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(filename: String) {
        guard let dir = try? photosDirectory() else { return }
        let url = dir.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}

private extension UIImage {
    /// Returns a copy scaled so that the longer edge is at most `maxDimension`
    /// points, preserving aspect ratio. Returns `self` if already smaller.
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longer = max(size.width, size.height)
        guard longer > maxDimension else { return self }
        let ratio = maxDimension / longer
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
