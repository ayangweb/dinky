import DinkyCorePDF
import DinkyCoreShared
import Foundation

public struct DinkyPdfCompressParseResult: Sendable {
    public var options: DinkyPdfCompressOptions
    public var paths: [String]
    public var explicit: Set<String>
    public var preset: PresetCLIRef

    public init(options: DinkyPdfCompressOptions, paths: [String], explicit: Set<String>, preset: PresetCLIRef) {
        self.options = options
        self.paths = paths
        self.explicit = explicit
        self.preset = preset
    }
}

public enum DinkyPdfCompressArgParser {
    public static func parse(_ args: [String]) throws -> DinkyPdfCompressParseResult {
        var o = DinkyPdfCompressOptions()
        var files: [String] = []
        var explicit: Set<String> = []
        var preset = PresetCLIRef()
        var i = 0
        let n = args.count
        while i < n {
            let a = args[i]
            if a == "--" {
                files.append(contentsOf: args[(i + 1)...].map { $0 })
                break
            }
            if a == "-h" || a == "--help" {
                throw DinkyCLIParseError(message: "help: use: dinky compress-pdf <files> [options]")
            }
            if a.hasPrefix("-") {
                switch a {
                case "--preset":
                    i += 1
                    guard i < n else { throw DinkyCLIParseError(message: "missing value for --preset") }
                    preset.name = args[i]
                case "--preset-id":
                    i += 1
                    guard i < n, let u = UUID(uuidString: args[i]) else {
                        throw DinkyCLIParseError(message: "invalid --preset-id (expected UUID)")
                    }
                    preset.id = u
                case "--preset-file":
                    i += 1
                    guard i < n else { throw DinkyCLIParseError(message: "missing value for --preset-file") }
                    preset.file = args[i]
                case "--mode":
                    i += 1
                    guard i < n else { throw DinkyCLIParseError(message: "missing value for --mode") }
                    let m = args[i].lowercased()
                    switch m {
                    case "preserve":
                        o.outputMode = .preserveStructure
                    case "flatten":
                        o.outputMode = .flattenPages
                    default:
                        throw DinkyCLIParseError(message: "unknown --mode (use preserve or flatten)")
                    }
                    explicit.insert("mode")
                case "-q", "--quality":
                    i += 1
                    guard i < n else { throw DinkyCLIParseError(message: "missing value for --quality") }
                    guard let q = PDFQuality(rawValue: args[i].lowercased()) else {
                        throw DinkyCLIParseError(message: "unknown --quality (smallest|low|medium|high)")
                    }
                    o.quality = q
                    explicit.insert("quality")
                case "--grayscale":
                    o.grayscale = true
                    explicit.insert("grayscale")
                case "--no-grayscale":
                    o.grayscale = false
                    explicit.insert("grayscale")
                case "--strip-metadata", "--strip":
                    o.stripMetadata = true
                    explicit.insert("stripMetadata")
                case "--no-strip-metadata":
                    o.stripMetadata = false
                    explicit.insert("stripMetadata")
                case "--resolution-downsample":
                    o.resolutionDownsampling = true
                    explicit.insert("downsample")
                case "--no-resolution-downsample":
                    o.resolutionDownsampling = false
                    explicit.insert("downsample")
                case "--target-kb":
                    i += 1
                    guard i < n, let k = Int(args[i]), k > 0 else { throw DinkyCLIParseError(message: "invalid --target-kb") }
                    o.targetKB = k
                    explicit.insert("targetKb")
                case "--preserve-experimental":
                    i += 1
                    guard i < n else { throw DinkyCLIParseError(message: "missing value for --preserve-experimental") }
                    let v = args[i].lowercased()
                    let raw: String
                    switch v {
                    case "none", "off":
                        raw = PDFPreserveExperimentalMode.none.rawValue
                    case "stripstructure", "strip":
                        raw = PDFPreserveExperimentalMode.stripNonEssentialStructure.rawValue
                    case "strongerimages", "stronger":
                        raw = PDFPreserveExperimentalMode.strongerImageRecompression.rawValue
                    case "maximum", "max":
                        raw = PDFPreserveExperimentalMode.maximum.rawValue
                    default:
                        raw = v
                    }
                    guard let mode = PDFPreserveExperimentalMode(rawValue: raw) else {
                        throw DinkyCLIParseError(message: "unknown --preserve-experimental value")
                    }
                    o.preserveExperimental = mode
                    explicit.insert("preserveExperimental")
                case "--no-smart-quality":
                    o.smartQuality = false
                    explicit.insert("smartQuality")
                case "--smart-quality":
                    o.smartQuality = true
                    explicit.insert("smartQuality")
                case "--auto-grayscale-mono":
                    o.autoGrayscaleMonoScans = true
                    explicit.insert("autoGrayscaleMono")
                case "--no-auto-grayscale-mono":
                    o.autoGrayscaleMonoScans = false
                    explicit.insert("autoGrayscaleMono")
                case "-o", "--output-dir":
                    i += 1
                    guard i < n else { throw DinkyCLIParseError(message: "missing --output-dir path") }
                    o.outputDir = URL(fileURLWithPath: args[i], isDirectory: true)
                    explicit.insert("outputDir")
                case "--json":
                    o.json = true
                case "--collision-style":
                    i += 1
                    guard i < n else { throw DinkyCLIParseError(message: "missing --collision-style") }
                    guard let s = CollisionNamingStyle(rawValue: args[i]) else {
                        throw DinkyCLIParseError(message: "unknown --collision-style")
                    }
                    o.collisionStyle = s
                    explicit.insert("collisionStyle")
                case "--collision-pattern":
                    i += 1
                    guard i < n else { throw DinkyCLIParseError(message: "missing --collision-pattern") }
                    o.collisionCustomPattern = args[i]
                    explicit.insert("collisionCustom")
                default:
                    throw DinkyCLIParseError(message: "unknown option: \(a)")
                }
            } else {
                files.append(a)
            }
            i += 1
        }
        return DinkyPdfCompressParseResult(options: o, paths: files, explicit: explicit, preset: preset)
    }
}
