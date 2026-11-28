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
        /// "근처에 가면 알려줘요" 토글. 켜려는 값 (GH-126 R-2)
        case toggleNearbyAlert(Bool)
        /// 수정 화면에서 돌아와 카테고리·장소가 바뀌었다
        case reload(Wish)
        case routeHandled
    }

    enum Route: Equatable {
        case placeSearch
        case errorAlert(String)
        /// 위치·알림 권한이 거부돼 근처 알림을 켤 수 없다. [설정 열기]/[닫기] 알럿 (GH-126 R-3)
        case nearbyAlertPermissionAlert
        case toast(String)
    }

    struct Config {
        let wish: Wish
        /// 근처 알림 토글을 보일 수 있는지. 완료 목록에서 연 상세는 숨긴다 (GH-126 R-2)
        var isNearbyAlertEditable = true
    }

    struct State: Equatable {
        var place: WishPlace?
        var isNearbyAlertOn = false
        /// 이룬 위시는 근처 알림을 걸지 않는다 (GH-126 R-7)
        var isSuccess = false
    }

    struct Dependency {
        let wishRepository: WishRepository
        let nearbyAlertScheduler: NearbyAlertSchedulerProtocol
        let logManager: LogManagerProtocol

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            nearbyAlertScheduler: NearbyAlertSchedulerProtocol = NearbyAlertScheduler.shared,
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.wishRepository = wishRepository
            self.nearbyAlertScheduler = nearbyAlertScheduler
            self.logManager = logManager
        }
    }
}

/// 상세 "장소" 섹션 (GH-31, GH-59 R-6). 고르거나 지우면 바로 저장한다 (GH-31 R-4).
/// 장소가 있으면 "근처에 가면 알려줘요" 토글로 300m 지역 알림을 켜고 끈다 (GH-126)
@Observable
final class DetailPlaceViewModel {
    let screenName: ScreenName = .wishDetail
    private(set) var state: State
    private(set) var route: Route?
    /// 저장한 장소(nil = 지움). 상세가 위시에 반영한다
    var onUpdate: ((WishPlace?) -> Void)?
    /// 저장한 근처 알림 켬 여부. 상세가 위시에 반영한다 (GH-126)
    var onNearbyAlertUpdate: ((Bool) -> Void)?

    private let wishId: String
    private let config: Config
    private let dependency: Dependency
    /// 권한을 묻는 중. 팝업이 떠 있는 동안 다시 눌러도 한 번만 묻는다
    private var isRequestingAuthorization = false

    /// 토글이 보이는지: 홈에서 연 상세, 못 이룬 위시, 장소가 있을 때만 (R-2)
    var isNearbyAlertVisible: Bool {
        config.isNearbyAlertEditable && !state.isSuccess && state.place != nil
    }

    init(config: Config, dependency: Dependency = Dependency()) {
        self.wishId = config.wish.id
        self.config = config
        self.dependency = dependency
        self.state = State(
            place: config.wish.place,
            isNearbyAlertOn: config.wish.nearbyAlertOn,
            isSuccess: config.wish.isSuccess
        )
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
        case .toggleNearbyAlert(let isOn):
            toggleNearbyAlert(isOn)
        case .reload(let wish):
            state.place = wish.place
            state.isNearbyAlertOn = wish.nearbyAlertOn
            state.isSuccess = wish.isSuccess
        case .routeHandled:
            route = nil
        }
    }

    private func save(place: WishPlace?) {
        switch dependency.wishRepository.updatePlace(wishId: wishId, place: place) {
        case .success(let updatedWish):
            state.place = updatedWish.place
            onUpdate?(updatedWish.place)
            applyNearbyAlert(updatedWish.nearbyAlertOn)
            if updatedWish.nearbyAlertOn {
                // 장소를 바꾸면 같은 식별자로 새 좌표에 다시 건다 (R-7)
                let scheduler = dependency.nearbyAlertScheduler
                let cancelCount = scheduler.cancelCount(wishId: wishId)
                Task { await scheduler.schedule(wish: updatedWish, cancelCount: cancelCount) }
            } else {
                // 장소를 지우면 저장소가 근처 알림을 껐다. 예약도 지운다 (R-7)
                dependency.nearbyAlertScheduler.cancel(wishId: wishId)
            }
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }

    // MARK: 근처 알림 (GH-126)

    private func toggleNearbyAlert(_ isOn: Bool) {
        guard isNearbyAlertVisible, isOn != state.isNearbyAlertOn, !isRequestingAuthorization else { return }
        // 권한 거부·한도로 켜지 못해도 누른 것은 1건 남긴다 (트래킹)
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: .nearbyAlert,
            extraParameters: [.enabled: isOn]
        ))
        if isOn {
            turnOn()
        } else {
            turnOff()
        }
    }

    private func turnOn() {
        // 한도에 닿았으면 권한을 묻지 않는다 (R-6)
        if dependency.nearbyAlertScheduler.isAtLimit(excluding: wishId) {
            showLimitToast()
            return
        }
        isRequestingAuthorization = true
        let scheduler = dependency.nearbyAlertScheduler
        Task { @MainActor [weak self] in
            let isGranted = await scheduler.requestAuthorization()
            guard let self else { return }
            isRequestingAuthorization = false
            guard isGranted else {
                route = .nearbyAlertPermissionAlert
                return
            }
            // 권한 팝업이 떠 있는 동안 다른 화면·동기화로 한도가 찼을 수 있다 (R-6)
            if scheduler.isAtLimit(excluding: wishId) {
                showLimitToast()
                return
            }
            switch dependency.wishRepository.updateNearbyAlert(wishId: wishId, isOn: true) {
            case .success(let updatedWish):
                applyNearbyAlert(updatedWish.nearbyAlertOn)
                await scheduler.schedule(wish: updatedWish)
            case .failure(let error):
                route = .errorAlert(error.localizedDescription)
            }
        }
    }

    private func turnOff() {
        switch dependency.wishRepository.updateNearbyAlert(wishId: wishId, isOn: false) {
        case .success:
            applyNearbyAlert(false)
            dependency.nearbyAlertScheduler.cancel(wishId: wishId)
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }

    private func showLimitToast() {
        route = .toast(Strings.Detail.Place.NearbyAlert.limitToast)
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: screenName,
            objectType: .banner,
            objectId: .nearbyAlertLimitToast
        ))
    }

    private func applyNearbyAlert(_ isOn: Bool) {
        guard isOn != state.isNearbyAlertOn else { return }
        state.isNearbyAlertOn = isOn
        onNearbyAlertUpdate?(isOn)
    }
}
