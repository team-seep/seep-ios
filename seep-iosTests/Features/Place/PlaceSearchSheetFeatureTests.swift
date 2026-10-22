import XCTest

@testable import seep_ios_dev

/// 장소 검색 시트 SwiftUI판 (GH-31 R-3, GH-64 TC-1003).
/// 레거시 `PlaceSearchViewModelTests`는 작성·상세(P2)가 아직 쓰는 레거시 ViewModel 용으로 남는다
final class PlaceSearchSheetFeatureTests: ViewModelTestCase {
    private var mockService: MockPlaceSearchService!
    private var sut: PlaceSearchSheetViewModel!

    private let candidates = [
        PlaceCandidate(id: "c-1", title: "성산일출봉", subtitle: "제주 서귀포시 성산읍 성산리 1"),
        PlaceCandidate(id: "c-2", title: "성산항", subtitle: "제주 서귀포시 성산읍 성산리")
    ]
    private let place = WishPlace(name: "성산일출봉", address: "제주 서귀포시 성산읍 성산리 1", latitude: 33.458, longitude: 126.942)

    override func setUp() {
        super.setUp()
        mockService = MockPlaceSearchService()
        sut = PlaceSearchSheetViewModel(dependency: .init(
            placeSearchService: mockService,
            logManager: logManager,
            debounce: 0.05
        ))
    }

    override func tearDown() {
        mockService = nil
        sut = nil
        super.tearDown()
    }

    private func search(_ query: String, result: Result<[PlaceCandidate], Error>) {
        sut.send(.inputQuery(query))
        mockService.sendCandidates(result)
    }

    // MARK: GH-31 TC2

    func test_GH31_TC2_후보를선택하면_좌표를받은장소를돌려주고_시트를닫는다() {
        // Given
        search("성산일출", result: .success(candidates))
        mockService.resolveResult = .success(place)
        waitUntil { self.mockService.searchedQueries == ["성산일출"] }

        // When
        sut.send(.tapCandidate(index: 0))

        // Then
        XCTAssertEqual(mockService.resolvedCandidates, [candidates[0]])
        waitUntil { self.sut.route == .selected(self.place) }
    }

    // MARK: GH-31 TC10

    func test_GH31_TC10_검색결과가0개면_찾는장소가없어요가보인다() {
        // Given
        XCTAssertFalse(sut.state.isEmptyVisible)

        // When
        search("없는장소이름", result: .success([]))

        // Then
        XCTAssertTrue(sut.state.isEmptyVisible)
        XCTAssertEqual(sut.state.candidates, [])
    }

    func test_GH31_TC10_검색이실패하면_찾는장소가없어요가보인다() {
        // Given
        search("성산", result: .success(candidates))

        // When
        mockService.sendCandidates(.failure(PlaceSearchError.notFound))

        // Then
        XCTAssertTrue(sut.state.isEmptyVisible)
        XCTAssertEqual(sut.state.candidates, [])
    }

    func test_GH31_TC10_검색어를지우면_후보와안내가비워진다() {
        // Given
        search("없는장소이름", result: .success([]))

        // When
        sut.send(.inputQuery("  "))

        // Then
        XCTAssertFalse(sut.state.isEmptyVisible)
        XCTAssertEqual(sut.state.candidates, [])
    }

    func test_GH31_TC10_후보좌표를받지못하면_시트를닫지않고_안내를보인다() {
        // Given
        search("성산", result: .success(candidates))
        mockService.resolveResult = .failure(PlaceSearchError.notFound)

        // When
        sut.send(.tapCandidate(index: 1))

        // Then
        waitUntil { self.sut.state.isEmptyVisible }
        XCTAssertNil(sut.route)
        XCTAssertFalse(sut.state.isResolving)
    }

    // MARK: GH-31 TC12

    func test_GH31_TC12_후보를선택하면_select_place클릭로그가1건전송된다() {
        // Given
        search("성산", result: .success(candidates))
        mockService.resolveResult = .success(place)

        // When
        sut.send(.tapCandidate(index: 0))

        // Then
        let clickEvents = logManager.sentEvents.compactMap { $0 as? ClickEvent }
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.screen, .placeSearchBottomSheet)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectType] as? LogObjectType, .card)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectId] as? LogObjectId, .selectPlace)
        XCTAssertEqual(clickEvents.first?.parameters["screen"] as? String, "place_search_bottom_sheet")
        XCTAssertEqual(clickEvents.first?.parameters["object_id"] as? String, "select_place")
    }

    // MARK: GH-64 TC1003

    func test_GH64_TC1003_빠르게입력하면_멈춘뒤마지막검색어로_서비스를1번만부른다() {
        // Given / When
        sut.send(.inputQuery("성"))
        sut.send(.inputQuery("성산"))
        sut.send(.inputQuery("성산일"))

        // Then
        XCTAssertEqual(mockService.searchedQueries, [], "디바운스 전에는 부르지 않는다")
        waitUntil { !self.mockService.searchedQueries.isEmpty }
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        XCTAssertEqual(mockService.searchedQueries, ["성산일"])
    }

    func test_GH64_TC1003_검색어를지우면_대기중인검색을보내지않는다() {
        // Given
        sut.send(.inputQuery("성산"))

        // When
        sut.send(.inputQuery(""))
        RunLoop.current.run(until: Date().addingTimeInterval(0.15))

        // Then
        XCTAssertEqual(mockService.searchedQueries, [])
        XCTAssertEqual(sut.state.query, "")
    }

    func test_GH64_TC1003_기본디바운스는_0점3초다() {
        // Given / When
        let dependency = PlaceSearchSheetViewModel.Dependency(placeSearchService: MockPlaceSearchService(), logManager: logManager)

        // Then
        XCTAssertEqual(dependency.debounce, 0.3, accuracy: 0.000_1)
    }
}
