import XCTest
import Combine

@testable import seep_ios_dev

/// 체크 위젯이 남긴 기록을 앱이 활성화될 때 홈이 처리한다 (GH-48 R-7, R-8, 트래킹 이벤트)
final class HomeViewModelWidgetCheckTests: XCTestCase {
    private let suiteName = "test.homeWidgetCheck"
    private var repository: MockWishRepository!
    private var notificationManager: MockNotificationManager!
    private var logManager: MockLogManager!
    private var store: WidgetCheckStore!
    private var sut: HomeViewModel!
    private var sheetWishIds: [String] = []
    private var cancellables = Set<AnyCancellable>()
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suiteName)
        repository = MockWishRepository()
        notificationManager = MockNotificationManager()
        logManager = MockLogManager()
        store = WidgetCheckStore(userDefaults: UserDefaults(suiteName: suiteName))
        sheetWishIds = []
        sut = HomeViewModel(dependency: .init(
            wishRepository: repository,
            preference: Preference(name: "test.homeWidgetCheck.preference"),
            notificationManager: notificationManager,
            logManager: logManager,
            now: { [now] in now },
            widgetCheckStore: store
        ))
        sut.output.route
            .sink { [weak self] route in
                if case .presentFinishNoteBottomSheet(let viewModel) = route {
                    self?.sheetWishIds.append(viewModel.output.wish.id)
                }
            }
            .store(in: &cancellables)
    }

    override func tearDown() {
        cancellables = []
        UserDefaults().removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func widgetCheckEvents() -> [String] {
        return logManager.sentEvents
            .filter { $0.screen == .checkWidget }
            .compactMap { $0.parameters[ParameterName.objectId.rawValue] as? String }
    }

    // MARK: GH-48 TC8

    func test_GH48_TC8_위젯에서완료한위시1개가있으면_앱활성화때알림취소1회_소감시트1회_목록을비운다() {
        // Given
        let wish = Wish(id: "wish-1", title: "기타로 노래 한 곡 치기", isSuccess: true)
        repository.fetchWishResult = [wish]
        sut.input.firstLoad.send(())
        store.recordFinish(wishId: wish.id, at: now.addingTimeInterval(10))

        // When
        sut.input.syncWidgetChanges.send(())

        // Then
        XCTAssertEqual(notificationManager.cancelledWishes.map(\.id), ["wish-1"])
        XCTAssertEqual(sheetWishIds, ["wish-1"])
        XCTAssertEqual(store.finishedWishIds, [])
    }

    func test_GH48_TC8_처리한뒤다시활성화되면_소감시트를또띄우지않는다() {
        // Given
        let wish = Wish(id: "wish-1", title: "위시", isSuccess: true)
        repository.fetchWishResult = [wish]
        store.recordFinish(wishId: wish.id, at: now)
        sut.input.syncWidgetChanges.send(())

        // When
        sut.input.syncWidgetChanges.send(())

        // Then
        XCTAssertEqual(sheetWishIds, ["wish-1"])
        XCTAssertEqual(notificationManager.cancelledWishes.count, 1)
    }

    func test_GH48_TC8_그사이앱에서완료를취소한위시는_알림을지우지않고소감도묻지않는다() {
        // Given
        repository.fetchWishResult = [Wish(id: "wish-1", title: "위시", isSuccess: false)]
        store.recordFinish(wishId: "wish-1", at: now)

        // When
        sut.input.syncWidgetChanges.send(())

        // Then
        XCTAssertTrue(notificationManager.cancelledWishes.isEmpty)
        XCTAssertTrue(sheetWishIds.isEmpty)
    }

    // MARK: GH-48 TC9

    func test_GH48_TC9_위젯에서완료한위시가2개면_알림취소2회_소감시트는가장최근1회() {
        // Given
        repository.fetchWishResult = [
            Wish(id: "wish-1", title: "먼저 완료", isSuccess: true),
            Wish(id: "wish-2", title: "나중에 완료", isSuccess: true)
        ]
        store.recordFinish(wishId: "wish-1", at: now)
        store.recordFinish(wishId: "wish-2", at: now.addingTimeInterval(5))

        // When
        sut.input.syncWidgetChanges.send(())

        // Then
        XCTAssertEqual(Set(notificationManager.cancelledWishes.map(\.id)), ["wish-1", "wish-2"])
        XCTAssertEqual(sheetWishIds, ["wish-2"])
        XCTAssertEqual(store.finishedWishIds, [])
    }

    // MARK: GH-48 TC15

    func test_GH48_TC15_위젯에서단계체크와위시완료가기록돼있으면_앱활성화때실행횟수만큼클릭로그를보낸다() {
        // Given
        repository.fetchWishResult = [Wish(id: "wish-1", title: "위시", isSuccess: true)]
        store.recordStepCheck(at: now)
        store.recordStepCheck(at: now.addingTimeInterval(1))
        store.recordFinish(wishId: "wish-1", at: now.addingTimeInterval(2))

        // When
        sut.input.syncWidgetChanges.send(())

        // Then
        XCTAssertEqual(widgetCheckEvents(), ["widget_check_step", "widget_check_step", "widget_finish_wish"])
        let event = logManager.sentEvents.first { $0.screen == .checkWidget }
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "widget")
        XCTAssertTrue(store.actionLogs.isEmpty)
    }

    func test_GH48_TC15_위젯에서완료를취소하면_widget_unfinish_wish로그를보낸다() {
        // Given
        store.recordFinish(wishId: "wish-1", at: now)
        store.recordUnfinish(wishId: "wish-1", at: now.addingTimeInterval(1))

        // When
        sut.input.syncWidgetChanges.send(())

        // Then
        XCTAssertEqual(widgetCheckEvents(), ["widget_finish_wish", "widget_unfinish_wish"])
        XCTAssertTrue(sheetWishIds.isEmpty)
    }

    // MARK: GH-48 R-8

    func test_GH48_TC11_마지막으로읽은뒤위젯이바꿨으면_앱활성화때홈을다시읽는다() {
        // Given
        sut.input.firstLoad.send(())
        let wish = Wish(id: "wish-1", title: "위시")
        repository.fetchWishesResult = [wish]
        store.recordStepCheck(at: now.addingTimeInterval(10))
        var latestWishIds: [String] = []
        sut.output.dataSource
            .sink { sections in
                latestWishIds = sections.flatMap(\.items).compactMap {
                    if case .wish(let cellViewModel) = $0 { return cellViewModel.output.wish.id }
                    return nil
                }
            }
            .store(in: &cancellables)

        // When
        sut.input.syncWidgetChanges.send(())

        // Then
        XCTAssertEqual(latestWishIds, ["wish-1"])
    }

    func test_GH48_TC11_위젯이바꾼게없으면_앱활성화때홈을다시읽지않는다() {
        // Given
        sut.input.firstLoad.send(())
        repository.fetchWishesResult = [Wish(id: "wish-1", title: "위시")]
        var emitCount = 0
        sut.output.dataSource
            .dropFirst()
            .sink { _ in emitCount += 1 }
            .store(in: &cancellables)

        // When
        sut.input.syncWidgetChanges.send(())

        // Then
        XCTAssertEqual(emitCount, 0)
    }
}
