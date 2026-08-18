import Foundation
import Observation

@MainActor
@Observable
final class BhajanStore {
    private(set) var bhajans: [Bhajan] = []
    var selectedBhajan: Bhajan?
    private(set) var meaning: BhajanMeaning?
    private(set) var isLoadingMeaning = false
    private(set) var isLoadingSvg = false
    private(set) var svgHTML: String?
    private(set) var errorMessage: String?

    private let parser = MEIParser()
    private let meaningService = MeaningService()

    func loadBhajansFromBundle() async {
        let meiURLs = (Bundle.main.urls(forResourcesWithExtension: "mei", subdirectory: "bhajans")
                      ?? []) + (Bundle.main.urls(forResourcesWithExtension: "xml", subdirectory: "bhajans")
                      ?? [])

        let allMei = meiURLs.isEmpty
            ? (Bundle.main.urls(forResourcesWithExtension: "mei", subdirectory: nil) ?? [])
            : meiURLs
        let allXml = meiURLs.isEmpty
            ? (Bundle.main.urls(forResourcesWithExtension: "xml", subdirectory: nil) ?? [])
            : []
        let urls = allMei + allXml

        guard !urls.isEmpty else {
            errorMessage = "Geen .mei of .xml bestanden gevonden in bundle."
            return
        }

        var parsed: [Bhajan] = []

        for url in urls {
            do {
                let metadata = try await parser.parse(url: url)
                let content = try String(contentsOf: url, encoding: .utf8)
                let id = url.deletingPathExtension().lastPathComponent

                let bhajan = Bhajan(
                    id: id,
                    title: metadata.title,
                    titleLatin: metadata.translatedTitle,
                    deity: extractDeity(from: metadata.title),
                    language: metadata.language,
                    composer: metadata.composer,
                    meiFileURL: url,
                    meiContent: content
                )
                parsed.append(bhajan)
            } catch {
                errorMessage = "Parse-fout voor \(url.lastPathComponent): \(error.localizedDescription)"
            }
        }

        parsed.sort { $0.titleLatin < $1.titleLatin }
        bhajans = parsed
    }

    // MARK: - Select bhajan + render SVG + fetch meaning
    func selectBhajan(_ bhajan: Bhajan) async {
        selectedBhajan = bhajan
        svgHTML = nil
        meaning = nil
        errorMessage = nil

        // Parallel: render SVG + fetch meaning
        async let svgTask = renderSvg(for: bhajan)
        async let meaningTask = fetchMeaning(for: bhajan)

        do {
            _ = try await svgTask
        } catch {
            errorMessage = "MEI rendering: \(error.localizedDescription)"
        }

        do {
            _ = try await meaningTask
        } catch {
            if errorMessage == nil {
                errorMessage = "Betekenis: \(error.localizedDescription)"
            }
        }
    }

    private func renderSvg(for bhajan: Bhajan) async throws {
        isLoadingSvg = true
        defer { isLoadingSvg = false }

        guard let html = VerovioService.shared.renderToHTML(bhajan.meiContent) else {
            throw VerovioRenderError.renderingFailed
        }
        svgHTML = html
    }

    private func fetchMeaning(for bhajan: Bhajan) async throws {
        isLoadingMeaning = true
        defer { isLoadingMeaning = false }

        do {
            meaning = try await meaningService.fetchMeaning(for: bhajan.meaningKey)
        } catch {
            if let fallback = try? await meaningService.loadFallbackMeaning(for: bhajan.meaningKey) {
                meaning = fallback
            } else {
                throw error
            }
        }
    }

    private func extractDeity(from title: String) -> String {
        let normalized = title
            .applyingTransform(.stripDiacritics, reverse: false)?
            .lowercased() ?? title.lowercased()

        let lower = title.lowercased()

        if lower.contains("kṟṣṇa") || lower.contains("krishna") || normalized.contains("krishna") || normalized.contains("krsna") || lower.contains("कृष्ण") { return "Kṛṣṇa" }
        if lower.contains("rāma") || lower.contains("rama") || normalized.contains("rama") || lower.contains("राम") { return "Rāma" }
        if lower.contains("śiva") || lower.contains("shiva") || normalized.contains("shiva") || normalized.contains("siva") || lower.contains("शिव") { return "Śiva" }
        if lower.contains("devī") || lower.contains("devi") || normalized.contains("devi") || lower.contains("देव") { return "Devī" }
        if lower.contains("govinda") || normalized.contains("govinda") { return "Govinda" }
        if lower.contains("nārāyaṇa") || lower.contains("narayana") || normalized.contains("narayana") { return "Nārāyaṇa" }
        if lower.contains("guru") || normalized.contains("guru") { return "Guru" }
        if lower.contains("ganesh") || lower.contains("ganesha") || normalized.contains("ganesha") { return "Gaṇeśa" }
        
        return "—"
    }
}

enum VerovioRenderError: LocalizedError {
    case renderingFailed

    var errorDescription: String? {
        switch self {
        case .renderingFailed: "Verovio kon de MEI data niet renderen."
        }
    }
}
