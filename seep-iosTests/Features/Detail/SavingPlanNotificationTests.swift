import XCTest
import UserNotifications

@testable import seep_ios

/// 적금 계획 넣는 날 알림 예약·취소(GH-121 R-6)와 알림을 눌러 상세 열기(TC-10·TC-13)
final class SavingPlanNotificationTests: ViewModelTestCase {
    private var scheduler: MockLocalNotificationScheduling!
    private var manager: NotificationManager!

    override func setUp() {
        super.setUp()
        scheduler = MockLocalNotificationScheduling()
        manager = NotificationManager(scheduler: scheduler)
    }

    override func tearDown() {
        scheduler = nil
        manager = nil
        super.tearDown()
    }

    private var fridayPlan: SavingPlan {
        SavingPlan(cycle: .weekly, day: 6, amount: 30_000)!
    }

    private func makeWish(
        category: seep_ios.Category = .wantToGet,
        targetAmount: Int = 359_000,
        saved: Int = 150_000,
        isSuccess: Bool = false,
        plan: SavingPlan? = nil,
        notifications: [SeepNotification] = []
    ) -> Wish {
        Wish(
            id: "wish-1",
            emoji: "🎧",
            category: category,
            title: "에어팟 프로 3",
            endDate: notifications.isEmpty ? nil : Date().addingTimeInterval(86_400 * 30),
            notifications: notifications,
            targetAmount: targetAmount,
            savings: saved > 0 ? [WishSaving(id: "s-1", amount: saved)] : [],
            isSuccess: isSuccess,
            savingPlan: plan ?? fridayPlan
        )
    }

    private func trigger(_ request: UNNotificationRequest?) -> UNCalendarNotificationTrigger? {
        request?.trigger as? UNCalendarNotificationTrigger
    }

    // MARK: GH-121 TC6

    func test_GH121_TC6_계획이있는위시를예약하면_금요일11시반복알림1건이예약된다() throws {
        // Given
        let wish = makeWish()

        // When
        manager.reserveNotifications(wish: wish)

        // Then
        let requests = scheduler.savingPlanRequests(wishId: "wish-1")
        XCTAssertEqual(requests.count, 1)
        let trigger = try XCTUnwrap(trigger(requests.first))
        XCTAssertTrue(trigger.repeats)
        XCTAssertEqual(trigger.dateComponents.weekday, 6)
        XCTAssertEqual(trigger.dateComponents.hour, 11)
        XCTAssertEqual(trigger.dateComponents.minute, 0)
        XCTAssertEqual(requests.first?.content.body, "오늘은 🎧 에어팟 프로 3에 30,000원 넣는 날이에요")
    }

    func test_GH121_TC6_완료_삭제로알림을지우면_계획알림도지워진다() {
        // Given
        let wish = makeWish(notifications: [SeepNotification(type: .targetDay, time: Date())])
        manager.reserveNotifications(wish: wish)
        XCTAssertEqual(scheduler.pending.count, 2, "D-day 알림 1 + 계획 알림 1")

        // When: 완료·삭제는 모두 cancelNotifications 를 부른다
        manager.cancelNotifications(wish: wish)

        // Then
        XCTAssertTrue(scheduler.pending.isEmpty)
    }

    func test_GH121_TC6_계획을지우거나_목표를다모으거나_목표금액이0이거나_이룬위시면_계획알림이지워진다() {
        let cases: [(String, Wish)] = [
            ("계획 지우기", { var wish = makeWish(); wish.savingPlan = nil; return wish }()),
            ("목표 달성", makeWish(saved: 359_000)),
            ("목표 금액 0", makeWish(targetAmount: 0)),
            ("카테고리 바꿈", makeWish(category: .wantToDo)),
            ("이룸", makeWish(isSuccess: true))
        ]
        for (name, wish) in cases {
            // Given
            manager.updateSavingPlanNotification(wish: makeWish())
            XCTAssertEqual(scheduler.savingPlanRequests(wishId: "wish-1").count, 1, name)

            // When: 수정 저장·동기화 받기·완료 취소는 reserveNotifications, 상세 기록·계획 저장은 updateSavingPlanNotification
            manager.reserveNotifications(wish: wish)

            // Then
            XCTAssertTrue(scheduler.savingPlanRequests(wishId: "wish-1").isEmpty, name)
        }
    }

    func test_GH121_TC6_주기를바꾸면_예전알림이남지않는다() throws {
        // Given: 매달 31일(짧은 달 알림 포함)
        manager.updateSavingPlanNotification(wish: makeWish(plan: SavingPlan(cycle: .monthly, day: 31, amount: 10_000)))
        XCTAssertEqual(scheduler.savingPlanRequests(wishId: "wish-1").count, 6)

        // When
        manager.updateSavingPlanNotification(wish: makeWish())

        // Then
        let requests = scheduler.savingPlanRequests(wishId: "wish-1")
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(trigger(requests.first)?.dateComponents.weekday, 6)
    }

    // MARK: GH-121 TC14

    func test_GH121_TC14_매달31일이면_31일반복과_짧은달마지막날반복이예약된다() throws {
        // Given
        let plan = try XCTUnwrap(SavingPlan(cycle: .monthly, day: 31, amount: 10_000))

        // When
        manager.reserveNotifications(wish: makeWish(plan: plan))

        // Then
        let components = scheduler.savingPlanRequests(wishId: "wish-1").compactMap { trigger($0)?.dateComponents }
        let monthly = components.filter { $0.month == nil }
        let shortMonths = components.filter { $0.month != nil }.sorted { ($0.month ?? 0) < ($1.month ?? 0) }
        XCTAssertEqual(monthly.map(\.day), [31])
        XCTAssertEqual(shortMonths.map(\.month), [2, 4, 6, 9, 11])
        XCTAssertEqual(shortMonths.map(\.day), [28, 30, 30, 30, 30])
        XCTAssertTrue(components.allSatisfy { $0.hour == 11 })
    }

    func test_GH121_TC14_매달15일이면_날짜반복1건만예약된다() throws {
        // Given
        let plan = try XCTUnwrap(SavingPlan(cycle: .monthly, day: 15, amount: 10_000))

        // When
        manager.reserveNotifications(wish: makeWish(plan: plan))

        // Then
        let requests = scheduler.savingPlanRequests(wishId: "wish-1")
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(trigger(requests.first)?.dateComponents.day, 15)
        XCTAssertNil(trigger(requests.first)?.dateComponents.month)
        XCTAssertEqual(trigger(requests.first)?.repeats, true)
    }

    // MARK: GH-121 TC15

    func test_GH121_TC15_계획이남은이룬위시를완료취소하면_넣는날알림이다시예약된다() {
        // Given: 이룬 위시는 알림이 없다
        let finished = makeWish(isSuccess: true)
        manager.reserveNotifications(wish: finished)
        XCTAssertTrue(scheduler.savingPlanRequests(wishId: "wish-1").isEmpty)
        let repository = MockWishRepository()
        repository.fetchWishResult = [finished]
        let notifications = MockNotificationManager()
        let detail = WishDetailViewModel(
            config: .init(wishId: "wish-1", mode: .fromFinish),
            dependency: .init(wishRepository: repository, notificationManager: notifications, logManager: logManager)
        )

        // When
        detail.send(.confirmCancelFinish)

        // Then: 상세가 되살린 위시(계획 포함)로 다시 예약하고, 그 위시면 계획 알림이 들어간다
        let restored = notifications.reservedWishes
        XCTAssertEqual(restored.map(\.savingPlan), [fridayPlan])
        restored.forEach(manager.reserveNotifications(wish:))
        XCTAssertEqual(scheduler.savingPlanRequests(wishId: "wish-1").count, 1)
    }

    // MARK: GH-121 TC10

    @MainActor
    func test_GH121_TC10_넣는날알림을누르면_그위시상세가열린다() throws {
        // Given: 실행 중, 알림에 담긴 링크
        let (router, request) = try makeRouterAndRequest()
        router.mainDidAppear()

        // When
        let opened = NotificationDeepLinkOpener(router: router, logManager: logManager).open(userInfo: request.content.userInfo)

        // Then
        XCTAssertEqual(opened, .wish(id: "wish-1", source: .savingPlanNotification))
        XCTAssertEqual(router.selectedTab, .wish)
        XCTAssertEqual(router.wishPath, [.wishDetail(id: "wish-1", isFinished: false)])
    }

    @MainActor
    func test_GH121_TC10_다른화면이쌓여있어도_비우고그위시상세를연다() throws {
        // Given: 다른 위시 상세를 보다가 앱을 내렸다
        let (router, request) = try makeRouterAndRequest()
        router.mainDidAppear()
        router.wishPath = [.wishDetail(id: "other", isFinished: false)]
        router.settingsPath = [.license]

        // When
        let opened = NotificationDeepLinkOpener(router: router, logManager: logManager).open(userInfo: request.content.userInfo)

        // Then
        XCTAssertEqual(opened, .wish(id: "wish-1", source: .savingPlanNotification))
        XCTAssertEqual(router.wishPath, [.wishDetail(id: "wish-1", isFinished: false)])
        XCTAssertTrue(router.settingsPath.isEmpty)
        XCTAssertEqual(clickEvents(objectId: .savingPlanNotification).count, 1)
    }

    @MainActor
    func test_GH121_TC10_시트가떠있으면_입력을지키려고링크를버린다() throws {
        // Given
        let (router, request) = try makeRouterAndRequest()
        router.mainDidAppear()
        router.wishPath = [.wishDetail(id: "other", isFinished: false)]
        router.modalDidAppear()

        // When
        let opened = NotificationDeepLinkOpener(router: router, logManager: logManager).open(userInfo: request.content.userInfo)

        // Then
        XCTAssertNil(opened)
        XCTAssertEqual(router.wishPath, [.wishDetail(id: "other", isFinished: false)])
        XCTAssertTrue(logManager.sentEvents.isEmpty)
    }

    @MainActor
    func test_GH121_TC10_냉시작에알림을누르면_메인이뜬뒤그위시상세가열린다() throws {
        // Given: 메인이 아직 없다
        let (router, request) = try makeRouterAndRequest()

        // When
        let opened = NotificationDeepLinkOpener(router: router, logManager: logManager).open(userInfo: request.content.userInfo)
        let afterMain = router.mainDidAppear()

        // Then
        XCTAssertNil(opened)
        XCTAssertEqual(afterMain, .wish(id: "wish-1", source: .savingPlanNotification))
        XCTAssertEqual(router.wishPath, [.wishDetail(id: "wish-1", isFinished: false)])
    }

    @MainActor
    func test_GH121_TC10_링크가없는알림은_화면을옮기지않는다() throws {
        // Given: D-day 알림
        let (router, _) = try makeRouterAndRequest()
        router.mainDidAppear()

        // When
        let opened = NotificationDeepLinkOpener(router: router, logManager: logManager).open(userInfo: [:])

        // Then
        XCTAssertNil(opened)
        XCTAssertTrue(router.wishPath.isEmpty)
        XCTAssertTrue(logManager.sentEvents.isEmpty)
    }

    // MARK: GH-121 TC13

    @MainActor
    func test_GH121_TC13_알림을눌러상세에들어가면_saving_plan_notification클릭로그1건() throws {
        // Given
        let (router, request) = try makeRouterAndRequest()
        router.mainDidAppear()

        // When
        NotificationDeepLinkOpener(router: router, logManager: logManager).open(userInfo: request.content.userInfo)

        // Then
        let events = clickEvents(objectId: .savingPlanNotification)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        XCTAssertEqual(events.first?.extraParameters?[.objectType] as? LogObjectType, .notification)
    }

    func test_GH121_TC13_냉시작으로열린알림링크도_같은클릭로그를고른다() {
        // Given / When: RootView 는 메인이 뜰 때 연 링크의 source.clickEvent 를 보낸다
        let event = WidgetDeepLink.Source.savingPlanNotification.clickEvent

        // Then
        XCTAssertEqual(event?.screen, .wishDetail)
        XCTAssertEqual(event?.extraParameters?[.objectId] as? LogObjectId, .savingPlanNotification)
        XCTAssertEqual(event?.extraParameters?[.objectType] as? LogObjectType, .notification)
    }

    @MainActor
    private func makeRouterAndRequest() throws -> (AppRouter, UNNotificationRequest) {
        let wish = makeWish()
        let repository = MockWishRepository()
        repository.fetchWishResult = [wish]
        let preference = Preference(name: "test-gh121-\(UUID().uuidString)")
        preference.reservedDeepLink = ""
        let router = AppRouter(dependency: .init(wishRepository: repository, deepLinkStore: preference))
        let request = try XCTUnwrap(SavingPlanNotification.requests(wish: wish).first)
        return (router, request)
    }
}
