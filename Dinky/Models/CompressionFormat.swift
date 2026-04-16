import UniformTypeIdentifiers

enum CompressionFormat: String, CaseIterable, Identifiable, Codable {
    case webp = "webp"
    case avif = "avif"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .webp: return S.webp
        case .avif: return S.avif
        }
    }

    var outputExtension: String {
        switch self {
        case .webp: return "webp"
        case .avif: return "avif"
        }
    }

    var binaryName: String {
        switch self {
        case .webp: return "cwebp"
        case .avif: return "avifenc"
        }
    }

    var acceptedInputTypes: [UTType] {
        switch self {
        case .webp: return [.jpeg, .png, .webP, .tiff]
        case .avif: return [.jpeg, .png, .tiff]
        }
    }
}
