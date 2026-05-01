import DinkyCorePDF
import DinkyCoreShared
import Foundation

public enum DinkyOcrArgParser {
    public struct Result: Sendable {
        public var languages: [String]
        public var outputDir: URL?
        public var json: Bool
        public var paths: [String]
        public init(languages: [String], outputDir: URL?, json: Bool, paths: [String]) {
            self.languages = languages
            self.outputDir = outputDir
            self.json = json
            self.paths = paths
        }
    }

    public static func parse(_ args: [String]) throws -> Result {
        var langs: [String] = CompressionPreset.defaultPdfOCRLanguages
        var outputDir: URL?
        var json = false
        var files: [String] = []
        var i = 0
        let n = args.count
        while i < n {
            let a = args[i]
            if a == "--" {
                files.append(contentsOf: args[(i + 1)...].map { $0 })
                break
            }
            if a == "-h" || a == "--help" {
                throw DinkyCLIParseError(message: "help: use: dinky ocr <pdf>... [--languages en-US,fr] [-o dir] [--json]")
            }
            if a.hasPrefix("-") {
                switch a {
                case "--languages", "--language":
                    i += 1
                    guard i < n else { throw DinkyCLIParseError(message: "missing value for --languages") }
                    langs = args[i].split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    if langs.isEmpty { langs = CompressionPreset.defaultPdfOCRLanguages }
                case "-o", "--output-dir":
                    i += 1
                    guard i < n else { throw DinkyCLIParseError(message: "missing --output-dir") }
                    outputDir = URL(fileURLWithPath: args[i], isDirectory: true)
                case "--json":
                    json = true
                default:
                    throw DinkyCLIParseError(message: "unknown option: \(a)")
                }
            } else {
                files.append(a)
            }
            i += 1
        }
        return Result(languages: langs, outputDir: outputDir, json: json, paths: files)
    }
}

private struct DinkyOcrJSONRow: Codable {
    var input: String
    var output: String?
    var error: String?
}

private struct DinkyOcrJSONEnvelope: Codable {
    var ok: Bool
    var results: [DinkyOcrJSONRow]
}

public enum DinkyOcrCommand: Sendable {
    public static func run(_ args: [String]) async -> Int32 {
        let parsed: DinkyOcrArgParser.Result
        do {
            parsed = try DinkyOcrArgParser.parse(args)
        } catch let e as DinkyCLIParseError {
            FileHandle.standardError.write(Data("dinky: \(e.message)\n".utf8))
            return 1
        } catch {
            FileHandle.standardError.write(Data("dinky: \(error.localizedDescription)\n".utf8))
            return 1
        }
        guard !parsed.paths.isEmpty else {
            FileHandle.standardError.write(Data("dinky ocr: no input files\n".utf8))
            return 1
        }

        var anyFailed = false
        var jsonRows: [DinkyOcrJSONRow] = []
        for p in parsed.paths {
            let inURL = URL(fileURLWithPath: p, isDirectory: false).standardizedFileURL
            guard inURL.pathExtension.lowercased() == "pdf", FileManager.default.isReadableFile(atPath: inURL.path) else {
                anyFailed = true
                if parsed.json {
                    jsonRows.append(DinkyOcrJSONRow(input: p, output: nil, error: "not a readable PDF"))
                } else {
                    FileHandle.standardError.write(Data("\(p): not a readable PDF\n".utf8))
                }
                continue
            }
            let outDir = parsed.outputDir ?? inURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
            let stem = inURL.deletingPathExtension().lastPathComponent
            let outURL = outDir.appendingPathComponent(stem + "-dinky-searchable.pdf", isDirectory: false)
            do {
                try await PDFOCRService.makeSearchableCopy(
                    sourceURL: inURL,
                    outputURL: outURL,
                    languages: parsed.languages,
                    progressHandler: { _, _ in }
                )
                if parsed.json {
                    jsonRows.append(DinkyOcrJSONRow(input: p, output: outURL.path, error: nil))
                } else {
                    print("\(p) -> \(outURL.path)")
                }
            } catch {
                anyFailed = true
                if parsed.json {
                    jsonRows.append(DinkyOcrJSONRow(input: p, output: nil, error: error.localizedDescription))
                } else {
                    FileHandle.standardError.write(Data("\(p): \(error.localizedDescription)\n".utf8))
                }
            }
        }
        if parsed.json {
            let env = DinkyOcrJSONEnvelope(ok: !anyFailed, results: jsonRows)
            let enc = JSONEncoder()
            enc.outputFormatting = [.sortedKeys, .prettyPrinted]
            if let d = try? enc.encode(env), let s = String(data: d, encoding: .utf8) {
                print(s)
            }
        }
        return anyFailed ? 1 : 0
    }
}
