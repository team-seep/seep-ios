import XCTest
import Combine

@testable import seep_ios_dev

/// 홈 가고 싶어요 탭의 지도 버튼 (GH-31 R-5).
final class HomePlaceMapTests: XCTestCase {
    private var mockLogManager: MockLogManager!
    private var sut: HomeViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockLogManager = MockLogManager()
        cancellables = []
        sut = HomeViewModel(dependency: .init(
            wishRepository: MockWishRepository(),
            preference: Preference(name: "test"),
            notificationManager: MockNotificationManager(),
            logManager: mockLogManager
        ))
        sut.input.firstLoad.send(())
    }

    override func tearDown() {
        mockLogManager = nil
        sut = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: GH-31 TC8

    func test_GH31_TC8_가고싶어요탭이아니면_지도버튼이보이지않는다() {
        // Given
        let header = sut.headerViewModel

        // When
        header.input.didTapCategory.send(.wantToDo)
        let wantToDo = header.output.isPlaceMapVisible.value
        header.input.didTapCategory.send(.wantToGet)
        let wantToGet = header.output.isPlaceMapVisible.value

        // Then
        XCTAssertFalse(wantToDo)
        XCTAssertFalse(wantToGet)
    }

    func test_GH31_TC8_가고싶어요탭이면_지도버튼이보인다() {
        // Given
        let header = sut.headerViewModel
        XCTAssertFalse(header.output.isPlaceMapVisible.value)

        // When
        header.input.didTapCategory.send(.wantToGo)

        // Then
        XCTAssertTrue(header.output.isPlaceMapVisible.value)
    }

    // MARK: GH-31 TC13

    func test_GH31_TC13_지도버튼을탭하면_place_map클릭로그가1건전송되고_지도화면으로이동한다() {
        // Given
        sut.headerViewModel.input.didTapCategory.send(.wantToGo)
        var isPlaceMapPushed = false
        sut.output.route.sink { route in
            if case .pushPlaceMap = route { isPlaceMapPushed = true }
        }.store(in: &cancellables)

        // When
        sut.headerViewModel.input.didTapPlaceMap.send(())

        // Then
        let placeMapEvents = mockLogManager.sentEvents
            .compactMap { $0 as? ClickEvent }
            .filter { ($0.extraParameters?[.objectId] as? LogObjectId) == .placeMap }
        XCTAssertEqual(placeMapEvents.count, 1)
        XCTAssertEqual(placeMapEvents.first?.screen, .home)
        XCTAssertEqual(placeMapEvents.first?.extraParameters?[.objectType] as? LogObjectType, .button)
        XCTAssertTrue(isPlaceMapPushed)
    }
}
