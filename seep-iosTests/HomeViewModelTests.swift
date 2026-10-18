import XCTest
import Combine

@testable import seep_ios_dev

final class HomeViewModelTests: XCTestCase {
    private var sut: HomeViewModel!
    private var mockRepository: MockWishRepository!
    private var mockNotificationManager: MockNotificationManager!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        mockNotificationManager = MockNotificationManager()
        cancellables = []

        let dependency = HomeViewModel.Dependency(
            wishRepository: mockRepository,
            preference: Preference(name: "test"),
            notificationManager: mockNotificationManager,
            logManager: MockLogManager()
        )
        sut = HomeViewModel(dependency: dependency)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockNotificationManager = nil
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
}
