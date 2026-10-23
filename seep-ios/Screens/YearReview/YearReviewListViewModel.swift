import Foundation
import Observation

extension YearReviewListViewModel {
    enum Action: Equatable {
        /// 나타날 때마다 다시 읽는다. 상세에서 완료 취소·삭제하고 돌아온 경우를 반영한다 (GH-34 R-7)
        case onAppear
        case tapWish(IndexPath)
        case routeHandled
    }

    struct State: Equatable {
        var totalCount = 0
        var sections: [Section] = []
    }

    struct Section: Hashable, Identifiable {
        let month: Int
        let items: [Item]

        var id: Int { month }
    }

    struct Item: Hashable, Identifiable {
        let wish: Wish
        /// 소감이 있으면 “소감”, 없으면 nil (완료일을 보인다)
        let note: String?
        /// MM.dd
        let finishDateText: String

        var id: String { wish.id }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.wish.id == rhs.wish.id && lhs.note == rhs.note && lhs.finishDateText == rhs.finishDateText
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(wish.id)
            hasher.combine(note)
            hasher.combine(finishDateText)
        }
    }

    enum Route: Equatable {
        case wishDetail(id: String)
    }

    struct Config {
        let year: Int
    }

    struct Dependency {
        let wishRepository: WishRepository
        let calendar: Calendar

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            calendar: Calendar = .current
        ) {
            self.wishRepository = wishRepository
            self.calendar = calendar
        }
    }
}

/// 올해 이룬 싶 모두 보기 — 달별 목록 (GH-34 R-6)
@Observable
final class YearReviewListViewModel {
    let screenName: ScreenName = .yearReviewList
    let year: Int
    private(set) var state = State()
    private(set) var route: Route?

    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.year = config.year
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            load()
        case .tapWish(let indexPath):
            guard let item = state.sections[safe: indexPath.section]?.items[safe: indexPath.item] else { return }
            route = .wishDetail(id: item.wish.id)
        case .routeHandled:
            route = nil
        }
    }

    private func load() {
        let calendar = dependency.calendar
        let wishes = YearReviewViewModel.fetchWishes(year: year, wishRepository: dependency.wishRepository, calendar: calendar)
        let summary = YearReviewSummary.make(wishes: wishes, year: year, calendar: calendar)
        let sections = summary.monthGroups.map { group in
            Section(month: group.month, items: group.wishes.map { makeItem(wish: $0, calendar: calendar) })
        }
        state = State(totalCount: summary.totalCount, sections: sections)
    }

    private func makeItem(wish: Wish, calendar: Calendar) -> Item {
        let finishDate = wish.finishDate ?? Date()
        let components = calendar.dateComponents([.month, .day], from: finishDate)
        let finishDateText = String(format: "%02d.%02d", components.month ?? 0, components.day ?? 0)
        let note = wish.finishNote.isEmpty ? nil : Strings.Home.FinishNote.cellFormat(wish.finishNote)
        return Item(wish: wish, note: note, finishDateText: finishDateText)
    }
}
