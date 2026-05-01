import Foundation

private let pdfMaxFileSizeKBMin = 5 * 1024
private let pdfMaxFileSizeKBMax = 25 * 1024

/// Clamps PDF max-size targets to 5–25 MB (matches app presets and manual entry).
public func clampPDFMaxFileSizeKB(_ kb: Int) -> Int {
    min(pdfMaxFileSizeKBMax, max(pdfMaxFileSizeKBMin, kb))
}
