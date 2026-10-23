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

    private func makeFollowUp(importError: Error? = nil) -> DatabaseMigrationFollowUp {
        DatabaseMigrationFollowUp(dependency: .init(
            database: database,
            importError: importError,
            logManager: logManager,
            notificationManager: notificationManager
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
}
