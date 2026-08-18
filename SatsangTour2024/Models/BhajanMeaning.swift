import Foundation

nonisolated struct BhajanMeaning: Identifiable, Sendable, Codable {
    let id: String
    let bhajanId: String
    let summary: String
    let context: String
    let lineByLine: [MeaningLine]

    nonisolated struct MeaningLine: Sendable, Codable, Hashable {
        let original: String          // Devanagari
        let transliteration: String   // ISO 15919
        let translation: String       // Nederlands
        let commentary: String
    }
}
