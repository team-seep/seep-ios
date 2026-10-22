import SwiftUI

/// 이룬 싶 탭 루트 (GH-64 R-17 ~ R-23).
/// 헤드라인 → 배지 카드 → 연말 회고 카드(기간에만) → 카테고리 필터 + 검색 → 월별 완료 목록
struct FinishedTabRootView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = FinishedViewModel()
    @State private var presentedYearReview: PresentedYear?

    private let filters: [Category?] = [nil, .wantToDo, .wantToGet, .wantToGo]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    headline
                        .id(ScrollAnchor.top)
                        .padding(.top, 24)
                        .padding(.horizontal, 22)

                    VStack(spacing: 10) {
                        FinishedBadgeCard(
                            earnedCount: viewModel.state.earnedBadgeCount,
                            recentBadges: viewModel.state.recentBadges,
                            onTap: { viewModel.send(.tapBadgeCollection) }
                        )
                        if let yearReview = viewModel.state.yearReview {
                            yearReviewCard(year: yearReview.year)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                    filterBar
                        .padding(.top, 24)

                    content
                        .padding(.top, 12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
                .frame(maxWidth: SeepLayout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: router.scrollToTopToken[.finished]) { _, _ in
                withAnimation { proxy.scrollTo(ScrollAnchor.top, anchor: .top) }
            }
        }
        .background(Color.gray2)
        .onAppear { viewModel.send(.onAppear) }
        .trackScreen(viewModel.screenName)
        .onChange(of: viewModel.route) { _, route in
            handle(route)
        }
        .seepFullScreenCover(item: $presentedYearReview) { presented in
            YearReviewScreen(year: presented.year)
        }
    }

    // MARK: Subviews

    private var headline: some View {
        Group {
            if viewModel.state.isEmpty {
                HeadlineText(text: Strings.Finished.headlineEmpty, boldPart: Strings.Finished.headlineEmptyBold)
            } else {
                countHeadline
            }
        }
        .accessibilityAddTraits(.isHeader)
    }

    /// "지금까지 이룬 싶이 / **n개** 모였어요!" — 숫자만 tennis-green (R-17)
    private var countHeadline: some View {
        let full = Strings.Finished.headlineFormat(viewModel.state.totalCount)
        let count = Strings.Finished.headlineCountFormat(viewModel.state.totalCount)
        let bold = Strings.Finished.headlineBold
        var text = Text(verbatim: full).font(.appleLight(size: 22))
        if let countRange = full.range(of: count), let boldRange = full.range(of: bold) {
            text = Text(verbatim: String(full[..<countRange.lowerBound])).font(.appleLight(size: 22))
                + Text(verbatim: count).font(.appleBold(size: 22)).foregroundStyle(Color.tennisGreen)
                + Text(verbatim: String(full[countRange.upperBound..<boldRange.lowerBound])).font(.appleLight(size: 22))
                + Text(verbatim: bold).font(.appleBold(size: 22))
        }
        return text
            .lineSpacing(9)
            .foregroundStyle(Color.gray5)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func yearReviewCard(year: Int) -> some View {
        Button {
            viewModel.send(.tapYearReview)
        } label: {
            HStack {
                Text(Strings.Finished.YearReviewCard.titleFormat(String(year)))
                    .font(.appleSemiBold(size: 16))
                    .foregroundStyle(Color.gray5)
                Spacer(minLength: 8)
                Text(Strings.Finished.YearReviewCard.more)
                    .font(.appleExtraBold(size: 14))
                    .foregroundStyle(Color.seepBlue)
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var filterBar: some View {
        HStack(spacing: 0) {
            CategoryTabs(titles: filters.map(filterTitle), selectedIndex: filterIndexBinding)
                .padding(.leading, 12)
            Spacer(minLength: 8)
            Button {
                viewModel.send(.tapSearch)
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.gray4)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(Strings.Finished.search))
            .padding(.trailing, 10)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isEmpty {
            emptyView(title: Strings.Finished.Empty.title, description: Strings.Finished.Empty.description)
        } else if viewModel.state.isFilteredEmpty {
            emptyView(title: Strings.Finished.Empty.filtered, description: nil)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.state.sections) { section in
                    Text(verbatim: section.title)
                        .font(.appleMedium(size: 14))
                        .foregroundStyle(Color.gray4)
                        .padding(.top, 4)
                        .padding(.leading, 2)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(section.rows) { row in
                        Button {
                            viewModel.send(.tapWish(id: row.id))
                        } label: {
                            WishRow(
                                model: row,
                                farFutureText: Strings.homeInFarFurture,
                                noDateText: Strings.homeNoDeanline,
                                dimsFinished: false
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func emptyView(title: String, description: String?) -> some View {
        VStack(spacing: 6) {
            Text(verbatim: title)
                .font(.appleMedium(size: 14))
                .foregroundStyle(Color.gray4)
            if let description {
                Text(verbatim: description)
                    .font(.appleMedium(size: 12))
                    .foregroundStyle(Color.gray4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: Helpers

    private var filterIndexBinding: Binding<Int> {
        Binding(
            get: { filters.firstIndex(of: viewModel.state.filter) ?? 0 },
            set: { viewModel.send(.selectFilter(filters[$0])) }
        )
    }

    private func filterTitle(_ filter: Category?) -> String {
        switch filter {
        case nil: return Strings.Finished.Filter.all
        case .wantToDo: return Strings.Finished.Filter.wantToDo
        case .wantToGet: return Strings.Finished.Filter.wantToGet
        case .wantToGo: return Strings.Finished.Filter.wantToGo
        }
    }

    // MARK: Route

    private func handle(_ route: FinishedViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .push(let destination):
            router.push(destination)
        case .yearReview(let year):
            presentedYearReview = PresentedYear(year: year)
        }
        viewModel.send(.routeHandled)
    }
}

private enum ScrollAnchor: Hashable {
    case top
}

private struct PresentedYear: Identifiable {
    let year: Int
    var id: Int { year }
}

/// 배지 카드: "배지 n/8" + "모아보기 ›" + 최근 배지 5칸, 빈 칸은 점선 원 (R-18)
struct FinishedBadgeCard: View {
    let earnedCount: Int
    let recentBadges: [BadgeType]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(Strings.Finished.BadgeCard.titleFormat(earnedCount, BadgeType.allCases.count))
                        .font(.appleSemiBold(size: 16))
                        .foregroundStyle(Color.gray5)
                    Spacer(minLength: 8)
                    Text(Strings.Finished.BadgeCard.more)
                        .font(.appleExtraBold(size: 14))
                        .foregroundStyle(Color.seepBlue)
                }
                HStack(spacing: 10) {
                    ForEach(0..<FinishedViewModel.recentBadgeLimit, id: \.self) { index in
                        if index < recentBadges.count {
                            FinishedBadgeMedal(type: recentBadges[index])
                        } else {
                            Circle()
                                .strokeBorder(Color.gray3, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                                .frame(width: 40, height: 40)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

/// 배지 메달 축소판(40). 얻은 배지 = tennis-green 링 + 숫자·카테고리 일러스트·"D-day" (GH-35 메달과 같은 내용)
private struct FinishedBadgeMedal: View {
    let type: BadgeType

    var body: some View {
        ZStack {
            Circle().fill(Color.gray1)
            Circle().strokeBorder(Color.tennisGreen, lineWidth: 2)
            switch type.medal {
            case .number(let number):
                Text(verbatim: "\(number)")
                    .font(.appleBold(size: 15))
                    .foregroundStyle(Color.gray5)
            case .category(let category):
                category.illustration
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            case .dday:
                Text(Strings.Badge.dday)
                    .font(.appleExtraBold(size: 9))
                    .foregroundStyle(Color.gray5)
            }
        }
        .frame(width: 40, height: 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: type.name))
    }
}
