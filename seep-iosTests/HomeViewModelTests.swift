// swiftlint:disable file_length - 2.4.0 홈 기능(고정·링크·잠든 위시·사진·캘린더·검색) 테스트가 한 파일에 모임. 기능별 파일 분리는 후속 작업
import XCTest
import Combine

@testable import seep_ios_dev

final class HomeViewModelTests: XCTestCase {
    private var sut: HomeViewModel!
    private var mockRepository: MockWishRepository!
    private var mockNotificationManager: MockNotificationManager!
    private var mockLinkPreviewCache: MockLinkPreviewCache!
    private var mockPhotoStorage: MockWishPhotoStorage!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        mockNotificationManager = MockNotificationManager()
        mockLinkPreviewCache = MockLinkPreviewCache()
        mockPhotoStorage = MockWishPhotoStorage()
        cancellables = []

        let dependency = HomeViewModel.Dependency(
            wishRepository: mockRepository,
            preference: Preference(name: "test"),
            notificationManager: mockNotificationManager,
            logManager: MockLogManager(),
            linkPreviewCache: mockLinkPreviewCache,
            photoStorage: mockPhotoStorage
        )
        sut = HomeViewModel(dependency: dependency)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockNotificationManager = nil
        mockLinkPreviewCache = nil
        mockPhotoStorage = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - finishWish 알림 취소 테스트

    func test_finishWish_success_cancelsNotifications() {
        // given
        let wish = Wish(
            id: "test-wish-1",
            emoji: "🎯",
            category: .wantToDo,
            title: "테스트 위시",
            endDate: Date(),
            notifications: [SeepNotification(type: .dayAgo)]
        )
        let finishedWish = Wish(
            id: wish.id,
            emoji: wish.emoji,
            category: wish.category,
            title: wish.title,
            endDate: wish.endDate,
            finishDate: Date(),
            notifications: wish.notifications,
            isSuccess: true
        )

        mockRepository.fetchWishesResult = [wish]
        mockRepository.fetchNotFinishCountResult = 1
        mockRepository.finishWishResult = .success(finishedWish)

        // 위시 목록 로드
        sut.input.firstLoad.send()

        // when
        sut.input.didTapFinish.send(wish)

        // then
        XCTAssertEqual(mockNotificationManager.cancelledWishes.count, 1)
        XCTAssertEqual(mockNotificationManager.cancelledWishes.first?.id, wish.id)
    }

    func test_finishWish_failure_doesNotCancelNotifications() {
        // given
        let wish = Wish(
            id: "test-wish-2",
            emoji: "🎯",
            category: .wantToDo,
            title: "테스트 위시",
            endDate: Date()
        )

        mockRepository.fetchWishesResult = [wish]
        mockRepository.fetchNotFinishCountResult = 1
        mockRepository.finishWishResult = .failure(.targetNotFound)

        sut.input.firstLoad.send()

        // when
        sut.input.didTapFinish.send(wish)

        // then
        XCTAssertTrue(mockNotificationManager.cancelledWishes.isEmpty)
    }

    func test_finishWish_success_showsToast() {
        // given
        let wish = Wish(id: "test-wish-3", category: .wantToDo, title: "테스트")
        let finishedWish = Wish(id: wish.id, isSuccess: true)

        mockRepository.fetchWishesResult = [wish]
        mockRepository.fetchNotFinishCountResult = 1
        mockRepository.finishWishResult = .success(finishedWish)

        sut.input.firstLoad.send()

        let expectation = expectation(description: "toast")
        var toastMessage: String?

        sut.output.toast
            .sink { message in
                toastMessage = message
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // when
        sut.input.didTapFinish.send(wish)

        // then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(toastMessage)
    }

    func test_finishWish_failure_showsErrorAlert() {
        // given
        let wish = Wish(id: "test-wish-4", category: .wantToDo, title: "테스트")

        mockRepository.fetchWishesResult = [wish]
        mockRepository.fetchNotFinishCountResult = 1
        mockRepository.finishWishResult = .failure(.writeFailed)

        sut.input.firstLoad.send()

        let expectation = expectation(description: "error route")
        var receivedRoute: HomeViewModel.Route?

        sut.output.route
            .sink { route in
                receivedRoute = route
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // when
        sut.input.didTapFinish.send(wish)

        // then
        wait(for: [expectation], timeout: 1.0)
        if case .showErrorAlert = receivedRoute {
            // success
        } else {
            XCTFail("Expected showErrorAlert route, got \(String(describing: receivedRoute))")
        }
    }

    // MARK: - GH-25 완료 소감

    private func wishCellViewModels() -> [HomeWishCellViewModel] {
        return sut.output.dataSource.value.flatMap(\.items).compactMap {
            if case .wish(let viewModel) = $0 { return viewModel }
            return nil
        }
    }

    private func makeFinishNoteWishes() -> (wish: Wish, finished: Wish) {
        let wish = Wish(id: "finish-note-1", emoji: "🏃", title: "하프 마라톤 완주하기")
        var finished = wish
        finished.isSuccess = true
        finished.finishDate = Date()
        return (wish, finished)
    }

    // MARK: GH-25 TC1

    func test_GH25_TC1_완료체크에성공하면_토스트후_소감시트route가_해당위시로1회전달된다() {
        // Given
        let (wish, finished) = makeFinishNoteWishes()
        mockRepository.fetchWishesResult = [wish]
        mockRepository.finishWishResult = .success(finished)
        sut.input.firstLoad.send()
        var events: [String] = []
        var sheetWishIds: [String] = []
        sut.output.toast
            .sink { _ in events.append("toast") }
            .store(in: &cancellables)
        sut.output.route
            .sink { route in
                if case .presentFinishNoteBottomSheet(let viewModel) = route {
                    events.append("sheet")
                    sheetWishIds.append(viewModel.output.wish.id)
                }
            }
            .store(in: &cancellables)

        // When
        sut.input.didTapFinish.send(wish)

        // Then
        XCTAssertEqual(events, ["toast", "sheet"])
        XCTAssertEqual(sheetWishIds, [wish.id])
    }

    func test_GH25_TC1_완료저장에실패하면_소감시트를띄우지않는다() {
        // Given
        let (wish, _) = makeFinishNoteWishes()
        mockRepository.fetchWishesResult = [wish]
        mockRepository.finishWishResult = .failure(.writeFailed)
        sut.input.firstLoad.send()
        var sheetCount = 0
        sut.output.route
            .sink { route in
                if case .presentFinishNoteBottomSheet = route { sheetCount += 1 }
            }
            .store(in: &cancellables)

        // When
        sut.input.didTapFinish.send(wish)

        // Then
        XCTAssertEqual(sheetCount, 0)
    }

    // MARK: GH-25 TC6

    func test_GH25_TC6_소감이있는완료위시를_완료취소하면_소감이빈문자열이된다() {
        // Given
        var (_, finished) = makeFinishNoteWishes()
        finished.finishNote = "끝까지 뛰었다!"
        mockRepository.fetchWishesResult = [finished]
        sut.input.firstLoad.send()
        XCTAssertEqual(wishCellViewModels().first?.output.finishNote, "끝까지 뛰었다!")

        // When
        sut.input.cancelFinish.send(finished)

        // Then
        let cellWish = wishCellViewModels().first?.output.wish
        XCTAssertEqual(cellWish?.isSuccess, false)
        XCTAssertEqual(cellWish?.finishNote, "")
        XCTAssertNil(wishCellViewModels().first?.output.finishNote)
    }

    // MARK: GH-25 TC11

    func test_GH25_TC11_소감을저장하면_홈목록셀에바로반영된다() {
        // Given
        let (wish, finished) = makeFinishNoteWishes()
        mockRepository.fetchWishesResult = [wish]
        mockRepository.finishWishResult = .success(finished)
        var updatedFinished = finished
        updatedFinished.finishNote = "최고!"
        mockRepository.updateFinishNoteResult = .success(updatedFinished)
        sut.input.firstLoad.send()
        var sheetViewModel: FinishNoteViewModel?
        sut.output.route
            .sink { route in
                if case .presentFinishNoteBottomSheet(let viewModel) = route { sheetViewModel = viewModel }
            }
            .store(in: &cancellables)
        sut.input.didTapFinish.send(wish)

        // When
        sheetViewModel?.input.inputNote.send("최고!")
        sheetViewModel?.input.didTapSave.send(())

        // Then
        XCTAssertEqual(mockRepository.updateFinishNoteCalls.map(\.note), ["최고!"])
        XCTAssertEqual(wishCellViewModels().first?.output.finishNote, "최고!")
    }

    // MARK: GH-28 TC9

    func test_GH28_TC9_위시를삭제하면_캘린더추가기록이지워진다() {
        // Given
        let preference = Preference(name: "test-gh28")
        let wishes = [
            Wish(id: "wish-detail-delete", emoji: "🏝️", title: "상세에서 삭제", endDate: Date()),
            Wish(id: "wish-swipe-delete", emoji: "🎧", title: "스와이프 삭제", endDate: Date())
        ]
        wishes.forEach { preference.setCalendarEventId("event-\($0.id)", wishId: $0.id) }
        mockRepository.fetchWishesResult = wishes
        mockRepository.fetchNotFinishCountResult = wishes.count
        let viewModel = HomeViewModel(dependency: .init(
            wishRepository: mockRepository,
            preference: preference,
            notificationManager: mockNotificationManager,
            logManager: MockLogManager()
        ))
        viewModel.input.firstLoad.send()

        // When
        viewModel.input.deleteWish.send(wishes[0])
        viewModel.input.didTapDelete.send(0)

        // Then
        XCTAssertNil(preference.calendarEventId(wishId: "wish-detail-delete"))
        XCTAssertNil(preference.calendarEventId(wishId: "wish-swipe-delete"))
        XCTAssertEqual(mockRepository.deleteWishCalledIds, ["wish-swipe-delete"])
    }

    // MARK: GH-32 TC10

    func test_GH32_TC10_돋보기버튼을탭하면_검색화면으로이동한다() {
        // Given
        var pushedSearch = false
        sut.output.route
            .sink { route in
                if case .pushWishSearch = route { pushedSearch = true }
            }
            .store(in: &cancellables)

        // When
        sut.headerViewModel.input.didTapSearch.send(())

        // Then
        XCTAssertTrue(pushedSearch)
    }

    // MARK: GH-32 TC11

    func test_GH32_TC11_돋보기버튼을탭하면_search클릭로그가1건전송된다() {
        // Given
        let logManager = MockLogManager()
        let viewModel = HomeViewModel(dependency: .init(
            wishRepository: mockRepository,
            preference: Preference(name: "test"),
            notificationManager: mockNotificationManager,
            logManager: logManager
        ))

        // When
        viewModel.headerViewModel.input.didTapSearch.send(())

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let parameters = logManager.sentEvents.first?.parameters
        XCTAssertEqual(logManager.sentEvents.first?.name, .click)
        XCTAssertEqual(parameters?[ParameterName.screen.rawValue] as? String, "home")
        XCTAssertEqual(parameters?[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(parameters?[ParameterName.objectId.rawValue] as? String, "search")
    }

    // MARK: GH-29 TC13

    func test_GH29_TC13_홈에서위시를스와이프삭제하면_그위시의링크미리보기캐시가지워진다() {
        // Given
        let wish = Wish(id: "wish-link", category: .wantToGet, title: "헤드폰", link: "https://store.example.com/p/1")
        mockLinkPreviewCache.previews[wish.id] = LinkPreview(link: wish.link, title: "헤드폰", imageData: nil)
        mockRepository.fetchWishesResult = [wish]
        sut.input.updateCategory.send(.wantToGet)

        // When
        sut.input.didTapDelete.send(0)

        // Then
        XCTAssertEqual(mockLinkPreviewCache.removedWishIds, ["wish-link"])
        XCTAssertNil(mockLinkPreviewCache.previews["wish-link"])
    }

    func test_GH29_TC13_상세에서위시를삭제하고돌아오면_그위시의링크미리보기캐시가지워진다() {
        // Given
        let wish = Wish(id: "wish-link", category: .wantToGet, title: "헤드폰", link: "https://store.example.com/p/1")
        mockLinkPreviewCache.previews[wish.id] = LinkPreview(link: wish.link, title: "헤드폰", imageData: nil)
        mockRepository.fetchWishesResult = [wish]
        sut.input.updateCategory.send(.wantToGet)

        // When
        sut.input.deleteWish.send(wish)

        // Then
        XCTAssertEqual(mockLinkPreviewCache.removedWishIds, ["wish-link"])
    }

    // MARK: GH-36 TC5

    func test_GH36_TC5_홈에서위시를삭제하면_위시삭제와함께사진파일삭제가호출된다() {
        // Given
        let wish = Wish(id: "wish-1", category: .wantToGo, title: "제주도 한 달 살기", photoFileName: "wish-1-a.jpg")
        mockRepository.fetchWishesResult = [wish]
        sut.input.firstLoad.send(())

        // When
        sut.input.didTapDelete.send(0)

        // Then
        XCTAssertEqual(mockRepository.deleteWishCalledIds, ["wish-1"])
        XCTAssertEqual(mockPhotoStorage.deletePhotosCalledWishIds, ["wish-1"])
    }

    func test_GH36_TC5_상세에서위시를삭제하면_사진파일삭제가호출된다() {
        // Given
        let wish = Wish(id: "wish-1", category: .wantToGo, title: "제주도 한 달 살기", photoFileName: "wish-1-a.jpg")
        mockRepository.fetchWishesResult = [wish]
        sut.input.firstLoad.send(())

        // When
        sut.input.deleteWish.send(wish)

        // Then
        XCTAssertEqual(mockPhotoStorage.deletePhotosCalledWishIds, ["wish-1"])
    }
}

// MARK: - GH-33 위시 맨 위 고정

extension HomeViewModelTests {
    private struct PinFixture {
        let viewModel: HomeViewModel
        let repository: MockWishRepository
        let logManager: MockLogManager
    }

    private func makePinFixture(wishes: [Wish]) -> PinFixture {
        let repository = MockWishRepository()
        let logManager = MockLogManager()
        repository.fetchWishesResult = wishes
        let viewModel = HomeViewModel(dependency: .init(
            wishRepository: repository,
            preference: Preference(name: "test"),
            notificationManager: MockNotificationManager(),
            logManager: logManager
        ))
        viewModel.input.firstLoad.send()
        return PinFixture(viewModel: viewModel, repository: repository, logManager: logManager)
    }

    private func cellViewModels(of viewModel: HomeViewModel) -> [HomeWishCellViewModel] {
        return viewModel.output.dataSource.value.flatMap(\.items).compactMap {
            if case .wish(let cellViewModel) = $0 { return cellViewModel }
            return nil
        }
    }

    private func objectId(_ event: (any LogEventType)?) -> String? {
        return event?.parameters[ParameterName.objectId.rawValue] as? String
    }

    private func date(daysFromNow days: Double) -> Date {
        return Date().addingTimeInterval(days * 86400)
    }

    // MARK: GH-33 TC1

    func test_GH33_TC1_마감순에서_일정없는위시를고정하면_맨위로온다() {
        // Given
        let soon = Wish(id: "soon", title: "D-1", endDate: date(daysFromNow: 1))
        let later = Wish(id: "later", title: "D-23", endDate: date(daysFromNow: 23))
        var noDate = Wish(id: "no-date", title: "일정없음")
        XCTAssertEqual(HomeSortOrder.deadlineOrder.sorted([noDate, later, soon]).map(\.id), ["soon", "later", "no-date"])

        // When
        noDate.pinnedAt = Date()
        let sorted = HomeSortOrder.deadlineOrder.sorted([soon, later, noDate])

        // Then
        XCTAssertEqual(sorted.map(\.id), ["no-date", "soon", "later"])
    }

    func test_GH33_TC1_고정메뉴를탭하면_저장후목록을다시불러와_핀이보인다() {
        // Given
        let wish = Wish(id: "wish-1", title: "기타로 노래 한 곡 치기")
        let fixture = makePinFixture(wishes: [wish])
        var pinned = wish
        pinned.pinnedAt = Date()
        fixture.repository.fetchWishesResult = [pinned]

        // When
        fixture.viewModel.input.didTapPinMenu.send(wish)

        // Then
        XCTAssertEqual(fixture.repository.updatePinCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(fixture.repository.updatePinCalls.map(\.isPinned), [true])
        XCTAssertEqual(cellViewModels(of: fixture.viewModel).first?.output.isPinned, true)
    }

    // MARK: GH-33 TC2

    func test_GH33_TC2_고정2개는_나중에고정한것부터맨위에오고_나머지는마감순이다() {
        // Given
        let pinnedA = Wish(id: "A", title: "A", endDate: date(daysFromNow: 30), pinnedAt: date(daysFromNow: -2))
        let pinnedB = Wish(id: "B", title: "B", pinnedAt: date(daysFromNow: -1))
        let soon = Wish(id: "soon", title: "D-1", endDate: date(daysFromNow: 1))
        let later = Wish(id: "later", title: "D-23", endDate: date(daysFromNow: 23))

        // When
        let sorted = HomeSortOrder.deadlineOrder.sorted([later, pinnedA, soon, pinnedB])

        // Then
        XCTAssertEqual(sorted.map(\.id), ["B", "A", "soon", "later"])
    }

    func test_GH33_TC2_최신순에서도_고정이맨위고_나머지는최신순이다() {
        // Given
        let pinnedOld = Wish(id: "pinned-old", title: "오래된 고정", pinnedAt: Date(), createdAt: date(daysFromNow: -10))
        let older = Wish(id: "older", title: "예전 위시", createdAt: date(daysFromNow: -5))
        let newer = Wish(id: "newer", title: "최근 위시", createdAt: date(daysFromNow: -1))

        // When
        let sorted = HomeSortOrder.latestOrder.sorted([older, pinnedOld, newer])

        // Then
        XCTAssertEqual(sorted.map(\.id), ["pinned-old", "newer", "older"])
    }

    // MARK: GH-33 TC3

    func test_GH33_TC3_고정3개인카테고리에서_네번째고정은_저장하지않고_토스트를띄운다() {
        // Given
        let pinnedWishes = (1...3).map { Wish(id: "pinned-\($0)", title: "고정 \($0)", pinnedAt: date(daysFromNow: -Double($0))) }
        let target = Wish(id: "target", title: "네 번째")
        let fixture = makePinFixture(wishes: pinnedWishes + [target])
        var toasts: [String] = []
        fixture.viewModel.output.toast
            .sink { toasts.append($0) }
            .store(in: &cancellables)

        // When
        fixture.viewModel.input.didTapPinMenu.send(target)

        // Then
        XCTAssertTrue(fixture.repository.updatePinCalls.isEmpty)
        XCTAssertEqual(toasts, ["고정은 3개까지 할 수 있어요"])
    }

    // MARK: GH-33 TC4

    func test_GH33_TC4_다른카테고리에고정3개가있어도_이카테고리에서는_고정된다() {
        // Given
        let wantToDoPinned = (1...3).map {
            Wish(id: "do-\($0)", category: .wantToDo, title: "하고 싶은 \($0)", pinnedAt: date(daysFromNow: -Double($0)))
        }
        let fixture = makePinFixture(wishes: wantToDoPinned)
        let wantToGet = Wish(id: "get-1", category: .wantToGet, title: "갖고 싶은 것")
        fixture.repository.fetchWishesResult = [wantToGet]
        fixture.viewModel.input.updateCategory.send(.wantToGet)

        // When
        fixture.viewModel.input.didTapPinMenu.send(wantToGet)

        // Then
        XCTAssertEqual(fixture.repository.updatePinCalls.map(\.wishId), ["get-1"])
        XCTAssertEqual(fixture.repository.updatePinCalls.map(\.isPinned), [true])
    }

    // MARK: GH-33 TC5

    func test_GH33_TC5_고정을해제하면_원래정렬위치로돌아간다() {
        // Given
        let soon = Wish(id: "soon", title: "D-1", endDate: date(daysFromNow: 1))
        var target = Wish(id: "target", title: "D-23", endDate: date(daysFromNow: 23), pinnedAt: Date())
        let noDate = Wish(id: "no-date", title: "일정없음")
        XCTAssertEqual(HomeSortOrder.deadlineOrder.sorted([soon, noDate, target]).map(\.id).first, "target")

        // When
        target.pinnedAt = nil
        let sorted = HomeSortOrder.deadlineOrder.sorted([soon, noDate, target])

        // Then
        XCTAssertEqual(sorted.map(\.id), ["soon", "target", "no-date"])
    }

    func test_GH33_TC5_고정된위시의메뉴를탭하면_해제로저장하고_핀이사라진다() {
        // Given
        let pinned = Wish(id: "wish-1", title: "고정된 위시", pinnedAt: Date())
        let fixture = makePinFixture(wishes: [pinned])
        var unpinned = pinned
        unpinned.pinnedAt = nil
        fixture.repository.fetchWishesResult = [unpinned]

        // When
        fixture.viewModel.input.didTapPinMenu.send(pinned)

        // Then
        XCTAssertEqual(fixture.repository.updatePinCalls.map(\.isPinned), [false])
        XCTAssertEqual(cellViewModels(of: fixture.viewModel).first?.output.isPinned, false)
    }

    // MARK: GH-33 TC7

    func test_GH33_TC7_완료된위시는_고정요청이와도_저장하지않는다() {
        // Given
        let finished = Wish(id: "finished", title: "완료된 위시", finishDate: Date(), isSuccess: true)
        let fixture = makePinFixture(wishes: [finished])

        // When
        fixture.viewModel.input.didTapPinMenu.send(finished)

        // Then
        XCTAssertTrue(fixture.repository.updatePinCalls.isEmpty)
        XCTAssertTrue(fixture.logManager.sentEvents.isEmpty)
    }

    // MARK: GH-33 TC9

    func test_GH33_TC9_고정하면_pin_wish클릭로그가_카테고리와고정후개수와함께1건전송된다() {
        // Given
        let alreadyPinned = Wish(id: "pinned", title: "이미 고정", pinnedAt: Date())
        let target = Wish(id: "target", title: "새로 고정")
        let fixture = makePinFixture(wishes: [alreadyPinned, target])

        // When
        fixture.viewModel.input.didTapPinMenu.send(target)

        // Then
        XCTAssertEqual(fixture.logManager.sentEvents.count, 1)
        let event = fixture.logManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.parameters[ParameterName.screen.rawValue] as? String, "home")
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(objectId(event), "pin_wish")
        XCTAssertEqual(event?.parameters[ParameterName.category.rawValue] as? String, seep_ios_dev.Category.wantToDo.rawValue)
        XCTAssertEqual(event?.parameters[ParameterName.count.rawValue] as? Int, 2)
    }

    func test_GH33_TC9_고정해제하면_unpin_wish클릭로그가1건전송된다() {
        // Given
        let pinned = Wish(id: "pinned", title: "고정된 위시", pinnedAt: Date())
        let fixture = makePinFixture(wishes: [pinned])

        // When
        fixture.viewModel.input.didTapPinMenu.send(pinned)

        // Then
        XCTAssertEqual(fixture.logManager.sentEvents.count, 1)
        let event = fixture.logManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(objectId(event), "unpin_wish")
        XCTAssertEqual(event?.parameters[ParameterName.category.rawValue] as? String, seep_ios_dev.Category.wantToDo.rawValue)
    }

    func test_GH33_TC9_3개초과로토스트가뜨면_pin_limit_toast노출로그가1건전송된다() {
        // Given
        let pinnedWishes = (1...3).map { Wish(id: "pinned-\($0)", title: "고정 \($0)", pinnedAt: Date()) }
        let target = Wish(id: "target", title: "네 번째")
        let fixture = makePinFixture(wishes: pinnedWishes + [target])

        // When
        fixture.viewModel.input.didTapPinMenu.send(target)

        // Then
        XCTAssertEqual(fixture.logManager.sentEvents.count, 1)
        let event = fixture.logManager.sentEvents.first
        XCTAssertEqual(event?.name, .impression)
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "banner")
        XCTAssertEqual(objectId(event), "pin_limit_toast")
        XCTAssertEqual(event?.parameters[ParameterName.category.rawValue] as? String, seep_ios_dev.Category.wantToDo.rawValue)
    }
}
