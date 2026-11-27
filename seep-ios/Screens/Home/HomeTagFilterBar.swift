import SwiftUI

/// 홈 태그 필터 칩 줄 (GH-136 R-3). 카테고리 탭과 정렬 줄 사이, 가로 스크롤.
/// 맨 앞 '전체' + (하는 중 싶이 있으면) "● 하는 중 n" (GH-143 R-4) + 지금 카테고리에서 쓴 태그(많이 쓴 순). 고른 칩은 seep-blue 테두리·글자
struct HomeTagFilterBar: View {
    let tags: [String]
    let filter: HomeListFilter
    /// 0 이면 "하는 중" 칩을 그리지 않는다
    let inProgressCount: Int
    let onSelectTag: (String?) -> Void
    let onSelectInProgress: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(title: Strings.Home.TagFilter.all, isSelected: filter == .all) { onSelectTag(nil) }
                    if inProgressCount > 0 {
                        chip(
                            title: Strings.Home.TagFilter.inProgressFormat(inProgressCount),
                            isSelected: filter == .inProgress,
                            showsDot: true,
                            action: onSelectInProgress
                        )
                    }
                    ForEach(tags, id: \.self) { tag in
                        chip(title: "#" + HashtagType.displayName(for: tag), isSelected: filter == .tag(tag)) { onSelectTag(tag) }
                    }
                }
                .padding(.horizontal, HomeLayout.horizontalInset)
                // 여백까지 포함한 줄 전체를 맨 앞으로 — 칩에 맞추면 왼쪽 여백 20pt 가 밀려 'All' 이 가장자리에 붙는다
                .id(ScrollStart.id)
            }
            .onChange(of: tags) { _, _ in
                proxy.scrollTo(ScrollStart.id, anchor: .leading)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(Strings.Home.TagFilter.accessibility))
    }

    private enum ScrollStart {
        static let id = "tag-filter-start"
    }

    private func chip(title: String, isSelected: Bool, showsDot: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            guard !isSelected else { return }
            action()
        } label: {
            HStack(spacing: 6) {
                if showsDot {
                    InProgressDot()
                }
                chipTitle(title, isSelected: isSelected)
            }
                // 칩은 글자 길이만큼 넓어지고 넘치면 줄이 가로 스크롤된다. 어떤 폭을 제안받아도 글자를 줄이지(…) 않는다 (GH-143 검수 피드백)
                .fixedSize()
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color.gray1, in: RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isSelected ? Color.seepBlue : Color.gray2_5, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// 폭은 늘 ExtraBold 기준으로 잡는다. 고를 때 Medium→ExtraBold 로 바뀌어도 칩 폭이 그대로라
    /// 폭이 바뀌는 중간 프레임에서 글자가 "하는…"처럼 잘려 보이지 않는다
    private func chipTitle(_ title: String, isSelected: Bool) -> some View {
        Text(verbatim: title)
            .font(.appleExtraBold(size: 14))
            .lineLimit(1)
            .hidden()
            .overlay {
                Text(verbatim: title)
                    .font(isSelected ? .appleExtraBold(size: 14) : .appleMedium(size: 14))
                    .foregroundStyle(isSelected ? Color.seepBlue : Color.gray4)
                    .lineLimit(1)
                    .fixedSize()
            }
    }
}

/// '하는 중' 표시 점. `tennisGreen`("실행") 6pt (GH-143 R-4, R-5)
struct InProgressDot: View {
    var body: some View {
        Circle()
            .fill(Color.tennisGreen)
            .frame(width: 6, height: 6)
            .accessibilityHidden(true)
    }
}
