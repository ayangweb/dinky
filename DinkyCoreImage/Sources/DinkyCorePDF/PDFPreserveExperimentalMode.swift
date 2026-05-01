import Foundation

/// Optional qpdf passes for **preserve** mode when normal optimization isn’t enough.
public enum PDFPreserveExperimentalMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case none = "none"
    case stripNonEssentialStructure = "stripStructure"
    case strongerImageRecompression = "strongerImages"
    case maximum = "maximum"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none:
            return String(localized: "Off (default)", comment: "PDF experimental preserve: disabled.")
        case .stripNonEssentialStructure:
            return String(localized: "Strip non-essential structure", comment: "PDF experimental preserve preset name.")
        case .strongerImageRecompression:
            return String(localized: "Stronger image recompression", comment: "PDF experimental preserve preset name.")
        case .maximum:
            return String(localized: "Maximum (both)", comment: "PDF experimental preserve preset name.")
        }
    }

    public var shortDescription: String {
        switch self {
        case .none:
            return String(localized: "Standard qpdf + PDFKit preserve path.", comment: "PDF experimental preserve description.")
        case .stripNonEssentialStructure:
            return String(localized: "Removes the PDF structure tree (tagged PDF / markup). Smaller on some exports; screen readers may lose tags.", comment: "PDF experimental preserve description.")
        case .strongerImageRecompression:
            return String(localized: "Recompresses embedded images more aggressively. Can introduce JPEG artifacts.", comment: "PDF experimental preserve description.")
        case .maximum:
            return String(localized: "Structure strip + stronger JPEG. Highest chance of a smaller file; highest risk to fidelity.", comment: "PDF experimental preserve description.")
        }
    }

    public var extraQpdfArgs: [String] {
        switch self {
        case .none:
            return []
        case .stripNonEssentialStructure:
            return ["--remove-structure"]
        case .strongerImageRecompression:
            return ["--jpeg-quality=50"]
        case .maximum:
            return ["--remove-structure", "--jpeg-quality=50"]
        }
    }

    public var qpdfExtrasWithoutJPEGQuality: [String] {
        extraQpdfArgs.filter { !$0.hasPrefix("--jpeg-quality=") }
    }
}
