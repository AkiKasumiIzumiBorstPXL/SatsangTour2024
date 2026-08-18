import Foundation
import VerovioToolkit

@MainActor
final class VerovioService {

    static let shared = VerovioService()

    let toolkit: VerovioToolkit
    private(set) var dataPath: String?

    private init() {
        toolkit = VerovioToolkit()
        configureResources()
    }

    private func configureResources() {
        let candidateNames = [
            "VerovioToolkit_VerovioToolkit",
            "VerovioResources",
            "VerovioToolkit",
        ]

        var resourceBundle: Bundle?

        for name in candidateNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "bundle") {
                resourceBundle = Bundle(url: url)
                if resourceBundle != nil {
                    print("📦 Found Verovio bundle: \(name)")
                    break
                }
            }
        }

        if resourceBundle == nil {
            let classBundle = Bundle(for: VerovioToolkit.self)
            for name in candidateNames {
                if let url = classBundle.url(forResource: name, withExtension: "bundle") {
                    resourceBundle = Bundle(url: url)
                    if resourceBundle != nil { break }
                }
            }
        }

        guard let bundle = resourceBundle else {
            print("❌ Could not find any Verovio resource bundle")
            return
        }

        let originalDataPath = bundle.resourceURL?
            .appendingPathComponent("data").path
            ?? bundle.bundlePath + "/Contents/Resources/data"

        let fm = FileManager.default
        let cachesDir = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let writableDataPath = cachesDir.appendingPathComponent("VerovioData")

        if !fm.fileExists(atPath: writableDataPath.path) {
            try? fm.copyItem(
                at: URL(fileURLWithPath: originalDataPath),
                to: writableDataPath
            )
        }

        for fontName in ["Bravura.otf", "Bravura.woff2"] {
            let dest = writableDataPath.appendingPathComponent(fontName)
            if !fm.fileExists(atPath: dest.path) {
                let ext = fontName.contains(".otf") ? "otf" : "woff2"
                let stripped = fontName.replacingOccurrences(of: ".\(ext)", with: "")
                if let source = Bundle.main.url(forResource: stripped, withExtension: ext) {
                    try? fm.copyItem(at: source, to: dest)
                }
            }
        }

        dataPath = writableDataPath.path
        let success = toolkit.setResourcePath(writableDataPath.path)
        print("🎵 setResourcePath result: \(success)")
    }

    // MARK: - Rendering (returns SVG string)

    func render(
        _ meiData: String,
        backgroundColor: String = "#ffffff",
        staffLineColor: String = "#000000",
        scale: Int = 1
    ) -> String? {
        let json = """
        {
            "font": "Bravura",
            "scale": 34,
            "pageWidth": 2100,
            "pageHeight": 2970,
            "adjustPageHeight": true,
            "breaks": "auto",
            "smuflTextFont": "embedded",
            "Header": false
        }
        """

        _ = toolkit.setOptions(json)

        guard toolkit.loadData(meiData) else {
            print("❌ Failed to load MEI data")
            return nil
        }

        let pageCount = toolkit.getPageCount()
        guard pageCount > 0 else { return nil }

        let rawSVG = toolkit.renderToSVG(1, false)
        guard !rawSVG.isEmpty else { return nil }

        return rawSVG
    }

    // MARK: - Complete HTML wrapper (for WebView)

    /// Genereert complete HTML met embedded Bravura font en SVG.
    /// Direct te laden via WebView(webPage: .html(...))
    func renderToHTML(
        _ meiData: String,
        backgroundColor: String = "#ffffff",
        staffLineColor: String = "#000000"
    ) -> String? {
        guard let svg = render(
            meiData,
            backgroundColor: backgroundColor,
            staffLineColor: staffLineColor
        ) else { return nil }

        var fontFaceCSS = ""
        if let path = dataPath,
           let fontData = try? Data(contentsOf: URL(fileURLWithPath: path + "/Bravura.otf")) {
            let base64 = fontData.base64EncodedString()
            fontFaceCSS = """
            @font-face {
                font-family: 'Bravura';
                src: url(data:font/otf;base64,\(base64)) format('opentype');
                font-display: block;
            }
            """
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
        <style>
            \(fontFaceCSS)
            html, body {
                margin: 0; padding: 0;
                background-color: \(backgroundColor);
                overflow: auto;
            }
            svg {
                display: block;
                width: 100%;
                height: auto;
            }
            path, line, use, text, rect, polygon, ellipse, circle {
                fill: \(staffLineColor);
                stroke: \(staffLineColor);
            }
            text { fill: \(staffLineColor) !important; }
        </style>
        </head>
        <body>
        \(svg)
        </body>
        </html>
        """
    }
}
