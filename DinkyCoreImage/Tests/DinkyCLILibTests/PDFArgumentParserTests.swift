import DinkyCLILib
import XCTest

final class PDFArgumentParserTests: XCTestCase {
    func testModeAndQuality() throws {
        let r = try DinkyPdfCompressArgParser.parse(["--mode", "preserve", "-q", "high", "x.pdf"])
        XCTAssertEqual(r.options.outputMode, .preserveStructure)
        XCTAssertEqual(r.options.quality, .high)
        XCTAssertEqual(r.paths, ["x.pdf"])
    }

    func testFlattenAliases() throws {
        let r = try DinkyPdfCompressArgParser.parse([
            "--mode", "flatten",
            "--preserve-experimental", "strip",
            "--target-kb", "500",
            "y.pdf",
        ])
        XCTAssertEqual(r.options.outputMode, .flattenPages)
        XCTAssertEqual(r.options.preserveExperimental, .stripNonEssentialStructure)
        XCTAssertEqual(r.options.targetKB, 500)
    }
}
