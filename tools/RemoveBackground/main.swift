// RemoveBackground — one-shot tool to generate bear_NN.png assets for Lumina.
//
// Reads the 48 teddy-bear JPEGs from an input directory, removes the white
// background from those that need it using VNGenerateForegroundInstanceMaskRequest,
// and writes numbered PNGs (`bear_01.png` ... `bear_48.png`) to an output directory.
//
// Files whose name contains "sin fondo" are assumed to be illustrations with a
// non-white background and are re-encoded to PNG without any mask.
//
// Run from Terminal:
//   swift tools/RemoveBackground/main.swift \
//     "$HOME/Downloads/Lumina Assets" \
//     "$(pwd)/tools/out"
//
// macOS 14+ required (Vision foreground instance mask).

import Foundation
import Vision
import CoreImage
import AppKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - Args

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write(Data("Usage: swift main.swift <input-dir> <output-dir>\n".utf8))
    exit(1)
}

let inputDir = URL(fileURLWithPath: arguments[1])
let outputDir = URL(fileURLWithPath: arguments[2])

try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

// MARK: - Helpers

let ciContext = CIContext()

func writePNG(_ ciImage: CIImage, to url: URL) throws {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let cgImage = ciContext.createCGImage(
        ciImage,
        from: ciImage.extent,
        format: .RGBA8,
        colorSpace: colorSpace
    ) else {
        throw NSError(
            domain: "RemoveBackground",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to rasterize CIImage"]
        )
    }
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw NSError(
            domain: "RemoveBackground",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG destination"]
        )
    }
    CGImageDestinationAddImage(destination, cgImage, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(
            domain: "RemoveBackground",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Failed to finalize PNG"]
        )
    }
}

func reencodeJPEGToPNG(source: URL, destination: URL) throws {
    guard let image = NSImage(contentsOf: source),
          let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let pngData = rep.representation(using: .png, properties: [:]) else {
        throw NSError(
            domain: "RemoveBackground",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "Failed to re-encode \(source.lastPathComponent)"]
        )
    }
    try pngData.write(to: destination)
}

func extractQuestionNumber(from filename: String) -> Int? {
    let name = (filename as NSString).deletingPathExtension
    let digits = name.prefix(while: { $0.isNumber })
    return Int(digits)
}

func hasNoBackgroundMarker(_ filename: String) -> Bool {
    let lowered = filename.lowercased()
    return lowered.contains("sin fondo") || lowered.contains("sin-fondo")
}

// MARK: - Main

let allFiles: [URL]
do {
    allFiles = try FileManager.default.contentsOfDirectory(
        at: inputDir,
        includingPropertiesForKeys: nil
    )
    .filter {
        let ext = $0.pathExtension.lowercased()
        return ext == "jpg" || ext == "jpeg"
    }
    .sorted { lhs, rhs in
        let lhsNum = extractQuestionNumber(from: lhs.lastPathComponent) ?? .max
        let rhsNum = extractQuestionNumber(from: rhs.lastPathComponent) ?? .max
        return lhsNum < rhsNum
    }
} catch {
    FileHandle.standardError.write(Data("Failed to list input dir: \(error)\n".utf8))
    exit(1)
}

print("Found \(allFiles.count) JPEG files in \(inputDir.path)")
print("Writing PNGs to \(outputDir.path)")
print(String(repeating: "-", count: 60))

var processed = 0
var keptAsIs = 0
var failed = 0

for fileURL in allFiles {
    let filename = fileURL.lastPathComponent

    guard let num = extractQuestionNumber(from: filename) else {
        print("  SKIP (no leading number): \(filename)")
        continue
    }

    let outputName = String(format: "bear_%02d.png", num)
    let outputURL = outputDir.appendingPathComponent(outputName)

    if hasNoBackgroundMarker(filename) {
        do {
            try reencodeJPEGToPNG(source: fileURL, destination: outputURL)
            print("  [\(String(format: "%02d", num))] \(filename) → \(outputName)  (kept as-is)")
            keptAsIs += 1
        } catch {
            print("  [\(String(format: "%02d", num))] \(filename) → FAILED: \(error)")
            failed += 1
        }
        continue
    }

    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(url: fileURL, options: [:])

    do {
        try handler.perform([request])
        guard let observation = request.results?.first else {
            print("  [\(String(format: "%02d", num))] \(filename) → no subject detected, keeping as-is")
            try reencodeJPEGToPNG(source: fileURL, destination: outputURL)
            keptAsIs += 1
            continue
        }

        let pixelBuffer = try observation.generateMaskedImage(
            ofInstances: observation.allInstances,
            from: handler,
            croppedToInstancesExtent: false
        )
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        try writePNG(ciImage, to: outputURL)
        print("  [\(String(format: "%02d", num))] \(filename) → \(outputName)  (bg removed)")
        processed += 1
    } catch {
        print("  [\(String(format: "%02d", num))] \(filename) → ERROR: \(error.localizedDescription)")
        failed += 1
    }
}

print(String(repeating: "-", count: 60))
print("Done. Background removed: \(processed) · Kept as-is: \(keptAsIs) · Failed: \(failed)")
