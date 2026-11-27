import XCTest

@testable import seep_ios

/// 작성·수정 문서의 "언제까지 이루고 싶어요?" 시트 — 기간 기한 고르기 (GH-118 R-2, R-3)
final class WishFormDeadlineFeatureTests: WishFormFeatureTestCase {
    private let calendar = Calendar.current

    override func setUp() {
        super.setUp()
        // 2026-10-29 12:00 (기기 시간대)
        now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 29, hour: 12)) ?? now
    }

    private func lastMoment(year: Int, month: Int, day: Int) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))?.endOfDay
    }

    private func makeWriteWithTitle() -> WishFormViewModel {
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        viewModel.send(.inputTitle("서핑 배워보기"))
        return viewModel
    }

    // MARK: GH-118 TC1

    func test_GH118_TC1_올해안에를고르고저장하면_종류year와올해12월31일끝으로저장된다() {
        // Given
        let viewModel = makeWriteWithTitle()
        viewModel.send(.tapChip(.date))

        // When
        viewModel.send(.selectDeadlineOption(.year))
        viewModel.send(.tapSave)

        // Then
        let saved = wishRepository.addedWishes.first
        XCTAssertEqual(saved?.deadlineKind, .year)
        XCTAssertEqual(saved?.endDate, lastMoment(year: 2026, month: 12, day: 31))
        XCTAssertNil(viewModel.state.sheet, "기간을 고르면 시트를 닫는다")
        XCTAssertEqual(notificationManager.reservedWishes.first?.endDate, lastMoment(year: 2026, month: 12, day: 31))
    }

    // MARK: GH-118 TC2

    func test_GH118_TC2_이번달안에는이달말일_내년까지는내년12월31일이다() {
        // Given
        let viewModel = makeWriteWithTitle()

        // When
        viewModel.send(.selectDeadlineOption(.month))

        // Then
        XCTAssertEqual(viewModel.state.deadline, lastMoment(year: 2026, month: 10, day: 31))
        XCTAssertEqual(viewModel.state.deadlineKind, .month)
        XCTAssertTrue(viewModel.state.isDeadlineEnabled)

        // When
        viewModel.send(.selectDeadlineOption(.nextYear))

        // Then
        XCTAssertEqual(viewModel.state.deadline, lastMoment(year: 2027, month: 12, day: 31))
        XCTAssertEqual(viewModel.state.deadlineKind, .nextYear)
    }

    func test_GH118_TC2_12월31일에고르면_이번달안과올해안이같은날이고_2월은윤년말일까지다() {
        // Given: 12월 31일 밤
        now = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 23, minute: 30)) ?? now

        // Then
        XCTAssertEqual(DeadlineKind.month.periodEnd(from: now, calendar: calendar), lastMoment(year: 2026, month: 12, day: 31))
        XCTAssertEqual(DeadlineKind.year.periodEnd(from: now, calendar: calendar), lastMoment(year: 2026, month: 12, day: 31))
        XCTAssertEqual(DeadlineKind.nextYear.periodEnd(from: now, calendar: calendar), lastMoment(year: 2027, month: 12, day: 31))

        // Given: 2028-02-10 (윤년)
        let february = calendar.date(from: DateComponents(year: 2028, month: 2, day: 10, hour: 9)) ?? now

        // Then
        XCTAssertEqual(DeadlineKind.month.periodEnd(from: february, calendar: calendar), lastMoment(year: 2028, month: 2, day: 29))
        XCTAssertNil(DeadlineKind.date.periodEnd(from: february, calendar: calendar))
    }

    func test_GH118_TC2_시트항목오른쪽에_지금고르면저장될마감이보인다() {
        // Given
        let viewModel = makeWriteWithTitle()
        viewModel.send(.tapChip(.date))

        // When
        let rows = viewModel.deadlineOptionRows

        // Then
        XCTAssertEqual(rows.map(\.option), [.date, .month, .year, .nextYear, .someday])
        XCTAssertEqual(rows.map(\.title), ["날짜 정하기", "이번 달 안에", "올해 안에", "내년까지", "언젠가"])
        XCTAssertEqual(rows.map(\.detail), ["달력에서 고르기", "10월 31일까지", "12월 31일까지", "2027년 12월 31일까지", "정하지 않을래요"])
        XCTAssertEqual(rows.filter(\.isSelected).map(\.option), [.date], "날짜 칩은 오늘로 채운 날짜 기한이다")
    }

    // MARK: GH-118 TC10

    func test_GH118_TC10_시트에서항목을고르면_select_deadline_kind클릭로그가type과함께1건씩간다() {
        // Given
        let viewModel = makeWriteWithTitle()

        // When
        for option in WishDeadlineOption.allCases {
            viewModel.send(.selectDeadlineOption(option))
        }

        // Then
        let events = clickEvents(objectId: .selectDeadlineKind)
        XCTAssertEqual(events.count, 5)
        XCTAssertEqual(events.compactMap { $0.extraParameters?[.type] as? String }, ["date", "month", "year", "next_year", "none"])
        XCTAssertEqual(events.map(\.screen), Array(repeating: .write, count: 5))
    }

    func test_GH118_TC10_수정문서에서고르면_screen이wish_edit이다() {
        // Given
        let viewModel = makeViewModel(mode: .edit(Wish(id: "w", title: "서핑")))

        // When
        viewModel.send(.selectDeadlineOption(.month))

        // Then
        let events = clickEvents(objectId: .selectDeadlineKind)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishEdit)
        XCTAssertEqual(events.first?.extraParameters?[.type] as? String, "month")
    }

    // MARK: GH-118 TC16

    func test_GH118_TC16_날짜정하기를고르면달력이열리고_날짜를고르면날짜기한으로저장된다() {
        // Given: 기간을 골랐다가
        let viewModel = makeWriteWithTitle()
        viewModel.send(.selectDeadlineOption(.year))
        let picked = calendar.date(from: DateComponents(year: 2026, month: 11, day: 15)) ?? now

        // When
        viewModel.send(.selectDeadlineOption(.date))

        // Then
        XCTAssertEqual(viewModel.state.sheet, .datePicker)

        // When
        viewModel.send(.inputDeadline(picked))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.first?.deadlineKind, .date)
        XCTAssertEqual(wishRepository.addedWishes.first?.endDate, picked.endOfDay)
    }

    func test_GH118_TC16_언젠가를고르면_기한과알림이꺼지고_날짜없음으로저장된다() {
        // Given
        let viewModel = makeWriteWithTitle()
        viewModel.send(.selectDeadlineOption(.year))
        viewModel.send(.tapChip(.notification))

        // When
        viewModel.send(.selectDeadlineOption(.someday))
        viewModel.send(.tapSave)

        // Then
        XCTAssertFalse(viewModel.state.isDeadlineEnabled)
        XCTAssertFalse(viewModel.state.isNotificationEnabled)
        XCTAssertNil(viewModel.state.sheet)
        XCTAssertNil(wishRepository.addedWishes.first?.endDate)
        XCTAssertEqual(wishRepository.addedWishes.first?.deadlineKind, .date)
        XCTAssertEqual(wishRepository.addedWishes.first?.notifications, [])
    }

    // MARK: GH-118 TC17

    func test_GH118_TC17_내년까지위시를수정하면_시트에내년까지가선택돼있고_그대로저장하면기간이유지된다() {
        // Given
        let end = lastMoment(year: 2027, month: 12, day: 31)
        let wish = Wish(id: "piano", title: "피아노 한 곡", endDate: end, deadlineKind: .nextYear)
        let viewModel = makeViewModel(mode: .edit(wish))

        // Then
        XCTAssertEqual(viewModel.deadlineOptionRows.filter(\.isSelected).map(\.option), [.nextYear])
        XCTAssertFalse(viewModel.hasChanges)

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.updatedWishes.first?.deadlineKind, .nextYear)
        XCTAssertEqual(wishRepository.updatedWishes.first?.endDate, end)
    }

    func test_GH118_TC17_수정에서기간을바꾸면_버리기확인대상이다() {
        // Given
        let wish = Wish(id: "piano", title: "피아노 한 곡", endDate: lastMoment(year: 2026, month: 12, day: 31), deadlineKind: .year)
        let viewModel = makeViewModel(mode: .edit(wish))

        // When: 같은 날짜지만 종류가 다르다 (12월에 "이번 달 안에"를 고른 것과 같은 경우)
        viewModel.send(.selectDeadlineOption(.date))
        viewModel.send(.inputDeadline(lastMoment(year: 2026, month: 12, day: 31) ?? now))

        // Then
        XCTAssertTrue(viewModel.hasChanges)
    }
}
