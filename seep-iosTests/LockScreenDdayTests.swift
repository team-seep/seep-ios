import XCTest

@testable import seep_ios_dev

/// 잠금화면 D-day 위젯의 위시 고르기·문구 (GH-47). 위젯과 앱이 같이 쓰는 순수 타입이다.
final class LockScreenDdayTests: XCTestCase {
    private var calendar: Calendar!
    private var now: Date!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        // 2026-10-19(월) 15:00
        now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 15))
    }

    private func day(_ offset: Int, hour: Int = 9) -> Date {
        let today = calendar.startOfDay(for: now)
        let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
        return calendar.date(byAdding: .hour, value: hour, to: date) ?? date
    }

    // MARK: GH-47 TC1

    func test_GH47_TC1_D3_D23_날짜없음중_D3위시가골라진다() {
        // Given
        let wishes = [
            Wish(id: "d23", endDate: day(23)),
            Wish(id: "none"),
            Wish(id: "d3", endDate: day(3))
        ]

        // When
        let picked = LockScreenDdayPicker.pick(wishes: wishes, now: now, calendar: calendar)

        // Then
        XCTAssertEqual(picked?.id, "d3")
    }

    // MARK: GH-47 TC2

    func test_GH47_TC2_기한지난D플러스2는빠지고_D10이골라진다() {
        // Given
        let wishes = [
            Wish(id: "past", endDate: day(-2)),
            Wish(id: "d10", endDate: day(10))
        ]

        // When
        let picked = LockScreenDdayPicker.pick(wishes: wishes, now: now, calendar: calendar)

        // Then
        XCTAssertEqual(picked?.id, "d10")
    }

    func test_GH47_TC2_오늘마감은시각이지나도_기한지난것으로보지않는다() {
        // Given 오늘 09:00 마감, 지금 15:00
        let wishes = [Wish(id: "today", endDate: day(0, hour: 9)), Wish(id: "d1", endDate: day(1))]

        // When
        let picked = LockScreenDdayPicker.pick(wishes: wishes, now: now, calendar: calendar)

        // Then
        XCTAssertEqual(picked?.id, "today")
    }

    // MARK: GH-47 TC3

    func test_GH47_TC3_같은날짜위시두개면_createdAt이이른위시가골라진다() {
        // Given
        let wishes = [
            Wish(id: "later", endDate: day(5, hour: 8), createdAt: day(-1)),
            Wish(id: "earlier", endDate: day(5, hour: 20), createdAt: day(-3))
        ]

        // When
        let picked = LockScreenDdayPicker.pick(wishes: wishes, now: now, calendar: calendar)

        // Then
        XCTAssertEqual(picked?.id, "earlier")
    }

    // MARK: GH-47 TC4

    func test_GH47_TC4_완료한D1위시와미완료D5면_D5가골라진다() {
        // Given
        let wishes = [
            Wish(id: "done", endDate: day(1), isSuccess: true),
            Wish(id: "d5", endDate: day(5))
        ]

        // When
        let picked = LockScreenDdayPicker.pick(wishes: wishes, now: now, calendar: calendar)

        // Then
        XCTAssertEqual(picked?.id, "d5")
    }

    // MARK: GH-47 TC5

    func test_GH47_TC5_날짜있는미완료위시가없으면_nil이고한줄문구는남은싶개수() {
        // Given
        let wishes = [
            Wish(id: "none"),
            Wish(id: "past", endDate: day(-1)),
            Wish(id: "done", endDate: day(2), isSuccess: true)
        ]

        // When
        let picked = LockScreenDdayPicker.pick(wishes: wishes, now: now, calendar: calendar)

        // Then
        XCTAssertNil(picked)
        XCTAssertEqual(LockScreenDdayPicker.remainText(count: 2), "남은 싶 2개")
    }

    // MARK: GH-47 TC6

    func test_GH47_TC6_오늘마감이면_D0과오늘까지() {
        // Given
        let endDate = day(0, hour: 23)

        // When
        let text = DdayText.make(endDate: endDate, now: now, calendar: calendar)

        // Then
        XCTAssertEqual(text.dday, "D-0")
        XCTAssertEqual(text.dueText, "오늘까지")
    }

    func test_GH47_TC6_3일뒤마감이면_D3과월일요일까지() {
        // Given 2026-10-22(목)
        let endDate = day(3)

        // When
        let text = DdayText.make(endDate: endDate, now: now, calendar: calendar)

        // Then
        XCTAssertEqual(text.dday, "D-3")
        XCTAssertEqual(text.dueText, "10월 22일 (목)까지")
    }

    // MARK: GH-47 TC7

    func test_GH47_TC7_400일뒤마감이면_먼훗날과연월일까지() {
        // Given 2027-11-23
        let endDate = day(400)

        // When
        let text = DdayText.make(endDate: endDate, now: now, calendar: calendar)

        // Then
        XCTAssertEqual(text.dday, "먼훗날")
        XCTAssertEqual(text.dueText, "2027년 11월 23일까지")
    }

    func test_GH47_TC7_365일뒤마감은_먼훗날이아니라D365() {
        // Given
        let endDate = day(365)

        // When
        let text = DdayText.make(endDate: endDate, now: now, calendar: calendar)

        // Then
        XCTAssertEqual(text.dday, "D-365")
    }

    // MARK: GH-47 TC14

    func test_GH47_TC14_2359에갱신시각을구하면_다음날0시다() {
        // Given 2026-10-19 23:59
        let lateNight = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 23, minute: 59))!

        // When
        let next = LockScreenDdayPicker.nextRefreshDate(after: lateNight, calendar: calendar)

        // Then
        XCTAssertEqual(next, calendar.date(from: DateComponents(year: 2026, month: 10, day: 20)))
        XCTAssertEqual(DdayText.make(endDate: day(1), now: lateNight, calendar: calendar).dday, "D-1")
        XCTAssertEqual(DdayText.make(endDate: day(1), now: next, calendar: calendar).dday, "D-0")
    }
}
