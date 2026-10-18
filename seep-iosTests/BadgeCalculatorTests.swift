import XCTest

@testable import seep_ios_dev

final class BadgeCalculatorTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? Date()
    }

    private func finishedWish(
        id: String = UUID().uuidString,
        category: seep_ios_dev.Category = .wantToGet,
        endDate: Date? = nil,
        finishDate: Date
    ) -> Wish {
        return Wish(id: id, category: category, endDate: endDate, finishDate: finishDate, isSuccess: true)
    }

    private func badge(_ type: BadgeType, in badges: [Badge]) -> Badge? {
        return badges.first { $0.type == type }
    }

    // MARK: GH-35 TC1

    func test_GH35_TC1_완료위시가0개면_8개모두잠김이다() {
        // Given
        let wishes: [Wish] = []

        // When
        let badges = BadgeCalculator.calculate(finishedWishes: wishes, calendar: calendar)

        // Then
        XCTAssertEqual(badges.map(\.type), BadgeType.allCases)
        XCTAssertEqual(badges.count, 8)
        XCTAssertTrue(badges.allSatisfy { !$0.isEarned })
        XCTAssertEqual(badge(.finish5, in: badges)?.lockedDescription, "0 / 5")
        XCTAssertEqual(badge(.firstWantToGo, in: badges)?.lockedDescription, "가고 싶은 곳 1개 이루기")
    }

    // MARK: GH-35 TC2

    func test_GH35_TC2_하고싶어요1개를완료하면_첫싶과첫하고싶어요를얻고_얻은날은그위시의완료일이다() {
        // Given
        let finishDate = date(2026, 3, 2, hour: 12)
        let wishes = [finishedWish(category: .wantToDo, finishDate: finishDate)]

        // When
        let badges = BadgeCalculator.calculate(finishedWishes: wishes, calendar: calendar)

        // Then
        XCTAssertEqual(badges.filter(\.isEarned).map(\.type), [.finish1, .firstWantToDo])
        XCTAssertEqual(badge(.finish1, in: badges)?.earnedDate, finishDate)
        XCTAssertEqual(badge(.firstWantToDo, in: badges)?.earnedDate, finishDate)
        XCTAssertEqual(badge(.finish1, in: badges)?.earnedDateText, "2026.03.02")
    }

    func test_GH35_TC2_미완료위시는_계산에서빠진다() {
        // Given
        let wishes = [Wish(category: .wantToDo, finishDate: date(2026, 3, 2), isSuccess: false)]

        // When
        let badges = BadgeCalculator.calculate(finishedWishes: wishes, calendar: calendar)

        // Then
        XCTAssertTrue(badges.allSatisfy { !$0.isEarned })
    }

    // MARK: GH-35 TC3

    func test_GH35_TC3_완료4개에서1개더완료하면_다섯번째싶을5번째완료일로얻고_열번째싶진행도는5대10이다() {
        // Given: 완료일이 뒤섞인 4개 + 5번째
        let fourWishes = [
            finishedWish(finishDate: date(2026, 4, 1)),
            finishedWish(finishDate: date(2026, 1, 1)),
            finishedWish(finishDate: date(2026, 3, 1)),
            finishedWish(finishDate: date(2026, 2, 1))
        ]
        let before = BadgeCalculator.calculate(finishedWishes: fourWishes, calendar: calendar)
        XCTAssertFalse(badge(.finish5, in: before)?.isEarned ?? true)
        XCTAssertEqual(badge(.finish5, in: before)?.lockedDescription, "4 / 5")

        // When
        let fifthDate = date(2026, 10, 18)
        let badges = BadgeCalculator.calculate(
            finishedWishes: fourWishes + [finishedWish(finishDate: fifthDate)],
            calendar: calendar
        )

        // Then
        XCTAssertEqual(badge(.finish5, in: badges)?.earnedDate, fifthDate)
        XCTAssertEqual(badge(.finish1, in: badges)?.earnedDate, date(2026, 1, 1))
        XCTAssertFalse(badge(.finish10, in: badges)?.isEarned ?? true)
        XCTAssertEqual(badge(.finish10, in: badges)?.lockedDescription, "5 / 10")
        XCTAssertEqual(badge(.finish30, in: badges)?.lockedDescription, "5 / 30")
    }

    // MARK: GH-35 TC4

    func test_GH35_TC4_마감일당일에완료하면_약속지킴이를얻는다() {
        // Given: 마감일 10/20, 10/20 오후에 완료
        let wishes = [finishedWish(endDate: date(2026, 10, 20), finishDate: date(2026, 10, 20, hour: 15))]

        // When
        let badges = BadgeCalculator.calculate(finishedWishes: wishes, calendar: calendar)

        // Then
        XCTAssertEqual(badge(.onTime, in: badges)?.earnedDate, date(2026, 10, 20, hour: 15))
    }

    func test_GH35_TC4_마감일다음날완료나_마감일없는위시는_약속지킴이를얻지않는다() {
        // Given
        let wishes = [
            finishedWish(endDate: date(2026, 10, 20), finishDate: date(2026, 10, 21)),
            finishedWish(endDate: nil, finishDate: date(2026, 10, 1))
        ]

        // When
        let badges = BadgeCalculator.calculate(finishedWishes: wishes, calendar: calendar)

        // Then
        XCTAssertFalse(badge(.onTime, in: badges)?.isEarned ?? true)
        XCTAssertEqual(badge(.onTime, in: badges)?.lockedDescription, "마감일까지 이루기")
    }

    func test_GH35_TC4_약속지킴이얻은날은_조건에맞는가장이른완료일이다() {
        // Given
        let wishes = [
            finishedWish(endDate: date(2026, 12, 1), finishDate: date(2026, 11, 1)),
            finishedWish(endDate: date(2026, 9, 1), finishDate: date(2026, 8, 15))
        ]

        // When
        let badges = BadgeCalculator.calculate(finishedWishes: wishes, calendar: calendar)

        // Then
        XCTAssertEqual(badge(.onTime, in: badges)?.earnedDate, date(2026, 8, 15))
    }
}
