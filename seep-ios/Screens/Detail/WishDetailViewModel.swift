import Foundation
import Observation

/// 상세를 어디서 열었는지. 이룬 싶 탭(완료 목록)에서 열면 수정 버튼이 없고 ⋯ 메뉴가 달라진다 (GH-59 R-8, R-9)
enum DetailMode: Equatable {
    case fromHome
    case fromFinish
}

extension WishDetailViewModel {
    enum Action: Equatable {
        /// 화면이 보일 때마다 저장소에서 위시를 다시 읽는다 (다른 화면·위젯에서 바뀌었을 수 있다)
        case onAppear
        /// 상단 바 "수정" (R-8)
        case tapEdit
        /// 상단 바 ⋯ (R-9)
        case tapMore
        case selectMoreItem(DetailMoreMenu.Item)
        /// 삭제 확인 알럿에서 "삭제"
        case confirmDelete
        /// 완료 취소 확인 알럿에서 "취소할게요"
        case confirmCancelFinish
        /// 수정 화면에서 저장하고 돌아왔다 (R-11)
        case editFinished(Wish)
        /// "이어지는 싶"의 다른 싶 줄 (GH-84 R-5)
        case tapChainWish(id: String)
        case routeHandled
    }

    enum Route: Equatable {
        case edit(Wish)
        case moreMenu([DetailMoreMenu.Item])
        case confirmDelete
        case confirmCancelFinish
        case sharePhoto(Wish)
        /// 이룬 위시에 이어서 작성 화면을 연다 (GH-84 R-3)
        case chainedWrite(Wish)
        /// 체인의 다른 위시 상세로 간다 (GH-84 R-5)
        case wishDetail(id: String, isFinished: Bool)
        case errorAlert(String)
        /// 삭제·완료 취소 뒤, 또는 위시가 지워져 있으면 상세를 닫는다
        case close
    }

    struct Config {
        let wishId: String
        let mode: DetailMode
    }

    struct State: Equatable {
        var wish: Wish?
        var summary: WishDetailSummary?
        var sections: [DetailSection] = []
        var letter: DetailLetter = .hidden
        /// 이어진 싶이 있을 때만 (GH-84 R-4, R-6)
        var chain: WishChain?
    }

    struct Dependency {
        let wishRepository: WishRepository
        let notificationManager: NotificationManagerProtocol
        let logManager: LogManagerProtocol
        let preference: Preference
        let photoStorage: WishPhotoStorage
        let linkMetadataProvider: LinkMetadataProviding
        let linkPreviewCache: LinkPreviewCaching
        let calendarManager: CalendarManagerProtocol
        let now: () -> Date
        let calendar: Calendar

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            logManager: LogManagerProtocol = LogManager.shared,
            preference: Preference = .shared,
            photoStorage: WishPhotoStorage = WishPhotoStorageImpl.shared,
            linkMetadataProvider: LinkMetadataProviding = LinkMetadataProvider(),
            linkPreviewCache: LinkPreviewCaching = LinkPreviewCache.shared,
            calendarManager: CalendarManagerProtocol = CalendarManager.shared,
            now: @escaping () -> Date = Date.init,
            calendar: Calendar = .current
        ) {
            self.wishRepository = wishRepository
            self.notificationManager = notificationManager
            self.logManager = logManager
            self.preference = preference
            self.photoStorage = photoStorage
            self.linkMetadataProvider = linkMetadataProvider
            self.linkPreviewCache = linkPreviewCache
            self.calendarManager = calendarManager
            self.now = now
            self.calendar = calendar
        }
    }
}

/// 위시 상세 = 읽는 문서 (GH-59 D2, GH-64 P2).
/// 문서 머리(제목·D-day·메타·메모)와 섹션 구성·상단 바·⋯ 메뉴·삭제·완료 취소를 맡고,
/// 섹션별 동작(단계 체크·모은 돈·링크·장소·사진·캘린더)은 섹션 ViewModel 이 맡아 바뀐 값을 돌려준다.
@Observable
final class WishDetailViewModel {
    let screenName: ScreenName = .wishDetail
    private(set) var state = State()
    private(set) var route: Route?

    private(set) var steps: DetailStepsViewModel?
    private(set) var savings: WishSavingsViewModel?
    private(set) var journal: WishJournalViewModel?
    private(set) var calendar: WishCalendarViewModel?
    private(set) var link: DetailLinkViewModel?
    private(set) var place: DetailPlaceViewModel?
    private(set) var photo: WishPhotoViewModel?

    private let config: Config
    private let dependency: Dependency

    /// 홈에서 연 상세에서만 "수정"이 보인다 (R-8)
    var isEditVisible: Bool {
        config.mode == .fromHome
    }

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
        if let wish = dependency.wishRepository.fetchWish(id: config.wishId) {
            reloadChain()
            apply(wish: wish)
            makeSectionViewModels(wish: wish)
        }
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            reload()
        case .tapEdit:
            pushEdit()
        case .tapMore:
            showMoreMenu()
        case .selectMoreItem(let item):
            handleMoreMenu(item: item)
        case .confirmDelete:
            deleteWish()
        case .confirmCancelFinish:
            cancelFinish()
        case .editFinished(let wish):
            apply(wish: wish)
            reloadSections(wish: wish)
        case .tapChainWish(let id):
            openChainWish(id: id)
        case .routeHandled:
            route = nil
        }
    }

    // MARK: 상단 바

    private func pushEdit() {
        guard isEditVisible, let wish = state.wish else { return }
        sendClickLog(objectId: .detailEdit)
        route = .edit(wish)
    }

    private func showMoreMenu() {
        sendClickLog(objectId: .detailMore)
        let items = DetailMoreMenu.items(context: .init(
            mode: config.mode,
            isCalendarVisible: calendar?.state.isVisible ?? false,
            isCalendarAdded: calendar?.state.isAdded ?? false,
            hasPhoto: photo?.hasPhoto ?? false
        ))
        route = .moreMenu(items)
    }

    private func handleMoreMenu(item: DetailMoreMenu.Item) {
        switch item {
        case .addCalendar:
            calendar?.send(.tapButton)
        case .share:
            guard let wish = state.wish else { return }
            route = .sharePhoto(wish)
        case .deletePhoto:
            photo?.send(.tapDelete)
        case .chainNext:
            guard let wish = state.wish else { return }
            sendClickLog(objectId: .chainNextWish)
            route = .chainedWrite(wish)
        case .delete:
            route = .confirmDelete
        case .cancelFinish:
            route = .confirmCancelFinish
        }
    }

    // MARK: 삭제 · 완료 취소

    private func deleteWish() {
        guard let wish = state.wish else { return }
        dependency.wishRepository.deleteWish(id: wish.id)
        // 지운 위시의 알림이 남아 울리지 않게 한다 (홈 삭제와 같음, GH-64 TC-106·604)
        dependency.notificationManager.cancelNotifications(wish: wish)
        WishDeletionCleanup(
            preference: dependency.preference,
            linkPreviewCache: dependency.linkPreviewCache,
            photoStorage: dependency.photoStorage
        ).run(wish: wish)
        route = .close
    }

    private func cancelFinish() {
        guard let wish = state.wish else { return }
        switch dependency.wishRepository.cancelFinish(wishId: wish.id) {
        case .success(let restoredWish):
            // 완료하면서 취소한 D-day 알림을 다시 예약한다 (GH-64 TC-605)
            dependency.notificationManager.reserveNotifications(wish: restoredWish)
            apply(wish: restoredWish)
            route = .close
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }

    // MARK: 위시 반영

    private func reload() {
        guard let wish = dependency.wishRepository.fetchWish(id: config.wishId) else {
            // 다른 곳(위젯 등)에서 지워졌다
            if state.wish != nil {
                route = .close
            }
            return
        }
        // `Wish ==`는 id 만 비교하므로 값이 같은지 따지지 않고 다시 반영한다
        reloadChain()
        apply(wish: wish)
        if steps == nil {
            makeSectionViewModels(wish: wish)
        } else {
            reloadSections(wish: wish)
        }
    }

    private func openChainWish(id: String) {
        guard let chain = state.chain, id != chain.current.id,
              let wish = (chain.previous + chain.next).first(where: { $0.id == id }) else { return }
        sendClickLog(objectId: .chainWishRow)
        route = .wishDetail(id: id, isFinished: wish.isSuccess)
    }

    /// 체인은 다른 위시가 바뀔 때도 달라지므로 화면이 보일 때마다 다시 읽는다 (GH-84 R-6)
    private func reloadChain() {
        let chain = dependency.wishRepository.fetchWishChain(wishId: config.wishId).flatMap { $0.isEmpty ? nil : $0 }
        if chain != state.chain {
            state.chain = chain
        }
    }

    private func apply(wish: Wish) {
        state.wish = wish
        let summary = WishDetailSummary(wish: wish, now: dependency.now(), calendar: dependency.calendar)
        if summary != state.summary {
            state.summary = summary
        }
        let sections = DetailSectionBuilder.sections(
            for: wish,
            hasPhoto: dependency.photoStorage.photoURL(fileName: wish.photoFileName) != nil,
            isPhotoEditable: config.mode == .fromFinish,
            hasChain: state.chain != nil,
            isJournalEditable: config.mode == .fromHome
        )
        if sections != state.sections {
            state.sections = sections
        }
        let letter = DetailLetter(wish: wish)
        if letter != state.letter {
            state.letter = letter
        }
    }

    /// 섹션이 저장한 값을 상세가 들고 있는 위시에 반영해, 수정 화면·공유로 넘길 위시가 최신이게 한다
    private func update(_ change: (inout Wish) -> Void) {
        guard var wish = state.wish else { return }
        change(&wish)
        apply(wish: wish)
    }

    private func makeSectionViewModels(wish: Wish) {
        let steps = DetailStepsViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: dependency.wishRepository, logManager: dependency.logManager)
        )
        steps.onUpdate = { [weak self] steps in
            self?.update { $0.steps = steps }
        }
        self.steps = steps

        let savings = WishSavingsViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: dependency.wishRepository, logManager: dependency.logManager)
        )
        savings.onUpdate = { [weak self] savings in
            self?.update { $0.savings = savings }
        }
        self.savings = savings

        let journal = WishJournalViewModel(
            config: .init(wish: wish, isEditable: config.mode == .fromHome),
            dependency: .init(wishRepository: dependency.wishRepository, logManager: dependency.logManager, now: dependency.now)
        )
        // 일지를 남기면 점검 시각도 바뀌므로(GH-95 R-6) 위시를 다시 읽어 수정 문서로 넘길 값을 맞춘다
        journal.onUpdate = { [weak self] in
            guard let self, let wish = dependency.wishRepository.fetchWish(id: config.wishId) else { return }
            apply(wish: wish)
        }
        self.journal = journal

        calendar = WishCalendarViewModel(
            config: .init(wish: wish, isAddable: config.mode == .fromHome),
            dependency: .init(
                calendarManager: dependency.calendarManager,
                preference: dependency.preference,
                logManager: dependency.logManager
            )
        )

        link = DetailLinkViewModel(
            config: .init(wish: wish),
            dependency: .init(
                linkMetadataProvider: dependency.linkMetadataProvider,
                linkPreviewCache: dependency.linkPreviewCache,
                logManager: dependency.logManager
            )
        )

        let place = DetailPlaceViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: dependency.wishRepository, logManager: dependency.logManager)
        )
        place.onUpdate = { [weak self] place in
            self?.update { $0.place = place }
        }
        self.place = place

        let photo = WishPhotoViewModel(
            config: .init(wish: wish, isEditable: config.mode == .fromFinish),
            dependency: .init(
                wishRepository: dependency.wishRepository,
                photoStorage: dependency.photoStorage,
                logManager: dependency.logManager
            )
        )
        photo.onUpdate = { [weak self] fileName in
            self?.update { $0.photoFileName = fileName }
        }
        self.photo = photo
    }

    private func reloadSections(wish: Wish) {
        steps?.send(.reload(wish.steps))
        savings?.send(.reload(wish))
        journal?.send(.reload(wish))
        calendar?.send(.reload(wish))
        link?.send(.reload(wish))
        place?.send(.reload(wish))
        photo?.send(.reload(wish))
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: objectId
        ))
    }
}
