import UniformTypeIdentifiers

enum CompressionFormat: String, CaseIterable, Identifiable, Codable {
    case webp = "webp"
    case avif = "avif"
    case png  = "png"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .webp: return S.webp
        case .avif: return S.avif
        case .png:  return S.png
        }
    }

    var outputExtension: String {
        switch self {
        case .webp: return "webp"
        case .avif: return "avif"
        case .png:  return "png"
        }
    }

    var binaryName: String {
        switch self {
        case .webp: return "cwebp"
        case .avif: return "avifenc"
        case .png:  return "oxipng"
        }
    }

    var acceptedInputTypes: [UTType] {
        switch self {
        case .webp: return [.jpeg, .png, .webP, .tiff]
        case .avif: return [.jpeg, .png, .tiff]
        case .png:  return [.png]
        }
    }
}
