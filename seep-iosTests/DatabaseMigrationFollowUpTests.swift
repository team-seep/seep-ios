import XCTest

@testable import seep_ios_dev

/// 1회 이전 뒤 앱이 할 일 — `db_migration` 이벤트와 알림 재예약 (GH-79 R-22, R-23)
final class DatabaseMigrationFollowUpTests: XCTestCase {
    private var fixture: LegacyRealmFixture!
    private var database: AppDatabase!
    private var logManager: MockLogManager!
    private var notificationManager: MockNotificationManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        fixture = try LegacyRealmFixture()
        database = try AppDatabase.makeInMemory()
        logManager = MockLogManager()
        notificationManager = MockNotificationManager()
    }

    override func tearDown() {
        fixture.remove()
        database = nil
        super.tearDown()
    }

    private func makeFollowUp(importError: Error? = nil, importer: LegacyRealmImporter? = nil) -> DatabaseMigrationFollowUp {
        DatabaseMigrationFollowUp(dependency: .init(
            database: database,
            importError: importError,
            logManager: logManager,
            notificationManager: notificationManager,
            importer: importer ?? fixture.importer()
        ))
    }

    private var migrationEvents: [any LogEventType] {
        logManager.sentEvents.filter { $0.name == .dbMigration }
    }

    // MARK: GH-79 TC14

    func test_GH79_TC14_새id를받은알림이있는위시만_다시예약한다() throws {
        // Given: 둘째 위시의 알림 id 가 첫째와 겹친다
        let notification = SeepNotification(id: "noti-dup", type: .dayAgo, time: LegacyRealmFixture.day(1))
        try fixture.seed([
            Wish(id: "first", title: "첫째", endDate: LegacyRealmFixture.day(5), notifications: [notification]),
            Wish(id: "second", title: "둘째", endDate: LegacyRealmFixture.day(6), notifications: [notification])
        ])
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // When
        makeFollowUp().run()

        // Then
        XCTAssertEqual(notificationManager.reservedWishes.map(\.id), ["second"])
        XCTAssertNotEqual(notificationManager.reservedWishes.first?.notifications.first?.id, "noti-dup")
        XCTAssertTrue(notificationManager.cancelledWishes.isEmpty)
    }

    // MARK: GH-79 TC16

    func test_GH79_TC16_이전이끝나면_db_migration성공이벤트가한번만전송된다() throws {
        // Given
        try fixture.seed([Wish(id: "dup", title: "첫째"), Wish(id: "dup", title: "둘째")])
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // When
        makeFollowUp().run()
        makeFollowUp().run()

        // Then
        XCTAssertEqual(migrationEvents.count, 1)
        let parameters = try XCTUnwrap(migrationEvents.first?.parameters)
        XCTAssertEqual(parameters["screen"] as? String, "app_launch")
        XCTAssertEqual(parameters["result"] as? String, "success")
        XCTAssertEqual(parameters["wish_count"] as? Int, 2)
        XCTAssertEqual(parameters["reassigned_id_count"] as? Int, 1)
    }

    func test_GH79_TC16_이전에실패하면_db_migration실패이벤트를보낸다() {
        // Given
        let error = NSError(domain: "io.realm", code: 2)

        // When
        makeFollowUp(importError: error).run()

        // Then
        XCTAssertEqual(migrationEvents.count, 1)
        XCTAssertEqual(migrationEvents.first?.parameters["result"] as? String, "failure")
        XCTAssertEqual(migrationEvents.first?.parameters["error_type"] as? String, "io.realm:2")
    }

    func test_GH79_TC16_신규설치처럼이전할게없으면_이벤트를보내지않는다() throws {
        // Given
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // When
        makeFollowUp().run()

        // Then
        XCTAssertTrue(migrationEvents.isEmpty)
    }

    // MARK: GH-96 TC10

    func test_GH96_TC10_재이전으로돌아온위시는_로컬알림이다시예약된다() throws {
        // Given
        let notification = SeepNotification(id: "noti-lost", type: .dayAgo, time: LegacyRealmFixture.day(4))
        try fixture.seed([
            Wish(id: "lost", title: "빠진 위시", endDate: LegacyRealmFixture.day(5), notifications: [notification]),
            Wish(id: "kept", title: "남은 위시")
        ])
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)
        makeFollowUp().run()
        let lost = try XCTUnwrap(database.snapshot().wishes.first { $0.id == "lost" })
        try database.deleteRecord(lost)

        // When
        let restoredCount = makeFollowUp().reimportIfRequested(token: "t1")

        // Then
        XCTAssertEqual(restoredCount, 1)
        XCTAssertEqual(notificationManager.reservedWishes.map(\.id), ["lost"])
        XCTAssertEqual(notificationManager.reservedWishes.first?.notifications.map(\.id), ["noti-lost"])
    }

    // MARK: GH-96 TC12

    func test_GH96_TC12_재이전이끝나면_db_migration재이전이벤트가복구개수와함께한번전송된다() throws {
        // Given
        try fixture.seed([LegacyRealmFixture.fullWish(id: "lost")])
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)
        makeFollowUp().run()
        let lost = try XCTUnwrap(database.snapshot().wishes.first)
        try database.deleteRecord(lost)

        // When
        makeFollowUp().reimportIfRequested(token: "t1")
        makeFollowUp().reimportIfRequested(token: "t1")

        // Then
        let reimportEvents = migrationEvents.filter { $0.parameters["trigger"] as? String == "reimport" }
        XCTAssertEqual(reimportEvents.count, 1)
        let parameters = try XCTUnwrap(reimportEvents.first?.parameters)
        XCTAssertEqual(parameters["result"] as? String, "success")
        XCTAssertEqual(parameters["restored_wish_count"] as? Int, 1)
        XCTAssertEqual(parameters["restored_row_count"] as? Int, 6)
    }

    func test_GH96_TC12_재이전이실패하면_db_migration재이전실패이벤트를보내고0을돌려준다() throws {
        // Given
        try fixture.seed([Wish(id: "lost", title: "빠진 위시")])
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)
        let brokenImporter = try fixture.brokenImporter()

        // When
        let restoredCount = makeFollowUp(importer: brokenImporter).reimportIfRequested(token: "t1")

        // Then
        XCTAssertEqual(restoredCount, 0)
        let event = try XCTUnwrap(migrationEvents.last)
        XCTAssertEqual(event.parameters["result"] as? String, "failure")
        XCTAssertEqual(event.parameters["trigger"] as? String, "reimport")
    }

    // MARK: GH-96 TC21

    func test_GH96_TC21_1회이전성공이벤트에_원본Realm위시수가같이전송된다() throws {
        // Given
        try fixture.seed([Wish(id: "a", title: "첫째"), Wish(id: "b", title: "둘째")])
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // When
        makeFollowUp().run()

        // Then
        let parameters = try XCTUnwrap(migrationEvents.first?.parameters)
        XCTAssertEqual(parameters["trigger"] as? String, "launch")
        XCTAssertEqual(parameters["wish_count"] as? Int, 2)
        XCTAssertEqual(parameters["realm_wish_count"] as? Int, 2)
    }
}
