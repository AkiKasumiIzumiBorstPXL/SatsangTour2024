import Foundation

struct Bhajan: Identifiable, Hashable, Sendable {
    let id: String             // bestandsnaam zonder extensie
    let title: String           // Devanagari of originele titel
    let titleLatin: String      // ISO 15919 transliteratie
    let deity: String           // Rāma, Śiva, Kṛṣṇa, etc.
    let language: String        // "Sanskrit", "Hindi", etc.
    let composer: String
    let meiFileURL: URL         // bronbestand in bundle
    let meiContent: String      // ruwe MEI XML string (voor Verovio)

    var meaningKey: String { id }
}
