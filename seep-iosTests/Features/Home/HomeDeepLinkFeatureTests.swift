import XCTest

@testable import seep_ios_dev

/// 위젯·컨트롤 링크로 싶 탭에서 작성·상세를 여는 동작 (GH-47, GH-49, GH-50).
/// 링크 처리는 홈 ViewModel 에서 `AppRouter`로 옮겨 갔다(GH-64 A-4). 기존 HomeViewModel*DeepLinkTests·WriteIntentTests 이전
final class HomeDeepLinkFeatureTests: ViewModelTestCase {
    private var repository: MockWishRepository!
    private var preference: Preference!
    private var router: AppRouter!

    private let wish = Wish(id: "wish-1", emoji: "🌴", title: "제주도 한 달 살기", endDate: Date())

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
        repository.fetchWishResult = [wish]
        preference = Preference(name: "test.lockScreenDeepLink")
        preference.reservedDeepLink = ""
        router = AppRouter(dependency: .init(wishRepository: repository, deepLinkStore: preference))
    }

    override func tearDown() {
        router = nil
        preference = nil
        repository = nil
        super.tearDown()
    }

    /// `RootView`와 같은 규칙으로, 화면을 옮긴 링크만 클릭 로그를 남긴다
    private func log(_ deepLink: WidgetDeepLink?) {
        guard let deepLink else { return }
        if let event = deepLink.source?.clickEvent {
            logManager.sendEvent(event: event)
        }
        if let event = deepLink.writeIntentClickEvent {
            logManager.sendEvent(event: event)
        }
    }

    /// 냉시작: 저장된 링크가 있는 채로 메인이 뜬다
    private func coldStart() {
        log(router.mainDidAppear())
    }

    /// 실행 중: 링크가 저장되고 처리 입력이 온다
    private func handleReserved() {
        log(router.consumeReservedDeepLink())
    }

    private var pushedWishIds: [String] {
        (router.wishPath + router.finishedPath).compactMap {
            if case .wishDetail(let id, _) = $0 { return id }
            return nil
        }
    }

    private var widgetClickObjectIds: [String] {
        logManager.sentEvents
            .filter { $0.name == .click && $0.screen == .lockScreenWidget }
            .compactMap { $0.parameters[ParameterName.objectId.rawValue] as? String }
    }

    private var writeControlClicks: [any LogEventType] {
        logManager.sentEvents.filter { $0.screen == .writeControl }
    }

    // MARK: GH-47 TC10

    func test_GH47_TC10_냉시작에위시링크가저장돼있으면_첫로드때그위시상세를연다() {
        // Given
        preference.reservedDeepLink = "widget://wish?id=wish-1&source=lockscreen_dday"

        // When
        coldStart()

        // Then
        XCTAssertEqual(pushedWishIds, ["wish-1"])
        XCTAssertEqual(repository.fetchWishCalledIds, ["wish-1"])
        XCTAssertEqual(preference.reservedDeepLink, "")
    }

    // MARK: GH-47 TC11

    func test_GH47_TC11_실행중에위시링크가오면_홈위에그위시상세를push한다() {
        // Given
        coldStart()
        XCTAssertTrue(pushedWishIds.isEmpty)

        // When
        preference.reservedDeepLink = "widget://wish?id=wish-1&source=lockscreen_dday"
        handleReserved()

        // Then
        XCTAssertEqual(pushedWishIds, ["wish-1"])
        XCTAssertNil(router.writeCategory)
    }

    // MARK: GH-47 TC12

    func test_GH47_TC12_위젯이가리키던위시가지워졌으면_상세를열지않고홈에머문다() {
        // Given
        repository.fetchWishResult = []
        preference.reservedDeepLink = "widget://wish?id=wish-1&source=lockscreen_dday"

        // When
        coldStart()

        // Then
        XCTAssertTrue(pushedWishIds.isEmpty)
        XCTAssertNil(router.writeCategory)
        XCTAssertEqual(preference.reservedDeepLink, "")
    }

    // MARK: GH-47 TC15

    func test_GH47_TC15_DDay위젯링크로열리면_lockscreen_dday_widget클릭로그1건() {
        // Given
        preference.reservedDeepLink = "widget://wish?id=wish-1&source=lockscreen_dday"

        // When
        coldStart()

        // Then
        XCTAssertEqual(widgetClickObjectIds, ["lockscreen_dday_widget"])
        let event = logManager.sentEvents.first { $0.screen == .lockScreenWidget }
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "widget")
    }

    func test_GH47_TC15_DDay위젯빈상태링크로열려도_lockscreen_dday_widget클릭로그1건() {
        // Given
        preference.reservedDeepLink = "widget://home?source=lockscreen_dday"

        // When
        coldStart()

        // Then
        XCTAssertEqual(widgetClickObjectIds, ["lockscreen_dday_widget"])
        XCTAssertTrue(pushedWishIds.isEmpty)
    }

    // MARK: GH-47 TC16

    func test_GH47_TC16_남은싶위젯링크로열리면_lockscreen_remain_widget클릭로그1건() {
        // Given
        preference.reservedDeepLink = "widget://home?source=lockscreen_remain"

        // When
        coldStart()

        // Then
        XCTAssertEqual(widgetClickObjectIds, ["lockscreen_remain_widget"])
        XCTAssertTrue(pushedWishIds.isEmpty)
    }

    func test_GH47_TC16_source없는바로적기링크는_위젯클릭로그를남기지않는다() {
        // Given
        preference.reservedDeepLink = "widget://add?category=category_want_to_do"

        // When
        coldStart()

        // Then
        XCTAssertTrue(widgetClickObjectIds.isEmpty)
        XCTAssertEqual(router.writeCategory, .wantToDo)
    }

    // MARK: GH-50 TC1

    func test_GH50_TC1_냉시작에저장된위젯링크가있으면_첫로드때그카테고리로작성화면을열고비운다() {
        // Given
        preference.reservedDeepLink = "widget://add?category=category_want_to_get"

        // When
        coldStart()

        // Then
        XCTAssertEqual(router.writeCategory, .wantToGet)
        XCTAssertEqual(preference.reservedDeepLink, "")
    }

    // MARK: GH-50 TC2

    func test_GH50_TC2_실행중에링크가저장되고처리입력이오면_작성화면을열고비운다() {
        // Given
        coldStart()
        XCTAssertNil(router.writeCategory)

        // When
        preference.reservedDeepLink = "widget://add?category=category_want_to_go"
        handleReserved()

        // Then
        XCTAssertEqual(router.writeCategory, .wantToGo)
        XCTAssertEqual(preference.reservedDeepLink, "")
    }

    // MARK: GH-50 TC3

    func test_GH50_TC3_카테고리가틀리거나다른링크면_작성화면을열지않고비운다() {
        coldStart()
        for link in ["widget://add?category=wrong", "widget://add", "widget://home"] {
            // Given
            router.writeCategory = nil
            preference.reservedDeepLink = link

            // When
            handleReserved()

            // Then
            XCTAssertNil(router.writeCategory, link)
            XCTAssertEqual(preference.reservedDeepLink, "", link)
        }
    }

    // MARK: GH-50 TC4

    func test_GH50_TC4_링크로작성화면을한번연뒤_다시로드해도또열지않는다() {
        // Given
        preference.reservedDeepLink = "widget://add?category=category_want_to_do"
        coldStart()
        XCTAssertEqual(router.writeCategory, .wantToDo)
        router.writeCategory = nil

        // When
        coldStart()
        handleReserved()

        // Then
        XCTAssertNil(router.writeCategory)
    }

    // MARK: GH-49 TC3

    func test_GH49_TC3_컨트롤링크가예약돼있으면_홈이뜰때가고싶어요작성화면을한번열고비운다() {
        // Given
        preference.reservedDeepLink = "widget://add?category=category_want_to_go&source=control"

        // When
        coldStart()

        // Then
        XCTAssertEqual(router.writeCategory, .wantToGo)
        XCTAssertEqual(preference.reservedDeepLink, "")
    }

    func test_GH49_TC3_앱이떠있을때컨트롤링크가오면_바로작성화면을연다() {
        // Given
        coldStart()

        // When
        log(router.openFromIntent(.add(.wantToGet, source: .shortcut)))

        // Then
        XCTAssertEqual(router.writeCategory, .wantToGet)
        XCTAssertEqual(preference.reservedDeepLink, "")
    }

    // MARK: GH-49 TC4

    func test_GH49_TC4_source없는바로적기위젯링크는_작성화면을열고클릭로그는남기지않는다() {
        // Given
        preference.reservedDeepLink = "widget://add?category=category_want_to_do"

        // When
        coldStart()

        // Then
        XCTAssertEqual(router.writeCategory, .wantToDo)
        XCTAssertTrue(writeControlClicks.isEmpty)
    }

    // MARK: GH-49 TC12

    func test_GH49_TC12_컨트롤로작성화면에들어가면_control_write클릭로그1건() {
        // Given
        preference.reservedDeepLink = "widget://add?category=category_want_to_get&source=control"

        // When
        coldStart()

        // Then
        XCTAssertEqual(writeControlClicks.count, 1)
        let parameters = writeControlClicks.first?.parameters
        XCTAssertEqual(parameters?["screen"] as? String, "write_control")
        XCTAssertEqual(parameters?["object_type"] as? String, "widget")
        XCTAssertEqual(parameters?["object_id"] as? String, "control_write")
        XCTAssertEqual(parameters?["category"] as? String, "category_want_to_get")
    }

    // MARK: GH-49 TC13

    func test_GH49_TC13_단축어로작성화면에들어가면_shortcut_write클릭로그1건() {
        // Given
        coldStart()

        // When
        log(router.openFromIntent(.add(.wantToDo, source: .shortcut)))

        // Then
        XCTAssertEqual(writeControlClicks.count, 1)
        let parameters = writeControlClicks.first?.parameters
        XCTAssertEqual(parameters?["object_id"] as? String, "shortcut_write")
        XCTAssertEqual(parameters?["category"] as? String, "category_want_to_do")
    }
}
