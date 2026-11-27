import XCTest

@testable import seep_ios

/// 기대 비교(`finishFeeling`) 저장소·마이그레이션 (GH-139 R-1, R-9, TC-1, TC-10). 메모리 DB 로 실제 구현을 돌린다
final class FinishFeelingRepositoryTests: XCTestCase {
    private let suiteName = "test.finishFeelingRepository"
    private var database: AppDatabase!
    private var sut: WishRepositoryImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeInMemory()
        sut = WishRepositoryImpl(database: database)
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
        database = nil
        sut = nil
        super.tearDown()
    }

    // MARK: GH-139 TC1

    func test_GH139_TC1_v12까지돈DB를올리면_모든위시의finishFeeling이빈값이고_다른컬럼은그대로다() throws {
        // Given: v12 스키마의 진행 중·이룬(소감 있음)·지운 위시
        let database = try AppDatabase.makeInMemory(migratedUpTo: "v12", seedSQL: [
            "INSERT INTO wish (id, category, title, isSuccess, createdAt, updatedAt) VALUES ('A', 'category_want_to_do', '서핑', 0, 100, 10)",
            "INSERT INTO wish (id, category, title, isSuccess, finishDate, finishNote, createdAt, updatedAt) VALUES ('B', 'category_want_to_go', '제주', 1, 300, '최고', 200, 20)",
            "INSERT INTO wish (id, category, title, createdAt, updatedAt, deletedAt) VALUES ('C', 'category_want_to_get', '에어팟', 300, 30, 40)"
        ])

        // When: 앱 업데이트 — 남은 마이그레이션(v13)이 돈 뒤 읽는다
        let records = try database.snapshot().wishes.sorted { $0.id < $1.id }

        // Then
        XCTAssertEqual(records.map(\.finishFeeling), ["", "", ""])
        XCTAssertEqual(records.map(\.finishNote), ["", "최고", ""])
        XCTAssertEqual(records.map(\.updatedAt), [10, 20, 30].map(Date.init(timeIntervalSinceReferenceDate:)))
        XCTAssertNil(WishRepositoryImpl(database: database).fetchWish(id: "B")?.finishFeeling)
    }

    // MARK: GH-139 R-3

    func test_GH139_R3_기대비교와소감을저장하면_함께읽히고_updatedAt이갱신된다() throws {
        // Given
        let clock = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let sut = WishRepositoryImpl(database: database, now: { clock })
        let wish = try sut.addWish(Wish(id: "w", title: "라멘")).get()
        _ = try sut.finishWish(wish: wish).get()

        // When
        let saved = try sut.updateFinishNote(wishId: "w", note: "", feeling: .better).get()

        // Then
        XCTAssertEqual(saved.finishFeeling, .better)
        XCTAssertEqual(sut.fetchWish(id: "w")?.finishFeeling, .better)
        XCTAssertEqual(try database.snapshot().wishes.first?.finishFeeling, "better")
    }

    // MARK: GH-139 TC10

    func test_GH139_TC10_better인완료싶의완료를취소하면_finishFeeling이빈값이된다() throws {
        // Given
        let wish = try sut.addWish(Wish(id: "w", title: "라멘")).get()
        _ = try sut.finishWish(wish: wish).get()
        _ = try sut.updateFinishNote(wishId: "w", note: "최고", feeling: .better).get()

        // When
        let canceled = try sut.cancelFinish(wishId: "w").get()

        // Then
        XCTAssertNil(canceled.finishFeeling)
        XCTAssertEqual(try database.snapshot().wishes.first?.finishFeeling, "")
    }

    func test_GH139_TC10_위젯에서완료를취소해도_finishFeeling이빈값이된다() throws {
        // Given
        let wish = try sut.addWish(Wish(id: "w", title: "라멘")).get()
        _ = try sut.finishWish(wish: wish).get()
        _ = try sut.updateFinishNote(wishId: "w", note: "", feeling: .better).get()
        let store = WidgetCheckStore(userDefaults: UserDefaults(suiteName: suiteName))
        let widgetRepository = WidgetCheckRepositoryImpl(database: database, store: store)

        // When
        _ = try widgetRepository.unfinishWish(wishId: "w").get()

        // Then
        XCTAssertEqual(try database.snapshot().wishes.first?.finishFeeling, "")
        XCTAssertNil(sut.fetchWish(id: "w")?.finishFeeling)
    }

    func test_GH139_R1_수정해저장해도_기대비교는그대로다() throws {
        // Given
        let wish = try sut.addWish(Wish(id: "w", title: "라멘")).get()
        _ = try sut.finishWish(wish: wish).get()
        let finished = try sut.updateFinishNote(wishId: "w", note: "", feeling: .worse).get()

        // When
        var edited = finished
        edited.title = "삿포로 라멘"
        _ = try sut.updateWish(edited).get()

        // Then
        XCTAssertEqual(sut.fetchWish(id: "w")?.finishFeeling, .worse)
    }
}
