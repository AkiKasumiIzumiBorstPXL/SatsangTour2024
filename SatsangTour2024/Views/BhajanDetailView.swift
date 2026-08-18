import SwiftUI
import WebKit

struct BhajanDetailView: View {
    @Bindable var store: BhajanStore
    @Binding var isMeaningVisible: Bool
    
    @State private var webPage = WebPage()
    
    let onToggleMeaning: () -> Void

    var body: some View {
        Group {
            if let bhajan = store.selectedBhajan {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection(bhajan)
                        scoreSection
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "Selecteer een bhajan",
                    systemImage: "music.note.list",
                    description: Text("Kies een bhajan uit het menu.\nSwipe ← op het menu om te verbergen.")
                )
            }
        }
    }

    // MARK: - Header
    private func headerSection(_ bhajan: Bhajan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(bhajan.title)
                .font(.system(size: 28, weight: .bold))
                .lineLimit(2)
            Text(bhajan.titleLatin)
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Label(bhajan.deity, systemImage: "sparkles")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.tint.opacity(0.12), in: Capsule())

                Label(bhajan.language, systemImage: "globe")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())

                if !bhajan.composer.isEmpty && bhajan.composer != "Composer / arranger" {
                    Label(bhajan.composer, systemImage: "person.fill")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Score (WebView rendering)
    @ViewBuilder
    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if store.isLoadingSvg {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if store.isLoadingSvg {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.quaternary.opacity(0.3))
                    .frame(minHeight: 300)
                    .overlay {
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(.accentColor)
                            Text("Verovio → SVG…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
            } else if let html = store.svgHTML {
                WebView(webPage)                          // ← no label, just the WebPage
                    .task(id: html) {
                        webPage.load(html: html, baseURL: URL(string: "about:blank")!)
                    }
                    .frame(minHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.red.opacity(0.1))
                    .frame(minHeight: 300)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.red)
                            Text("Rendering mislukt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let err = store.errorMessage {
                                Text(err)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Meaning button
    private var meaningButton: some View {
        Button(action: onToggleMeaning) {
            Label(
                isMeaningVisible ? "Verberg betekenis" : "Toon betekenis",
                systemImage: isMeaningVisible ? "sidebar.right" : "sidebar.right"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    // MARK: - Hints
    private var swipeHints: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Swipe ← op menu om te verbergen", systemImage: "arrow.left")
            Label("Swipe vanaf rechter rand ← voor betekenis", systemImage: "arrow.left")
            Label("Swipe → op betekenis-paneel om te sluiten", systemImage: "arrow.right")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top, 8)
    }
}
