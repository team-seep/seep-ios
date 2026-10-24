// swiftlint:disable file_length - 홈 한 화면에 고정·잠든 위시·회고 배너·배지·체크 위젯·완료 흐름이 함께 있다. 기능별 extension 으로 나눴다
import CoreGraphics
import Foundation
import Observation

extension HomeViewModel {
    enum Action: Equatable {
        /// 화면이 나타날 때마다. 처음이면 배지 초기화까지 하고, 다시 나타나면 상세·검색·지도에서 바뀐 것을 반영한다 (TC-113)
        case onAppear
        case selectCategory(Category)
        case tapSortOrder
        case selectSortOrder(HomeSortOrder)
        /// 필터 바 "순서 바꾸기" → 순서 바꾸기 모드 (GH-73 R-4)
        case tapReorder
        /// 순서 바꾸기 모드 "완료" (R-7)
        case finishReorder
        /// 순서 바꾸기 모드에서 옮길 수 있는 위시(고정 제외) 안의 이동 (R-5~R-7)
        case moveWish(from: IndexSet, to: Int)
        case toggleViewType
        /// 필터 바 "선택" → 여러 개 골라 지우기 (GH-86 R-3)
        case tapSelect
        case cancelSelection
        case selectAll
        /// 선택 모드 "{n}개 삭제" → 확인 알럿 (R-4)
        case tapDeleteSelected
        case confirmDeleteSelected
        case cancelDeleteSelected
        case tapWish(Wish)
        case tapFinish(Wish)
        case tapPinMenu(Wish)
        case delete(Wish)
        case tapSearch
        case tapPlaceMap
        case loadThumbnail(wishId: String, maxPixelSize: Int)

        // 잠든 위시 카드 (GH-30)
        case keepSleepingWish(Wish)
        case tapReleaseSleepingWish(Wish)
        case confirmReleaseSleepingWish(Wish)
        case cancelReleaseSleepingWish

        // 연말 회고 배너 (GH-34)
        case tapYearReviewBanner
        case closeYearReviewBanner
        case yearReviewDismissed

        /// 체크 위젯이 남긴 기록 처리. 싶 탭이 보일 때 첫 로드 직후·앱 활성화마다 (GH-48 R-7, R-8)
        case syncWidgetChanges
        /// 떠 있던 시트가 닫혔다(버튼·끌어내리기 모두)
        case sheetDismissed
        case errorAlertDismissed
    }

    struct State: Equatable {
        var category: Category = .wantToDo
        var sortOrder: HomeSortOrder
        var viewType: ViewType
        /// 순서 바꾸기 모드. 리스트 셀 + 손잡이, 탭 바·배너·잠든 위시 카드를 숨긴다 (GH-73 R-5)
        var isReordering = false
        /// 여러 개 골라 지우기 모드. 리스트 셀 + 체크, 탭 바를 숨긴다 (GH-86 R-3)
        var isSelecting = false
        var selectedIds: Set<String> = []
        /// 일괄 삭제 확인 알럿에 보일 개수. nil 이면 알럿 없음 (R-4)
        var deleteConfirmCount: Int?
        /// 헤드라인의 남은 개수. 첫 로드 전에는 nil
        var notFinishedCount: Int?
        var items: [HomeWishItem] = []
        /// 리스트 맨 위 잠든 위시 카드. 없으면 그리지 않는다 (GH-30 R-4)
        var sleepingWishCard: SleepingWishCard?
        var yearReviewBanner: YearReviewEligibility?
        var badges: [Badge] = []
        var sheet: HomeSheet?
        var yearReviewPresentation: YearReviewPresentation?
        /// 잠든 위시 "이제 됐어요" 확인 알럿 대상 (GH-30 R-7)
        var releaseAlertWish: Wish?
        var errorMessage: String?
        var toast: HomeToast?

        /// 가고 싶어요 탭에서만 지도 버튼을 보인다 (GH-31 R-5)
        var isPlaceMapVisible: Bool {
            category == .wantToGo
        }

        /// 리스트·그리드 모두 비었으면 빈 상태를 그린다
        var isEmpty: Bool {
            items.isEmpty && sleepingWishCard == nil
        }

        /// 순서 바꾸기 모드에서 맨 위에 흐리게 고정된 위시 (끌 수 없다, R-6)
        var pinnedItems: [HomeWishItem] {
            items.filter { $0.isPinned && !$0.wish.isSuccess }
        }

        /// 순서 바꾸기 모드에서 옮길 수 있는 위시. 방금 완료해 흐린 위시는 뺀다 (R-6)
        var movableItems: [HomeWishItem] {
            items.filter { !$0.isPinned && !$0.wish.isSuccess }
        }

        /// 선택 모드에서 고를 수 있는 위시. 방금 완료해 흐린 위시는 뺀다 (GH-86 R-5)
        var selectableItems: [HomeWishItem] {
            items.filter { !$0.wish.isSuccess }
        }

        /// 위시가 하나라도 있고 다른 모드가 아닐 때 "선택"이 보인다 (GH-86 R-3)
        var isSelectButtonVisible: Bool {
            !selectableItems.isEmpty && !isReordering && !isSelecting
        }

        /// "내가 정한 순서"이고 옮길 위시가 2개 이상일 때만 "순서 바꾸기"가 보인다 (R-4, TC-11)
        var isReorderButtonVisible: Bool {
            sortOrder == .manualOrder && movableItems.count >= 2 && !isReordering
        }
    }

    struct Dependency {
        let wishRepository: WishRepository
        let preference: Preference
        let notificationManager: NotificationManagerProtocol
        let logManager: LogManagerProtocol
        /// 오늘. 회고 배너 노출 기간 판정용 (GH-34 R-8)
        let now: () -> Date
        let calendar: Calendar
        /// 회고 배너 노출 기간 (GH-34 R-9)
        let remoteConfigRepository: RemoteConfigRepository
        let linkPreviewCache: LinkPreviewCaching
        /// 잠든 위시 판정의 "오늘". 테스트에서 날짜를 고정한다 (GH-30 R-10)
        let dateProvider: () -> Date
        let photoStorage: WishPhotoStorage
        /// 체크 위젯이 App Group 에 남긴 기록 (GH-48)
        let widgetCheckStore: WidgetCheckStore
        /// 화면 이동·이룬 싶 탭 점·적기 시트의 기본 카테고리. 테스트에서는 없어도 된다
        let router: AppRouter?

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            preference: Preference = .shared,
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            logManager: LogManagerProtocol = LogManager.shared,
            now: @escaping () -> Date = Date.init,
            calendar: Calendar = .current,
            remoteConfigRepository: RemoteConfigRepository = RemoteConfigRepositoryImpl(),
            linkPreviewCache: LinkPreviewCaching = LinkPreviewCache.shared,
            dateProvider: @escaping () -> Date = Date.init,
            photoStorage: WishPhotoStorage = WishPhotoStorageImpl.shared,
            widgetCheckStore: WidgetCheckStore = .shared,
            router: AppRouter? = nil
        ) {
            self.wishRepository = wishRepository
            self.preference = preference
            self.notificationManager = notificationManager
            self.logManager = logManager
            self.now = now
            self.calendar = calendar
            self.remoteConfigRepository = remoteConfigRepository
            self.linkPreviewCache = linkPreviewCache
            self.dateProvider = dateProvider
            self.photoStorage = photoStorage
            self.widgetCheckStore = widgetCheckStore
            self.router = router
        }
    }
}

/// 홈 위에 뜨는 시트 (모두 `seepSheet`로 띄운다)
enum HomeSheet: Identifiable, Equatable {
    case sortOrder
    case finishNote(FinishNoteViewModel)
    case badgeCelebration(BadgeCelebrationViewModel)

    var id: String {
        switch self {
        case .sortOrder:
            return "sort-order"
        case .finishNote(let viewModel):
            return "finish-note-\(viewModel.wish.id)"
        case .badgeCelebration(let viewModel):
            return "badge-celebration-\(viewModel.badges.map(\.type.rawValue).joined(separator: ","))"
        }
    }

    static func == (lhs: HomeSheet, rhs: HomeSheet) -> Bool {
        lhs.id == rhs.id
    }
}

/// 연말 회고 풀스크린 (GH-34)
struct YearReviewPresentation: Identifiable, Equatable {
    let year: Int
    var id: Int { year }
}

/// 싶 탭(홈). 진행 중인 위시만 보이고, 완료하면 소감·배지 축하가 끝난 뒤 목록에서 빠진다 (GH-64 R-12 ~ R-16)
@Observable
final class HomeViewModel {
    let screenName: ScreenName = .home
    private(set) var state: State
    /// 그리드 셀 사진 썸네일. 위시 id → 이미지 (GH-36 R-8)
    private(set) var thumbnails: [String: CGImage] = [:]

    private let dependency: Dependency
    private var didFirstLoad = false
    /// 홈에서 완료해 소감·배지 흐름이 끝날 때까지 흐리게 남겨 두는 위시 (R-14)
    private var finishingWishIds: Set<String> = []
    /// 이번 완료 흐름이 홈 체크에서 시작했는지. 위젯에서 완료한 위시의 소감은 토스트·점을 붙이지 않는다
    private var isHomeFinishFlow = false
    private var toastId = 0
    private var didSendYearReviewImpression = false
    /// 이번 실행에서 카테고리별로 카드에 올리기로 고른 위시 id — 실행당 카테고리별 1번만 고른다
    private var sleepingWishIds: [Category: String] = [:]
    /// 이번 실행에서 카드를 처리한 카테고리 — 다음 잠든 위시를 이어서 띄우지 않는다
    private var resolvedSleepingCategories: Set<Category> = []
    /// 홈이 위젯 변경을 마지막으로 반영한 시각 (GH-48 R-8)
    private var widgetSyncedAt: Date?
    /// 홈 목록 원본(완료 흐름 중인 위시 포함)
    private var wishes: [Wish] = []

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
        self.state = State(sortOrder: dependency.preference.homeSortOrder, viewType: dependency.preference.viewType)
        if let router = dependency.router {
            state.category = router.homeCategory
        }
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            if !didFirstLoad {
                didFirstLoad = true
                initializeBadgesIfNeeded()
                widgetSyncedAt = dependency.now()
            }
            fetchWishes()

        case .selectCategory(let category):
            state.category = category
            // 다른 카테고리의 선택은 이어가지 않는다 (GH-86)
            state.selectedIds = []
            dependency.router?.homeCategory = category
            fetchWishes()

        case .tapSortOrder:
            state.sheet = .sortOrder

        case .selectSortOrder(let sortOrder):
            selectSortOrder(sortOrder)

        case .tapReorder:
            guard state.isReorderButtonVisible else { return }
            sendClickLog(objectId: .reorderWishes)
            state.isReordering = true

        case .finishReorder:
            state.isReordering = false

        case .moveWish(let source, let destination):
            moveWish(from: source, to: destination)

        case .toggleViewType:
            let viewType = state.viewType.toggle()
            state.viewType = viewType
            dependency.preference.viewType = viewType

        case .tapSelect:
            guard state.isSelectButtonVisible else { return }
            sendClickLog(objectId: .selectWishes)
            state.selectedIds = []
            state.isSelecting = true

        case .cancelSelection:
            state.isSelecting = false
            state.selectedIds = []

        case .selectAll:
            let all = Set(state.selectableItems.map(\.id))
            state.selectedIds = state.selectedIds == all ? [] : all

        case .tapDeleteSelected:
            guard !state.selectedIds.isEmpty else { return }
            state.deleteConfirmCount = state.selectedIds.count

        case .confirmDeleteSelected:
            state.deleteConfirmCount = nil
            deleteSelected()

        case .cancelDeleteSelected:
            state.deleteConfirmCount = nil

        case .tapWish(let wish):
            // 선택 모드에서는 상세 대신 선택/해제 (GH-86 R-5, TC-7)
            if state.isSelecting {
                toggleSelection(wish)
                return
            }
            // 잠든 위시 카드는 상세로 가지 않는다(카드에는 버튼만 있다)
            dependency.router?.push(.wishDetail(id: wish.id, isFinished: wish.isSuccess))

        case .tapFinish(let wish):
            guard !wish.isSuccess else { return }
            sendClickLog(objectId: .finish, extraParameters: [.category: state.category.rawValue])
            finish(wish)

        case .tapPinMenu(let wish):
            togglePin(wish: wish)

        case .delete(let wish):
            dependency.wishRepository.deleteWish(id: wish.id)
            // 지운 위시의 예약 알림이 남아 울리지 않게 같이 취소한다 (TC-106)
            dependency.notificationManager.cancelNotifications(wish: wish)
            cleanUpDeleted(wish)

        case .tapSearch:
            sendClickLog(objectId: .search)
            dependency.router?.push(.search(finishedOnly: false))

        case .tapPlaceMap:
            sendClickLog(objectId: .placeMap)
            dependency.router?.push(.placeMap)

        case .loadThumbnail(let wishId, let maxPixelSize):
            loadThumbnail(wishId: wishId, maxPixelSize: maxPixelSize)

        case .keepSleepingWish(let wish):
            keepSleepingWish(wish)

        case .tapReleaseSleepingWish(let wish):
            state.releaseAlertWish = wish

        case .confirmReleaseSleepingWish(let wish):
            state.releaseAlertWish = nil
            releaseSleepingWish(wish)

        case .cancelReleaseSleepingWish:
            state.releaseAlertWish = nil

        case .tapYearReviewBanner:
            presentYearReview()

        case .closeYearReviewBanner:
            closeYearReviewBanner()

        case .yearReviewDismissed:
            state.yearReviewPresentation = nil
            // 회고·목록에서 상세로 들어가 완료 취소·삭제했을 수 있어 다시 읽는다 (GH-34 R-7)
            fetchWishes()

        case .syncWidgetChanges:
            syncWidgetChanges()

        case .sheetDismissed:
            handleSheetDismissed()

        case .errorAlertDismissed:
            state.errorMessage = nil
        }
    }

    private func fetchWishes() {
        state.notFinishedCount = dependency.wishRepository.fetchNotFinishCount(category: state.category)
        // 싶 탭에는 완료하지 않은 위시만. 방금 완료해 소감을 묻는 중인 위시는 흐리게 남긴다 (R-14)
        wishes = dependency.wishRepository
            .fetchWishes(category: state.category, sort: state.sortOrder, isOnlyFinished: false)
            .filter { !$0.isSuccess || finishingWishIds.contains($0.id) }
        state.yearReviewBanner = makeYearReviewBanner()
        state.badges = calculateBadges()
        rebuildItems()
    }

    private func rebuildItems() {
        refreshSleepingWish()
        state.items = wishes.map { HomeWishItem(wish: $0, photoStorage: dependency.photoStorage) }
        if let banner = state.yearReviewBanner {
            sendYearReviewImpressionIfNeeded(banner: banner)
        }
    }

    private func sendClickLog(objectId: LogObjectId, extraParameters: [ParameterName: Any]? = nil) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: objectId,
            extraParameters: extraParameters
        ))
    }

    private func showToast(_ message: String) {
        toastId += 1
        state.toast = HomeToast(id: toastId, message: message)
    }

    private func showError(_ error: Error) {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            state.errorMessage = description
        } else {
            state.errorMessage = error.localizedDescription
        }
    }

    private func loadThumbnail(wishId: String, maxPixelSize: Int) {
        guard maxPixelSize > 0,
              thumbnails[wishId] == nil,
              let fileName = state.items.first(where: { $0.id == wishId })?.photoFileName else { return }

        dependency.photoStorage.loadThumbnail(fileName: fileName, maxPixelSize: maxPixelSize) { [weak self] image in
            guard let self else { return }
            if let image {
                thumbnails[wishId] = image
            }
        }
    }
}

// MARK: 고정·삭제 (GH-33, GH-28, GH-29, GH-36)
extension HomeViewModel {
    private func togglePin(wish: Wish) {
        guard !wish.isSuccess else { return }
        let category = state.category
        let shouldPin = !wish.isPinned
        // 메뉴는 완료 아닌 위시에만 뜨므로 목록에 이 카테고리의 고정 위시가 모두 있다
        let otherPinnedCount = wishes.filter { $0.isPinned && $0.id != wish.id }.count

        if shouldPin, otherPinnedCount >= Wish.maxPinCountPerCategory {
            showToast(Strings.Home.Pin.limitToast)
            dependency.logManager.sendEvent(event: ImpressionEvent(
                screen: screenName,
                objectType: .banner,
                objectId: .pinLimitToast,
                extraParameters: [.category: category.rawValue]
            ))
            return
        }

        switch dependency.wishRepository.updatePin(wishId: wish.id, isPinned: shouldPin) {
        case .success:
            if shouldPin {
                sendClickLog(objectId: .pinWish, extraParameters: [
                    .category: category.rawValue,
                    .count: otherPinnedCount + 1
                ])
            } else {
                sendClickLog(objectId: .unpinWish, extraParameters: [.category: category.rawValue])
            }
            // 고정 순서가 바뀌므로 정렬을 다시 적용한다 (GH-33 R-4)
            fetchWishes()
        case .failure(let error):
            showError(error)
        }
    }

    private func toggleSelection(_ wish: Wish) {
        guard !wish.isSuccess else { return }
        if state.selectedIds.contains(wish.id) {
            state.selectedIds.remove(wish.id)
        } else {
            state.selectedIds.insert(wish.id)
        }
    }

    /// 한 트랜잭션으로 지우고, 성공하면 알림·사진·링크 캐시를 정리한다. 실패하면 아무것도 지우지 않는다 (GH-86 R-4)
    private func deleteSelected() {
        let targets = wishes.filter { state.selectedIds.contains($0.id) }
        guard !targets.isEmpty else { return }
        switch dependency.wishRepository.deleteWishes(ids: targets.map(\.id)) {
        case .success:
            sendClickLog(objectId: .deleteSelectedWishes, extraParameters: [.count: targets.count])
            for wish in targets {
                dependency.notificationManager.cancelNotifications(wish: wish)
                cleanUpDeleted(wish)
            }
            state.isSelecting = false
            state.selectedIds = []
        case .failure(let error):
            showError(error)
        }
    }

    private func cleanUpDeleted(_ wish: Wish) {
        WishDeletionCleanup(
            preference: dependency.preference,
            linkPreviewCache: dependency.linkPreviewCache,
            photoStorage: dependency.photoStorage
        ).run(wish: wish)
        thumbnails[wish.id] = nil
        wishes.removeAll { $0.id == wish.id }
        state.notFinishedCount = dependency.wishRepository.fetchNotFinishCount(category: state.category)
        state.yearReviewBanner = makeYearReviewBanner()
        state.badges = calculateBadges()
        rebuildItems()
    }
}

// MARK: 완료 흐름 — 소감 → 배지 축하 → 목록에서 빠짐 (GH-25, GH-35, GH-64 R-14)
extension HomeViewModel {
    private func finish(_ wish: Wish) {
        guard let targetIndex = wishes.firstIndex(where: { $0.id == wish.id }) else { return }

        switch dependency.wishRepository.finishWish(wish: wish) {
        case .success(let result):
            // 목록이 들고 있던 값은 상세에서 바뀌기 전일 수 있어(예: 방금 봉인한 편지) 저장소에서 다시 읽는다 (GH-61 R-5)
            let finishedWish = dependency.wishRepository.fetchWish(id: result.id).flatMap { $0.isSuccess ? $0 : nil } ?? result
            dependency.notificationManager.cancelNotifications(wish: finishedWish)
            finishingWishIds.insert(finishedWish.id)
            isHomeFinishFlow = true
            wishes[targetIndex] = finishedWish
            state.notFinishedCount = dependency.wishRepository.fetchNotFinishCount(category: state.category)
            state.yearReviewBanner = makeYearReviewBanner()
            state.badges = calculateBadges()
            rebuildItems()
            presentFinishNote(wish: finishedWish)
        case .failure(let error):
            showError(error)
        }
    }

    private func presentFinishNote(wish: Wish) {
        let viewModel = FinishNoteViewModel(
            config: .init(wish: wish),
            dependency: .init(
                wishRepository: dependency.wishRepository,
                logManager: dependency.logManager,
                now: dependency.now,
                calendar: dependency.calendar
            )
        )
        viewModel.onSave = { [weak self] savedWish in
            self?.updateWish(savedWish)
        }
        state.sheet = .finishNote(viewModel)
    }

    private func updateWish(_ wish: Wish) {
        guard let index = wishes.firstIndex(where: { $0.id == wish.id }) else { return }
        wishes[index] = wish
        rebuildItems()
    }

    private func handleSheetDismissed() {
        let dismissedSheet = state.sheet
        state.sheet = nil
        switch dismissedSheet {
        case .finishNote:
            // 소감 시트가 닫힌 뒤에만 배지 축하를 띄운다 (GH-35 R-7)
            if !presentBadgeCelebrationIfNeeded() {
                completeFinishFlow()
            }
        case .badgeCelebration:
            completeFinishFlow()
        case .sortOrder, .none:
            break
        }
    }

    /// 완료 흐름이 끝났다: 완료한 위시를 목록에서 빼고, 토스트와 이룬 싶 탭 점을 붙인다 (R-14, TC-6)
    private func completeFinishFlow() {
        let wasHomeFinish = isHomeFinishFlow
        isHomeFinishFlow = false
        finishingWishIds.removeAll()
        fetchWishes()
        guard wasHomeFinish else { return }

        showToast(Strings.Home.Toast.addedToFinished)
        if let router = dependency.router, !router.showsFinishedDot {
            router.showsFinishedDot = true
            dependency.logManager.sendEvent(event: ImpressionEvent(
                screen: screenName,
                objectType: .banner,
                objectId: .finishedTabDot
            ))
        }
    }
}

// MARK: 잠든 위시 (GH-30)
extension HomeViewModel {
    /// 현재 카테고리에 보여줄 잠든 위시를 정한다 (GH-30 R-4, R-5)
    private func refreshSleepingWish() {
        let category = state.category
        guard !resolvedSleepingCategories.contains(category) else {
            state.sleepingWishCard = nil
            return
        }

        let today = dependency.dateProvider()
        let candidates = wishes.filter { !$0.isSuccess }
        if let wishId = sleepingWishIds[category] {
            if let wish = candidates.first(where: { $0.id == wishId }),
               SleepingWishPolicy.isSleeping(wish, today: today) {
                state.sleepingWishCard = makeSleepingCard(wish: wish, today: today)
            } else {
                // 수정·완료·삭제로 더 이상 잠든 위시가 아니면 이번 실행에서는 처리한 것으로 본다
                resolvedSleepingCategories.insert(category)
                state.sleepingWishCard = nil
            }
            return
        }

        guard let wish = SleepingWishPolicy.oldestSleepingWish(in: candidates, today: today) else {
            state.sleepingWishCard = nil
            return
        }
        sleepingWishIds[category] = wish.id
        state.sleepingWishCard = makeSleepingCard(wish: wish, today: today)
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: screenName,
            objectType: .card,
            objectId: .sleepingWishCard,
            extraParameters: [.category: category.rawValue]
        ))
    }

    private func makeSleepingCard(wish: Wish, today: Date) -> SleepingWishCard {
        SleepingWishCard(wish: wish, daysSinceTouched: SleepingWishPolicy.daysSinceTouched(wish, today: today))
    }

    private func keepSleepingWish(_ wish: Wish) {
        switch dependency.wishRepository.markChecked(wishId: wish.id) {
        case .success(let checkedWish):
            if let index = wishes.firstIndex(where: { $0.id == wish.id }) {
                wishes[index].lastCheckedAt = checkedWish.lastCheckedAt
            }
            resolvedSleepingCategories.insert(wish.category)
            rebuildItems()
            sendClickLog(objectId: .keepSleepingWish, extraParameters: [.category: wish.category.rawValue])
            showToast(Strings.Home.SleepingWish.Toast.keep)
        case .failure(let error):
            showError(error)
        }
    }

    private func releaseSleepingWish(_ wish: Wish) {
        dependency.wishRepository.deleteWish(id: wish.id)
        dependency.notificationManager.cancelNotifications(wish: wish)
        resolvedSleepingCategories.insert(wish.category)
        cleanUpDeleted(wish)
        sendClickLog(objectId: .releaseSleepingWish, extraParameters: [.category: wish.category.rawValue])
        showToast(Strings.Home.SleepingWish.Toast.release)
    }
}

// MARK: 연말 회고 배너 (GH-34)
extension HomeViewModel {
    private func makeYearReviewBanner() -> YearReviewEligibility? {
        YearReviewEligibility.make(
            remoteConfigRepository: dependency.remoteConfigRepository,
            wishRepository: dependency.wishRepository,
            now: dependency.now(),
            calendar: dependency.calendar,
            closedYears: dependency.preference.closedYearReviewYears
        )
    }

    private func sendYearReviewImpressionIfNeeded(banner: YearReviewEligibility) {
        guard !didSendYearReviewImpression else { return }
        didSendYearReviewImpression = true
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: screenName,
            objectType: .banner,
            objectId: .yearReviewBanner,
            extraParameters: [.year: banner.year]
        ))
    }

    private func presentYearReview() {
        guard let banner = state.yearReviewBanner else { return }
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .banner,
            objectId: .yearReviewBanner,
            extraParameters: [.year: banner.year]
        ))
        state.yearReviewPresentation = YearReviewPresentation(year: banner.year)
    }

    private func closeYearReviewBanner() {
        guard let banner = state.yearReviewBanner else { return }
        sendClickLog(objectId: .closeYearReviewBanner, extraParameters: [.year: banner.year])
        dependency.preference.closedYearReviewYears.append(banner.year)
        state.yearReviewBanner = nil
    }
}

// MARK: 배지 (GH-35)
extension HomeViewModel {
    private func calculateBadges() -> [Badge] {
        BadgeCalculator.calculate(finishedWishes: dependency.wishRepository.fetchAllFinishedWishes())
    }

    /// 업데이트 직후 첫 진입: 이미 얻은 배지는 축하 없이 축하함으로 넘긴다 (R-8)
    private func initializeBadgesIfNeeded() {
        guard !dependency.preference.isBadgeInitialized else { return }
        let earnedIds = calculateBadges().filter(\.isEarned).map(\.type.rawValue)
        dependency.preference.celebratedBadgeIds.formUnion(earnedIds)
        dependency.preference.isBadgeInitialized = true
    }

    /// 아직 축하하지 않은 배지가 있으면 축하 시트를 띄우고 바로 축하함에 넣는다 (R-6, R-7, R-9). 띄웠으면 true
    private func presentBadgeCelebrationIfNeeded() -> Bool {
        let badges = calculateBadges()
        state.badges = badges
        let celebratedIds = dependency.preference.celebratedBadgeIds
        let newBadges = badges.filter { $0.isEarned && !celebratedIds.contains($0.type.rawValue) }
        guard let first = newBadges.first else { return false }

        dependency.preference.celebratedBadgeIds.formUnion(newBadges.map(\.type.rawValue))

        let viewModel = BadgeCelebrationViewModel(
            config: .init(badges: newBadges, finishedCount: first.finishedCount),
            dependency: .init(logManager: dependency.logManager)
        )
        viewModel.onViewBadges = { [weak self] in
            guard let self else { return }
            state.sheet = nil
            dependency.router?.push(.badgeCollection)
            completeFinishFlow()
        }
        state.sheet = .badgeCelebration(viewModel)
        return true
    }
}

// MARK: 체크 위젯 (GH-48)
extension HomeViewModel {
    /// 위젯에서 완료한 위시의 알림을 지우고, 홈을 다시 읽고, 가장 최근 하나로 소감 시트를 띄운다 (R-7, R-8)
    private func syncWidgetChanges() {
        let sync = HomeWidgetCheckSync(
            store: dependency.widgetCheckStore,
            wishRepository: dependency.wishRepository,
            notificationManager: dependency.notificationManager,
            logManager: dependency.logManager
        )
        let result = sync.consume(lastSyncedAt: widgetSyncedAt)
        widgetSyncedAt = dependency.now()

        if result.needsReload {
            fetchWishes()
        }
        if let wish = result.finishNoteWish, state.sheet == nil {
            presentFinishNote(wish: wish)
        }
    }
}

// MARK: 내가 정한 순서 (GH-73)
extension HomeViewModel {
    private func selectSortOrder(_ sortOrder: HomeSortOrder) {
        sendClickLog(objectId: .sortOrder, extraParameters: [.type: sortOrder.rawValue])
        state.sortOrder = sortOrder
        dependency.preference.homeSortOrder = sortOrder
        state.sheet = nil
        fetchWishes()
    }

    private func moveWish(from source: IndexSet, to destination: Int) {
        guard state.isReordering, let sourceIndex = source.first else { return }
        var ids = state.movableItems.map(\.id)
        guard ids.indices.contains(sourceIndex) else { return }
        let movedId = ids[sourceIndex]
        ids.move(fromOffsets: source, toOffset: destination)
        guard ids != state.movableItems.map(\.id) else { return }

        switch dependency.wishRepository.moveWish(wishId: movedId, orderedIds: ids) {
        case .success:
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: screenName,
                objectType: .card,
                objectId: .moveWish
            ))
            fetchWishes()
        case .failure(let error):
            showError(error)
        }
    }
}
