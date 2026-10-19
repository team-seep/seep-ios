import XCTest
import Combine

@testable import seep_ios_dev

/// 위시 상세·작성의 장소 섹션 (GH-31 R-1·R-2·R-4).
final class WishPlaceViewModelTests: XCTestCase {
    private var mockRepository: MockWishRepository!
    private var mockLogManager: MockLogManager!
    private var mockSearchService: MockPlaceSearchService!
    private var cancellables: Set<AnyCancellable>!

    private let place = WishPlace(name: "성산일출봉", address: "제주 서귀포시 성산읍 성산리 1", latitude: 33.458, longitude: 126.942)

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        mockLogManager = MockLogManager()
        mockSearchService = MockPlaceSearchService()
        cancellables = []
    }

    override func tearDown() {
        mockRepository = nil
        mockLogManager = nil
        mockSearchService = nil
        cancellables = nil
        super.tearDown()
    }

    private func makeViewModel(mode: WishPlaceViewModel.Mode) -> WishPlaceViewModel {
        let searchService = mockSearchService!
        return WishPlaceViewModel(
            config: .init(mode: mode),
            dependency: .init(
                wishRepository: mockRepository,
                logManager: mockLogManager,
                makePlaceSearchService: { searchService }
            )
        )
    }

    private func makeWish(category: seep_ios_dev.Category, place: WishPlace? = nil) -> Wish {
        return Wish(id: "wish-1", emoji: "🌅", category: category, title: "성산일출봉에서 새해 일출 보기", place: place)
    }

    // MARK: GH-31 TC1

    func test_GH31_TC1_가고싶어요위시상세면_장소섹션이보인다() {
        // Given
        let viewModel = makeViewModel(mode: .persisted(makeWish(category: .wantToGo)))

        // When
        let isVisible = viewModel.output.isVisible.value

        // Then
        XCTAssertTrue(isVisible)
        XCTAssertNil(viewModel.output.place.value)
    }

    func test_GH31_TC1_하고싶어요_갖고싶어요위시상세면_장소섹션이보이지않는다() {
        // Given
        let wantToDo = makeViewModel(mode: .persisted(makeWish(category: .wantToDo)))
        let wantToGet = makeViewModel(mode: .persisted(makeWish(category: .wantToGet)))

        // When
        let visibilities = [wantToDo.output.isVisible.value, wantToGet.output.isVisible.value]

        // Then
        XCTAssertEqual(visibilities, [false, false])
    }

    func test_GH31_TC1_수정화면에서카테고리를바꾸면_섹션은숨고_장소값은남는다() {
        // Given
        let viewModel = makeViewModel(mode: .persisted(makeWish(category: .wantToGo, place: place)))

        // When
        viewModel.input.reloadWish.send(makeWish(category: .wantToDo, place: place))

        // Then
        XCTAssertFalse(viewModel.output.isVisible.value)
        XCTAssertEqual(viewModel.output.place.value, place)
        XCTAssertTrue(mockRepository.updatePlaceCalls.isEmpty)
    }

    // MARK: GH-31 TC2

    func test_GH31_TC2_검색시트에서후보를고르면_Repository에장소가저장되고_섹션이장소로바뀐다() {
        // Given
        let viewModel = makeViewModel(mode: .persisted(makeWish(category: .wantToGo)))
        var searchViewModel: PlaceSearchViewModel?
        viewModel.output.route.sink { route in
            if case .presentPlaceSearch(let presented) = route { searchViewModel = presented }
        }.store(in: &cancellables)
        var updatedPlaces: [WishPlace?] = []
        viewModel.output.didUpdatePlace.sink { updatedPlaces.append($0) }.store(in: &cancellables)
        viewModel.input.didTapPlace.send(())
        mockSearchService.resolveResult = .success(place)
        searchViewModel?.input.inputQuery.send("성산일출")
        mockSearchService.sendCandidates(.success([
            PlaceCandidate(id: "c-1", title: "성산일출봉", subtitle: "제주 서귀포시 성산읍 성산리 1")
        ]))

        // When
        searchViewModel?.input.didTapCandidate.send(0)

        // Then
        XCTAssertNotNil(searchViewModel)
        XCTAssertEqual(mockRepository.updatePlaceCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(mockRepository.updatePlaceCalls.first?.place, place)
        XCTAssertEqual(viewModel.output.place.value, place)
        XCTAssertEqual(updatedPlaces, [place])
    }

    func test_GH31_TC2_저장에실패하면_에러알럿을띄우고_섹션은그대로다() {
        // Given
        let viewModel = makeViewModel(mode: .persisted(makeWish(category: .wantToGo)))
        mockRepository.updatePlaceResult = .failure(.writeFailed)
        var errorRouteCount = 0
        viewModel.output.route.sink { route in
            if case .showErrorAlert = route { errorRouteCount += 1 }
        }.store(in: &cancellables)

        // When
        viewModel.input.selectPlace.send(place)

        // Then
        XCTAssertEqual(errorRouteCount, 1)
        XCTAssertNil(viewModel.output.place.value)
    }

    // MARK: GH-31 TC3

    func test_GH31_TC3_장소지우기를하면_빈값으로저장되고_플레이스홀더로돌아간다() {
        // Given
        let viewModel = makeViewModel(mode: .persisted(makeWish(category: .wantToGo, place: place)))
        XCTAssertEqual(viewModel.output.place.value, place)

        // When
        viewModel.input.didTapDelete.send(())

        // Then
        XCTAssertEqual(mockRepository.updatePlaceCalls.count, 1)
        XCTAssertNil(mockRepository.updatePlaceCalls.first?.place)
        XCTAssertNil(viewModel.output.place.value)
    }

    // MARK: GH-31 TC9

    func test_GH31_TC9_작성화면에서는_장소를골라도_Repository에저장하지않는다() {
        // Given
        let viewModel = makeViewModel(mode: .draft(category: .wantToGo, screenName: .write))
        var updatedPlaces: [WishPlace?] = []
        viewModel.output.didUpdatePlace.sink { updatedPlaces.append($0) }.store(in: &cancellables)

        // When
        viewModel.input.selectPlace.send(place)

        // Then
        XCTAssertTrue(mockRepository.updatePlaceCalls.isEmpty)
        XCTAssertEqual(viewModel.output.place.value, place)
        XCTAssertEqual(updatedPlaces, [place])
    }

    func test_GH31_TC9_작성화면에서카테고리를바꾸면_섹션이접히고펴진다() {
        // Given
        let viewModel = makeViewModel(mode: .draft(category: .wantToDo, screenName: .write))
        XCTAssertFalse(viewModel.output.isVisible.value)

        // When
        viewModel.input.updateCategory.send(.wantToGo)

        // Then
        XCTAssertTrue(viewModel.output.isVisible.value)
    }

    // MARK: GH-31 TC11

    func test_GH31_TC11_상세에서장소섹션을탭하면_wish_detail의add_place클릭로그가1건전송된다() {
        // Given
        let viewModel = makeViewModel(mode: .persisted(makeWish(category: .wantToGo)))

        // When
        viewModel.input.didTapPlace.send(())

        // Then
        let clickEvents = mockLogManager.sentEvents.compactMap { $0 as? ClickEvent }
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.screen, .wishDetail)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectType] as? LogObjectType, .button)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectId] as? LogObjectId, .addPlace)
    }

    func test_GH31_TC11_작성화면에서장소섹션을탭하면_write의add_place클릭로그가1건전송된다() {
        // Given
        let viewModel = makeViewModel(mode: .draft(category: .wantToGo, screenName: .write))

        // When
        viewModel.input.didTapPlace.send(())

        // Then
        let clickEvents = mockLogManager.sentEvents.compactMap { $0 as? ClickEvent }
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.screen, .write)
        XCTAssertEqual(clickEvents.first?.parameters["object_id"] as? String, "add_place")
    }
}
