import SwiftUI

/// 이모지 고르기 시트 (GH-64 R-40). 최근 사용 줄 + 카테고리 탭 + 8열 그리드.
/// 고르면 바로 반영하고 닫는다. 검색은 없다
struct EmojiPickerSheet: View {
    let recentStore: EmojiRecentStore
    let onSelect: (String) -> Void

    @State private var category: EmojiCategory = .smileys
    @State private var recents: [String] = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.EmojiPicker.title)
                .font(.appleBold(size: 17))
                .foregroundStyle(Color.gray5)
                .padding(.top, 24)

            if !recents.isEmpty {
                Text(Strings.EmojiPicker.recent)
                    .font(.appleMedium(size: 12))
                    .foregroundStyle(Color.gray4)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(recents, id: \.self) { emoji in
                            emojiButton(emoji)
                                .frame(width: 40)
                        }
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(EmojiCategory.allCases) { item in
                        Button {
                            category = item
                        } label: {
                            Text(verbatim: item.title)
                                .font(item == category ? .appleExtraBold(size: 14) : .appleMedium(size: 14))
                                .foregroundStyle(item == category ? Color.gray1 : Color.gray4)
                                .padding(.horizontal, 14)
                                .frame(height: 30)
                                .background {
                                    if item == category {
                                        Capsule().fill(Color.seepBlue)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(item == category ? .isSelected : [])
                    }
                }
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(category.emojis, id: \.self) { emoji in
                        emojiButton(emoji)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            recents = recentStore.recents
        }
    }

    private func emojiButton(_ emoji: String) -> some View {
        Button {
            recentStore.add(emoji)
            onSelect(emoji)
        } label: {
            Text(verbatim: emoji)
                .font(.system(size: 30))
                .frame(maxWidth: .infinity, minHeight: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
