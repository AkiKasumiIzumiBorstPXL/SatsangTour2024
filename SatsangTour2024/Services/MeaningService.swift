import Foundation

actor MeaningService {

    // GitHub raw content — use 'main' branch (or your commit hash for pinned versions)
    private let baseURL = URL(string: "https://raw.githubusercontent.com/AkiKasumiIzumiBorstPXL/SatsangTour2024/main/SatsangTour2024/meanings")!

    func fetchMeaning(for bhajanKey: String) async throws -> BhajanMeaning {
        let url = baseURL.appending(path: "\(bhajanKey).json")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw MeaningError.serviceUnavailable
        }

        return try JSONDecoder().decode(BhajanMeaning.self, from: data)
    }

    /// Fallback: bundled JSON bestand
    func loadFallbackMeaning(for bhajanKey: String) async throws -> BhajanMeaning? {
        // Try individual bundled file first
        if let url = Bundle.main.url(forResource: bhajanKey, withExtension: "json", subdirectory: "meanings") {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(BhajanMeaning.self, from: data)
        }

        // Legacy: single bundled meanings.json
        guard let url = Bundle.main.url(forResource: "meanings", withExtension: "json") else {
            return nil
        }

        let data = try Data(contentsOf: url)
        let allMeanings = try JSONDecoder().decode([BhajanMeaning].self, from: data)
        return allMeanings.first { $0.bhajanId == bhajanKey }
    }
}

enum MeaningError: LocalizedError {
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            "De betekenis-service is momenteel niet bereikbaar."
        }
    }
}
