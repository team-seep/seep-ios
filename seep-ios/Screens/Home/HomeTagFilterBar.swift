import SwiftUI

/// 홈 태그 필터 칩 줄 (GH-136 R-3). 카테고리 탭과 정렬 줄 사이, 가로 스크롤.
/// 맨 앞 '전체' + 지금 카테고리에서 쓴 태그(많이 쓴 순). 고른 칩은 seep-blue 테두리·글자
struct HomeTagFilterBar: View {
    let tags: [String]
    let selectedTag: String?
    let onSelect: (String?) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(title: Strings.Home.TagFilter.all, tag: nil)
                    ForEach(tags, id: \.self) { tag in
                        chip(title: "#" + HashtagType.displayName(for: tag), tag: tag)
                    }
                }
                .padding(.horizontal, HomeLayout.horizontalInset)
            }
            .onChange(of: tags) { _, _ in
                proxy.scrollTo(ChipID.all, anchor: .leading)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(Strings.Home.TagFilter.accessibility))
    }

    private enum ChipID: Hashable {
        case all
        case tag(String)
    }

    private func chip(title: String, tag: String?) -> some View {
        let isSelected = tag == selectedTag
        return Button {
            guard !isSelected else { return }
            onSelect(tag)
        } label: {
            Text(verbatim: title)
                .font(isSelected ? .appleExtraBold(size: 14) : .appleMedium(size: 14))
                .foregroundStyle(isSelected ? Color.seepBlue : Color.gray4)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color.gray1, in: RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isSelected ? Color.seepBlue : Color.gray2_5, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .id(tag.map(ChipID.tag) ?? ChipID.all)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
