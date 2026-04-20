import Foundation
import PDFKit
import CoreGraphics
import AppKit

/// Heuristic PDF quality tier from quick page sampling (runs off the main thread).
enum PDFSmartQuality {

    /// Picks a ``PDFQuality`` from document structure and rendered thumbnails. On any failure, returns `fallback`.
    static func inferQuality(url: URL, fallback: PDFQuality) -> PDFQuality {
        guard let document = PDFDocument(url: url) else { return fallback }
        let pageCount = document.pageCount
        guard pageCount > 0 else { return fallback }

        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? 0
        let bytesPerPage = Double(fileSize) / Double(pageCount)

        let indices = samplePageIndices(pageCount: pageCount)
        var spreads: [Double] = []
        var fills: [Double] = []

        for i in indices {
            guard let page = document.page(at: i) else { continue }
            guard let stats = thumbnailStats(for: page) else { continue }
            spreads.append(stats.avgChromaSpread)
            fills.append(stats.nonWhiteFraction)
        }

        guard !spreads.isEmpty else { return fallback }

        let avgSpread = spreads.reduce(0, +) / Double(spreads.count)
        let avgFill = fills.reduce(0, +) / Double(fills.count)

        // Colorful decks (capabilities, portfolios): Medium/High flatten often loses to already-tuned JPEGs — default to strongest tiers.
        if bytesPerPage >= 85_000, bytesPerPage < 560_000 {
            if avgSpread > 0.065 || avgFill > 0.11 {
                return .smallest
            }
            if avgSpread > 0.045 {
                return .low
            }
        }

        return mapSignals(bytesPerPage: bytesPerPage, avgChromaSpread: avgSpread, avgNonWhiteFill: avgFill)
    }

    private static func samplePageIndices(pageCount: Int) -> [Int] {
        let cap = 5
        if pageCount <= cap {
            return Array(0..<pageCount)
        }
        var set = Set<Int>()
        set.insert(0)
        set.insert(pageCount - 1)
        set.insert(pageCount / 2)
        set.insert(pageCount / 4)
        set.insert((3 * pageCount) / 4)
        return Array(set).sorted()
    }

    private struct ThumbStats {
        let avgChromaSpread: Double
        let nonWhiteFraction: Double
    }

    /// Renders a small bitmap and computes cheap color / coverage stats.
    private static func thumbnailStats(for page: PDFPage) -> ThumbStats? {
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 1, bounds.height > 1 else { return nil }

        let maxEdge: CGFloat = 256
        let scale = min(maxEdge / bounds.width, maxEdge / bounds.height, 4)
        let pixelWidth = max(1, Int(bounds.width * scale))
        let pixelHeight = max(1, Int(bounds.height * scale))

        guard let ctx = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        ctx.scaleBy(x: scale, y: scale)

        let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.current = nsCtx
        page.draw(with: .mediaBox, to: ctx)
        NSGraphicsContext.current = nil

        guard let data = ctx.data else { return nil }
        let count = pixelWidth * pixelHeight
        let ptr = data.bindMemory(to: UInt8.self, capacity: count * 4)

        var sumSpread = 0.0
        var nonWhite = 0
        let step = 4
        var samples = 0

        for i in stride(from: 0, to: count, by: step) {
            let o = i * 4
            let r = Double(ptr[o]) / 255
            let g = Double(ptr[o + 1]) / 255
            let b = Double(ptr[o + 2]) / 255
            let mx = max(r, g, b)
            let mn = min(r, g, b)
            sumSpread += mx - mn
            if r + g + b < 2.55 {
                nonWhite += 1
            }
            samples += 1
        }

        guard samples > 0 else { return nil }
        let avgSpread = sumSpread / Double(samples)
        let fill = Double(nonWhite) / Double(samples)
        return ThumbStats(avgChromaSpread: avgSpread, nonWhiteFraction: fill)
    }

    private static func mapSignals(bytesPerPage: Double, avgChromaSpread: Double, avgNonWhiteFill: Double) -> PDFQuality {
        // Low bytes/page usually means efficient embedded images or vector text — Medium/High flatten often bloats.
        if bytesPerPage < 260_000 {
            if avgChromaSpread < 0.035, avgNonWhiteFill < 0.07 {
                return .smallest
            }
            if avgChromaSpread < 0.055, avgNonWhiteFill < 0.12 {
                return .low
            }
            return .low
        }
        // Large per-page byte counts: embedded images are often already efficient — avoid High/Medium flatten that bloats.
        if bytesPerPage > 520_000 {
            if avgChromaSpread > 0.14 || avgNonWhiteFill > 0.32 {
                return .low
            }
            return .smallest
        }
        // Reserve High for very large, visually heavy pages only (flatten is expensive and easy to oversize).
        if bytesPerPage > 2_300_000, avgChromaSpread > 0.10 || avgNonWhiteFill > 0.25 {
            return .high
        }
        if bytesPerPage > 1_350_000, avgChromaSpread > 0.115, avgNonWhiteFill > 0.27 {
            return .high
        }
        if bytesPerPage > 880_000, avgNonWhiteFill > 0.20, avgChromaSpread > 0.09 {
            return .high
        }
        if avgChromaSpread > 0.11, avgNonWhiteFill > 0.28 {
            // Bias toward smaller flatten tiers when pages are already byte-heavy to avoid JPEG bloat vs source.
            return bytesPerPage > 240_000 ? .low : .medium
        }
        if bytesPerPage > 380_000, avgNonWhiteFill > 0.14 {
            return .low
        }
        if avgChromaSpread < 0.035, avgNonWhiteFill < 0.07, bytesPerPage < 95_000 {
            return .smallest
        }
        if avgChromaSpread < 0.045, avgNonWhiteFill < 0.11, bytesPerPage < 180_000 {
            return .low
        }
        return .low
    }
}
