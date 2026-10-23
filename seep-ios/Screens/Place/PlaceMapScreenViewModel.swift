import Foundation
import Observation

extension PlaceMapScreenViewModel {
    enum Action: Equatable {
        /// 처음 열 때·상세에서 돌아올 때 다시 불러온다 (GH-31 R-6)
        case onAppear
        /// 핀 선택(빈 곳을 눌러 풀리면 nil)
        case selectPin(wishId: String?)
        /// 아래 위시 카드 탭
        case tapCard
        case routeHandled
    }

    struct State: Equatable {
        /// 핀으로 보일 위시 (장소 있음 + 미완료 + 가고 싶어요)
        var wishes: [Wish] = []
        var selectedWishId: String?
        /// 처음 불러왔을 때만 모든 핀이 들어오게 영역을 맞춘다 (R-6). 돌아올 때는 보던 영역을 유지한다
        var cameraFit: CameraFit?

        var count: Int { wishes.count }
        var isEmpty: Bool { wishes.isEmpty }
        var selectedWish: Wish? { wishes.first { $0.id == selectedWishId } }
    }

    /// 영역 맞추기 요청. `id`가 바뀔 때마다 View 가 카메라를 옮긴다
    struct CameraFit: Equatable {
        let id: Int
        let wishIds: [String]
    }

    enum Route: Equatable {
        case wishDetail(id: String)
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

/// "가고 싶은 곳 지도" (GH-31 R-6~R-8, GH-64 TC-38·TC-1001~1002)
@Observable
final class PlaceMapScreenViewModel {
    let screenName: ScreenName = .placeMap
    private(set) var state = State()
    private(set) var route: Route?

    private let dependency: Dependency
    private var fitCount = 0

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    /// 지도에 핀으로 보일 위시: 가고 싶어요 + 장소 있음 + 미완료 (R-6)
    static func pinnedWishes(_ wishes: [Wish]) -> [Wish] {
        wishes.filter { $0.category == .wantToGo && $0.place != nil && !$0.isSuccess }
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            load()
        case .selectPin(let wishId):
            select(wishId: wishId)
        case .tapCard:
            pushSelectedWishDetail()
        case .routeHandled:
            route = nil
        }
    }

    private func load() {
        let wishes = Self.pinnedWishes(dependency.wishRepository.fetchWishes(
            category: .wantToGo,
            sort: .deadlineOrder,
            isOnlyFinished: false
        ))
        state.wishes = wishes

        // 상세에서 장소를 지우거나 완료했으면 선택도 푼다
        if let selectedWishId = state.selectedWishId, !wishes.contains(where: { $0.id == selectedWishId }) {
            state.selectedWishId = nil
        }

        if fitCount == 0 {
            fitCount += 1
            state.cameraFit = CameraFit(id: fitCount, wishIds: wishes.map(\.id))
        }
    }

    private func select(wishId: String?) {
        guard let wishId else {
            state.selectedWishId = nil
            return
        }
        guard state.wishes.contains(where: { $0.id == wishId }) else { return }
        state.selectedWishId = wishId
    }

    private func pushSelectedWishDetail() {
        guard let wish = state.selectedWish else { return }
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .card,
            objectId: .placeMapWish
        ))
        route = .wishDetail(id: wish.id)
    }
}
