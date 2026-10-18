import XCTest

@testable import seep_ios_dev

final class YearReviewSummaryTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? Date()
    }

    private func finished(
        id: String,
        category: seep_ios_dev.Category = .wantToDo,
        createdAt: Date? = nil,
        finishedAt: Date,
        note: String = ""
    ) -> Wish {
        Wish(
            id: id,
            category: category,
            title: id,
            finishDate: finishedAt,
            isSuccess: true,
            finishNote: note,
            createdAt: createdAt ?? finishedAt
        )
    }

    // MARK: GH-34 TC1 · TC2 · TC3 (노출 기간·대상 연도)

    func test_GH34_TC1_12월이면_그해가대상연도다() {
        // Given
        let now = date(2026, 12, 5)

        // When
        let year = YearReviewSummary.targetYear(now: now, calendar: calendar)

        // Then
        XCTAssertEqual(year, 2026)
    }

    func test_GH34_TC2_1월이면_지난해가대상연도다() {
        // Given
        let now = date(2027, 1, 20)

        // When
        let year = YearReviewSummary.targetYear(now: now, calendar: calendar)

        // Then
        XCTAssertEqual(year, 2026)
    }

    func test_GH34_TC3_11월30일과2월1일은_노출기간이아니다() {
        // Given
        let lastDayBefore = date(2026, 11, 30, 23, 59)
        let firstDayAfter = date(2027, 2, 1)

        // When
        let before = YearReviewSummary.targetYear(now: lastDayBefore, calendar: calendar)
        let after = YearReviewSummary.targetYear(now: firstDayAfter, calendar: calendar)

        // Then
        XCTAssertNil(before)
        XCTAssertNil(after)
        XCTAssertEqual(YearReviewSummary.targetYear(now: date(2026, 12, 1), calendar: calendar), 2026)
        XCTAssertEqual(YearReviewSummary.targetYear(now: date(2027, 1, 31, 23, 59), calendar: calendar), 2026)
    }

    // MARK: GH-34 TC6

    func test_GH34_TC6_카테고리별완료수를세고_다른해완료와미완료는빠진다() {
        // Given
        let wishes = [
            finished(id: "do1", category: .wantToDo, finishedAt: date(2026, 3, 1)),
            finished(id: "do2", category: .wantToDo, finishedAt: date(2026, 5, 1)),
            finished(id: "get1", category: .wantToGet, finishedAt: date(2026, 7, 1)),
            finished(id: "old", category: .wantToGo, finishedAt: date(2025, 12, 31)),
            Wish(id: "notYet", category: .wantToGo, isSuccess: false)
        ]

        // When
        let summary = YearReviewSummary.make(wishes: wishes, year: 2026, calendar: calendar)

        // Then
        XCTAssertEqual(summary.totalCount, 3)
        XCTAssertEqual(summary.count(of: .wantToDo), 2)
        XCTAssertEqual(summary.count(of: .wantToGet), 1)
        XCTAssertEqual(summary.count(of: .wantToGo), 0)
        XCTAssertFalse(summary.wishes.contains { $0.id == "old" })
    }

    // MARK: GH-34 TC7

    func test_GH34_TC7_가장오래품고이룬싶은_적은날부터이룬날까지가가장긴위시다() {
        // Given
        let finishA = date(2026, 9, 1)
        let finishB = date(2026, 8, 31)
        let wishA = finished(id: "A", createdAt: calendar.date(byAdding: .day, value: -100, to: finishA), finishedAt: finishA)
        let wishB = finished(id: "B", createdAt: calendar.date(byAdding: .day, value: -412, to: finishB), finishedAt: finishB)

        // When
        let summary = YearReviewSummary.make(wishes: [wishA, wishB], year: 2026, calendar: calendar)

        // Then
        XCTAssertEqual(summary.longestHeld?.wish.id, "B")
        XCTAssertEqual(summary.longestHeld?.days, 412)
    }

    func test_GH34_TC7_품은일수가같으면_먼저완료한위시다() {
        // Given
        let early = finished(id: "early", createdAt: date(2026, 1, 1), finishedAt: date(2026, 3, 1))
        let late = finished(id: "late", createdAt: date(2026, 2, 1), finishedAt: date(2026, 4, 1))
        // 1/1→3/1 = 59일, 2/1→4/1 = 59일

        // When
        let summary = YearReviewSummary.make(wishes: [late, early], year: 2026, calendar: calendar)

        // Then
        XCTAssertEqual(summary.longestHeld?.days, 59)
        XCTAssertEqual(summary.longestHeld?.wish.id, "early")
    }

    // MARK: GH-34 TC8

    func test_GH34_TC8_가장많이이룬달은_완료수가가장많은달이다() {
        // Given
        let wishes = [
            finished(id: "a1", finishedAt: date(2026, 8, 2)),
            finished(id: "a2", finishedAt: date(2026, 8, 14)),
            finished(id: "a3", finishedAt: date(2026, 8, 31)),
            finished(id: "o1", finishedAt: date(2026, 10, 3))
        ]

        // When
        let summary = YearReviewSummary.make(wishes: wishes, year: 2026, calendar: calendar)

        // Then
        XCTAssertEqual(summary.busiestMonth, YearReviewSummary.BusiestMonth(month: 8, count: 3))
    }

    func test_GH34_TC8_완료수가같으면이른달이고_완료가1개면nil이다() {
        // Given
        let tied = [
            finished(id: "m10", finishedAt: date(2026, 10, 3)),
            finished(id: "m3", finishedAt: date(2026, 3, 3))
        ]
        let single = [finished(id: "only", finishedAt: date(2026, 6, 1))]

        // When
        let tiedSummary = YearReviewSummary.make(wishes: tied, year: 2026, calendar: calendar)
        let singleSummary = YearReviewSummary.make(wishes: single, year: 2026, calendar: calendar)

        // Then
        XCTAssertEqual(tiedSummary.busiestMonth, YearReviewSummary.BusiestMonth(month: 3, count: 1))
        XCTAssertNil(singleSummary.busiestMonth)
    }

    // MARK: GH-34 TC9

    func test_GH34_TC9_올해의한줄은_소감있는위시중가장최근완료한위시다() {
        // Given
        let wishes = [
            finished(id: "oct", finishedAt: date(2026, 10, 10), note: "10월 소감"),
            finished(id: "dec", finishedAt: date(2026, 12, 3), note: "12월 소감"),
            finished(id: "decNoNote", finishedAt: date(2026, 12, 20))
        ]

        // When
        let summary = YearReviewSummary.make(wishes: wishes, year: 2026, calendar: calendar)

        // Then
        XCTAssertEqual(summary.noteOfYear?.id, "dec")
        XCTAssertEqual(summary.noteOfYear?.finishNote, "12월 소감")
    }

    func test_GH34_TC9_소감이하나도없으면_올해의한줄은nil이다() {
        // Given
        let wishes = [finished(id: "a", finishedAt: date(2026, 10, 10))]

        // When
        let summary = YearReviewSummary.make(wishes: wishes, year: 2026, calendar: calendar)

        // Then
        XCTAssertNil(summary.noteOfYear)
    }

    // MARK: GH-34 TC11

    func test_GH34_TC11_12월31일23시30분완료는_그해에들어가고_1월1일0시는빠진다() {
        // Given
        let lastMinute = finished(id: "lastMinute", finishedAt: date(2026, 12, 31, 23, 30))
        let newYear = finished(id: "newYear", finishedAt: date(2027, 1, 1, 0, 0))

        // When
        let summary = YearReviewSummary.make(wishes: [lastMinute, newYear], year: 2026, calendar: calendar)
        let range = YearReviewSummary.dateRange(year: 2026, calendar: calendar)

        // Then
        XCTAssertEqual(summary.wishes.map(\.id), ["lastMinute"])
        XCTAssertEqual(range?.from, date(2026, 1, 1))
        XCTAssertEqual(range?.to, date(2027, 1, 1))
    }

    // MARK: GH-34 TC15 (달별 묶음)

    func test_GH34_TC15_달내림차순으로묶고_달안은완료일내림차순이다() {
        // Given
        let wishes = [
            finished(id: "aug2", finishedAt: date(2026, 8, 2)),
            finished(id: "dec3", finishedAt: date(2026, 12, 3)),
            finished(id: "aug31", finishedAt: date(2026, 8, 31))
        ]

        // When
        let summary = YearReviewSummary.make(wishes: wishes, year: 2026, calendar: calendar)

        // Then
        XCTAssertEqual(summary.monthGroups.map(\.month), [12, 8])
        XCTAssertEqual(summary.monthGroups.last?.wishes.map(\.id), ["aug31", "aug2"])
    }
}

/// 연도 문구 (시뮬레이터 검증에서 "2,026년"으로 보인 문제)
final class YearReviewStringsTests: XCTestCase {
    func test_회귀_연도문구에_천단위구분기호가붙지않는다() {
        // Given
        let year = 2026

        // When
        let caption = Strings.Home.YearReview.captionFormat(String(year))
        let headline = Strings.YearReview.List.headlineFormat(String(year), 12)

        // Then
        XCTAssertEqual(caption, "2026년 돌아보기")
        XCTAssertTrue(headline.hasPrefix("2026년에 이룬 싶"))
    }
}

/// 4:5 공유 이미지 캔버스 크기 (R-5)
final class YearReviewImageRendererTests: XCTestCase {
    // MARK: GH-34 TC10 (이미지 비율)

    func test_GH34_TC10_공유이미지캔버스는_카드를여백안에담는4대5비율이다() {
        // Given
        let wideCard = CGSize(width: 362, height: 300)
        let tallCard = CGSize(width: 362, height: 600)

        // When
        let wideCanvas = YearReviewImageRenderer.canvasSize(cardSize: wideCard, padding: 24)
        let tallCanvas = YearReviewImageRenderer.canvasSize(cardSize: tallCard, padding: 24)

        // Then
        XCTAssertEqual(wideCanvas.width / wideCanvas.height, 0.8, accuracy: 0.0001)
        XCTAssertEqual(wideCanvas.width, 410, accuracy: 0.0001)
        XCTAssertEqual(tallCanvas.width / tallCanvas.height, 0.8, accuracy: 0.0001)
        XCTAssertEqual(tallCanvas.height, 648, accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(tallCanvas.width, 362 + 48)
    }
}
