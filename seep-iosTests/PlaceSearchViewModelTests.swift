import XCTest
import Combine

@testable import seep_ios_dev

/// 장소 검색 바텀시트 (GH-31 R-3).
final class PlaceSearchViewModelTests: XCTestCase {
    private var mockService: MockPlaceSearchService!
    private var mockLogManager: MockLogManager!
    private var sut: PlaceSearchViewModel!
    private var cancellables: Set<AnyCancellable>!

    private let candidates = [
        PlaceCandidate(id: "c-1", title: "성산일출봉", subtitle: "제주 서귀포시 성산읍 성산리 1"),
        PlaceCandidate(id: "c-2", title: "성산항", subtitle: "제주 서귀포시 성산읍 성산리")
    ]
    private let place = WishPlace(name: "성산일출봉", address: "제주 서귀포시 성산읍 성산리 1", latitude: 33.458, longitude: 126.942)

    override func setUp() {
        super.setUp()
        mockService = MockPlaceSearchService()
        mockLogManager = MockLogManager()
        cancellables = []
        sut = PlaceSearchViewModel(dependency: .init(placeSearchService: mockService, logManager: mockLogManager))
    }

    override func tearDown() {
        mockService = nil
        mockLogManager = nil
        sut = nil
        cancellables = nil
        super.tearDown()
    }

    private func search(_ query: String, result: Result<[PlaceCandidate], Error>) {
        sut.input.inputQuery.send(query)
        mockService.sendCandidates(result)
    }

    // MARK: GH-31 TC2

    func test_GH31_TC2_후보를선택하면_좌표를받은장소를돌려주고_시트를닫는다() {
        // Given
        search("성산일출", result: .success(candidates))
        mockService.resolveResult = .success(place)
        var selectedPlaces: [WishPlace] = []
        var isDismissed = false
        sut.output.didSelectPlace.sink { selectedPlaces.append($0) }.store(in: &cancellables)
        sut.output.route.sink { route in
            if case .dismiss = route { isDismissed = true }
        }.store(in: &cancellables)

        // When
        sut.input.didTapCandidate.send(0)

        // Then
        XCTAssertEqual(mockService.searchedQueries, ["성산일출"])
        XCTAssertEqual(mockService.resolvedCandidates, [candidates[0]])
        XCTAssertEqual(selectedPlaces, [place])
        XCTAssertTrue(isDismissed)
    }

    // MARK: GH-31 TC10

    func test_GH31_TC10_검색결과가0개면_찾는장소가없어요가보인다() {
        // Given
        XCTAssertFalse(sut.output.isEmptyVisible.value)

        // When
        search("없는장소이름", result: .success([]))

        // Then
        XCTAssertTrue(sut.output.isEmptyVisible.value)
        XCTAssertEqual(sut.output.candidates.value, [])
    }

    func test_GH31_TC10_검색이실패하면_찾는장소가없어요가보인다() {
        // Given
        search("성산", result: .success(candidates))

        // When
        mockService.sendCandidates(.failure(PlaceSearchError.notFound))

        // Then
        XCTAssertTrue(sut.output.isEmptyVisible.value)
        XCTAssertEqual(sut.output.candidates.value, [])
    }

    func test_GH31_TC10_검색어를지우면_후보와안내가비워진다() {
        // Given
        search("없는장소이름", result: .success([]))

        // When
        sut.input.inputQuery.send("  ")

        // Then
        XCTAssertFalse(sut.output.isEmptyVisible.value)
        XCTAssertEqual(sut.output.candidates.value, [])
    }

    func test_GH31_TC10_후보좌표를받지못하면_시트를닫지않고_안내를보인다() {
        // Given
        search("성산", result: .success(candidates))
        mockService.resolveResult = .failure(PlaceSearchError.notFound)
        var routes: [PlaceSearchViewModel.Route] = []
        sut.output.route.sink { routes.append($0) }.store(in: &cancellables)

        // When
        sut.input.didTapCandidate.send(1)

        // Then
        XCTAssertTrue(routes.isEmpty)
        XCTAssertTrue(sut.output.isEmptyVisible.value)
    }

    // MARK: GH-31 TC12

    func test_GH31_TC12_후보를선택하면_select_place클릭로그가1건전송된다() {
        // Given
        search("성산", result: .success(candidates))
        mockService.resolveResult = .success(place)

        // When
        sut.input.didTapCandidate.send(0)

        // Then
        let clickEvents = mockLogManager.sentEvents.compactMap { $0 as? ClickEvent }
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.screen, .placeSearchBottomSheet)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectType] as? LogObjectType, .card)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectId] as? LogObjectId, .selectPlace)
        XCTAssertEqual(clickEvents.first?.parameters["screen"] as? String, "place_search_bottom_sheet")
        XCTAssertEqual(clickEvents.first?.parameters["object_id"] as? String, "select_place")
    }
}
