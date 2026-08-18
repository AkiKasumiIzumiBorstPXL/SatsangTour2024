import SwiftUI

struct MeaningPanelView: View {
    let meaning: BhajanMeaning?
    let isLoading: Bool
    let errorMessage: String?
    let parentBhajan: Bhajan?
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Artha — Betekenis")
                        .font(.headline)
                    if let parentBhajan {
                        Text(parentBhajan.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.bar)

            Divider()

            // Content
            contentArea

            // Bottom hint
            Label("Swipe → om te verbergen", systemImage: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
        }
        // Swipe right → dismiss
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 60 { onClose() }
                }
        )
    }

    @ViewBuilder
    private var contentArea: some View {
        if isLoading {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                Text("Betekenis ophalen…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        } else if let errorMessage {
            Spacer()
            ContentUnavailableView(
                "Niet beschikbaar",
                systemImage: "wifi.exclamationmark",
                description: Text(errorMessage)
            )
            Spacer()
        } else if let meaning {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summarySection(meaning)
                    contextSection(meaning)
                    lineByLineSection(meaning)
                }
                .padding()
            }
        } else {
            Spacer()
            ContentUnavailableView(
                "Geen betekenis",
                systemImage: "doc.text.magnifyingglass",
                description: Text("Betekenis nog niet geladen.")
            )
            Spacer()
        }
    }

    private func summarySection(_ meaning: BhajanMeaning) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Saṃgraha — Samenvatting", systemImage: "text.alignleft")
                .font(.headline)
            Text(meaning.summary)
                .font(.body)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func contextSection(_ meaning: BhajanMeaning) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Sandarbha — Context", systemImage: "book.fill")
                .font(.headline)
            Text(meaning.context)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func lineByLineSection(_ meaning: BhajanMeaning) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Paddhati — Regel voor regel", systemImage: "list.bullet.indent")
                .font(.headline)

            ForEach(Array(meaning.lineByLine.enumerated()), id: \.offset) { _, line in
                VStack(alignment: .leading, spacing: 6) {
                    Text(line.original)
                        .font(.body.bold())

                    Text(line.transliteration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()

                    Text(line.translation)
                        .font(.subheadline)

                    if !line.commentary.isEmpty {
                        Text(line.commentary)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 8)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
