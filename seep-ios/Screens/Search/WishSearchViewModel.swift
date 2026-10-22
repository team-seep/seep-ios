import Foundation
import Observation

struct WishSearchSection: Equatable, Identifiable {
    let category: Category
    let items: [WishSearchResultItem]

    var id: String { category.rawValue }
}

struct WishSearchResultItem: Equatable, Identifiable {
    let wish: Wish
    /// 제목에서 일치한 범위. 해시태그·메모에서만 찾았으면 nil
    let titleHighlightRange: NSRange?
    /// 제목이 아니라 메모에서 찾았을 때만 값이 있다 — 셀에서 뱃지 줄 대신 보여준다
    let memoSnippet: WishSearchMemoSnippet?

    var id: String { wish.id }
}

extension WishSearchViewModel {
    enum Action: Equatable {
        /// 나타날 때마다. 상세에서 위시를 바꾸고 돌아오면 같은 검색어로 다시 찾는다 (GH-32 R-8)
        case onAppear
        /// 디바운스는 화면에서 건다. ViewModel은 들어온 검색어로 바로 찾는다 (GH-32 R-3)
        case inputKeyword(String)
        case tapResult(IndexPath)
        case routeHandled
    }

    struct State: Equatable {
        var sections: [WishSearchSection] = []
        /// 검색어가 비어 있으면 nil — 개수 줄을 숨긴다
        var resultCount: Int?
        /// 결과 없음 안내에 넣을 검색어. 안내를 숨길 때는 nil
        var emptyKeyword: String?
    }

    enum Route: Equatable {
        case wishDetail(id: String, isFinished: Bool)
    }

    struct Config {
        /// 이룬 싶 탭에서 열면 완료한 위시만 찾는다 (GH-64 R-19, TC-202)
        let finishedOnly: Bool
    }

    struct Dependency {
        let wishRepository: WishRepository
        let logManager: LogManagerProtocol

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.wishRepository = wishRepository
            self.logManager = logManager
        }
    }
}

/// 제목·메모·해시태그로 세 카테고리 전체에서 위시를 찾는다 (GH-32)
@Observable
final class WishSearchViewModel {
    /// 결과 섹션 순서 (GH-32 R-4)
    static let categoryOrder: [Category] = [.wantToDo, .wantToGet, .wantToGo]

    let screenName: ScreenName = .wishSearch
    private(set) var state = State()
    private(set) var route: Route?

    private let config: Config
    private let dependency: Dependency
    private var keyword: String?
    /// 결과 없음 노출 로그를 보낸 검색어 — 검색어당 1회 (GH-32 TC-13)
    private var loggedEmptyKeywords: Set<String> = []

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            if keyword != nil {
                search()
            }
        case .inputKeyword(let text):
            keyword = WishSearchMatcher.normalize(text)
            search()
        case .tapResult(let indexPath):
            handleTapResult(indexPath: indexPath)
        case .routeHandled:
            route = nil
        }
    }

    private func search() {
        guard let keyword else {
            state = State()
            return
        }

        var wishes = dependency.wishRepository.searchWishes(keyword: keyword)
        if config.finishedOnly {
            wishes = wishes.filter(\.isSuccess)
        }
        let sections = Self.makeSections(wishes: wishes, keyword: keyword)
        let count = sections.reduce(0) { $0 + $1.items.count }

        state = State(
            sections: sections,
            resultCount: count == 0 ? nil : count,
            emptyKeyword: count == 0 ? keyword : nil
        )

        if count == 0 {
            sendEmptyImpressionLogIfNeeded(keyword: keyword)
        }
    }

    private func handleTapResult(indexPath: IndexPath) {
        guard let section = state.sections[safe: indexPath.section],
              let item = section.items[safe: indexPath.item] else { return }

        let totalCount = state.sections.reduce(0) { $0 + $1.items.count }
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .card,
            objectId: .searchResult,
            extraParameters: [.count: totalCount, .category: item.wish.category.rawValue]
        ))
        route = .wishDetail(id: item.wish.id, isFinished: item.wish.isSuccess)
    }

    private func sendEmptyImpressionLogIfNeeded(keyword: String) {
        let logKey = keyword.lowercased()
        guard !loggedEmptyKeywords.contains(logKey) else { return }
        loggedEmptyKeywords.insert(logKey)

        // 검색어 원문은 개인 기록이라 보내지 않는다
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: screenName,
            objectType: .card,
            objectId: .searchEmpty
        ))
    }

    /// 카테고리별로 묶고(결과 없는 카테고리는 뺀다), 섹션 안은 미완료 먼저·마감순으로 정렬한다 (GH-32 R-4)
    static func makeSections(wishes: [Wish], keyword: String) -> [WishSearchSection] {
        categoryOrder.compactMap { category in
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
        wishes.enumerated()
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
