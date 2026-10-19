import XCTest

@testable import seep_ios_dev

final class SleepingWishPolicyTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private lazy var today: Date = {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 13)) ?? Date()
    }()

    private func daysAgo(_ days: Int) -> Date {
        return calendar.date(byAdding: .day, value: -days, to: today) ?? today
    }

    private func isSleeping(_ wish: Wish) -> Bool {
        return SleepingWishPolicy.isSleeping(wish, today: today, calendar: calendar)
    }

    // MARK: GH-30 TC1

    func test_GH30_TC1_61일전에만든_일정없는미완료위시는_잠든위시이고_61일째다() {
        // Given
        let wish = Wish(title: "기타 치기", createdAt: daysAgo(61))

        // When
        let sleeping = isSleeping(wish)
        let days = SleepingWishPolicy.daysSinceTouched(wish, today: today, calendar: calendar)

        // Then
        XCTAssertTrue(sleeping)
        XCTAssertEqual(days, 61)
    }

    // MARK: GH-30 TC2

    func test_GH30_TC2_59일전에만든위시는_잠든위시가아니다() {
        // Given
        let wish = Wish(createdAt: daysAgo(59))

        // When
        let sleeping = isSleeping(wish)

        // Then
        XCTAssertFalse(sleeping)
    }

    func test_GH30_TC2_딱60일째부터_잠든위시다() {
        // Given
        let wish = Wish(createdAt: daysAgo(60))

        // When
        let sleeping = isSleeping(wish)

        // Then
        XCTAssertTrue(sleeping)
    }

    // MARK: GH-30 TC3

    func test_GH30_TC3_90일전에만들었어도_마감일이다음달이면_대상이아니다() {
        // Given
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: today)
        let wish = Wish(endDate: nextMonth, createdAt: daysAgo(90))

        // When
        let sleeping = isSleeping(wish)

        // Then
        XCTAssertFalse(sleeping)
    }

    func test_GH30_TC3_마감일이오늘이면_대상이아니고_지났으면_대상이다() {
        // Given
        let dueToday = Wish(endDate: today, createdAt: daysAgo(90))
        let overdue = Wish(endDate: daysAgo(1), createdAt: daysAgo(90))

        // When
        let dueTodaySleeping = isSleeping(dueToday)
        let overdueSleeping = isSleeping(overdue)

        // Then
        XCTAssertFalse(dueTodaySleeping)
        XCTAssertTrue(overdueSleeping)
    }

    // MARK: GH-30 TC4

    func test_GH30_TC4_90일전에만든_완료위시는_대상이아니다() {
        // Given
        let wish = Wish(isSuccess: true, createdAt: daysAgo(90))

        // When
        let sleeping = isSleeping(wish)

        // Then
        XCTAssertFalse(sleeping)
    }

    // MARK: GH-30 TC5

    func test_GH30_TC5_잠든위시가둘이면_가장오래된위시하나만고른다() {
        // Given
        let seventy = Wish(id: "70", createdAt: daysAgo(70))
        let hundred = Wish(id: "100", createdAt: daysAgo(100))
        let fresh = Wish(id: "10", createdAt: daysAgo(10))

        // When
        let oldest = SleepingWishPolicy.oldestSleepingWish(in: [seventy, fresh, hundred], today: today, calendar: calendar)

        // Then
        XCTAssertEqual(oldest?.id, "100")
    }

    // MARK: GH-30 TC6

    func test_GH30_TC6_오늘점검한위시는_만든지오래돼도_60일동안대상이아니다() {
        // Given
        let checkedToday = Wish(lastCheckedAt: today, createdAt: daysAgo(100))
        let checked59DaysAgo = Wish(lastCheckedAt: daysAgo(59), createdAt: daysAgo(200))
        let checked60DaysAgo = Wish(lastCheckedAt: daysAgo(60), createdAt: daysAgo(200))

        // When
        let results = [checkedToday, checked59DaysAgo, checked60DaysAgo].map(isSleeping)

        // Then
        XCTAssertEqual(results, [false, false, true])
    }

    // MARK: GH-30 TC9

    func test_GH30_TC9_70일전에만든위시를_오늘수정해저장하면_대상이아니다() {
        // Given: 수정 저장으로 lastCheckedAt 이 오늘이 됐다 (R-2)
        let wish = Wish(lastCheckedAt: today, createdAt: daysAgo(70))

        // When
        let sleeping = isSleeping(wish)

        // Then
        XCTAssertFalse(sleeping)
    }

    // MARK: GH-30 TC11

    func test_GH30_TC11_DTO의lastCheckedAt이nil이면_위시도nil이고_되돌려도nil이다() {
        // Given: 마이그레이션 직후 기존 위시 (R-1)
        let dto = WishDTO()
        dto.createdAt = daysAgo(80)

        // When
        let wish = Wish(dto: dto)
        let roundTrip = WishDTO(wish: wish)

        // Then
        XCTAssertNil(wish.lastCheckedAt)
        XCTAssertNil(roundTrip.lastCheckedAt)
    }

    func test_GH30_TC11_lastCheckedAt은_DTO와위시사이에서그대로옮겨진다() {
        // Given
        let wish = Wish(lastCheckedAt: daysAgo(3), createdAt: daysAgo(80))

        // When
        let restored = Wish(dto: WishDTO(wish: wish))

        // Then
        XCTAssertEqual(restored.lastCheckedAt, daysAgo(3))
    }
}
