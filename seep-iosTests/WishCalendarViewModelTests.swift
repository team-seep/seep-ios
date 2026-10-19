import XCTest
import Combine

@testable import seep_ios_dev

/// 위시 상세 "캘린더에 추가" 버튼 (GH-28).
final class WishCalendarViewModelTests: XCTestCase {
    private var mockCalendarManager: MockCalendarManager!
    private var mockLogManager: MockLogManager!
    private var preference: Preference!
    private var cancellables: Set<AnyCancellable>!

    /// 2026-11-21 (토) 12:00 KST
    private let dday = Date(timeIntervalSince1970: 1_795_230_000)

    override func setUp() {
        super.setUp()
        mockCalendarManager = MockCalendarManager()
        mockLogManager = MockLogManager()
        preference = Preference(name: "test-gh28-calendar")
        cancellables = []
    }

    override func tearDown() {
        mockCalendarManager = nil
        mockLogManager = nil
        preference = nil
        cancellables = nil
        super.tearDown()
    }

    private func makeWish(
        endDate: Date?,
        memo: String = "숙소는 애월 쪽으로 알아보기",
        isSuccess: Bool = false
    ) -> Wish {
        return Wish(
            id: "wish-1",
            emoji: "🏝️",
            category: .wantToDo,
            title: "제주도 한 달 살기",
            endDate: endDate,
            memo: memo,
            isSuccess: isSuccess
        )
    }

    private func makeViewModel(wish: Wish, isAddable: Bool = true) -> WishCalendarViewModel {
        return WishCalendarViewModel(
            config: .init(wish: wish, isAddable: isAddable),
            dependency: .init(
                calendarManager: mockCalendarManager,
                preference: preference,
                logManager: mockLogManager
            )
        )
    }

    private func collectRoutes(_ viewModel: WishCalendarViewModel) -> () -> [WishCalendarViewModel.Route] {
        var routes: [WishCalendarViewModel.Route] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)
        return { routes }
    }

    private func collectToasts(_ viewModel: WishCalendarViewModel) -> () -> [String] {
        var toasts: [String] = []
        viewModel.output.toast
            .sink { toasts.append($0) }
            .store(in: &cancellables)
        return { toasts }
    }

    private func clickEvents(objectId: LogObjectId) -> [ClickEvent] {
        return mockLogManager.sentEvents
            .compactMap { $0 as? ClickEvent }
            .filter { $0.extraParameters?[.objectId] as? LogObjectId == objectId }
    }

    // MARK: GH-28 TC1

    func test_GH28_TC1_날짜가있는미완료위시를홈에서열면_버튼이보인다() {
        // Given
        let wish = makeWish(endDate: dday)

        // When
        let viewModel = makeViewModel(wish: wish, isAddable: true)

        // Then
        XCTAssertTrue(viewModel.output.isVisible.value)
        XCTAssertFalse(viewModel.output.isAdded.value)
    }

    // MARK: GH-28 TC2

    func test_GH28_TC2_날짜가없는위시는_버튼이보이지않는다() {
        // Given
        let wish = makeWish(endDate: nil)

        // When
        let viewModel = makeViewModel(wish: wish)

        // Then
        XCTAssertFalse(viewModel.output.isVisible.value)
    }

    func test_GH28_TC2_완료목록에서연상세는_버튼이보이지않는다() {
        // Given
        let wish = makeWish(endDate: dday, isSuccess: true)

        // When
        let fromFinish = makeViewModel(wish: wish, isAddable: false)
        let finishedFromHome = makeViewModel(wish: wish, isAddable: true)

        // Then
        XCTAssertFalse(fromFinish.output.isVisible.value)
        XCTAssertFalse(finishedFromHome.output.isVisible.value)
    }

    func test_GH28_TC2_수정화면에서날짜를지우면_버튼이숨겨진다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(endDate: dday))

        // When
        viewModel.input.reloadWish.send(makeWish(endDate: nil))

        // Then
        XCTAssertFalse(viewModel.output.isVisible.value)
    }

    // MARK: GH-28 TC3

    func test_GH28_TC3_권한허용시탭하면_이벤트가한번저장되고_토스트후추가됨상태가된다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(endDate: dday))
        let toasts = collectToasts(viewModel)

        // When
        viewModel.input.didTapButton.send(())

        // Then
        XCTAssertEqual(mockCalendarManager.requestAccessCallCount, 1)
        XCTAssertEqual(mockCalendarManager.savedDrafts, [CalendarEventDraft(
            title: "🏝️ 제주도 한 달 살기",
            date: dday,
            notes: "숙소는 애월 쪽으로 알아보기"
        )])
        XCTAssertEqual(toasts(), ["👏 11월 21일 캘린더에 추가했어요!"])
        XCTAssertTrue(viewModel.output.isAdded.value)
        XCTAssertEqual(preference.calendarEventId(wishId: "wish-1"), "event-1")
    }

    func test_GH28_TC3_메모가없으면_이벤트메모를비운다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(endDate: dday, memo: ""))

        // When
        viewModel.input.didTapButton.send(())

        // Then
        XCTAssertEqual(mockCalendarManager.savedDrafts.count, 1)
        XCTAssertNil(mockCalendarManager.savedDrafts.first?.notes)
    }

    // MARK: GH-28 TC4

    func test_GH28_TC4_저장된이벤트id가있으면_다시들어와도추가됨상태다() {
        // Given
        preference.setCalendarEventId("event-old", wishId: "wish-1")

        // When
        let viewModel = makeViewModel(wish: makeWish(endDate: dday))

        // Then
        XCTAssertTrue(viewModel.output.isAdded.value)
    }

    // MARK: GH-28 TC5

    func test_GH28_TC5_추가됨상태에서탭하면_저장하지않고확인알럿을띄운다() {
        // Given
        preference.setCalendarEventId("event-old", wishId: "wish-1")
        let viewModel = makeViewModel(wish: makeWish(endDate: dday))
        let routes = collectRoutes(viewModel)

        // When (알럿에서 "취소"는 Input 을 보내지 않는다)
        viewModel.input.didTapButton.send(())

        // Then
        guard case .showAddAgainAlert = routes().first else {
            return XCTFail("확인 알럿 route 가 없다: \(routes())")
        }
        XCTAssertEqual(routes().count, 1)
        XCTAssertEqual(mockCalendarManager.requestAccessCallCount, 0)
        XCTAssertTrue(mockCalendarManager.savedDrafts.isEmpty)
    }

    func test_GH28_TC5_확인알럿에서추가하기를누르면_한번더저장한다() {
        // Given
        preference.setCalendarEventId("event-old", wishId: "wish-1")
        mockCalendarManager.saveAllDayEventResult = .success("event-new")
        let viewModel = makeViewModel(wish: makeWish(endDate: dday))
        let toasts = collectToasts(viewModel)
        viewModel.input.didTapButton.send(())

        // When
        viewModel.input.confirmAddAgain.send(())

        // Then
        XCTAssertEqual(mockCalendarManager.savedDrafts.count, 1)
        XCTAssertEqual(toasts(), ["👏 11월 21일 캘린더에 추가했어요!"])
        XCTAssertEqual(preference.calendarEventId(wishId: "wish-1"), "event-new")
    }

    // MARK: GH-28 TC6

    func test_GH28_TC6_권한거부시탭하면_저장하지않고설정안내알럿을띄운다() {
        // Given
        mockCalendarManager.requestAccessResult = false
        let viewModel = makeViewModel(wish: makeWish(endDate: dday))
        let routes = collectRoutes(viewModel)

        // When
        viewModel.input.didTapButton.send(())

        // Then
        guard case .showPermissionDeniedAlert = routes().first else {
            return XCTFail("설정 안내 알럿 route 가 없다: \(routes())")
        }
        XCTAssertTrue(mockCalendarManager.savedDrafts.isEmpty)
        XCTAssertFalse(viewModel.output.isAdded.value)
        XCTAssertNil(preference.calendarEventId(wishId: "wish-1"))
    }

    // MARK: GH-28 TC7

    func test_GH28_TC7_저장이실패하면_에러알럿을띄우고_추가전상태그대로다() {
        // Given
        mockCalendarManager.saveAllDayEventResult = .failure(CalendarManagerError.noDefaultCalendar)
        let viewModel = makeViewModel(wish: makeWish(endDate: dday))
        let routes = collectRoutes(viewModel)
        let toasts = collectToasts(viewModel)

        // When
        viewModel.input.didTapButton.send(())

        // Then
        guard case .showErrorAlert = routes().first else {
            return XCTFail("에러 알럿 route 가 없다: \(routes())")
        }
        XCTAssertTrue(toasts().isEmpty)
        XCTAssertFalse(viewModel.output.isAdded.value)
        XCTAssertNil(preference.calendarEventId(wishId: "wish-1"))
    }

    // MARK: GH-28 TC10

    func test_GH28_TC10_처음탭해저장하면_add_calendar로그가first_saved로1건전송된다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(endDate: dday))

        // When
        viewModel.input.didTapButton.send(())

        // Then
        let events = clickEvents(objectId: .addCalendar)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        XCTAssertEqual(events.first?.extraParameters?[.objectType] as? LogObjectType, .button)
        XCTAssertEqual(events.first?.extraParameters?[.type] as? String, "first")
        XCTAssertEqual(events.first?.extraParameters?[.value] as? String, "saved")
    }

    func test_GH28_TC10_권한거부와저장실패는_value가denied_failed다() {
        // Given
        mockCalendarManager.requestAccessResult = false
        let deniedViewModel = makeViewModel(wish: makeWish(endDate: dday))

        // When
        deniedViewModel.input.didTapButton.send(())
        mockCalendarManager.requestAccessResult = true
        mockCalendarManager.saveAllDayEventResult = .failure(CalendarManagerError.noDefaultCalendar)
        let failedViewModel = makeViewModel(wish: makeWish(endDate: dday))
        failedViewModel.input.didTapButton.send(())

        // Then
        let values = clickEvents(objectId: .addCalendar).map { $0.extraParameters?[.value] as? String }
        XCTAssertEqual(values, ["denied", "failed"])
    }

    // MARK: GH-28 TC11

    func test_GH28_TC11_추가됨상태에서탭하면_add_calendar_again1건_추가하기면_confirm로그1건() {
        // Given
        preference.setCalendarEventId("event-old", wishId: "wish-1")
        let viewModel = makeViewModel(wish: makeWish(endDate: dday))

        // When
        viewModel.input.didTapButton.send(())

        // Then
        let addEvents = clickEvents(objectId: .addCalendar)
        XCTAssertEqual(addEvents.count, 1)
        XCTAssertEqual(addEvents.first?.extraParameters?[.type] as? String, "again")
        XCTAssertNil(addEvents.first?.extraParameters?[.value])
        XCTAssertTrue(clickEvents(objectId: .confirmAddCalendar).isEmpty)

        // When
        viewModel.input.confirmAddAgain.send(())

        // Then
        let confirmEvents = clickEvents(objectId: .confirmAddCalendar)
        XCTAssertEqual(confirmEvents.count, 1)
        XCTAssertEqual(confirmEvents.first?.extraParameters?[.value] as? String, "saved")
        XCTAssertEqual(clickEvents(objectId: .addCalendar).count, 1)
    }
}
