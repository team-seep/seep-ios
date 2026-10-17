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
}
