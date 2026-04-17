import AppIntents
import Foundation

struct CompressImagesIntent: AppIntent {
    static var title: LocalizedStringResource = "Compress Images"
    static var description = IntentDescription(
        "Compresses image files using Dinky and returns the compressed versions.",
        categoryName: "Images"
    )

    @Parameter(title: "Images", description: "The image files to compress.")
    var images: [IntentFile]

    @Parameter(title: "Format", description: "Output format for compressed images.", default: .webp)
    var format: CompressionFormatEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Compress \(\.$images) as \(\.$format)")
    }

    func perform() async throws -> some ReturnsValue<[IntentFile]> {
        let outputFormat = format.compressionFormat
        let goals = CompressionGoals(maxWidth: nil, maxFileSizeKB: nil)
        var results: [IntentFile] = []

        for image in images {
            // IntentFile.filename is non-optional String; use URL to parse extension and stem
            let srcURL = URL(fileURLWithPath: image.filename)
            let ext = srcURL.pathExtension.isEmpty ? "jpg" : srcURL.pathExtension
            let stem = srcURL.deletingPathExtension().lastPathComponent.isEmpty
                ? "image" : srcURL.deletingPathExtension().lastPathComponent

            let tmpIn = FileManager.default.temporaryDirectory
                .appendingPathComponent("dinky_intent_\(UUID().uuidString)")
                .appendingPathExtension(ext)
            let tmpOut = FileManager.default.temporaryDirectory
                .appendingPathComponent("dinky_intent_\(UUID().uuidString)")
                .appendingPathExtension(outputFormat.outputExtension)

            // IntentFile.data is non-throwing
            try image.data.write(to: tmpIn)
            defer { try? FileManager.default.removeItem(at: tmpIn) }

            let result = try await CompressionService.shared.compress(
                source: tmpIn,
                format: outputFormat,
                goals: goals,
                stripMetadata: true,
                outputURL: tmpOut,
                moveToTrash: false,
                smartQuality: false
            )
            defer { try? FileManager.default.removeItem(at: result.outputURL) }

            let outData = try Data(contentsOf: result.outputURL)
            let outFilename = stem + "." + outputFormat.outputExtension
            results.append(IntentFile(data: outData, filename: outFilename,
                                      type: .init(filenameExtension: outputFormat.outputExtension)))
        }

        return .result(value: results)
    }
}

enum CompressionFormatEntity: String, AppEnum {
    case webp, avif, png

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Format")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .webp: "WebP",
        .avif: "AVIF",
        .png:  "PNG",
    ]

    var compressionFormat: CompressionFormat {
        switch self {
        case .webp: return .webp
        case .avif: return .avif
        case .png:  return .png
        }
    }
}
