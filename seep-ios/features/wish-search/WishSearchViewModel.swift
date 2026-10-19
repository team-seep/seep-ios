import Foundation
import Combine

struct WishSearchSection: Equatable {
    let category: Category
    let items: [WishSearchResultItem]
}

struct WishSearchResultItem: Equatable {
    let wish: Wish
    /// 제목에서 일치한 범위. 해시태그·메모에서만 찾았으면 nil
    let titleHighlightRange: NSRange?
    /// 제목이 아니라 메모에서 찾았을 때만 값이 있다 — 셀에서 뱃지 줄 대신 보여준다
    let memoSnippet: WishSearchMemoSnippet?
}

extension WishSearchViewModel {
    struct Input {
        /// 디바운스는 화면(VC)에서 건다. ViewModel은 들어온 검색어로 바로 찾는다
        let inputKeyword = PassthroughSubject<String, Never>()
        let didTapResult = PassthroughSubject<IndexPath, Never>()

        // From WishDetail
        let wishDidChange = PassthroughSubject<Void, Never>()
    }

    struct Output {
        let screenName: ScreenName = .wishSearch
        let sections = CurrentValueSubject<[WishSearchSection], Never>([])
        /// 검색어가 비어 있으면 nil — 개수 줄을 숨긴다
        let resultCount = CurrentValueSubject<Int?, Never>(nil)
        /// 결과 없음 안내에 넣을 검색어. 안내를 숨길 때는 nil
        let emptyKeyword = CurrentValueSubject<String?, Never>(nil)
        /// 상세에서 위시가 바뀌었음을 홈에 알린다 (R-8)
        let didChangeWishes = PassthroughSubject<Void, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case pushWishDetail(WishDetailReactor)
    }

    struct State {
        var keyword: String?
        var sections: [WishSearchSection] = []
        /// 결과 없음 노출 로그를 보낸 검색어 — 검색어당 1회 (TC-13)
        var loggedEmptyKeywords: Set<String> = []
    }

    struct Dependency {
        let wishRepository: WishRepository
        let wishService: WishServiceProtocol
        let logManager: LogManagerProtocol

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            wishService: WishServiceProtocol = WishService(),
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.wishRepository = wishRepository
            self.wishService = wishService
            self.logManager = logManager
        }
    }
}

final class WishSearchViewModel {
    /// 결과 섹션 순서 (R-4)
    static let categoryOrder: [Category] = [.wantToDo, .wantToGet, .wantToGo]

    let input = Input()
    let output = Output()
    var cancellables = Set<AnyCancellable>()
    private var state = State()
    private let dependency: Dependency

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
        bind()
    }

    private func bind() {
        input.inputKeyword
            .withUnretained(self)
            .sink { (owner: WishSearchViewModel, keyword: String) in
                owner.state.keyword = WishSearchMatcher.normalize(keyword)
                owner.search()
            }
            .store(in: &cancellables)

        input.didTapResult
            .withUnretained(self)
            .sink { (owner: WishSearchViewModel, indexPath: IndexPath) in
                owner.handleTapResult(indexPath: indexPath)
            }
            .store(in: &cancellables)

        input.wishDidChange
            .withUnretained(self)
            .sink { (owner: WishSearchViewModel, _) in
                owner.search()
                owner.output.didChangeWishes.send(())
            }
            .store(in: &cancellables)
    }

    private func search() {
        guard let keyword = state.keyword else {
            state.sections = []
            output.sections.send([])
            output.resultCount.send(nil)
            output.emptyKeyword.send(nil)
            return
        }

        let wishes = dependency.wishRepository.searchWishes(keyword: keyword)
        let sections = Self.makeSections(wishes: wishes, keyword: keyword)
        let count = sections.reduce(0) { $0 + $1.items.count }

        state.sections = sections
        output.sections.send(sections)
        output.resultCount.send(count == 0 ? nil : count)
        output.emptyKeyword.send(count == 0 ? keyword : nil)

        if count == 0 {
            sendEmptyImpressionLogIfNeeded(keyword: keyword)
        }
    }

    private func handleTapResult(indexPath: IndexPath) {
        guard let section = state.sections[safe: indexPath.section],
              let item = section.items[safe: indexPath.item] else { return }

        let totalCount = state.sections.reduce(0) { $0 + $1.items.count }
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .card,
            objectId: .searchResult,
            extraParameters: [.count: totalCount, .category: item.wish.category.rawValue]
        ))
        pushWishDetail(wish: item.wish)
    }

    private func pushWishDetail(wish: Wish) {
        let reactor = WishDetailReactor(wish: wish, wishService: dependency.wishService)
        Publishers.Merge3(
            reactor.updateWishPublisher.map { _ in () },
            reactor.deleteWishPublisher.map { _ in () },
            reactor.cancelFinishPublisher.map { _ in () }
        )
        .subscribe(input.wishDidChange)
        .store(in: &reactor.cancellables)

        output.route.send(.pushWishDetail(reactor))
    }

    private func sendEmptyImpressionLogIfNeeded(keyword: String) {
        let logKey = keyword.lowercased()
        guard !state.loggedEmptyKeywords.contains(logKey) else { return }
        state.loggedEmptyKeywords.insert(logKey)

        // 검색어 원문은 개인 기록이라 보내지 않는다
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: output.screenName,
            objectType: .card,
            objectId: .searchEmpty
        ))
    }

    /// 카테고리별로 묶고(결과 없는 카테고리는 뺀다), 섹션 안은 미완료 먼저·마감순으로 정렬한다 (R-4)
    static func makeSections(wishes: [Wish], keyword: String) -> [WishSearchSection] {
        return categoryOrder.compactMap { category in
            let items = sortForSearch(wishes.filter { $0.category == category })
                .map { wish in
                    WishSearchResultItem(
                        wish: wish,
                        titleHighlightRange: WishSearchMatcher.titleHighlightRange(title: wish.title, keyword: keyword),
                        memoSnippet: WishSearchMatcher.memoSnippet(wish: wish, keyword: keyword)
                    )
                }
            return items.isEmpty ? nil : WishSearchSection(category: category, items: items)
        }
    }

    /// 미완료 먼저, 그 안은 마감 가까운 순(마감 없음은 뒤). 같으면 저장소 순서를 지킨다
    static func sortForSearch(_ wishes: [Wish]) -> [Wish] {
        return wishes.enumerated()
            .sorted { lhs, rhs in
                if lhs.element.isSuccess != rhs.element.isSuccess {
                    return !lhs.element.isSuccess
                }
                switch (lhs.element.endDate, rhs.element.endDate) {
                case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
                    return lhsDate < rhsDate
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                default:
                    return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }
}
