import Foundation
import AVFoundation

/// Heuristic video export tier from track metadata.
enum VideoSmartQuality {

    /// Picks a ``VideoQuality`` from resolution and estimated bitrate. On failure, returns `fallback`.
    static func inferQuality(source: URL, fallback: VideoQuality) async -> VideoQuality {
        await inferQuality(asset: VideoCompressor.makeURLAsset(url: source), fallback: fallback)
    }

    /// Same as ``inferQuality(source:fallback:)`` but reuses a loaded ``AVURLAsset`` (avoids a second file open).
    static func inferQuality(asset: AVURLAsset, fallback: VideoQuality) async -> VideoQuality {
        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let track = tracks.first else { return fallback }

            let size = try await track.load(.naturalSize)
            let rate = try await track.load(.estimatedDataRate)
            let transform = try await track.load(.preferredTransform)
            let transformed = size.applying(transform)
            let w = abs(transformed.width)
            let h = abs(transformed.height)
            guard w >= 1, h >= 1 else { return fallback }

            let maxDim = Double(max(w, h))
            let minDim = Double(min(w, h))
            let megapixels = (w * h) / 1_000_000.0

            return mapSignals(maxDimension: maxDim, minDimension: minDim, megapixels: megapixels, bitsPerSecond: rate)
        } catch {
            return fallback
        }
    }

    private static func mapSignals(
        maxDimension: Double,
        minDimension: Double,
        megapixels: Double,
        bitsPerSecond: Float
    ) -> VideoQuality {
        let rate = Double(bitsPerSecond)

        if maxDimension < 540 || megapixels < 0.22 {
            return rate > 4_000_000 ? .medium : .low
        }

        if maxDimension <= 960 || megapixels < 0.65 {
            return rate > 10_000_000 ? .high : .medium
        }

        if maxDimension <= 1440 {
            if rate > 14_000_000 { return .high }
            return .medium
        }

        if maxDimension <= 1920 {
            if minDimension >= 1080, rate > 12_000_000 { return .high }
            return .medium
        }

        return .high
    }
}
