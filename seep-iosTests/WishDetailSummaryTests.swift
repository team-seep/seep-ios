import XCTest

@testable import seep_ios

/// 위시 상세 문서 머리 문구 (GH-59). `WishDetailSummary`·`DdayStyle`은 UIKit 없는 순수 타입이다.
final class WishDetailSummaryTests: XCTestCase {
    private var calendar: Calendar!
    /// 2026-10-20(화) 15:00 KST
    private var now: Date!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: 15))
    }

    override func tearDown() {
        calendar = nil
        now = nil
        super.tearDown()
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? now
    }

    private func day(_ offset: Int) -> Date {
        return calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) ?? now
    }

    private func summary(_ wish: Wish) -> WishDetailSummary {
        return WishDetailSummary(wish: wish, now: now, calendar: calendar)
    }

    // MARK: GH-59 TC1

    func test_GH59_TC1_마감61일전이면_D61과_12월20일일까지_파랑() {
        // Given
        let wish = Wish(title: "에어팟 프로 3", endDate: date(2026, 12, 20))

        // When
        let line = summary(wish).ddayLine

        // Then
        XCTAssertEqual(line.text, "D-61")
        XCTAssertEqual(line.dateText, "12월 20일 (일)까지")
        XCTAssertEqual(line.tone, .later)
        XCTAssertFalse(line.isWord)
    }

    func test_GH59_TC1_남은날수별색이_DdayLabel규칙과같다() {
        // Given
        let cases: [(offset: Int, tone: DdayTone)] = [
            (-1, .past), (0, .urgent), (7, .urgent), (8, .soon), (30, .soon), (31, .later), (400, .later)
        ]

        // When
        let tones = cases.map { DdayStyle(endDate: day($0.offset), now: now, calendar: calendar).tone }

        // Then
        XCTAssertEqual(tones, cases.map(\.tone))
        XCTAssertEqual(DdayStyle(endDate: nil, now: now, calendar: calendar).tone, .later)
    }

    // MARK: GH-59 TC2

    func test_GH59_TC2_오늘마감이면_DDay와_오늘까지() {
        // Given 마감 시각이 오늘 오전이어도 당일이다
        let wish = Wish(endDate: date(2026, 10, 20, hour: 9))

        // When
        let line = summary(wish).ddayLine

        // Then
        XCTAssertEqual(line.text, "D-Day")
        XCTAssertEqual(line.dateText, "오늘까지")
        XCTAssertEqual(line.tone, .urgent)
    }

    func test_GH59_TC2_5일지나면_D플러스5와_날짜이었어요_보라() {
        // Given
        let wish = Wish(endDate: date(2026, 10, 15))

        // When
        let line = summary(wish).ddayLine

        // Then
        XCTAssertEqual(line.text, "D+5")
        XCTAssertEqual(line.dateText, "10월 15일 (목)이었어요")
        XCTAssertEqual(line.tone, .past)
    }

    func test_GH59_TC2_날짜없으면_일정없음단어_날짜자리없음() {
        // Given
        let wish = Wish(endDate: nil)

        // When
        let line = summary(wish).ddayLine

        // Then
        XCTAssertEqual(line.text, "일정없음")
        XCTAssertNil(line.dateText)
        XCTAssertTrue(line.isWord)
    }

    func test_GH59_TC2_365일넘으면_먼훗날단어() {
        // Given
        let wish = Wish(endDate: date(2028, 3, 1))

        // When
        let line = summary(wish).ddayLine

        // Then
        XCTAssertEqual(line.text, "먼훗날")
        XCTAssertTrue(line.isWord)
        XCTAssertEqual(line.dateText, "2028년 3월 1일 (수)까지")
    }

    func test_GH59_TC2_홈셀배지는_당일표기D0를그대로둔다() {
        // Given
        let style = DdayStyle(endDate: day(0), now: now, calendar: calendar)

        // When
        let labelText = style.labelText

        // Then 홈 셀 "D-0" → "D-Day" 통일은 범위 밖
        XCTAssertEqual(labelText, "D-0")
        XCTAssertEqual(style.text, "D-Day")
    }

    // MARK: GH-59 TC3

    func test_GH59_TC3_알림2개면_첫알림외1개가메타줄에들어간다() {
        // Given
        let wish = Wish(
            category: .wantToGet,
            notifications: [
                SeepNotification(type: .targetDay, time: date(2026, 10, 20, hour: 11)),
                SeepNotification(type: .dayAgo, time: date(2026, 10, 20, hour: 9))
            ],
            hashtag: "shopping"
        )

        // When
        let items = summary(wish).metaItems

        // Then
        XCTAssertEqual(items, [.category("갖고 싶어요"), .notification("당일 오전 11:00 외 1개"), .hashtag("#쇼핑")])
    }

    func test_GH59_TC3_알림1개면_외가없다() {
        // Given
        let wish = Wish(notifications: [SeepNotification(type: .dayAgo, time: date(2026, 10, 20, hour: 21, minute: 30))])

        // When
        let items = summary(wish).metaItems

        // Then
        XCTAssertEqual(items, [.category("하고 싶어요"), .notification("1일 전 오후 9:30")])
    }

    func test_GH59_TC3_알림해시태그없으면_카테고리만남는다() {
        // Given
        let wish = Wish(category: .wantToGo, notifications: [], hashtag: "  ")

        // When
        let result = summary(wish)

        // Then
        XCTAssertEqual(result.metaItems, [.category("가고 싶어요")])
        XCTAssertEqual(result.metaText, "가고 싶어요")
    }

    func test_GH59_TC3_직접입력해시태그는_그대로샵을붙인다() {
        // Given
        let wish = Wish(hashtag: "독서모임")

        // When
        let items = summary(wish).metaItems

        // Then
        XCTAssertEqual(items.last, .hashtag("#독서모임"))
    }

    // MARK: GH-59 TC14

    func test_GH59_TC14_상단바D데이는_숫자일때만붙고_일정없음먼훗날은빠진다() {
        // Given
        let dated = summary(Wish(endDate: day(26)))
        let noDeadline = summary(Wish(endDate: nil))
        let farFuture = summary(Wish(endDate: day(400)))

        // When / Then
        XCTAssertEqual(dated.navigationDday?.text, "D-26")
        XCTAssertEqual(dated.navigationDday?.tone, .soon)
        XCTAssertNil(noDeadline.navigationDday)
        XCTAssertNil(farFuture.navigationDday)
    }
}
