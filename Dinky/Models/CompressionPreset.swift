import Foundation

struct CompressionPreset: Codable, Identifiable {
    let id: UUID
    var name: String
    // Format
    var format: CompressionFormat
    var smartQuality: Bool
    var autoFormat: Bool
    // Limits
    var maxWidthEnabled: Bool
    var maxWidth: Int
    var maxFileSizeEnabled: Bool
    var maxFileSizeKB: Int
    // Output
    var saveLocationRaw: String
    var filenameHandlingRaw: String
    var customSuffix: String
    // Advanced
    var stripMetadata: Bool
    var sanitizeFilenames: Bool
    var openFolderWhenDone: Bool
    // Notifications
    var notifyWhenDone: Bool

    let createdAt: Date

    init(name: String, from prefs: DinkyPreferences, format: CompressionFormat) {
        self.id = UUID()
        self.name = name
        self.format = format
        self.smartQuality = prefs.smartQuality
        self.autoFormat = prefs.autoFormat
        self.maxWidthEnabled = prefs.maxWidthEnabled
        self.maxWidth = prefs.maxWidth
        self.maxFileSizeEnabled = prefs.maxFileSizeEnabled
        self.maxFileSizeKB = prefs.maxFileSizeKB
        self.saveLocationRaw = prefs.saveLocationRaw
        self.filenameHandlingRaw = prefs.filenameHandlingRaw
        self.customSuffix = prefs.customSuffix
        self.stripMetadata = prefs.stripMetadata
        self.sanitizeFilenames = prefs.sanitizeFilenames
        self.openFolderWhenDone = prefs.openFolderWhenDone
        self.notifyWhenDone = prefs.notifyWhenDone
        self.createdAt = .now
    }

    // Custom decoder so old presets (missing new fields) still load
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        format = try c.decode(CompressionFormat.self, forKey: .format)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        smartQuality = try c.decodeIfPresent(Bool.self, forKey: .smartQuality) ?? true
        autoFormat = try c.decodeIfPresent(Bool.self, forKey: .autoFormat) ?? false
        maxWidthEnabled = try c.decodeIfPresent(Bool.self, forKey: .maxWidthEnabled) ?? false
        maxWidth = try c.decodeIfPresent(Int.self, forKey: .maxWidth) ?? 1920
        maxFileSizeEnabled = try c.decodeIfPresent(Bool.self, forKey: .maxFileSizeEnabled) ?? false
        maxFileSizeKB = try c.decodeIfPresent(Int.self, forKey: .maxFileSizeKB) ?? 2048
        saveLocationRaw = try c.decodeIfPresent(String.self, forKey: .saveLocationRaw) ?? "sameFolder"
        filenameHandlingRaw = try c.decodeIfPresent(String.self, forKey: .filenameHandlingRaw) ?? "appendSuffix"
        customSuffix = try c.decodeIfPresent(String.self, forKey: .customSuffix) ?? "-dinky"
        stripMetadata = try c.decodeIfPresent(Bool.self, forKey: .stripMetadata) ?? true
        sanitizeFilenames = try c.decodeIfPresent(Bool.self, forKey: .sanitizeFilenames) ?? false
        openFolderWhenDone = try c.decodeIfPresent(Bool.self, forKey: .openFolderWhenDone) ?? false
        notifyWhenDone = try c.decodeIfPresent(Bool.self, forKey: .notifyWhenDone) ?? false
    }

    func apply(to prefs: DinkyPreferences, selectedFormat: inout CompressionFormat) {
        selectedFormat = format
        prefs.smartQuality = smartQuality
        prefs.autoFormat = autoFormat
        prefs.maxWidthEnabled = maxWidthEnabled
        prefs.maxWidth = maxWidth
        prefs.maxFileSizeEnabled = maxFileSizeEnabled
        prefs.maxFileSizeKB = maxFileSizeKB
        prefs.saveLocationRaw = saveLocationRaw
        prefs.filenameHandlingRaw = filenameHandlingRaw
        prefs.customSuffix = customSuffix
        prefs.stripMetadata = stripMetadata
        prefs.sanitizeFilenames = sanitizeFilenames
        prefs.openFolderWhenDone = openFolderWhenDone
        prefs.notifyWhenDone = notifyWhenDone
    }
}
