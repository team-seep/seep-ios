import XCTest
import Combine

@testable import seep_ios_dev

/// 위시 상세 상단 바(수정·⋯)·⋯ 메뉴 구성·문서 갱신 (GH-59).
final class WishDetailViewModelTests: XCTestCase {
    private var mockLogManager: MockLogManager!
    private var cancellables: Set<AnyCancellable>!
    private var calendar: Calendar!
    /// 2026-10-20(화) 15:00 KST
    private var now: Date!

    override func setUp() {
        super.setUp()
        mockLogManager = MockLogManager()
        cancellables = []
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: 15))
    }

    override func tearDown() {
        mockLogManager = nil
        cancellables = nil
        calendar = nil
        now = nil
        super.tearDown()
    }

    private func makeWish(endDate: Date? = nil, isSuccess: Bool = false) -> Wish {
        return Wish(
            id: "wish-1",
            emoji: "🎧",
            category: .wantToGet,
            title: "에어팟 프로 3",
            endDate: endDate,
            memo: "연말 보너스 나오면 사기",
            isSuccess: isSuccess
        )
    }

    private func makeViewModel(wish: Wish, mode: DetailMode) -> WishDetailViewModel {
        let now = self.now ?? Date()
        return WishDetailViewModel(
            config: .init(wish: wish, mode: mode),
            dependency: .init(logManager: mockLogManager, now: { now }, calendar: calendar)
        )
    }

    private func collectRoutes(_ viewModel: WishDetailViewModel) -> () -> [WishDetailViewModel.Route] {
        var routes: [WishDetailViewModel.Route] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)
        return { routes }
    }

    private func clickEvents(objectId: LogObjectId) -> [ClickEvent] {
        return mockLogManager.sentEvents
            .compactMap { $0 as? ClickEvent }
            .filter { $0.extraParameters?[.objectId] as? LogObjectId == objectId }
    }

    private func menuItems(_ route: WishDetailViewModel.Route?) -> [DetailMoreMenu.Item]? {
        guard case .showMoreMenu(let items) = route else { return nil }
        return items
    }

    // MARK: GH-59 TC6

    func test_GH59_TC6_홈에서연상세에서_수정을탭하면_수정화면Route와_detail_edit로그1건() {
        // Given
        let wish = makeWish()
        let viewModel = makeViewModel(wish: wish, mode: .fromHome)
        let routes = collectRoutes(viewModel)

        // When
        viewModel.input.didTapEdit.send(())

        // Then
        guard case .pushEdit(let pushed) = routes().first else {
            return XCTFail("수정 화면 Route 가 없다")
        }
        XCTAssertEqual(pushed.id, wish.id)
        let events = clickEvents(objectId: .detailEdit)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        XCTAssertEqual(events.first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }

    func test_GH59_TC6_수정화면으로는_최신위시를넘긴다() {
        // Given 단계 체크 등으로 Reactor 의 위시가 바뀌었다
        let viewModel = makeViewModel(wish: makeWish(), mode: .fromHome)
        let routes = collectRoutes(viewModel)
        var updated = makeWish()
        updated.title = "에어팟 프로 3 화이트"
        viewModel.input.updateWish.send(updated)

        // When
        viewModel.input.didTapEdit.send(())

        // Then
        guard case .pushEdit(let pushed) = routes().first else {
            return XCTFail("수정 화면 Route 가 없다")
        }
        XCTAssertEqual(pushed.title, "에어팟 프로 3 화이트")
    }

    // MARK: GH-59 TC7

    func test_GH59_TC7_완료목록에서연상세는_수정버튼이없고_탭이와도무시한다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(isSuccess: true), mode: .fromFinish)
        let routes = collectRoutes(viewModel)

        // When
        viewModel.input.didTapEdit.send(())

        // Then
        XCTAssertFalse(viewModel.output.isEditVisible)
        XCTAssertTrue(routes().isEmpty)
        XCTAssertTrue(clickEvents(objectId: .detailEdit).isEmpty)
    }

    func test_GH59_TC7_홈에서연상세는_수정버튼이보인다() {
        // Given / When
        let viewModel = makeViewModel(wish: makeWish(), mode: .fromHome)

        // Then
        XCTAssertTrue(viewModel.output.isEditVisible)
    }

    // MARK: GH-59 TC8

    func test_GH59_TC8_홈상세_날짜사진있으면_캘린더공유사진지우기삭제순이고_수정하기없음_detail_more로그1건() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(endDate: now), mode: .fromHome)
        let routes = collectRoutes(viewModel)

        // When
        viewModel.input.didTapMore.send(.init(isCalendarVisible: true, isCalendarAdded: false, hasPhoto: true))

        // Then
        let items = menuItems(routes().first)
        XCTAssertEqual(items, [.addCalendar(isAdded: false), .share, .deletePhoto, .delete])
        XCTAssertEqual(items?.map(\.title), ["캘린더에 추가", "공유하기", "사진 지우기", "삭제하기"])
        XCTAssertFalse(items?.map(\.title).contains("수정하기") ?? true)
        XCTAssertEqual(items?.filter(\.isDestructive), [.delete])
        let events = clickEvents(objectId: .detailMore)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
    }

    func test_GH59_TC8_사진이없으면_사진지우기가없다() {
        // Given
        let items = DetailMoreMenu.items(context: .init(
            mode: .fromHome,
            isCalendarVisible: true,
            isCalendarAdded: false,
            hasPhoto: false
        ))

        // Then
        XCTAssertEqual(items, [.addCalendar(isAdded: false), .share, .delete])
    }

    // MARK: GH-59 TC9

    func test_GH59_TC9_완료상세메뉴는_완료취소하기가있고_캘린더수정하기는없다() {
        // Given 완료 위시는 캘린더 ViewModel 이 숨긴다(isVisible false)
        let viewModel = makeViewModel(wish: makeWish(endDate: now, isSuccess: true), mode: .fromFinish)
        let routes = collectRoutes(viewModel)

        // When
        viewModel.input.didTapMore.send(.init(isCalendarVisible: false, isCalendarAdded: false, hasPhoto: true))

        // Then
        XCTAssertEqual(menuItems(routes().first), [.cancelFinish, .deletePhoto, .share])
    }

    func test_GH59_TC9_완료모드는_캘린더상태와상관없이_캘린더항목이없다() {
        // Given
        let items = DetailMoreMenu.items(context: .init(
            mode: .fromFinish,
            isCalendarVisible: true,
            isCalendarAdded: true,
            hasPhoto: false
        ))

        // Then
        XCTAssertEqual(items, [.cancelFinish, .share])
    }

    // MARK: GH-59 TC10

    func test_GH59_TC10_날짜없는위시는_캘린더에추가가없다() {
        // Given 날짜가 없으면 캘린더 ViewModel 이 숨긴다
        let viewModel = makeViewModel(wish: makeWish(endDate: nil), mode: .fromHome)
        let routes = collectRoutes(viewModel)

        // When
        viewModel.input.didTapMore.send(.init(isCalendarVisible: false, isCalendarAdded: false, hasPhoto: false))

        // Then
        XCTAssertEqual(menuItems(routes().first), [.share, .delete])
    }

    func test_GH59_TC10_이미추가했으면_캘린더에추가됨으로보인다() {
        // Given
        let items = DetailMoreMenu.items(context: .init(
            mode: .fromHome,
            isCalendarVisible: true,
            isCalendarAdded: true,
            hasPhoto: false
        ))

        // Then
        XCTAssertEqual(items.first, .addCalendar(isAdded: true))
        XCTAssertEqual(items.first?.title, "캘린더에 추가됨")
    }

    // MARK: GH-59 TC16

    func test_GH59_TC16_수정저장후위시가바뀌면_제목메모DDay와섹션이새값이된다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(), mode: .fromHome)
        var updated = makeWish(endDate: calendar.date(byAdding: .day, value: 3, to: now))
        updated.title = "에어팟 맥스"
        updated.memo = ""

        // When
        viewModel.input.updateWish.send(updated)

        // Then
        let summary = viewModel.output.summary.value
        XCTAssertEqual(summary.title, "에어팟 맥스")
        XCTAssertNil(summary.memo)
        XCTAssertEqual(summary.ddayLine.text, "D-3")
        XCTAssertFalse(viewModel.output.sections.value.contains(.memo))
    }

    // MARK: GH-59 TC19

    func test_GH59_TC19_메뉴에서캘린더에추가를고르면_add_calendar로그1건() {
        // Given 상세는 메뉴의 "캘린더에 추가"를 WishCalendarViewModel.didTapButton 으로 넘긴다
        let calendarManager = MockCalendarManager()
        let preference = Preference(name: "test-gh59-calendar-\(UUID().uuidString)")
        let calendarViewModel = WishCalendarViewModel(
            config: .init(wish: makeWish(endDate: now), isAddable: true),
            dependency: .init(calendarManager: calendarManager, preference: preference, logManager: mockLogManager)
        )

        // When
        calendarViewModel.input.didTapButton.send(())

        // Then
        let events = clickEvents(objectId: .addCalendar)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        XCTAssertEqual(calendarManager.savedDrafts.count, 1)
    }
}
