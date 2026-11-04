import XCTest

@testable import seep_ios

/// 체크 위젯이 남긴 기록을 싶 탭이 처리한다 (GH-48 R-7, R-8, 트래킹 이벤트). 기존 HomeViewModelWidgetCheckTests 이전
final class HomeWidgetCheckFeatureTests: HomeFeatureTestCase {
    private let suiteName = "test.homeWidgetCheck"
    private var store: WidgetCheckStore!
    private var sut: HomeViewModel!
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suiteName)
        store = WidgetCheckStore(userDefaults: UserDefaults(suiteName: suiteName))
        preference = Preference(name: "test.homeWidgetCheck.preference")
        sut = makeSut(now: { [now] in now }, widgetCheckStore: store)
    }

    override func tearDown() {
        sut = nil
        store = nil
        UserDefaults().removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private var sheetWishId: String? {
        finishNoteViewModel(of: sut)?.wish.id
    }

    private func widgetCheckEvents() -> [String] {
        logManager.sentEvents
            .filter { $0.screen == .checkWidget }
            .compactMap { $0.parameters[ParameterName.objectId.rawValue] as? String }
    }

    // MARK: GH-48 TC8

    func test_GH48_TC8_위젯에서완료한위시1개가있으면_앱활성화때알림취소1회_소감시트1회_목록을비운다() {
        // Given
        let wish = Wish(id: "wish-1", title: "기타로 노래 한 곡 치기", isSuccess: true)
        repository.fetchWishResult = [wish]
        sut.send(.onAppear)
        store.recordFinish(wishId: wish.id, at: now.addingTimeInterval(10))

        // When
        sut.send(.syncWidgetChanges)

        // Then
        XCTAssertEqual(notificationManager.cancelledWishes.map(\.id), ["wish-1"])
        XCTAssertEqual(sheetWishId, "wish-1")
        XCTAssertEqual(store.finishedWishIds, [])
    }

    func test_GH48_TC8_처리한뒤다시활성화되면_소감시트를또띄우지않는다() {
        // Given
        let wish = Wish(id: "wish-1", title: "위시", isSuccess: true)
        repository.fetchWishResult = [wish]
        store.recordFinish(wishId: wish.id, at: now)
        sut.send(.syncWidgetChanges)
        sut.send(.sheetDismissed)

        // When
        sut.send(.syncWidgetChanges)

        // Then
        XCTAssertNil(sheetWishId)
        XCTAssertEqual(notificationManager.cancelledWishes.count, 1)
    }

    func test_GH48_TC8_그사이앱에서완료를취소한위시는_알림을지우지않고소감도묻지않는다() {
        // Given
        repository.fetchWishResult = [Wish(id: "wish-1", title: "위시", isSuccess: false)]
        store.recordFinish(wishId: "wish-1", at: now)

        // When
        sut.send(.syncWidgetChanges)

        // Then
        XCTAssertTrue(notificationManager.cancelledWishes.isEmpty)
        XCTAssertNil(sheetWishId)
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
        sut.send(.syncWidgetChanges)

        // Then
        XCTAssertEqual(Set(notificationManager.cancelledWishes.map(\.id)), ["wish-1", "wish-2"])
        XCTAssertEqual(sheetWishId, "wish-2")
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
        sut.send(.syncWidgetChanges)

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
        sut.send(.syncWidgetChanges)

        // Then
        XCTAssertEqual(widgetCheckEvents(), ["widget_finish_wish", "widget_unfinish_wish"])
        XCTAssertNil(sheetWishId)
    }

    // MARK: GH-48 R-8

    func test_GH48_TC11_마지막으로읽은뒤위젯이바꿨으면_앱활성화때홈을다시읽는다() {
        // Given
        sut.send(.onAppear)
        repository.fetchWishesResult = [Wish(id: "wish-1", title: "위시")]
        store.recordStepCheck(at: now.addingTimeInterval(10))

        // When
        sut.send(.syncWidgetChanges)

        // Then
        XCTAssertEqual(listedWishIds(of: sut), ["wish-1"])
    }

    func test_GH48_TC11_위젯이바꾼게없으면_앱활성화때홈을다시읽지않는다() {
        // Given
        sut.send(.onAppear)
        repository.fetchWishesResult = [Wish(id: "wish-1", title: "위시")]

        // When
        sut.send(.syncWidgetChanges)

        // Then
        XCTAssertTrue(sut.state.items.isEmpty)
    }
}
