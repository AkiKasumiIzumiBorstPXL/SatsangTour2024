import SwiftUI

struct NavigationMenuView: View {
    @Bindable var store: BhajanStore
    let onSelect: (Bhajan) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundStyle(.tint)
                Text("Bhajan Sangrah")
                    .font(.headline)
                Spacer()
                Text("\(store.bhajans.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            // List = RecyclerView equivalent
            List(store.bhajans) { bhajan in
                MenuRow(bhajan: bhajan, isSelected: store.selectedBhajan?.id == bhajan.id)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(bhajan) }
            }
            .listStyle(.plain)

        }
        .overlay {
            if store.bhajans.isEmpty {
                ContentUnavailableView(
                    "Geen bhajans gevonden",
                    systemImage: "music.note",
                    description: Text("Voeg .mei of .xml bestanden toe aan de bundle.")
                )
            }
        }
    }
}




