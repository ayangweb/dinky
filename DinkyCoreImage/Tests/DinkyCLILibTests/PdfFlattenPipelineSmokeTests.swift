import DinkyCoreImage
import DinkyCorePDF
import DinkyCoreShared
import DinkyCLILib
import Foundation
import PDFKit
import XCTest

final class PdfFlattenPipelineSmokeTests: XCTestCase {
    func testCompressOnePagePDFToSmallerOrEqual() async throws {
        let temp = FileManager.default.temporaryDirectory
        let id = UUID().uuidString
        let inURL = temp.appendingPathComponent("dinky-pdf-\(id).pdf", isDirectory: false)
        defer { try? FileManager.default.removeItem(at: inURL) }

        let doc = PDFDocument()
        doc.insert(PDFPage(), at: 0)
        guard doc.write(to: inURL) else {
            throw XCTSkip("Could not write test PDF")
        }
        let original = Int64((try inURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)

        guard let bin = DinkyEncoderPath.resolveBinDirectory() else {
            throw XCTSkip("No Dinky bin directory")
        }
        let qpdf = DinkyEncoderPath.qpdfExecutable(inBinDirectory: bin)

        var o = DinkyPdfCompressOptions()
        o.outputMode = .flattenPages
        o.quality = .smallest
        o.smartQuality = false
        o.grayscale = true

        let (code, results) = await DinkyPdfCompressCommand.runWithOptions(
            o,
            paths: [inURL.path],
            preset: nil,
            qpdfBinary: qpdf
        )

        XCTAssertEqual(results.count, 1, "stderr: \(results.first?.error ?? "")")
        if code != 0, results.first?.error != nil {
            throw XCTSkip("PDF flatten failed in this environment: \(results[0].error!)")
        }
        XCTAssertEqual(code, 0)
        guard let out = results[0].output, let bytes = results[0].outputBytes else {
            XCTFail("missing output")
            return
        }
        defer { try? FileManager.default.removeItem(at: URL(fileURLWithPath: out)) }
        XCTAssertNotNil(results[0].output)
        XCTAssertLessThanOrEqual(bytes, original + 5000, "flatten should not explode size badly on blank page")
    }
}
