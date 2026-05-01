import DinkyCLILib
import XCTest

final class VideoArgumentParserTests: XCTestCase {
    func testDefaults() throws {
        let r = try DinkyVideoCompressArgParser.parse(["a.mov"])
        XCTAssertEqual(r.paths, ["a.mov"])
        XCTAssertTrue(r.options.smartQuality)
    }

    func testCodecAndQuality() throws {
        let r = try DinkyVideoCompressArgParser.parse(["--codec", "hevc", "-q", "low", "--no-smart-quality", "v.mp4"])
        XCTAssertEqual(r.options.codec, .hevc)
        XCTAssertEqual(r.options.quality, .medium)
        XCTAssertFalse(r.options.smartQuality)
    }

    func testProresRejected() {
        XCTAssertThrowsError(try DinkyVideoCompressArgParser.parse(["--codec", "prores", "a.mov"])) { err in
            let e = err as? DinkyCLIParseError
            XCTAssertTrue(e?.message.contains("ProRes") == true)
        }
    }
}
