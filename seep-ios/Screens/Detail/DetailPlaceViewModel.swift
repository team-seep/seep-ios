import Foundation
import Observation

extension DetailPlaceViewModel {
    enum Action: Equatable {
        /// "＋ 장소 붙이기" 또는 섹션 "변경" 탭 (검색 시트를 연다)
        case tapPlace
        /// 검색 시트에서 고른 장소
        case selectPlace(WishPlace)
        /// 길게 눌러 "장소 지우기"
        case tapDelete
        /// 수정 화면에서 돌아와 카테고리·장소가 바뀌었다
        case reload(Wish)
        case routeHandled
    }

    enum Route: Equatable {
        case placeSearch
        case errorAlert(String)
    }

    struct Config {
        let wish: Wish
    }

    struct State: Equatable {
        var place: WishPlace?
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

/// 상세 "장소" 섹션 (GH-31, GH-59 R-6). 고르거나 지우면 바로 저장한다 (GH-31 R-4)
@Observable
final class DetailPlaceViewModel {
    let screenName: ScreenName = .wishDetail
    private(set) var state: State
    private(set) var route: Route?
    /// 저장한 장소(nil = 지움). 상세가 위시에 반영한다
    var onUpdate: ((WishPlace?) -> Void)?

    private let wishId: String
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.wishId = config.wish.id
        self.dependency = dependency
        self.state = State(place: config.wish.place)
    }

    func send(_ action: Action) {
        switch action {
        case .tapPlace:
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: screenName,
                objectType: .button,
                objectId: .addPlace
            ))
            route = .placeSearch
        case .selectPlace(let place):
            save(place: place)
        case .tapDelete:
            save(place: nil)
        case .reload(let wish):
            state.place = wish.place
        case .routeHandled:
            route = nil
        }
    }

    private func save(place: WishPlace?) {
        switch dependency.wishRepository.updatePlace(wishId: wishId, place: place) {
        case .success(let updatedWish):
            state.place = updatedWish.place
            onUpdate?(updatedWish.place)
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }
}
