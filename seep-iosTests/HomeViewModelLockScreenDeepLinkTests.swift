import XCTest
import Combine

@testable import seep_ios_dev

/// 잠금화면 위젯 링크로 위시 상세 열기·클릭 로그 (GH-47). 링크 저장·소비는 #51 구조(Preference.reservedDeepLink)를 쓴다.
final class HomeViewModelLockScreenDeepLinkTests: XCTestCase {
    private var repository: MockWishRepository!
    private var preference: Preference!
    private var logManager: MockLogManager!
    private var sut: HomeViewModel!
    private var pushedWishIds: [String] = []
    private var presentedCategories: [seep_ios_dev.Category] = []
    private var cancellables = Set<AnyCancellable>()

    private let wish = Wish(id: "wish-1", emoji: "🌴", title: "제주도 한 달 살기", endDate: Date())

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
        repository.fetchWishResult = [wish]
        preference = Preference(name: "test.lockScreenDeepLink")
        preference.reservedDeepLink = ""
        logManager = MockLogManager()
        pushedWishIds = []
        presentedCategories = []
        sut = HomeViewModel(dependency: .init(
            wishRepository: repository,
            preference: preference,
            notificationManager: MockNotificationManager(),
            logManager: logManager
        ))
        sut.output.route
            .sink { [weak self] route in
                switch route {
                case .pushWishDetail(let reactor):
                    self?.pushedWishIds.append(reactor.initialState.wish.id)
                case .presentWrite(let category):
                    self?.presentedCategories.append(category)
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    private var widgetClickObjectIds: [String] {
        return logManager.sentEvents
            .filter { $0.name == .click && $0.screen == .lockScreenWidget }
            .compactMap { $0.parameters[ParameterName.objectId.rawValue] as? String }
    }

    // MARK: GH-47 TC10

    func test_GH47_TC10_냉시작에위시링크가저장돼있으면_첫로드때그위시상세를연다() {
        // Given
        preference.reservedDeepLink = "widget://wish?id=wish-1&source=lockscreen_dday"

        // When
        sut.input.firstLoad.send(())

        // Then
        XCTAssertEqual(pushedWishIds, ["wish-1"])
        XCTAssertEqual(repository.fetchWishCalledIds, ["wish-1"])
        XCTAssertEqual(preference.reservedDeepLink, "")
    }

    // MARK: GH-47 TC11

    func test_GH47_TC11_실행중에위시링크가오면_홈위에그위시상세를push한다() {
        // Given
        sut.input.firstLoad.send(())
        XCTAssertTrue(pushedWishIds.isEmpty)

        // When
        preference.reservedDeepLink = "widget://wish?id=wish-1&source=lockscreen_dday"
        sut.input.handleReservedDeepLink.send(())

        // Then
        XCTAssertEqual(pushedWishIds, ["wish-1"])
        XCTAssertTrue(presentedCategories.isEmpty)
    }

    // MARK: GH-47 TC12

    func test_GH47_TC12_위젯이가리키던위시가지워졌으면_상세를열지않고홈에머문다() {
        // Given
        repository.fetchWishResult = []
        preference.reservedDeepLink = "widget://wish?id=wish-1&source=lockscreen_dday"

        // When
        sut.input.firstLoad.send(())

        // Then
        XCTAssertTrue(pushedWishIds.isEmpty)
        XCTAssertTrue(presentedCategories.isEmpty)
        XCTAssertEqual(preference.reservedDeepLink, "")
    }

    // MARK: GH-47 TC15

    func test_GH47_TC15_DDay위젯링크로열리면_lockscreen_dday_widget클릭로그1건() {
        // Given
        preference.reservedDeepLink = "widget://wish?id=wish-1&source=lockscreen_dday"

        // When
        sut.input.firstLoad.send(())

        // Then
        XCTAssertEqual(widgetClickObjectIds, ["lockscreen_dday_widget"])
        let event = logManager.sentEvents.first { $0.screen == .lockScreenWidget }
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "widget")
    }

    func test_GH47_TC15_DDay위젯빈상태링크로열려도_lockscreen_dday_widget클릭로그1건() {
        // Given
        preference.reservedDeepLink = "widget://home?source=lockscreen_dday"

        // When
        sut.input.firstLoad.send(())

        // Then
        XCTAssertEqual(widgetClickObjectIds, ["lockscreen_dday_widget"])
        XCTAssertTrue(pushedWishIds.isEmpty)
    }

    // MARK: GH-47 TC16

    func test_GH47_TC16_남은싶위젯링크로열리면_lockscreen_remain_widget클릭로그1건() {
        // Given
        preference.reservedDeepLink = "widget://home?source=lockscreen_remain"

        // When
        sut.input.firstLoad.send(())

        // Then
        XCTAssertEqual(widgetClickObjectIds, ["lockscreen_remain_widget"])
        XCTAssertTrue(pushedWishIds.isEmpty)
    }

    func test_GH47_TC16_source없는바로적기링크는_위젯클릭로그를남기지않는다() {
        // Given
        preference.reservedDeepLink = "widget://add?category=category_want_to_do"

        // When
        sut.input.firstLoad.send(())

        // Then
        XCTAssertTrue(widgetClickObjectIds.isEmpty)
        XCTAssertEqual(presentedCategories, [.wantToDo])
    }
}
