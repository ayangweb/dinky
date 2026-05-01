import Foundation
import os

/// Structured PDF compression outcomes for Console.app debugging.
public enum PDFCompressionMetrics: Sendable {
    private static let log = Logger(
        subsystem: "dinky",
        category: "PDFMetrics"
    )

    public static let regressionNoteFlattenShouldShrinkTypicalScanPDF = true
    public static let regressionNotePreserveMayShowNoGain = true

    private static let eventPrefix = "pdf_metrics"

    public static func logOutcome(
        outputMode: PDFOutputMode,
        originalBytes: Int64,
        outputBytes: Int64,
        flattenLastResort: Bool,
        flattenUltra: Bool,
        preserveQpdfChain: String? = nil,
        preserveQpdfWinningStep: String? = nil
    ) {
        let saved = originalBytes - outputBytes
        let pct = originalBytes > 0 ? Double(saved) / Double(originalBytes) * 100.0 : 0
        let bailout = flattenUltra ? "ultra" : (flattenLastResort ? "lastResort" : "none")
        if let chain = preserveQpdfChain, let win = preserveQpdfWinningStep {
            log.debug("\(Self.eventPrefix, privacy: .public) outcome mode=\(outputMode.rawValue, privacy: .public) in=\(originalBytes, privacy: .public) out=\(outputBytes, privacy: .public) savedBytes=\(saved, privacy: .public) savedPct=\(String(format: "%.2f", pct), privacy: .public) bailout=\(bailout, privacy: .public) preserveChain=\(chain, privacy: .public) preserveWin=\(win, privacy: .public)")
        } else if let chain = preserveQpdfChain {
            log.debug("\(Self.eventPrefix, privacy: .public) outcome mode=\(outputMode.rawValue, privacy: .public) in=\(originalBytes, privacy: .public) out=\(outputBytes, privacy: .public) savedBytes=\(saved, privacy: .public) savedPct=\(String(format: "%.2f", pct), privacy: .public) bailout=\(bailout, privacy: .public) preserveChain=\(chain, privacy: .public) preserveWin=pdfkit")
        } else {
            log.debug("\(Self.eventPrefix, privacy: .public) outcome mode=\(outputMode.rawValue, privacy: .public) in=\(originalBytes, privacy: .public) out=\(outputBytes, privacy: .public) savedBytes=\(saved, privacy: .public) savedPct=\(String(format: "%.2f", pct), privacy: .public) bailout=\(bailout, privacy: .public)")
        }
    }

    public static func logRejectedOutput(
        outputMode: PDFOutputMode,
        originalBytes: Int64,
        attemptedBytes: Int64,
        reason: String
    ) {
        log.debug("\(Self.eventPrefix, privacy: .public) rejected mode=\(outputMode.rawValue, privacy: .public) reason=\(reason, privacy: .public) in=\(originalBytes, privacy: .public) attempted=\(attemptedBytes, privacy: .public)")
    }
}
