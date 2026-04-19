import Foundation

/// Central place for "what happens to the original file after a successful compress."
enum OriginalsHandler {

    /// Move to trash, move to backup folder, or leave in place.
    static func dispose(originalAt url: URL, action: OriginalsAction, backupFolder: URL?) throws {
        switch action {
        case .keep:
            return
        case .trash:
            var resulting: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &resulting)
        case .backup:
            guard let folder = backupFolder else {
                throw OriginalsHandlerError.missingBackupFolder
            }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let destination = uniqueDestination(in: folder, for: url)
            try FileManager.default.moveItem(at: url, to: destination)
        }
    }

    /// When **Replace original** is on, the source must leave its path so the output can take its name.
    /// If the user chose **Keep** originals, we still remove the source from disk by moving it to Trash
    /// (otherwise the rename would fail). Trash and Backup use the same paths as normal disposal.
    static func disposeForReplace(originalAt url: URL, action: OriginalsAction, backupFolder: URL?) throws {
        switch action {
        case .keep:
            try dispose(originalAt: url, action: .trash, backupFolder: nil)
        case .trash, .backup:
            try dispose(originalAt: url, action: action, backupFolder: backupFolder)
        }
    }
}

enum OriginalsHandlerError: LocalizedError {
    case missingBackupFolder

    var errorDescription: String? {
        switch self {
        case .missingBackupFolder:
            return "Backup folder is not set or could not be accessed."
        }
    }
}

// MARK: - Unique name (Finder-style "name (1).ext")

extension OriginalsHandler {
    /// Picks `name.ext`, then `name (1).ext`, `name (2).ext`, … until unused in `folder`.
    static func uniqueDestination(in folder: URL, for original: URL) -> URL {
        let base = original.deletingPathExtension().lastPathComponent
        let ext = original.pathExtension
        var candidate = folder.appendingPathComponent(base).appendingPathExtension(ext)
        var n = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            let stem = "\(base) (\(n))"
            candidate = folder.appendingPathComponent(stem).appendingPathExtension(ext)
            n += 1
        }
        return candidate
    }
}
