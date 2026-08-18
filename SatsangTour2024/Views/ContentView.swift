import SwiftUI
import WebKit

struct ContentView: View {
    @State private var store = BhajanStore()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var preferredCompactColumn: NavigationSplitViewColumn = .content
    @State private var detailMode: DetailMode = .music

    @AppStorage("lastBhajanId") private var lastBhajanId: String = ""

    enum DetailMode: String, CaseIterable {
        case music = "music.note"
        case meaning = "text.book.closed"

        var label: String {
            switch self {
            case .music: "Muziek"
            case .meaning: "Betekenis"
            }
        }
    }

    var body: some View {
        NavigationSplitView(
            preferredCompactColumn: $preferredCompactColumn
        ) {
            NavigationMenuView(
                store: store,
                onSelect: { bhajan in
                    detailMode = .music
                    preferredCompactColumn = .detail
                    Task { await selectBhajan(bhajan) }
                }
            )
            .navigationTitle("Bhajans")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationSplitViewColumnWidth(min: 240, ideal: 300, max: 340)
        } detail: {
            if let bhajan = store.selectedBhajan {
                VStack(spacing: 0) {
                    if horizontalSizeClass == .compact {
                        // ── Compact: segmented picker + swap ──
                        detailSegmentedPicker

                        switch detailMode {
                        case .music:
                            BhajanDetailView(
                                store: store,
                                isMeaningVisible: .constant(false),
                                onToggleMeaning: {
                                    withAnimation { detailMode = .meaning }
                                }
                            )
                        case .meaning:
                            MeaningPanelView(
                                meaning: store.meaning,
                                isLoading: store.isLoadingMeaning,
                                errorMessage: store.errorMessage,
                                parentBhajan: store.selectedBhajan,
                                onClose: {
                                    withAnimation { detailMode = .music }
                                }
                            )
                            #if os(iOS)
                            .background(Color(UIColor.systemBackground))
                            #endif
                        }
                    } else {
                        // ── Regular: ALWAYS music, overlay handles meaning ──
                        // Key fix: pass .constant(false) so BhajanDetailView
                        // never shows meaning itself — the overlay does that
                        BhajanDetailView(
                            store: store,
                            isMeaningVisible: .constant(false),
                            onToggleMeaning: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    detailMode = detailMode == .music ? .meaning : .music
                                }
                            }
                        )
                    }
                }
                .navigationTitle(bhajan.title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                detailMode = detailMode == .music ? .meaning : .music
                            }
                        } label: {
                            Label("Switch", systemImage: detailMode == .music ? "text.book.closed" : "music.note")
                        }
                        .disabled(store.meaning == nil && !store.isLoadingMeaning)
                    }
                }
            } else if store.bhajans.isEmpty {
                ContentUnavailableView(
                    "Loading bhajans...",
                    systemImage: "arrow.triangle.2.circlepath",
                    description: Text("Please wait while files load from bundle.")
                )
            } else {
                ContentUnavailableView(
                    "Select a Bhajan",
                    systemImage: "music.note",
                    description: Text("Choose a bhajan from the sidebar")
                )
            }
        }
        .overlay(alignment: .trailing) {
            if horizontalSizeClass == .regular && detailMode == .meaning {
                MeaningPanelView(
                    meaning: store.meaning,
                    isLoading: store.isLoadingMeaning,
                    errorMessage: store.errorMessage,
                    parentBhajan: store.selectedBhajan,
                    onClose: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            detailMode = .music
                        }
                    }
                )
                .frame(width: 380)
                .frame(maxHeight: .infinity, alignment: .topTrailing)
                #if os(macOS)
                .background(Color(NSColor.windowBackgroundColor))
                #else
                .background(Color(UIColor.systemBackground))
                #endif
                .shadow(radius: 10, y: -2)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .task {
            await store.loadBhajansFromBundle()

            if !lastBhajanId.isEmpty,
               let saved = store.bhajans.first(where: { $0.id == lastBhajanId }) {
                preferredCompactColumn = .detail
                await selectBhajan(saved)
            } else if !store.bhajans.isEmpty {
                preferredCompactColumn = .detail
                await selectBhajan(store.bhajans[0])
            }
        }
    }

    private var detailSegmentedPicker: some View {
        Picker("Detail Mode", selection: $detailMode) {
            ForEach(DetailMode.allCases, id: \.self) { mode in
                Label(mode.label, systemImage: mode.rawValue)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func selectBhajan(_ bhajan: Bhajan) async {
        lastBhajanId = bhajan.id
        await store.selectBhajan(bhajan)

        if horizontalSizeClass == .compact {
            detailMode = .music
        }
    }
}
