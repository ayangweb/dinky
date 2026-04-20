import Foundation

/// Picks an available filename in the same directory when the desired path is already taken.
enum OutputPathUniqueness {

    /// Returns `desired` if it does not exist, or the first free path using `style` disambiguation.
    /// When `desired` is the same file as `sourceURL`, returns `desired` so in-place replace can proceed.
    static func uniqueOutputURL(desired: URL, sourceURL: URL, style: CollisionNamingStyle) -> URL {
        let desiredPath = desired.standardizedFileURL.path
        let sourcePath = sourceURL.standardizedFileURL.path
        if desiredPath == sourcePath { return desired }

        let dir = desired.deletingLastPathComponent()
        let ext = desired.pathExtension
        let baseStem = desired.deletingPathExtension().lastPathComponent

        var candidate = desired
        if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }

        switch style {
        case .finderDuplicate:
            let copyFrag = String(localized: " copy", comment: "Filename: first duplicate after base name, as in Finder “file copy”.")
            var n = 1
            while true {
                let stem: String
                if n == 1 {
                    stem = baseStem + copyFrag
                } else {
                    stem = baseStem + copyFrag + " \(n)"
                }
                candidate = dir.appendingPathComponent(stem).appendingPathExtension(ext)
                if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }
                n += 1
            }
        case .finderNumbered:
            var n = 1
            while true {
                let stem = "\(baseStem) (\(n))"
                candidate = dir.appendingPathComponent(stem).appendingPathExtension(ext)
                if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }
                n += 1
            }
        }
    }
}
