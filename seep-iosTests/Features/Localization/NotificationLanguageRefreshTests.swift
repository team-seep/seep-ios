import XCTest

@testable import seep_ios_dev

/// 기기 언어를 바꾸면 D-day 알림을 다시 예약한다 (GH-100 R-14)
final class NotificationLanguageRefreshTests: XCTestCase {
    private var database: AppDatabase!
    private var repository: WishRepositoryImpl!
    private var notificationManager: MockNotificationManager!
    private var preference: Preference!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeInMemory()
        repository = WishRepositoryImpl(database: database)
        notificationManager = MockNotificationManager()
        preference = Preference(name: "NotificationLanguageRefreshTests")
    }

    override func tearDown() {
        database = nil
        repository = nil
        super.tearDown()
    }

    private func makeRefresh(language: String) -> NotificationLanguageRefresh {
        NotificationLanguageRefresh(dependency: .init(
            wishRepository: repository,
            notificationManager: notificationManager,
            preference: preference,
            currentLanguage: { language }
        ))
    }

    private func seedWishes() {
        let deadline = Date().addingTimeInterval(10 * 24 * 60 * 60)
        let notification = SeepNotification(id: "noti-1", type: .dayAgo, time: Date())
        _ = repository.addWish(Wish(id: "a", category: .wantToDo, title: "제주도", endDate: deadline, notifications: [notification]))
        _ = repository.addWish(Wish(id: "b", category: .wantToGo, title: "교토", endDate: deadline))
    }

    // MARK: GH-100 TC10

    func test_GH100_TC10_언어가바뀌면_못이룬위시의알림을다시예약하고_언어를저장한다() {
        // Given: 예전 버전이 한국어로 예약해 둔 상태(저장된 언어 없음)에서 기기 언어가 영어로 바뀌었다
        seedWishes()

        // When
        let count = makeRefresh(language: "en").run()

        // Then: 모든 못 이룬 위시를 같은 알림 id 로 다시 예약한다
        XCTAssertEqual(count, 2)
        XCTAssertEqual(Set(notificationManager.reservedWishes.map(\.id)), ["a", "b"])
        XCTAssertEqual(notificationManager.reservedWishes.first { $0.id == "a" }?.notifications.map(\.id), ["noti-1"])
        XCTAssertTrue(notificationManager.cancelledWishes.isEmpty)
        XCTAssertEqual(preference.notificationLanguage, "en")
    }

    // MARK: GH-100 TC11

    func test_GH100_TC11_언어가그대로면_다시예약하지않는다() {
        // Given: 처음 실행(저장된 언어 없음)이고 한국어 그대로다
        seedWishes()

        // When
        let first = makeRefresh(language: "ko").run()
        preference.notificationLanguage = "en"
        let second = makeRefresh(language: "en").run()

        // Then
        XCTAssertEqual(first, 0)
        XCTAssertEqual(second, 0)
        XCTAssertTrue(notificationManager.reservedWishes.isEmpty)
    }
}
