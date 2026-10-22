import Foundation
import Combine

extension LegacyYearReviewListViewModel {
    struct Input {
        /// 나타날 때마다 다시 읽는다. 상세에서 완료 취소·삭제하고 돌아온 경우를 반영한다 (R-7)
        let viewWillAppear = PassthroughSubject<Void, Never>()
        let didTapWish = PassthroughSubject<IndexPath, Never>()
        let didTapBack = PassthroughSubject<Void, Never>()
    }

    struct Output {
        let screenName: ScreenName = .yearReviewList
        let year: Int
        let totalCount = CurrentValueSubject<Int, Never>(0)
        let sections = CurrentValueSubject<[Section], Never>([])
        let route = PassthroughSubject<Route, Never>()
    }

    struct Section: Hashable {
        let month: Int
        let items: [Item]
    }

    struct Item: Hashable {
        let wish: Wish
        /// 소감이 있으면 “소감”, 없으면 nil (완료일을 보인다)
        let note: String?
        /// MM.dd
        let finishDateText: String

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.wish.id == rhs.wish.id && lhs.note == rhs.note && lhs.finishDateText == rhs.finishDateText
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(wish.id)
            hasher.combine(note)
            hasher.combine(finishDateText)
        }
    }

    enum Route {
        case pushWishDetail(WishDetailReactor)
        case pop
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

/// 올해 이룬 싶 모두 보기 — 달별 목록 (GH-34 R-6).
final class LegacyYearReviewListViewModel {
    let input = Input()
    let output: Output
    var cancellables = Set<AnyCancellable>()
    private let config: Config
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
        self.output = Output(year: config.year)
        bind()
    }

    private func bind() {
        input.viewWillAppear
            .withUnretained(self)
            .sink { (owner: LegacyYearReviewListViewModel, _) in
                owner.load()
            }
            .store(in: &cancellables)

        input.didTapWish
            .withUnretained(self)
            .sink { (owner: LegacyYearReviewListViewModel, indexPath: IndexPath) in
                guard let item = owner.output.sections.value[safe: indexPath.section]?.items[safe: indexPath.item] else { return }
                owner.output.route.send(.pushWishDetail(WishDetailReactor(wish: item.wish, wishService: WishService())))
            }
            .store(in: &cancellables)

        input.didTapBack
            .withUnretained(self)
            .sink { (owner: LegacyYearReviewListViewModel, _) in
                owner.output.route.send(.pop)
            }
            .store(in: &cancellables)
    }

    private func load() {
        let calendar = dependency.calendar
        let wishes = LegacyYearReviewViewModel.fetchWishes(
            year: config.year,
            wishRepository: dependency.wishRepository,
            calendar: calendar
        )
        let summary = YearReviewSummary.make(wishes: wishes, year: config.year, calendar: calendar)
        let sections = summary.monthGroups.map { group in
            Section(month: group.month, items: group.wishes.map { makeItem(wish: $0, calendar: calendar) })
        }

        output.totalCount.send(summary.totalCount)
        output.sections.send(sections)
    }

    private func makeItem(wish: Wish, calendar: Calendar) -> Item {
        let finishDate = wish.finishDate ?? Date()
        let components = calendar.dateComponents([.month, .day], from: finishDate)
        let finishDateText = String(format: "%02d.%02d", components.month ?? 0, components.day ?? 0)
        let note = wish.finishNote.isEmpty ? nil : Strings.Home.FinishNote.cellFormat(wish.finishNote)
        return Item(wish: wish, note: note, finishDateText: finishDateText)
    }
}
