import SwiftUI

/// 제목·메모·해시태그로 세 카테고리 전체에서 위시를 찾는 화면 (GH-32, GH-64 TC-701~703).
/// 이룬 싶 탭에서 열면 완료한 위시만 찾는다 (TC-202)
struct WishSearchScreen: View {
    let finishedOnly: Bool

    @State private var viewModel: WishSearchViewModel

    init(finishedOnly: Bool) {
        self.finishedOnly = finishedOnly
        _viewModel = State(initialValue: WishSearchViewModel(config: .init(finishedOnly: finishedOnly)))
    }

    var body: some View {
        WishSearchContentView(viewModel: viewModel)
    }
}

private enum WishSearchLayout {
    static let horizontalInset: CGFloat = 20
    /// 입력하는 대로 찾되 글자마다 조회하지 않도록 0.3초 멈추면 찾는다 (GH-32 R-3)
    static let debounce: Duration = .milliseconds(300)
}

private struct WishSearchContentView: View {
    let viewModel: WishSearchViewModel

    @Environment(AppRouter.self) private var router
    @FocusState private var isFieldFocused: Bool
    @State private var keyword = ""
    @State private var didFocusOnce = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            resultCount
            ZStack(alignment: .top) {
                resultList
                if let emptyKeyword = viewModel.state.emptyKeyword {
                    WishSearchEmptyStateView(keyword: emptyKeyword)
                        .padding(.horizontal, WishSearchLayout.horizontalInset)
                        .padding(.top, 120 - 20)
                }
            }
        }
        .frame(maxWidth: SeepLayout.maxContentWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray2.ignoresSafeArea())
        // 검색 칸은 시스템 내비게이션 바 아래 항상 펼쳐 둔다
        .navigationTitle(Strings.WishSearch.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $keyword,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(Strings.WishSearch.placeholder)
        )
        .searchFocused($isFieldFocused)
        .onSubmit(of: .search) { isFieldFocused = false }
        .autocorrectionDisabled()
        .trackScreen(viewModel.screenName)
        .onAppear {
            viewModel.send(.onAppear)
            // 처음 열릴 때만 바로 입력할 수 있게 포커스를 준다. 상세에서 돌아올 때는 결과를 보던 중이다 (GH-32 R-2)
            if !didFocusOnce {
                didFocusOnce = true
                isFieldFocused = true
            }
        }
        .task(id: keyword) {
            try? await Task.sleep(for: WishSearchLayout.debounce)
            guard !Task.isCancelled else { return }
            viewModel.send(.inputKeyword(keyword))
        }
        .onChange(of: viewModel.route) { _, route in
            handle(route)
        }
    }

    @ViewBuilder
    private var resultCount: some View {
        if let count = viewModel.state.resultCount {
            highlighted(
                Strings.WishSearch.resultCountFormat(count),
                part: Strings.WishSearch.resultCountHighlightFormat(count),
                baseFont: .appleMedium(size: 14),
                baseColor: .gray4,
                highlightFont: .appleBold(size: 14),
                highlightColor: .seepBlue
            )
            .padding(.horizontal, WishSearchLayout.horizontalInset + 2)
            .padding(.top, 20)
            .padding(.bottom, 4)
        } else {
            Color.clear.frame(height: 20)
        }
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(viewModel.state.sections.enumerated()), id: \.element.id) { sectionIndex, section in
                    Text(verbatim: section.category.searchHeaderTitle)
                        .font(.appleMedium(size: 14))
                        .foregroundStyle(Color.gray4)
                        .padding(.leading, 2)
                        .frame(height: 44, alignment: .bottomLeading)
                        .padding(.bottom, 10)
                    VStack(spacing: 10) {
                        ForEach(Array(section.items.enumerated()), id: \.element.id) { itemIndex, item in
                            Button {
                                isFieldFocused = false
                                viewModel.send(.tapResult(IndexPath(item: itemIndex, section: sectionIndex)))
                            } label: {
                                WishSearchResultRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, WishSearchLayout.horizontalInset)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
    }

    private func handle(_ route: WishSearchViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .wishDetail(let id, let isFinished):
            router.push(.wishDetail(id: id, isFinished: isFinished))
        }
        viewModel.send(.routeHandled)
    }
}

/// 검색 결과 줄. 홈 리스트 셀과 같은 모양이고, 일치 글자를 강조한다 (GH-32 R-6, R-7).
/// 검색 화면에서는 체크할 수 없어 완료 여부만 보인다
private struct WishSearchResultRow: View {
    let item: WishSearchResultItem

    var body: some View {
        let wish = item.wish
        HStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                Text(verbatim: wish.emoji)
                    .font(.system(size: 36))
                VStack(alignment: .leading, spacing: 5) {
                    titleText
                        .lineLimit(1)
                    if let memoSnippet = item.memoSnippet {
                        memoText(memoSnippet)
                            .lineLimit(1)
                    } else {
                        HStack(spacing: 7) {
                            DdayBadge(
                                style: DdayBadgeStyle(endDate: wish.endDate),
                                farFutureText: Strings.homeInFarFurture,
                                noDateText: Strings.homeNoDeanline
                            )
                            if !wish.hashtag.isEmpty {
                                TagBadge(text: HashtagType(rawValue: wish.hashtag)?.description ?? wish.hashtag)
                            }
                        }
                    }
                }
                .padding(.top, 3)
                Spacer(minLength: 12)
            }
            .opacity(wish.isSuccess ? 0.5 : 1)

            (wish.isSuccess ? Assets.Icons.icCheckOn : Assets.Icons.icCheckOff).swiftUIImage
                .foregroundStyle(Color.gray3)
                .accessibilityHidden(true)
        }
        .padding(.leading, 14)
        .padding(.trailing, 16)
        .frame(height: 70)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }

    private var titleText: Text {
        let wish = item.wish
        return highlighted(
            wish.title,
            range: item.titleHighlightRange,
            baseFont: .appleSemiBold(size: 16),
            baseColor: .gray5,
            highlightFont: .appleSemiBold(size: 16),
            highlightColor: .seepBlue
        )
        // 홈과 같이 완료 위시는 취소선
        .strikethrough(wish.isSuccess, color: .gray4)
    }

    private func memoText(_ snippet: WishSearchMemoSnippet) -> Text {
        let prefix = Strings.WishSearch.memoFormat("")
        let offset = (prefix as NSString).length
        let range = NSRange(location: snippet.highlightRange.location + offset, length: snippet.highlightRange.length)
        return highlighted(
            Strings.WishSearch.memoFormat(snippet.text),
            range: range,
            baseFont: .appleMedium(size: 12),
            baseColor: .gray4,
            highlightFont: .appleMedium(size: 12),
            highlightColor: .seepBlue
        )
    }
}

/// 결과 없음 안내 (GH-32 R-9)
private struct WishSearchEmptyStateView: View {
    let keyword: String

    var body: some View {
        VStack(spacing: 0) {
            Assets.Images.imgEmojiEmpty.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .accessibilityHidden(true)
            Text(verbatim: Strings.WishSearch.emptyTitleFormat(keyword))
                .font(.appleMedium(size: 16))
                .foregroundStyle(Color.gray5)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 24)
            Text(Strings.WishSearch.emptyDescription)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
    }
}

/// 문자열 일부(`part` 첫 일치 또는 `range`)만 다른 글꼴·색으로 그린다
private func highlighted(
    _ text: String,
    part: String,
    baseFont: Font,
    baseColor: Color,
    highlightFont: Font,
    highlightColor: Color
) -> Text {
    let range = (text as NSString).range(of: part)
    return highlighted(
        text,
        range: range.location == NSNotFound ? nil : range,
        baseFont: baseFont,
        baseColor: baseColor,
        highlightFont: highlightFont,
        highlightColor: highlightColor
    )
}

private func highlighted(
    _ text: String,
    range: NSRange?,
    baseFont: Font,
    baseColor: Color,
    highlightFont: Font,
    highlightColor: Color
) -> Text {
    guard let range, let swiftRange = Range(range, in: text) else {
        return Text(verbatim: text).font(baseFont).foregroundStyle(baseColor)
    }
    return Text(verbatim: String(text[..<swiftRange.lowerBound])).font(baseFont).foregroundStyle(baseColor)
        + Text(verbatim: String(text[swiftRange])).font(highlightFont).foregroundStyle(highlightColor)
        + Text(verbatim: String(text[swiftRange.upperBound...])).font(baseFont).foregroundStyle(baseColor)
}

private extension Category {
    /// 검색 결과 섹션 제목 (GH-32 R-4)
    var searchHeaderTitle: String {
        switch self {
        case .wantToDo: return Strings.categoryWantToDo
        case .wantToGet: return Strings.categoryWantToGet
        case .wantToGo: return Strings.categoryWantToGo
        }
    }
}
