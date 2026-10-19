import Foundation
import Combine

extension PlaceMapViewModel {
    struct Input {
        /// 처음 열 때·상세에서 돌아올 때 다시 불러온다 (R-6)
        let viewWillAppear = PassthroughSubject<Void, Never>()
        /// 핀 탭 — 위시 id
        let didSelectPin = PassthroughSubject<String, Never>()
        let didDeselectPin = PassthroughSubject<Void, Never>()
        /// 아래 위시 카드 탭
        let didTapCard = PassthroughSubject<Void, Never>()
        let didTapBack = PassthroughSubject<Void, Never>()
    }

    struct Output {
        let screenName: ScreenName = .placeMap
        /// 핀으로 보일 위시 (장소 있음 + 미완료 + 가고 싶어요)
        let wishes = CurrentValueSubject<[Wish], Never>([])
        let count = CurrentValueSubject<Int, Never>(0)
        let isEmpty = CurrentValueSubject<Bool, Never>(false)
        let selectedWish = CurrentValueSubject<Wish?, Never>(nil)
        /// 처음 불러왔을 때만 모든 핀이 들어오게 영역을 맞춘다 (R-6). 돌아올 때는 보던 영역을 유지한다.
        let fitAllPins = PassthroughSubject<[Wish], Never>()
        /// 지도에서 들어간 상세에서 위시가 바뀌었다. 홈 목록도 다시 불러온다.
        let didChangeWishes = PassthroughSubject<Void, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case pushWishDetail(WishDetailReactor)
        case pop
    }

    struct State {
        var wishes: [Wish] = []
        var selectedWishId: String?
        var hasLoaded = false
    }

    struct Dependency {
        let wishRepository: WishRepository
        let logManager: LogManagerProtocol
        let wishService: WishServiceProtocol

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            logManager: LogManagerProtocol = LogManager.shared,
            wishService: WishServiceProtocol = WishService()
        ) {
            self.wishRepository = wishRepository
            self.logManager = logManager
            self.wishService = wishService
        }
    }
}

/// "가고 싶은 곳 지도" (GH-31 R-6~R-8).
final class PlaceMapViewModel {
    let input = Input()
    let output = Output()
    var cancellables = Set<AnyCancellable>()
    private var state = State()
    private let dependency: Dependency

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
        bind()
    }

    /// 지도에 핀으로 보일 위시: 가고 싶어요 + 장소 있음 + 미완료 (R-6)
    static func pinnedWishes(_ wishes: [Wish]) -> [Wish] {
        return wishes.filter { $0.category == .wantToGo && $0.place != nil && !$0.isSuccess }
    }

    private func bind() {
        input.viewWillAppear
            .withUnretained(self)
            .sink { (owner: PlaceMapViewModel, _) in
                owner.load()
            }
            .store(in: &cancellables)

        input.didSelectPin
            .withUnretained(self)
            .sink { (owner: PlaceMapViewModel, wishId: String) in
                owner.select(wishId: wishId)
            }
            .store(in: &cancellables)

        input.didDeselectPin
            .withUnretained(self)
            .sink { (owner: PlaceMapViewModel, _) in
                owner.select(wishId: nil)
            }
            .store(in: &cancellables)

        input.didTapCard
            .withUnretained(self)
            .sink { (owner: PlaceMapViewModel, _) in
                owner.pushSelectedWishDetail()
            }
            .store(in: &cancellables)

        input.didTapBack
            .withUnretained(self)
            .sink { (owner: PlaceMapViewModel, _) in
                owner.output.route.send(.pop)
            }
            .store(in: &cancellables)
    }

    private func load() {
        let wishes = Self.pinnedWishes(dependency.wishRepository.fetchWishes(
            category: .wantToGo,
            sort: .deadlineOrder,
            isOnlyFinished: false
        ))
        state.wishes = wishes
        output.wishes.send(wishes)
        output.count.send(wishes.count)
        output.isEmpty.send(wishes.isEmpty)

        // 상세에서 장소를 지우거나 완료했으면 선택도 푼다
        if let selectedWishId = state.selectedWishId, !wishes.contains(where: { $0.id == selectedWishId }) {
            select(wishId: nil)
        } else {
            select(wishId: state.selectedWishId)
        }

        if !state.hasLoaded {
            state.hasLoaded = true
            output.fitAllPins.send(wishes)
        }
    }

    private func select(wishId: String?) {
        state.selectedWishId = wishId
        output.selectedWish.send(state.wishes.first { $0.id == wishId })
    }

    private func pushSelectedWishDetail() {
        guard let wish = state.wishes.first(where: { $0.id == state.selectedWishId }) else { return }
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .card,
            objectId: .placeMapWish
        ))

        let reactor = WishDetailReactor(wish: wish, wishService: dependency.wishService)
        Publishers.Merge3(
            reactor.updateWishPublisher,
            reactor.deleteWishPublisher,
            reactor.cancelFinishPublisher
        )
        .mapVoid
        .subscribe(output.didChangeWishes)
        .store(in: &reactor.cancellables)

        output.route.send(.pushWishDetail(reactor))
    }
}
