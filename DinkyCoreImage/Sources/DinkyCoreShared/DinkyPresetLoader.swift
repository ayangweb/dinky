import Foundation

public enum DinkyPresetLoadError: Error, Sendable {
    case fileNotFound(String)
    case invalidJSON(String)
    case presetNotFound(String)
    case multiplePresetsMatch(String)
}

/// Loads ``CompressionPreset`` from file or the Dinky app's UserDefaults.
public enum DinkyPresetLoader {
    public static let appSuiteName = "com.dinky.app"
    public static let savedPresetsDataKey = "savedPresetsData"

    /// Resolution order: explicit file → `$DINKY_PRESETS_PATH` → `~/.config/dinky/presets.json` → app UserDefaults.
    public static func loadPresets(presetFile: String?) throws -> [CompressionPreset] {
        if let path = presetFile?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
            let url = URL(fileURLWithPath: path, isDirectory: false)
            guard let data = try? Data(contentsOf: url), !data.isEmpty else {
                throw DinkyPresetLoadError.fileNotFound(path)
            }
            return try decodePresetsArray(data)
        }
        if let env = ProcessInfo.processInfo.environment["DINKY_PRESETS_PATH"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !env.isEmpty {
            let url = URL(fileURLWithPath: env, isDirectory: false)
            if let data = try? Data(contentsOf: url), !data.isEmpty {
                return try decodePresetsArray(data)
            }
        }
        let homeConfig = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/dinky/presets.json", isDirectory: false)
        if let data = try? Data(contentsOf: homeConfig), !data.isEmpty {
            return try decodePresetsArray(data)
        }
        guard let data = UserDefaults(suiteName: appSuiteName)?.data(forKey: savedPresetsDataKey),
              !data.isEmpty
        else {
            return []
        }
        return try decodePresetsArray(data)
    }

    public static func resolve(
        name: String?,
        id: UUID?,
        presetFile: String?
    ) throws -> CompressionPreset {
        let presets = try loadPresets(presetFile: presetFile)
        if let id {
            guard let p = presets.first(where: { $0.id == id }) else {
                throw DinkyPresetLoadError.presetNotFound("id=\(id.uuidString)")
            }
            return p
        }
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            throw DinkyPresetLoadError.presetNotFound("(empty name)")
        }
        let exact = presets.filter { $0.name == name }
        if exact.count == 1 { return exact[0] }
        if exact.count > 1 {
            throw DinkyPresetLoadError.multiplePresetsMatch(name)
        }
        let lowered = name.lowercased()
        let ci = presets.filter { $0.name.lowercased() == lowered }
        if ci.count == 1 { return ci[0] }
        if ci.count > 1 {
            throw DinkyPresetLoadError.multiplePresetsMatch(name)
        }
        throw DinkyPresetLoadError.presetNotFound(name)
    }

    private static func decodePresetsArray(_ data: Data) throws -> [CompressionPreset] {
        do {
            return try JSONDecoder().decode([CompressionPreset].self, from: data)
        } catch {
            throw DinkyPresetLoadError.invalidJSON(error.localizedDescription)
        }
    }
}
