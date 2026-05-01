import DinkyCoreShared
import Foundation

/// One qpdf attempt on the preserve path (`extraArgs` append after base `--optimize-images` args).
public struct PDFPreserveQpdfStep: Sendable, Equatable {
    public let id: String
    public let extraArgs: [String]

    public init(id: String, extraArgs: [String]) {
        self.id = id
        self.extraArgs = extraArgs
    }

    public static let base = PDFPreserveQpdfStep(id: "base", extraArgs: [])

    public static func from(experimental: PDFPreserveExperimentalMode) -> PDFPreserveQpdfStep {
        PDFPreserveQpdfStep(id: "exp_\(experimental.rawValue)", extraArgs: experimental.extraQpdfArgs)
    }

    public func extrasWithoutJPEGQuality() -> [String] {
        extraArgs.filter { !$0.hasPrefix("--jpeg-quality=") }
    }
}

public enum PDFPreserveHeuristics: Sendable {
    private static let maxSteps = 4

    public static func qpdfSteps(for s: PDFDocumentSignals) -> [PDFPreserveQpdfStep] {
        let textHeavy = s.totalTextCharsSampled >= 6000
        let imageHeavy = s.totalTextCharsSampled < 2000 && s.bytesPerPage > 100_000

        var steps: [PDFPreserveQpdfStep] = [.base]

        if imageHeavy {
            steps.append(PDFPreserveQpdfStep(id: "jpeg65", extraArgs: ["--jpeg-quality=65"]))
            steps.append(PDFPreserveQpdfStep(id: "jpeg50", extraArgs: ["--jpeg-quality=50"]))
            if !textHeavy {
                steps.append(PDFPreserveQpdfStep(id: "strip_jpeg50", extraArgs: ["--remove-structure", "--jpeg-quality=50"]))
            }
        } else if !textHeavy, s.bytesPerPage < 900_000 {
            steps.append(PDFPreserveQpdfStep(id: "strip", extraArgs: ["--remove-structure"]))
        }

        if steps.count > maxSteps {
            steps = Array(steps.prefix(maxSteps))
        }
        return steps
    }
}

public enum PDFPreserveQpdfStepsResolver: Sendable {
    public static func steps(
        sourceURL: URL,
        preserveExperimental: PDFPreserveExperimentalMode,
        smartQuality: Bool
    ) -> [PDFPreserveQpdfStep] {
        if preserveExperimental != .none {
            return [PDFPreserveQpdfStep.from(experimental: preserveExperimental)]
        }
        guard smartQuality, let signals = PDFDocumentSampler.sample(url: sourceURL) else {
            return [.base]
        }
        return PDFPreserveHeuristics.qpdfSteps(for: signals)
    }
}
