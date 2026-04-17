import Foundation

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let fileCount: Int
    let totalBytesSaved: Int64
    let formats: [String]
}
