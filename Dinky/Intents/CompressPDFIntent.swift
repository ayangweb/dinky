import AppIntents
import Foundation

struct CompressPDFIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource(
        "Compress PDFs",
        comment: "Shortcuts app: PDF intent title."
    )
    static var description = IntentDescription(
        LocalizedStringResource(
            "Compresses PDF files using Dinky and returns the compressed versions. Uses preserve vs flatten, flatten quality, grayscale, and strip metadata from the app’s Settings.",
            comment: "Shortcuts app: PDF intent description."
        ),
        categoryName: LocalizedStringResource("PDF", comment: "Shortcuts app: PDF intent category.")
    )

    @Parameter(
        title: LocalizedStringResource("PDFs", comment: "Shortcuts: PDFs parameter title."),
        description: LocalizedStringResource("The PDF files to compress.", comment: "Shortcuts: PDFs parameter description.")
    )
    var pdfs: [IntentFile]

    static var parameterSummary: some ParameterSummary {
        Summary("Compress \(\.$pdfs)")
    }

    func perform() async throws -> some ReturnsValue<[IntentFile]> {
        let settings = DinkyPreferences.pdfCompressionSettingsForIntent()
        var results: [IntentFile] = []

        for pdf in pdfs {
            let srcURL = URL(fileURLWithPath: pdf.filename)
            let ext = srcURL.pathExtension.isEmpty ? "pdf" : srcURL.pathExtension
            let stem = srcURL.deletingPathExtension().lastPathComponent.isEmpty
                ? String(localized: "document", comment: "Default filename stem for Shortcuts PDF output when source has no name.")
                : srcURL.deletingPathExtension().lastPathComponent

            let tmpIn = FileManager.default.temporaryDirectory
                .appendingPathComponent("dinky_pdf_intent_\(UUID().uuidString)")
                .appendingPathExtension(ext)
            let tmpOut = FileManager.default.temporaryDirectory
                .appendingPathComponent("dinky_pdf_intent_\(UUID().uuidString)")
                .appendingPathExtension("pdf")

            try pdf.data.write(to: tmpIn)
            defer { try? FileManager.default.removeItem(at: tmpIn) }

            let result = try await CompressionService.shared.compressPDF(
                source: tmpIn,
                outputMode: settings.outputMode,
                quality: settings.quality,
                grayscale: settings.grayscale,
                stripMetadata: settings.stripMetadata,
                outputURL: tmpOut,
                preserveExperimental: settings.preserveExperimental
            )
            defer { try? FileManager.default.removeItem(at: result.outputURL) }

            let outData = try Data(contentsOf: result.outputURL)
            let outFilename = stem + ".pdf"
            results.append(IntentFile(data: outData, filename: outFilename, type: .init(filenameExtension: "pdf")))
        }

        return .result(value: results)
    }
}
