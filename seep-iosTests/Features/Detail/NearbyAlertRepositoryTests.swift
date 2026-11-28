import XCTest

@testable import seep_ios

/// 근처 알림 저장소·마이그레이션 (GH-126 R-1, R-7, R-10). 메모리 DB 로 실제 구현을 돌린다
final class NearbyAlertRepositoryTests: XCTestCase {
    private var database: AppDatabase!
    private var clock = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private var sut: WishRepositoryImpl!

    private let place = WishPlace(name: "블루보틀 성수 카페", address: "서울 성동구 아차산로 7", latitude: 37.5478, longitude: 127.0451)

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

    private func tick(_ seconds: TimeInterval = 60) {
        clock = clock.addingTimeInterval(seconds)
    }

    /// 장소를 붙이고 근처 알림을 켠 가고 싶어요 위시
    @discardableResult
    private func addOnWish(id: String = "w1") throws -> Wish {
        _ = try sut.addWish(Wish(id: id, emoji: "☕️", category: .wantToGo, title: "성수 블루보틀", place: place)).get()
        tick()
        return try sut.updateNearbyAlert(wishId: id, isOn: true).get()
    }

    private func record(_ id: String = "w1") throws -> WishRecord {
        try XCTUnwrap(database.snapshot().wishes.first { $0.id == id })
    }

    // MARK: GH-126 TC3

    func test_GH126_TC3_근처알림을켜면_저장되고_updatedAt이갱신되며_켠위시목록에보인다() throws {
        // Given
        _ = try sut.addWish(Wish(id: "w1", category: .wantToGo, title: "성수 블루보틀", place: place)).get()
        let before = try record().updatedAt
        tick()

        // When
        let saved = try sut.updateNearbyAlert(wishId: "w1", isOn: true).get()

        // Then
        XCTAssertTrue(saved.nearbyAlertOn)
        XCTAssertTrue(try record().nearbyAlertOn)
        XCTAssertGreaterThan(try record().updatedAt, before)
        XCTAssertEqual(sut.fetchNearbyAlertWishes().map(\.id), ["w1"])

        // When: 끈다
        _ = try sut.updateNearbyAlert(wishId: "w1", isOn: false).get()

        // Then
        XCTAssertFalse(try record().nearbyAlertOn)
        XCTAssertTrue(sut.fetchNearbyAlertWishes().isEmpty)
    }

    // MARK: GH-126 TC6

    func test_GH126_TC6_이룬위시나장소없는위시는_켜기를저장하지않는다() throws {
        // Given: 권한 팝업을 기다리는 사이 위젯으로 이뤘거나, 장소를 지운 위시
        let wish = try sut.addWish(Wish(id: "w1", category: .wantToGo, title: "성수 블루보틀", place: place)).get()
        _ = try sut.finishWish(wish: wish).get()
        _ = try sut.addWish(Wish(id: "w2", category: .wantToGo, title: "을지로 냉면")).get()
        tick()

        // When
        let finished = try sut.updateNearbyAlert(wishId: "w1", isOn: true).get()
        let noPlace = try sut.updateNearbyAlert(wishId: "w2", isOn: true).get()

        // Then
        XCTAssertFalse(finished.nearbyAlertOn)
        XCTAssertFalse(noPlace.nearbyAlertOn)
        XCTAssertFalse(try record("w1").nearbyAlertOn)
        XCTAssertFalse(try record("w2").nearbyAlertOn)
        XCTAssertTrue(sut.fetchNearbyAlertWishes().isEmpty)
    }

    func test_GH126_TC6_근처알림켠위시를완료하면_꺼진다() throws {
        // Given
        let wish = try addOnWish()

        // When
        let finished = try sut.finishWish(wish: wish).get()

        // Then
        XCTAssertFalse(finished.nearbyAlertOn)
        XCTAssertFalse(try record().nearbyAlertOn)
        XCTAssertTrue(sut.fetchNearbyAlertWishes().isEmpty)
    }

    func test_GH126_TC6_근처알림켠위시를삭제하면_삭제표시와함께꺼진다() throws {
        // Given
        try addOnWish(id: "w1")
        try addOnWish(id: "w2")

        // When
        sut.deleteWish(id: "w1")
        _ = try sut.deleteWishes(ids: ["w2"]).get()

        // Then
        XCTAssertNotNil(try record("w1").deletedAt)
        XCTAssertFalse(try record("w1").nearbyAlertOn)
        XCTAssertFalse(try record("w2").nearbyAlertOn)
        XCTAssertTrue(sut.fetchNearbyAlertWishes().isEmpty)
    }

    func test_GH126_TC6_장소를지우면_꺼지고_장소를바꾸면_켠채로남는다() throws {
        // Given
        try addOnWish()
        let newPlace = WishPlace(name: "을지면옥", address: "서울 중구", latitude: 37.5663, longitude: 126.9918)

        // When: 장소 변경
        let moved = try sut.updatePlace(wishId: "w1", place: newPlace).get()

        // Then
        XCTAssertTrue(moved.nearbyAlertOn)
        XCTAssertEqual(moved.place, newPlace)

        // When: 장소 지우기
        let cleared = try sut.updatePlace(wishId: "w1", place: nil).get()

        // Then
        XCTAssertFalse(cleared.nearbyAlertOn)
        XCTAssertFalse(try record().nearbyAlertOn)
    }

    func test_GH126_TC6_위젯에서완료해도_꺼진다() throws {
        // Given
        try addOnWish()
        let widgetRepository = WidgetCheckRepositoryImpl(database: database)

        // When
        _ = try widgetRepository.finishWish(wishId: "w1", lastStepId: nil).get()

        // Then
        XCTAssertFalse(try record().nearbyAlertOn)
    }

    // MARK: GH-126 TC9

    func test_GH126_TC9_v12까지돈DB를v16으로올리면_모든위시가꺼짐이고_다른컬럼은그대로다() throws {
        // Given: v12 스키마의 진행 중(장소 있음)·이룬·지운 위시
        let database = try AppDatabase.makeInMemory(migratedUpTo: "v12", seedSQL: [
            "INSERT INTO wish (id, category, title, placeName, latitude, longitude, startedAt, createdAt, updatedAt) VALUES ('A', 'category_want_to_go', '성수', '블루보틀', 37.5, 127.0, 50, 100, 10)",
            "INSERT INTO wish (id, category, title, isSuccess, finishDate, createdAt, updatedAt) VALUES ('B', 'category_want_to_go', '제주', 1, 300, 200, 20)",
            "INSERT INTO wish (id, category, title, createdAt, updatedAt, deletedAt) VALUES ('C', 'category_want_to_get', '에어팟', 300, 30, 40)"
        ])

        // When: 앱 업데이트 — 남은 마이그레이션(v16 등)이 돈 뒤 읽는다
        let wishes = try database.snapshot().wishes.sorted { $0.id < $1.id }

        // Then
        XCTAssertEqual(wishes.map(\.nearbyAlertOn), [false, false, false])
        XCTAssertEqual(wishes.map(\.title), ["성수", "제주", "에어팟"])
        XCTAssertEqual(wishes.map(\.placeName), ["블루보틀", "", ""])
        XCTAssertEqual(wishes.map(\.latitude), [37.5, 0, 0])
        XCTAssertEqual(wishes.map(\.startedAt), [Date(timeIntervalSinceReferenceDate: 50), nil, nil])
        XCTAssertEqual(wishes.map(\.isSuccess), [false, true, false])
        XCTAssertEqual(wishes.map(\.updatedAt), [10, 20, 30].map(Date.init(timeIntervalSinceReferenceDate:)))
        XCTAssertEqual(wishes.map(\.deletedAt), [nil, nil, Date(timeIntervalSinceReferenceDate: 40)])
    }

    // MARK: GH-126 TC14

    func test_GH126_TC14_수정화면에서카테고리를가고싶어요밖으로바꿔저장하면_꺼진다() throws {
        // Given
        var wish = try addOnWish()

        // When
        wish.category = .wantToDo
        let saved = try sut.updateWish(wish).get()

        // Then
        XCTAssertFalse(saved.nearbyAlertOn)
        XCTAssertFalse(try record().nearbyAlertOn)
    }

    func test_GH126_TC14_가고싶어요그대로수정저장하면_켠채로남는다() throws {
        // Given
        var wish = try addOnWish()

        // When
        wish.title = "성수 블루보틀 아침 커피"
        let saved = try sut.updateWish(wish).get()

        // Then
        XCTAssertTrue(saved.nearbyAlertOn)
    }

    func test_GH126_TC14_완료후완료취소하면_토글은꺼진채로돌아온다() throws {
        // Given
        let wish = try addOnWish()
        _ = try sut.finishWish(wish: wish).get()

        // When
        let restored = try sut.cancelFinish(wishId: "w1").get()

        // Then
        XCTAssertFalse(restored.isSuccess)
        XCTAssertFalse(restored.nearbyAlertOn)
    }
}
