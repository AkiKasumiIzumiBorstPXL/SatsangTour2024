import SwiftUI

struct MenuRow: View {
    let bhajan: Bhajan
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(bhajan.deity.prefix(1))
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(bhajan.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 6) {
                    TagView(text: bhajan.deity)
                    TagView(text: bhajan.language)
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}
