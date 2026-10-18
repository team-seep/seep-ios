import Foundation
import Combine

extension WishPlaceViewModel {
    struct Input {
        /// 플레이스홀더 또는 "바꾸기" 탭 (검색 시트를 연다)
        let didTapPlace = PassthroughSubject<Void, Never>()
        /// 검색 시트에서 고른 장소
        let selectPlace = PassthroughSubject<WishPlace, Never>()
        /// "장소 지우기"
        let didTapDelete = PassthroughSubject<Void, Never>()
        /// 작성 화면에서 카테고리를 바꾸면 섹션을 접거나 편다
        let updateCategory = PassthroughSubject<Category, Never>()
        /// 작성 화면에서 이모지를 고르면 지도 미리보기 핀을 바꾼다
        let updateEmoji = PassthroughSubject<String, Never>()
        /// 상세: 수정 화면에서 돌아와 위시가 바뀌면 카테고리·이모지·장소를 갈아끼운다
        let reloadWish = PassthroughSubject<Wish, Never>()
    }

    struct Output {
        let screenName: ScreenName
        /// 가고 싶어요일 때만 섹션을 보인다 (R-1)
        let isVisible: CurrentValueSubject<Bool, Never>
        let place: CurrentValueSubject<WishPlace?, Never>
        /// 지도 미리보기 핀에 그릴 이모지
        let emoji: CurrentValueSubject<String, Never>
        /// 장소가 바뀔 때마다 보낸다. 상세는 Reactor 위시에 반영하고, 작성은 Reactor 상태에 담는다.
        let didUpdatePlace = PassthroughSubject<WishPlace?, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case presentPlaceSearch(PlaceSearchViewModel)
        case showErrorAlert(Error)
    }

    struct Config {
        let mode: Mode
    }

    enum Mode {
        /// 위시 상세: 고르거나 지우면 Repository 에 바로 저장한다 (R-4)
        case persisted(Wish)
        /// 위시 작성: 저장하지 않고 작성 완료 때 위시와 함께 저장된다 (R-4)
        case draft(category: Category, screenName: ScreenName)
    }

    struct State {
        var category: Category
        var place: WishPlace?
    }

    struct Dependency {
        let wishRepository: WishRepository
        let logManager: LogManagerProtocol
        /// 검색 시트를 열 때마다 새 검색기를 만든다 (MapKit completer 는 시트 하나에 하나)
        let makePlaceSearchService: () -> PlaceSearchServiceProtocol

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            logManager: LogManagerProtocol = LogManager.shared,
            makePlaceSearchService: @escaping () -> PlaceSearchServiceProtocol = { PlaceSearchService() }
        ) {
            self.wishRepository = wishRepository
            self.logManager = logManager
            self.makePlaceSearchService = makePlaceSearchService
        }
    }
}

/// 위시 상세·작성의 "장소" 섹션 (GH-31). 두 화면 모두 레거시 Reactor 라 GH-16 모으기 섹션처럼 이 섹션만 Combine ViewModel 로 붙인다.
final class WishPlaceViewModel {
    static let fallbackEmoji = "📍"

    let input = Input()
    let output: Output
    private var state: State
    private let config: Config
    private let dependency: Dependency
    private var cancellables = Set<AnyCancellable>()

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency

        switch config.mode {
        case .persisted(let wish):
            state = State(category: wish.category, place: wish.place)
            output = Output(
                screenName: .wishDetail,
                isVisible: .init(wish.category == .wantToGo),
                place: .init(wish.place),
                emoji: .init(Self.pinEmoji(wish.emoji))
            )
        case .draft(let category, let screenName):
            state = State(category: category, place: nil)
            output = Output(
                screenName: screenName,
                isVisible: .init(category == .wantToGo),
                place: .init(nil),
                emoji: .init(Self.fallbackEmoji)
            )
        }

        bind()
    }

    private func bind() {
        input.didTapPlace
            .withUnretained(self)
            .sink { (owner: WishPlaceViewModel, _) in
                owner.presentPlaceSearch()
            }
            .store(in: &cancellables)

        input.selectPlace
            .withUnretained(self)
            .sink { (owner: WishPlaceViewModel, place: WishPlace) in
                owner.save(place: place)
            }
            .store(in: &cancellables)

        input.didTapDelete
            .withUnretained(self)
            .sink { (owner: WishPlaceViewModel, _) in
                owner.save(place: nil)
            }
            .store(in: &cancellables)

        input.updateCategory
            .withUnretained(self)
            .sink { (owner: WishPlaceViewModel, category: Category) in
                owner.state.category = category
                owner.output.isVisible.send(category == .wantToGo)
            }
            .store(in: &cancellables)

        input.updateEmoji
            .withUnretained(self)
            .sink { (owner: WishPlaceViewModel, emoji: String) in
                owner.output.emoji.send(Self.pinEmoji(emoji))
            }
            .store(in: &cancellables)

        input.reloadWish
            .withUnretained(self)
            .sink { (owner: WishPlaceViewModel, wish: Wish) in
                owner.state.category = wish.category
                owner.state.place = wish.place
                owner.output.isVisible.send(wish.category == .wantToGo)
                owner.output.emoji.send(Self.pinEmoji(wish.emoji))
                owner.output.place.send(wish.place)
            }
            .store(in: &cancellables)
    }

    private func presentPlaceSearch() {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .button,
            objectId: .addPlace
        ))

        let viewModel = PlaceSearchViewModel(dependency: .init(
            placeSearchService: dependency.makePlaceSearchService(),
            logManager: dependency.logManager
        ))
        viewModel.output.didSelectPlace
            .subscribe(input.selectPlace)
            .store(in: &viewModel.cancellables)
        output.route.send(.presentPlaceSearch(viewModel))
    }

    private func save(place: WishPlace?) {
        switch config.mode {
        case .persisted(let wish):
            switch dependency.wishRepository.updatePlace(wishId: wish.id, place: place) {
            case .success(let updatedWish):
                apply(place: updatedWish.place)
            case .failure(let error):
                output.route.send(.showErrorAlert(error))
            }
        case .draft:
            apply(place: place)
        }
    }

    private func apply(place: WishPlace?) {
        state.place = place
        output.place.send(place)
        output.didUpdatePlace.send(place)
    }

    private static func pinEmoji(_ emoji: String) -> String {
        return emoji.isEmpty ? fallbackEmoji : emoji
    }
}
