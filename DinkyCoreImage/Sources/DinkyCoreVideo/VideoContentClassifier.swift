// VideoContentClassifier.swift — content-aware video classification.

import AVFoundation
import CoreGraphics
import DinkyCoreImage
import Foundation

public enum VideoContentType: String, Sendable, Codable {
    case screenRecording
    case camera
    case animation
    case generic

    public var label: String {
        switch self {
        case .screenRecording: return "screen"
        case .camera: return "camera"
        case .animation: return "animation"
        case .generic: return "video"
        }
    }

    public var tooltipLabel: String {
        switch self {
        case .screenRecording:
            return "Detected as a screen recording — quality nudged up so text stays crisp"
        case .camera:
            return "Detected as camera footage — compressed at the standard tier for the source"
        case .animation:
            return "Detected as animation / motion graphics — quality nudged up so edges stay crisp"
        case .generic:
            return "Generic video — compressed at the standard tier for the source"
        }
    }
}

public enum VideoContentClassifier: Sendable {

    public static func classify(asset: AVAsset) async -> VideoContentType {
        let common: [AVMetadataItem]
        do {
            common = try await asset.load(.commonMetadata)
        } catch {
            common = []
        }

        if let software = await stringValue(in: common, identifier: .commonIdentifierSoftware),
           looksLikeScreenRecording(software) {
            return .screenRecording
        }

        let qtMeta: [AVMetadataItem]
        do {
            qtMeta = try await asset.loadMetadata(for: .quickTimeMetadata)
        } catch {
            qtMeta = []
        }

        if let qtSoftware = await stringValue(in: qtMeta, identifier: .quickTimeMetadataSoftware),
           looksLikeScreenRecording(qtSoftware) {
            return .screenRecording
        }

        let make: String?
        if let m = await stringValue(in: common, identifier: .commonIdentifierMake) {
            make = m
        } else {
            make = await stringValue(in: qtMeta, identifier: .quickTimeMetadataMake)
        }
        let model: String?
        if let m = await stringValue(in: common, identifier: .commonIdentifierModel) {
            model = m
        } else {
            model = await stringValue(in: qtMeta, identifier: .quickTimeMetadataModel)
        }
        if (make?.isEmpty == false) && (model?.isEmpty == false) {
            return .camera
        }

        if await framesLookLikeAnimation(asset: asset) {
            return .animation
        }

        return .generic
    }

    private static func looksLikeScreenRecording(_ software: String) -> Bool {
        let s = software.lowercased()
        return s.contains("screen")
            || s.contains("screencapture")
            || s.contains("quicktime")
            || s.contains("loom")
            || s.contains("obs")
            || s.contains("screenflow")
            || s.contains("camtasia")
            || s.contains("cleanshot")
    }

    private static func stringValue(in items: [AVMetadataItem], identifier: AVMetadataIdentifier) async -> String? {
        let matched = AVMetadataItem.metadataItems(from: items, filteredByIdentifier: identifier)
        for item in matched {
            if let s = try? await item.load(.stringValue), !s.isEmpty { return s }
        }
        return nil
    }

    private static func framesLookLikeAnimation(asset: AVAsset) async -> Bool {
        let durationSeconds: Double
        do {
            durationSeconds = try await CMTimeGetSeconds(asset.load(.duration))
        } catch {
            return false
        }
        guard durationSeconds.isFinite, durationSeconds > 0 else { return false }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 256, height: 256)
        generator.requestedTimeToleranceBefore = .positiveInfinity
        generator.requestedTimeToleranceAfter = .positiveInfinity

        let fractions: [Double] = [0.25, 0.5, 0.75]
        let times = fractions.map { CMTime(seconds: max(0.05, durationSeconds * $0), preferredTimescale: 600) }

        var totalUnique = 0
        var totalFlat = 0.0
        var samples = 0

        for time in times {
            let cg: CGImage
            do {
                cg = try await generator.image(at: time).image
            } catch {
                continue
            }
            guard let stats = ContentClassifier.samplePixelStats(cg) else { continue }
            totalUnique += stats.uniqueColors
            totalFlat += stats.flatRatio
            samples += 1
        }

        guard samples > 0 else { return false }
        let meanUnique = Double(totalUnique) / Double(samples)
        let meanFlat = totalFlat / Double(samples)

        return meanUnique < 1500 && meanFlat > 0.25
    }
}
