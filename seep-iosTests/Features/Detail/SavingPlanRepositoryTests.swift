import XCTest

@testable import seep_ios

/// 적금 계획 저장소·마이그레이션 (GH-121 R-8). 메모리 DB 로 실제 구현을 돌린다
final class SavingPlanRepositoryTests: XCTestCase {
    private var database: AppDatabase!
    private var clock = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private var sut: WishRepositoryImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeInMemory()
        sut = WishRepositoryImpl(database: database, now: { [unowned self] in self.clock })
    }

    override func tearDown() {
        database = nil
        sut = nil
        super.tearDown()
    }

    // MARK: GH-121 TC7

    func test_GH121_TC7_계획을저장하고_저장소를새로만들어읽어도_주기요일금액이그대로다() throws {
        // Given
        _ = try sut.addWish(Wish(id: "w1", category: .wantToGet, title: "에어팟", targetAmount: 359_000)).get()
        _ = try sut.addWish(Wish(id: "w2", category: .wantToGet, title: "아이패드", targetAmount: 999_000)).get()
        _ = try sut.addSaving(wishId: "w1", amount: 150_000).get()
        let weekly = try XCTUnwrap(SavingPlan(cycle: .weekly, day: 6, amount: 30_000))
        let monthly = try XCTUnwrap(SavingPlan(cycle: .monthly, day: 31, amount: 100_000))
        clock = clock.addingTimeInterval(60)

        // When
        let saved = try sut.updateSavingPlan(wishId: "w1", plan: weekly).get()
        _ = try sut.updateSavingPlan(wishId: "w2", plan: monthly).get()
        let restarted = WishRepositoryImpl(database: database)

        // Then
        XCTAssertEqual(saved.savingPlan, weekly)
        XCTAssertEqual(saved.savings.map(\.amount), [150_000], "모은 돈 기록은 건드리지 않는다")
        XCTAssertEqual(restarted.fetchWish(id: "w1")?.savingPlan, weekly)
        XCTAssertEqual(restarted.fetchWish(id: "w2")?.savingPlan, monthly)
        let record = try XCTUnwrap(database.snapshot().wishes.first { $0.id == "w1" })
        XCTAssertEqual(record.savingPlanCycle, "weekly")
        XCTAssertEqual(record.savingPlanDay, 6)
        XCTAssertEqual(record.savingPlanAmount, 30_000)
        XCTAssertEqual(record.updatedAt, clock, "동기화가 올리도록 updatedAt 을 갱신한다")
    }

    func test_GH121_TC7_계획을지우면_빈값으로저장되고_수정폼저장은계획을건드리지않는다() throws {
        // Given
        let plan = try XCTUnwrap(SavingPlan(cycle: .weekly, day: 2, amount: 10_000))
        _ = try sut.addWish(Wish(id: "w1", category: .wantToGet, title: "에어팟", targetAmount: 359_000)).get()
        _ = try sut.updateSavingPlan(wishId: "w1", plan: plan).get()

        // When: 수정 폼 저장(계획이 없는 위시 값으로 저장해도)
        let edited = try sut.updateWish(Wish(id: "w1", category: .wantToGet, title: "에어팟 프로", targetAmount: 359_000)).get()

        // Then
        XCTAssertEqual(edited.savingPlan, plan)

        // When
        let cleared = try sut.updateSavingPlan(wishId: "w1", plan: nil).get()

        // Then
        XCTAssertNil(cleared.savingPlan)
        let record = try XCTUnwrap(database.snapshot().wishes.first)
        XCTAssertEqual([record.savingPlanCycle, "\(record.savingPlanDay)", "\(record.savingPlanAmount)"], ["", "0", "0"])
    }

    func test_GH121_TC7_어긋난저장값은_계획없음으로읽는다() {
        // Given / When / Then: 주기 모름·날 범위 밖·금액 0
        XCTAssertNil(SavingPlan(storedCycle: "daily", day: 1, amount: 1_000))
        XCTAssertNil(SavingPlan(storedCycle: "weekly", day: 8, amount: 1_000))
        XCTAssertNil(SavingPlan(storedCycle: "monthly", day: 0, amount: 1_000))
        XCTAssertNil(SavingPlan(storedCycle: "monthly", day: 15, amount: 0))
        XCTAssertNil(SavingPlan(storedCycle: "", day: 0, amount: 0))
        XCTAssertNotNil(SavingPlan(storedCycle: "monthly", day: 31, amount: 1))
    }

    // MARK: GH-121 TC8

    func test_GH121_TC8_v15이전DB를올리면_모든위시가계획없음이고_다른값은그대로다() throws {
        // Given: v15 직전 스키마(v12)의 진행 중·이룬·지운 위시
        let database = try AppDatabase.makeInMemory(migratedUpTo: "v12", seedSQL: [
            "INSERT INTO wish (id, category, title, targetAmount, isSuccess, createdAt, updatedAt) VALUES ('A', 'category_want_to_get', '에어팟', 359000, 0, 100, 10)",
            "INSERT INTO wish (id, category, title, isSuccess, finishDate, createdAt, updatedAt) VALUES ('B', 'category_want_to_go', '제주', 1, 300, 200, 20)",
            "INSERT INTO wish (id, category, title, startedAt, createdAt, updatedAt, deletedAt) VALUES ('C', 'category_want_to_do', '서핑', 250, 300, 30, 40)"
        ])

        // When: 앱 업데이트 — 남은 마이그레이션(v15)이 돈 뒤 읽는다
        let wishes = try database.snapshot().wishes.sorted { $0.id < $1.id }

        // Then
        XCTAssertEqual(wishes.map(\.savingPlanCycle), ["", "", ""])
        XCTAssertEqual(wishes.map(\.savingPlanDay), [0, 0, 0])
        XCTAssertEqual(wishes.map(\.savingPlanAmount), [0, 0, 0])
        XCTAssertNil(WishRepositoryImpl(database: database).fetchWish(id: "A")?.savingPlan)
        XCTAssertEqual(wishes.map(\.title), ["에어팟", "제주", "서핑"])
        XCTAssertEqual(wishes.map(\.targetAmount), [359_000, 0, 0])
        XCTAssertEqual(wishes.map(\.isSuccess), [false, true, false])
        XCTAssertEqual(wishes.map(\.startedAt), [nil, nil, Date(timeIntervalSinceReferenceDate: 250)])
        XCTAssertEqual(wishes.map(\.updatedAt), [10, 20, 30].map(Date.init(timeIntervalSinceReferenceDate:)))
        XCTAssertEqual(wishes.map(\.deletedAt), [nil, nil, Date(timeIntervalSinceReferenceDate: 40)])
    }
}
