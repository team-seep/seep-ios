import XCTest

@testable import seep_ios

/// 상세 "장소" 섹션 (GH-31 R-1·R-2·R-4, GH-59 R-6).
/// 작성 화면의 장소 칸은 `WishPlaceViewModelTests`(작성 폼) 쪽에 남는다
final class DetailPlaceFeatureTests: ViewModelTestCase {
    private var mockRepository: MockWishRepository!

    private let place = WishPlace(name: "성산일출봉", address: "제주 서귀포시 성산읍 성산리 1", latitude: 33.458, longitude: 126.942)

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
    }

    override func tearDown() {
        mockRepository = nil
        super.tearDown()
    }

    private func makeWish(category: seep_ios.Category, place: WishPlace? = nil) -> Wish {
        Wish(id: "wish-1", emoji: "🌅", category: category, title: "성산일출봉에서 새해 일출 보기", place: place)
    }

    private func makeViewModel(wish: Wish) -> DetailPlaceViewModel {
        DetailPlaceViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: mockRepository, logManager: logManager)
        )
    }

    // MARK: GH-31 TC1

    func test_GH31_TC1_가고싶어요위시상세면_장소섹션이보인다() {
        // Given
        let wish = makeWish(category: .wantToGo)

        // When
        let sections = DetailSectionBuilder.sections(for: wish)

        // Then
        XCTAssertTrue(sections.contains(.place))
        XCTAssertNil(makeViewModel(wish: wish).state.place)
    }

    func test_GH31_TC1_하고싶어요_갖고싶어요위시상세면_장소섹션이보이지않는다() {
        // Given / When
        let visibilities = [seep_ios.Category.wantToDo, .wantToGet].map {
            DetailSectionBuilder.sections(for: makeWish(category: $0)).contains(.place)
        }

        // Then
        XCTAssertEqual(visibilities, [false, false])
    }

    // MARK: GH-31 TC2

    func test_GH31_TC2_검색시트에서후보를고르면_Repository에장소가저장되고_섹션이장소로바뀐다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(category: .wantToGo))
        var updatedPlaces: [WishPlace?] = []
        viewModel.onUpdate = { updatedPlaces.append($0) }
        viewModel.send(.tapPlace)
        XCTAssertEqual(viewModel.route, .placeSearch)

        // When — 검색 시트(`PlaceSearchSheet`)가 고른 장소를 넘긴다
        viewModel.send(.selectPlace(place))

        // Then
        XCTAssertEqual(mockRepository.updatePlaceCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(mockRepository.updatePlaceCalls.first?.place, place)
        XCTAssertEqual(viewModel.state.place, place)
        XCTAssertEqual(updatedPlaces, [place])
    }

    func test_GH31_TC2_저장에실패하면_에러알럿을띄우고_섹션은그대로다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(category: .wantToGo))
        mockRepository.updatePlaceResult = .failure(.writeFailed)

        // When
        viewModel.send(.selectPlace(place))

        // Then
        guard case .errorAlert = viewModel.route else {
            return XCTFail("에러 알럿 route 가 와야 한다")
        }
        XCTAssertNil(viewModel.state.place)
    }

    // MARK: GH-31 TC3

    func test_GH31_TC3_장소지우기를하면_빈값으로저장되고_플레이스홀더로돌아간다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(category: .wantToGo, place: place))
        XCTAssertEqual(viewModel.state.place, place)

        // When
        viewModel.send(.tapDelete)

        // Then
        XCTAssertEqual(mockRepository.updatePlaceCalls.count, 1)
        XCTAssertNil(mockRepository.updatePlaceCalls.first?.place)
        XCTAssertNil(viewModel.state.place)
    }

    // MARK: GH-31 TC11

    func test_GH31_TC11_상세에서장소섹션을탭하면_wish_detail의add_place클릭로그가1건전송된다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(category: .wantToGo))

        // When
        viewModel.send(.tapPlace)

        // Then
        let clicks = clickEvents(objectId: .addPlace)
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.screen, .wishDetail)
        XCTAssertEqual(clicks.first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }
}
