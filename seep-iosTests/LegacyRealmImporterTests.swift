// swiftlint:disable db_only_in_repository - 이전 테스트라 예전 Realm 파일을 직접 만든다 (R3 대상은 앱 코드)
import XCTest

import RealmSwift

@testable import seep_ios_dev

/// Realm → GRDB 1회 이전 (GH-79 R-17~R-19). 임시 폴더의 Realm 파일과 메모리 DB 로 돌린다.
final class LegacyRealmImporterTests: XCTestCase {
    private var fixture: LegacyRealmFixture!
    private var database: AppDatabase!

    override func setUpWithError() throws {
        try super.setUpWithError()
        fixture = try LegacyRealmFixture()
        database = try AppDatabase.makeInMemory()
    }

    override func tearDown() {
        fixture.remove()
        database = nil
        super.tearDown()
    }

    private var repository: WishRepositoryImpl {
        WishRepositoryImpl(database: database)
    }

    // MARK: GH-79 TC1

    func test_GH79_TC1_v7Realm위시를이전하면_모든필드가그대로보인다() throws {
        // Given
        let original = LegacyRealmFixture.fullWish(id: "wish-1")
        try fixture.seed([original])

        // When
        let report = try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // Then
        XCTAssertEqual(report?.wishCount, 1)
        let imported = try XCTUnwrap(repository.fetchWish(id: "wish-1"))
        let sameUpdatedAt = Date(timeIntervalSinceReferenceDate: 0)
        // GH-73: 이전은 "내가 정한 순서" 값을 카테고리별 최근 생성순(1부터)으로 새로 매긴다
        var expected = original
        expected.manualOrder = 1
        XCTAssertEqual(WishRecord(wish: imported, updatedAt: sameUpdatedAt), WishRecord(wish: expected, updatedAt: sameUpdatedAt))
    }

    // MARK: GH-79 TC2

    func test_GH79_TC2_단계저금알림이_순서와값그대로이전된다() throws {
        // Given
        let original = LegacyRealmFixture.fullWish(id: "wish-1")
        try fixture.seed([original])

        // When
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // Then
        let imported = try XCTUnwrap(repository.fetchWish(id: "wish-1"))
        XCTAssertEqual(imported.steps.map(\.id), ["step-a", "step-b"])
        XCTAssertEqual(imported.steps.map(\.isDone), [true, false])
        XCTAssertEqual(imported.savings.map(\.id), ["saving-new", "saving-old"])
        XCTAssertEqual(imported.savings.map(\.amount), [20_000, 10_000])
        XCTAssertEqual(imported.targetAmount, 300_000)
        XCTAssertEqual(imported.notifications.map(\.id), ["noti-1", "noti-2"])
        XCTAssertEqual(imported.notifications.map(\.type), [.dayAgo, .weekAgo])
        XCTAssertEqual(imported.notifications.map(\.time), original.notifications.map(\.time))
    }

    // MARK: GH-79 TC3

    func test_GH79_TC3_schema3미만의예전위시도_이전된다() throws {
        // Given: schemaVersion 2 의 "Wish" 객체 (빈 날짜 하나 포함)
        try fixture.seedSchema2(titles: ["예전 위시", "날짜 없는 예전 위시"], dates: [LegacyRealmFixture.day(10), nil])

        // When
        let report = try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // Then
        XCTAssertEqual(report?.wishCount, 2)
        let titles = Set(repository.fetchWishes(category: .wantToDo, sort: .deadlineOrder, isOnlyFinished: false).map(\.title))
        XCTAssertEqual(titles, ["예전 위시", "날짜 없는 예전 위시"])
    }

    // MARK: GH-79 TC4

    func test_GH79_TC4_이전을두번돌려도_위시가중복되지않는다() throws {
        // Given
        try fixture.seed([Wish(id: "wish-1", title: "위시"), Wish(id: "wish-2", title: "위시 2")])
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // When
        let secondReport = try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // Then
        XCTAssertNil(secondReport)
        XCTAssertEqual(try database.snapshot().wishes.count, 2)
    }

    // MARK: GH-79 TC5

    func test_GH79_TC5_이전도중실패하면_아무것도남지않고_다음실행에서다시이전한다() throws {
        // Given: 두 번째 위시를 넣다가 실패하도록 같은 id 의 줄을 미리 넣어 둔다
        try fixture.seed([
            Wish(id: "wish-1", title: "첫 위시", steps: [WishStep(id: "step-1", title: "단계", order: 0)]),
            Wish(id: "wish-2", title: "둘째 위시")
        ])
        let blocker = WishRecord(wish: Wish(id: "wish-2", title: "막는 줄"), updatedAt: Date())
        try database.insertRecord(blocker)

        // When
        XCTAssertThrowsError(try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true))

        // Then: 첫 위시·단계도 남지 않고 완료 표시도 없다
        let failed = try database.snapshot()
        XCTAssertEqual(failed.wishes.map(\.id), ["wish-2"])
        XCTAssertTrue(failed.steps.isEmpty)
        XCTAssertNil(failed.metadata[LegacyRealmImporter.MetadataKey.completedAt])

        // When: 다음 실행
        try database.deleteRecord(blocker)
        let report = try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // Then
        XCTAssertEqual(report?.wishCount, 2)
        XCTAssertEqual(Set(try database.snapshot().wishes.map(\.title)), ["첫 위시", "둘째 위시"])
    }

    // MARK: GH-79 TC6

    func test_GH79_TC6_Realm파일이없는신규설치는_빈DB로시작하고위시를추가할수있다() throws {
        // Given: Realm 파일 없음

        // When
        let report = try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)
        let added = repository.addWish(Wish(id: "new", title: "새 위시"))

        // Then
        XCTAssertNil(report)
        XCTAssertNotNil(try database.snapshot().metadata[LegacyRealmImporter.MetadataKey.completedAt])
        XCTAssertEqual(try added.get().title, "새 위시")
        XCTAssertEqual(repository.fetchWishes(category: .wantToDo, sort: .deadlineOrder, isOnlyFinished: false).map(\.id), ["new"])
    }

    func test_GH79_TC6_위젯이먼저열때Realm파일이없으면_완료로표시하지않는다() throws {
        // Given: 아주 예전 사용자는 앱이 실행돼야 Realm 이 App Group 으로 옮겨진다

        // When
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: false)

        // Then
        XCTAssertNil(try database.snapshot().metadata[LegacyRealmImporter.MetadataKey.completedAt])
    }

    // MARK: GH-79 TC17

    func test_GH79_TC17_id가겹치는위시와하위레코드도_빠짐없이각각이전된다() throws {
        // Given: Realm 은 _id 에 PK 제약이 없어 같은 id 가 여럿일 수 있다
        let notification = SeepNotification(id: "noti-dup", type: .dayAgo, time: LegacyRealmFixture.day(1))
        try fixture.seed([
            Wish(id: "dup", title: "첫째", endDate: LegacyRealmFixture.day(5), notifications: [notification],
                 steps: [WishStep(id: "step-dup", title: "단계 A", order: 0)]),
            Wish(id: "dup", title: "둘째", endDate: LegacyRealmFixture.day(6), notifications: [notification],
                 steps: [WishStep(id: "step-dup", title: "단계 B", order: 0)])
        ])

        // When
        let report = try XCTUnwrap(fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true))

        // Then
        let wishes = repository.fetchWishes(category: .wantToDo, sort: .deadlineOrder, isOnlyFinished: false)
        XCTAssertEqual(Set(wishes.map(\.title)), ["첫째", "둘째"])
        XCTAssertEqual(Set(wishes.map(\.id)).count, 2)
        XCTAssertEqual(Set(wishes.flatMap(\.steps).map(\.title)), ["단계 A", "단계 B"])
        XCTAssertEqual(report.reassignedIdCount, 3)
        let second = try XCTUnwrap(wishes.first { $0.title == "둘째" })
        XCTAssertEqual(report.rescheduleWishIds, [second.id])
        XCTAssertNotEqual(second.notifications.first?.id, "noti-dup")
    }

    // MARK: GH-79 TC18

    func test_GH79_TC18_빈id와모르는값이있어도_이전되고기본값으로보인다() throws {
        // Given
        try fixture.seed([Wish(id: "ignored", title: "", notifications: [SeepNotification(type: .dayAgo)])]) { dto in
            dto._id = ""
            dto.category = "category_unknown"
            dto.notifications.first?.type = "unknownType"
        }

        // When
        let report = try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // Then
        XCTAssertEqual(report?.wishCount, 1)
        let wish = try XCTUnwrap(repository.fetchWishes(category: .wantToDo, sort: .deadlineOrder, isOnlyFinished: false).first)
        XCTAssertFalse(wish.id.isEmpty)
        XCTAssertEqual(wish.category, .wantToDo)
        XCTAssertEqual(wish.notifications.map(\.type), [.targetDay])
    }
}

/// 임시 폴더에 예전 Realm 파일을 만든다. 이전 뒤 처리(`DatabaseMigrationFollowUpTests`)도 같이 쓴다
final class LegacyRealmFixture {
    let directory: URL
    let realmURL: URL
    static let importedAt = Date(timeIntervalSinceReferenceDate: 800_000_000)

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("legacy-realm-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        realmURL = directory.appendingPathComponent("legacy.realm")
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }

    func importer() -> LegacyRealmImporter {
        LegacyRealmImporter(realmFileURL: realmURL, now: { Self.importedAt })
    }

    /// 읽을 수 없는(손상된) Realm 파일을 보는 이전기. 한 번도 열지 않은 파일이라 Realm 이 오류를 던진다 (GH-96 TC-9)
    func brokenImporter() throws -> LegacyRealmImporter {
        let brokenURL = directory.appendingPathComponent("broken.realm")
        try Data("broken".utf8).write(to: brokenURL)
        return LegacyRealmImporter(realmFileURL: brokenURL, now: { Self.importedAt })
    }

    /// schemaVersion 7 Realm 에 위시를 넣는다. `modify`로 저장 전 DTO 를 망가뜨릴 수 있다
    func seed(_ wishes: [Wish], modify: (WishDTO) -> Void = { _ in }) throws {
        try autoreleasepool {
            let realm = try Realm(configuration: LegacyRealmConfiguration.make(fileURL: realmURL))
            try realm.write {
                for wish in wishes {
                    let dto = WishDTO(wish: wish)
                    modify(dto)
                    realm.add(dto)
                }
            }
        }
    }

    /// schemaVersion 2 시절의 "Wish" 객체로 Realm 파일을 만든다
    func seedSchema2(titles: [String], dates: [Date?]) throws {
        try autoreleasepool {
            var configuration = Realm.Configuration(fileURL: realmURL, objectTypes: [SchemaV2Wish.self])
            configuration.schemaVersion = 2
            let realm = try Realm(configuration: configuration)
            try realm.write {
                for (title, date) in zip(titles, dates) {
                    let wish = SchemaV2Wish()
                    wish.title = title
                    wish.date = date
                    wish.category = Category.wantToDo.rawValue
                    realm.add(wish)
                }
            }
        }
    }

    static func day(_ day: Int) -> Date {
        Date(timeIntervalSinceReferenceDate: 790_000_000 + Double(day) * 86_400)
    }

    /// 모든 필드를 채운 위시. 날짜는 초 단위로 둔다
    static func fullWish(id: String) -> Wish {
        Wish(
            id: id,
            emoji: "🏄",
            category: .wantToGo,
            title: "양양에서 서핑 배우기",
            endDate: day(30),
            finishDate: day(20),
            notifications: [
                SeepNotification(id: "noti-1", type: .dayAgo, time: day(29)),
                SeepNotification(id: "noti-2", type: .weekAgo, time: day(23))
            ],
            steps: [
                WishStep(id: "step-a", title: "강습 예약", isDone: true, order: 0),
                WishStep(id: "step-b", title: "숙소 잡기", order: 1)
            ],
            targetAmount: 300_000,
            savings: [
                WishSaving(id: "saving-old", amount: 10_000, createdAt: day(2)),
                WishSaving(id: "saving-new", amount: 20_000, createdAt: day(3))
            ],
            memo: "오전반이 좋대요",
            hashtag: "trip",
            isSuccess: true,
            finishNote: "파도 탔다",
            pinnedAt: day(4),
            link: "https://example.com/board",
            lastCheckedAt: day(5),
            place: WishPlace(name: "양양 서피비치", address: "강원 양양군", latitude: 38.03, longitude: 128.71),
            photoFileName: "photo.jpg",
            createdAt: day(1)
        )
    }
}

/// schemaVersion 3 이전의 위시 객체 (Realm 클래스 이름 "Wish")
final class SchemaV2Wish: Object {
    override class func _realmObjectName() -> String { "Wish" }

    @objc dynamic var _id = ObjectId.generate()
    @objc dynamic var emoji = ""
    @objc dynamic var category = ""
    @objc dynamic var title = ""
    @objc dynamic var date: Date?
    @objc dynamic var finishDate: Date?
    @objc dynamic var isPushEnable = false
    @objc dynamic var memo = ""
    @objc dynamic var hashtag = ""
    @objc dynamic var isSuccess = false
    @objc dynamic var createdAt = Date()
}
