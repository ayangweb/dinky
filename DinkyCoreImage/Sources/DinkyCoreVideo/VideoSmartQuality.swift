import AVFoundation
import DinkyCoreShared
import Foundation
import os

/// Heuristic video export tier from track metadata + content type.
public enum VideoSmartQuality: Sendable {

    private static let timingLog = Logger(
        subsystem: "dinky",
        category: "VideoSmartQuality"
    )

    /// What we picked + why.
    public struct Decision: Sendable {
        public let quality: VideoQuality
        public let contentType: VideoContentType
        public let isHDR: Bool

        public init(quality: VideoQuality, contentType: VideoContentType, isHDR: Bool) {
            self.quality = quality
            self.contentType = contentType
            self.isHDR = isHDR
        }
    }

    public static func decide(source: URL, fallback: VideoQuality) async -> Decision {
        await decide(asset: VideoCompressor.makeURLAsset(url: source), fallback: fallback)
    }

    public static func decide(asset: AVURLAsset, fallback: VideoQuality) async -> Decision {
        let t0 = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = CFAbsoluteTimeGetCurrent() - t0
            timingLog.debug("video.smartQuality.decide \(String(format: "%.3f", elapsed))s")
        }

        let contentType = await VideoContentClassifier.classify(asset: asset)
        let isHDR = await detectHDR(asset: asset)

        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let track = tracks.first else {
                return Decision(quality: fallback, contentType: contentType, isHDR: isHDR)
            }

            let size = try await track.load(.naturalSize)
            let rate = try await track.load(.estimatedDataRate)
            let transform = try await track.load(.preferredTransform)
            let transformed = size.applying(transform)
            let w = abs(transformed.width)
            let h = abs(transformed.height)
            guard w >= 1, h >= 1 else {
                return Decision(quality: fallback, contentType: contentType, isHDR: isHDR)
            }

            let maxDim = Double(max(w, h))
            let minDim = Double(min(w, h))
            let megapixels = (w * h) / 1_000_000.0

            var quality = mapSignals(
                maxDimension: maxDim, minDimension: minDim,
                megapixels: megapixels, bitsPerSecond: rate
            )

            if contentType == .screenRecording || contentType == .animation {
                quality = quality.bumpedUp
            }

            return Decision(quality: quality, contentType: contentType, isHDR: isHDR)
        } catch {
            return Decision(quality: fallback, contentType: contentType, isHDR: isHDR)
        }
    }

    public static func inferQuality(asset: AVURLAsset, fallback: VideoQuality) async -> VideoQuality {
        await decide(asset: asset, fallback: fallback).quality
    }

    public static func inferQuality(source: URL, fallback: VideoQuality) async -> VideoQuality {
        await decide(source: source, fallback: fallback).quality
    }

    private static func detectHDR(asset: AVAsset) async -> Bool {
        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let track = tracks.first else { return false }

            let characteristics = try await track.load(.mediaCharacteristics)
            if characteristics.contains(.containsHDRVideo) { return true }

            let descriptions = try await track.load(.formatDescriptions)
            for desc in descriptions {
                if let ext = CMFormatDescriptionGetExtension(desc, extensionKey: kCMFormatDescriptionExtension_TransferFunction) as? String {
                    let hlg = kCMFormatDescriptionTransferFunction_ITU_R_2100_HLG as String
                    let pq = kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ as String
                    if ext == hlg || ext == pq { return true }
                }
            }
        } catch {
            return false
        }
        return false
    }

    private static func mapSignals(
        maxDimension: Double,
        minDimension: Double,
        megapixels: Double,
        bitsPerSecond: Float
    ) -> VideoQuality {
        let rate = Double(bitsPerSecond)

        if maxDimension < 540 || megapixels < 0.22 {
            return .medium
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
