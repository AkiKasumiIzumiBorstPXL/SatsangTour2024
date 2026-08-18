import Foundation

final class MEIParser: NSObject, XMLParserDelegate {

    private struct ParseState {
        var currentElement: String = ""
        var inTitle: Bool = false
        var inTranslatedTitle: Bool = false
        var inPersName: Bool = false
        var inLanguage: Bool = false
        var title: String = ""
        var translatedTitle: String = ""
        var composer: String = ""
        var language: String = "Sanskrit"
    }

    private var state = ParseState()
    private var continuation: CheckedContinuation<ParsedMetadata, Error>?

    struct ParsedMetadata: Sendable {
        let title: String
        let translatedTitle: String
        let composer: String
        let language: String
    }

    func parse(url: URL) async throws -> ParsedMetadata {
        state = ParseState()
        
        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont

            guard let data = try? Data(contentsOf: url) else {
                cont.resume(throwing: MEIParseError.fileNotFound)
                return
            }

            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.shouldProcessNamespaces = true

            guard parser.parse() else {
                if let err = parser.parserError {
                    cont.resume(throwing: err)
                } else {
                    cont.resume(throwing: MEIParseError.invalidXML)
                }
                return
            }
        }
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        state.currentElement = elementName.lowercased()

        switch state.currentElement {
        case "title":
            state.inTitle = true
            // type="translated" of type="main"
            if attributeDict["type"] == "translated" {
                state.inTranslatedTitle = true
                state.inTitle = false
            }
        case "persname":
            state.inPersName = true
        case "language":
            state.inLanguage = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if state.inTitle {
            state.title += trimmed
        } else if state.inTranslatedTitle {
            state.translatedTitle += trimmed
        } else if state.inPersName {
            state.composer += trimmed
        } else if state.inLanguage {
            state.language += trimmed
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let lowered = elementName.lowercased()
        if lowered == "title" {
            state.inTitle = false
            state.inTranslatedTitle = false
        }
        if lowered == "persname" { state.inPersName = false }
        if lowered == "language" { state.inLanguage = false }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        let metadata = ParsedMetadata(
            title: state.title.isEmpty ? "Onbekend" : state.title,
            translatedTitle: state.translatedTitle.isEmpty ? state.title : state.translatedTitle,
            composer: state.composer,
            language: state.language
        )
        continuation?.resume(returning: metadata)
        continuation = nil
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        continuation?.resume(throwing: parseError)
        continuation = nil
    }
}

enum MEIParseError: LocalizedError {
    case invalidXML
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .invalidXML: "Het MEI bestand bevat geen geldige XML."
        case .fileNotFound: "Het opgegeven MEI bestand werd niet gevonden."
        }
    }
}
