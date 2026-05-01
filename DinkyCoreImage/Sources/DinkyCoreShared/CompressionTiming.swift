import Foundation
import os

/// Debug-level timing for compression phases.
public enum CompressionTiming {
    private static let log = Logger(
        subsystem: "dinky",
        category: "CompressionTiming"
    )

    public static func logPhase(_ name: String, startedAt: CFAbsoluteTime) {
        let elapsed = CFAbsoluteTimeGetCurrent() - startedAt
        log.debug("\(name, privacy: .public) \(String(format: "%.3f", elapsed))s")
    }

    public static func logReproContext(media: String, smartQuality: Bool, extra: String = "") {
        if extra.isEmpty {
            log.debug("repro context: media=\(media, privacy: .public) smartQ=\(smartQuality, privacy: .public)")
        } else {
            log.debug("repro context: media=\(media, privacy: .public) smartQ=\(smartQuality, privacy: .public) \(extra, privacy: .public)")
        }
    }
}
