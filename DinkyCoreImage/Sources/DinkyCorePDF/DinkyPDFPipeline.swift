import DinkyCoreShared
import Foundation
import PDFKit

/// Unified PDF compress path (qpdf preserve chain, PDFKit fallback, flatten, optional downsample).
public struct DinkyPDFCompressResult: Sendable {
    public let outputURL: URL
    public let originalSize: Int64
    public let outputSize: Int64
    public let winningPreserveQpdfStepId: String?
    public let appliedResolutionDownsampling: Bool

    public init(
        outputURL: URL,
        originalSize: Int64,
        outputSize: Int64,
        winningPreserveQpdfStepId: String?,
        appliedResolutionDownsampling: Bool
    ) {
        self.outputURL = outputURL
        self.originalSize = originalSize
        self.outputSize = outputSize
        self.winningPreserveQpdfStepId = winningPreserveQpdfStepId
        self.appliedResolutionDownsampling = appliedResolutionDownsampling
    }
}

public enum DinkyPDFPipeline: Sendable {
    public static func compress(
        source: URL,
        outputMode: PDFOutputMode,
        quality: PDFQuality,
        grayscale: Bool,
        stripMetadata: Bool,
        outputURL: URL,
        flattenLastResort: Bool = false,
        flattenUltra: Bool = false,
        preserveQpdfSteps: [PDFPreserveQpdfStep] = [.base],
        targetBytes: Int64? = nil,
        resolutionDownsampling: Bool = false,
        collisionNamingStyle: CollisionNamingStyle = .finderDuplicate,
        collisionCustomPattern: String = "",
        qpdfBinary: URL?,
        progressHandler: (@Sendable (Float) -> Void)? = nil
    ) async throws -> DinkyPDFCompressResult {
        let tPDF = CFAbsoluteTimeGetCurrent()
        func fileSize(_ url: URL) -> Int64 {
            (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { Int64($0) } ?? 0
        }
        let originalSize = fileSize(source)

        var effOut = OutputPathUniqueness.uniqueOutputURL(
            desired: outputURL,
            sourceURL: source,
            style: collisionNamingStyle,
            customPattern: collisionCustomPattern
        )

        try FileManager.default.createDirectory(
            at: effOut.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        var winningPreserveQpdfStepId: String? = nil
        var appliedDownsample = false

        switch outputMode {
        case .preserveStructure:
            progressHandler?(0.06)
            let fm = FileManager.default
            var usedQpdf = false
            if let qpdfBin = qpdfBinary {
                let steps = preserveQpdfSteps.isEmpty ? [PDFPreserveQpdfStep.base] : preserveQpdfSteps
                let n = max(steps.count, 1)
                var bestQpdfURL: URL? = nil
                var bestQpdfSize: Int64 = originalSize
                for (idx, step) in steps.enumerated() {
                    let qpdfTmp = fm.temporaryDirectory.appendingPathComponent("dinky_qpdf_\(UUID().uuidString).pdf")
                    progressHandler?(0.06 + 0.08 * Float(idx + 1) / Float(n))
                    do {
                        try await runQpdfPreserve(
                            source: source,
                            output: qpdfTmp,
                            stripMetadata: stripMetadata,
                            binary: qpdfBin,
                            extraQpdfArgs: step.extraArgs
                        )
                        let qSz = fileSize(qpdfTmp)
                        if qSz > 0 && qSz < bestQpdfSize {
                            if let prev = bestQpdfURL { try? fm.removeItem(at: prev) }
                            bestQpdfURL = qpdfTmp
                            bestQpdfSize = qSz
                            winningPreserveQpdfStepId = step.id
                            let targetMet = targetBytes.map { qSz <= $0 } ?? true
                            if targetMet { break }
                        } else {
                            try? fm.removeItem(at: qpdfTmp)
                        }
                    } catch {
                        try? fm.removeItem(at: qpdfTmp)
                        continue
                    }
                }
                if let best = bestQpdfURL {
                    effOut = try OutputPathUniqueness.moveTempItemToUniqueOutput(
                        temp: best,
                        desiredOutput: effOut,
                        sourceURL: source,
                        style: collisionNamingStyle,
                        customPattern: collisionCustomPattern,
                        fileManager: fm
                    )
                    usedQpdf = true
                }
            }
            if !usedQpdf {
                let ph = progressHandler
                effOut = try PDFCompressor.preserveStructure(
                    source: source,
                    stripMetadata: stripMetadata,
                    outputURL: effOut,
                    collisionSourceURL: source,
                    collisionNamingStyle: collisionNamingStyle,
                    collisionCustomPattern: collisionCustomPattern,
                    progress: ph
                )
            } else {
                progressHandler?(1)
            }

            if resolutionDownsampling, fm.fileExists(atPath: effOut.path),
               let structureDoc = PDFDocument(url: effOut) {
                let dsURL = fm.temporaryDirectory.appendingPathComponent("dinky_pdf_ds_\(UUID().uuidString).pdf")
                if let mixed = PDFImageDownsampler.downsample(source: source, structureDoc: structureDoc, stripMetadata: stripMetadata),
                   mixed.write(to: dsURL) {
                    let dsSz = fileSize(dsURL)
                    if dsSz > 0 && dsSz < fileSize(effOut) {
                        try? fm.removeItem(at: effOut)
                        try fm.moveItem(at: dsURL, to: effOut)
                        appliedDownsample = true
                    } else {
                        try? fm.removeItem(at: dsURL)
                    }
                }
            }
        case .flattenPages:
            effOut = OutputPathUniqueness.refreshUniqueOutput(
                currentCandidate: effOut,
                sourceURL: source,
                style: collisionNamingStyle,
                customPattern: collisionCustomPattern
            )
            let ph = progressHandler
            let ultra = flattenUltra
            let lastResort = flattenLastResort && !ultra
            try PDFCompressor.compressFlattened(
                source: source, quality: quality, grayscale: grayscale,
                stripMetadata: stripMetadata, outputURL: effOut,
                lastResortFlatten: lastResort,
                ultraLastResortFlatten: ultra,
                progress: ph
            )
        }
        CompressionTiming.logPhase("pdf.compress.\(outputMode == .flattenPages ? "flatten" : "preserve")", startedAt: tPDF)

        guard FileManager.default.fileExists(atPath: effOut.path) else {
            throw DinkyPDFProcessError.outputMissing
        }

        let outSz = fileSize(effOut)
        let chainIds = preserveQpdfSteps.isEmpty ? "base" : preserveQpdfSteps.map(\.id).joined(separator: ">")
        PDFCompressionMetrics.logOutcome(
            outputMode: outputMode,
            originalBytes: originalSize,
            outputBytes: outSz,
            flattenLastResort: flattenLastResort,
            flattenUltra: flattenUltra,
            preserveQpdfChain: outputMode == .preserveStructure ? chainIds : nil,
            preserveQpdfWinningStep: winningPreserveQpdfStepId
        )

        return DinkyPDFCompressResult(
            outputURL: effOut,
            originalSize: originalSize,
            outputSize: outSz,
            winningPreserveQpdfStepId: winningPreserveQpdfStepId,
            appliedResolutionDownsampling: appliedDownsample
        )
    }

    private static func runQpdfPreserve(
        source: URL,
        output: URL,
        stripMetadata: Bool,
        binary: URL,
        extraQpdfArgs: [String]
    ) async throws {
        var args: [String] = [
            source.path,
            output.path,
            "--object-streams=generate",
            "--compress-streams=y",
            "--recompress-flate",
            "--compression-level=9",
            "--remove-unreferenced-resources=yes",
            "--coalesce-contents",
            "--optimize-images",
        ]
        args.append(contentsOf: extraQpdfArgs)
        if stripMetadata {
            args.append(contentsOf: ["--remove-metadata", "--remove-info"])
        }
        do {
            try await PDFProcessRunner.run(binary, args: args)
        } catch {
            let withoutJpeg = extraQpdfArgs.filter { !$0.hasPrefix("--jpeg-quality=") }
            var fallback = [
                source.path,
                output.path,
                "--object-streams=generate",
                "--compress-streams=y",
                "--recompress-flate",
                "--compression-level=9",
                "--remove-unreferenced-resources=yes",
                "--coalesce-contents",
            ]
            fallback.append(contentsOf: withoutJpeg)
            if stripMetadata {
                fallback.append(contentsOf: ["--remove-metadata", "--remove-info"])
            }
            try await PDFProcessRunner.run(binary, args: fallback)
        }
    }
}
