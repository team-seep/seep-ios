import XCTest
import Combine

@testable import seep_ios_dev

/// 위젯 딥링크 처리 (GH-50). 링크는 Preference.reservedDeepLink 한 곳에서 읽고, 처리하면 비운다.
final class HomeViewModelDeepLinkTests: XCTestCase {
    private var repository: MockWishRepository!
    private var preference: Preference!
    private var sut: HomeViewModel!
    private var presentedCategories: [seep_ios_dev.Category] = []
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
        preference = Preference(name: "test.deepLink")
        presentedCategories = []
        sut = HomeViewModel(dependency: .init(
            wishRepository: repository,
            preference: preference,
            notificationManager: MockNotificationManager(),
            logManager: MockLogManager()
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

    // MARK: GH-50 TC1

    func test_GH50_TC1_냉시작에저장된위젯링크가있으면_첫로드때그카테고리로작성화면을열고비운다() {
        // Given
        preference.reservedDeepLink = "widget://add?category=category_want_to_get"

        // When
        sut.input.firstLoad.send(())

        // Then
        XCTAssertEqual(presentedCategories, [.wantToGet])
        XCTAssertEqual(preference.reservedDeepLink, "")
    }

    // MARK: GH-50 TC2

    func test_GH50_TC2_실행중에링크가저장되고처리입력이오면_작성화면을열고비운다() {
        // Given
        sut.input.firstLoad.send(())
        XCTAssertTrue(presentedCategories.isEmpty)

        // When
        preference.reservedDeepLink = "widget://add?category=category_want_to_go"
        sut.input.handleReservedDeepLink.send(())

        // Then
        XCTAssertEqual(presentedCategories, [.wantToGo])
        XCTAssertEqual(preference.reservedDeepLink, "")
    }

    // MARK: GH-50 TC3

    func test_GH50_TC3_카테고리가틀리거나다른링크면_작성화면을열지않고비운다() {
        for link in ["widget://add?category=wrong", "widget://add", "widget://home"] {
            // Given
            presentedCategories = []
            preference.reservedDeepLink = link

            // When
            sut.input.handleReservedDeepLink.send(())

            // Then
            XCTAssertTrue(presentedCategories.isEmpty, link)
            XCTAssertEqual(preference.reservedDeepLink, "", link)
        }
    }

    // MARK: GH-50 TC4

    func test_GH50_TC4_링크로작성화면을한번연뒤_다시로드해도또열지않는다() {
        // Given
        preference.reservedDeepLink = "widget://add?category=category_want_to_do"
        sut.input.firstLoad.send(())
        XCTAssertEqual(presentedCategories, [.wantToDo])

        // When
        sut.input.firstLoad.send(())
        sut.input.handleReservedDeepLink.send(())

        // Then
        XCTAssertEqual(presentedCategories, [.wantToDo])
    }
}
