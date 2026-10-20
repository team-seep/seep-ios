import XCTest
import Combine

@testable import seep_ios_dev

/// 싶 적기 컨트롤·단축어 링크로 홈이 작성 화면을 연다 (GH-49)
final class HomeViewModelWriteIntentTests: XCTestCase {
    private var preference: Preference!
    private var logManager: MockLogManager!
    private var sut: HomeViewModel!
    private var presentedCategories: [seep_ios_dev.Category] = []
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        preference = Preference(name: "test.writeIntentDeepLink")
        logManager = MockLogManager()
        presentedCategories = []
        sut = HomeViewModel(dependency: .init(
            wishRepository: MockWishRepository(),
            preference: preference,
            notificationManager: MockNotificationManager(),
            logManager: logManager
        ))
        sut.output.route
            .sink { [weak self] route in
                if case .presentWrite(let category) = route {
                    self?.presentedCategories.append(category)
                }
            }
            .store(in: &cancellables)
    }

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    private var writeControlClicks: [ClickEvent] {
        return logManager.sentEvents
            .compactMap { $0 as? ClickEvent }
            .filter { $0.screen == .writeControl }
    }

    // MARK: GH-49 TC3

    func test_GH49_TC3_컨트롤링크가예약돼있으면_홈이뜰때가고싶어요작성화면을한번열고비운다() {
        // Given
        preference.reservedDeepLink = "widget://add?category=category_want_to_go&source=control"

        // When
        sut.input.firstLoad.send(())

        // Then
        XCTAssertEqual(presentedCategories, [.wantToGo])
        XCTAssertEqual(preference.reservedDeepLink, "")
    }

    func test_GH49_TC3_앱이떠있을때컨트롤링크가오면_바로작성화면을연다() {
        // Given
        sut.input.firstLoad.send(())

        // When
        preference.reservedDeepLink = "widget://add?category=category_want_to_get&source=shortcut"
        sut.input.handleReservedDeepLink.send(())

        // Then
        XCTAssertEqual(presentedCategories, [.wantToGet])
        XCTAssertEqual(preference.reservedDeepLink, "")
    }

    // MARK: GH-49 TC4

    func test_GH49_TC4_source없는바로적기위젯링크는_작성화면을열고클릭로그는남기지않는다() {
        // Given
        preference.reservedDeepLink = "widget://add?category=category_want_to_do"

        // When
        sut.input.firstLoad.send(())

        // Then
        XCTAssertEqual(presentedCategories, [.wantToDo])
        XCTAssertTrue(writeControlClicks.isEmpty)
    }

    // MARK: GH-49 TC12

    func test_GH49_TC12_컨트롤로작성화면에들어가면_control_write클릭로그1건() {
        // Given
        preference.reservedDeepLink = "widget://add?category=category_want_to_get&source=control"

        // When
        sut.input.firstLoad.send(())

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
        sut.input.firstLoad.send(())

        // When
        preference.reservedDeepLink = "widget://add?category=category_want_to_do&source=shortcut"
        sut.input.handleReservedDeepLink.send(())

        // Then
        XCTAssertEqual(writeControlClicks.count, 1)
        let parameters = writeControlClicks.first?.parameters
        XCTAssertEqual(parameters?["object_id"] as? String, "shortcut_write")
        XCTAssertEqual(parameters?["category"] as? String, "category_want_to_do")
    }
}
