import XCTest
import MapKit

@testable import seep_ios_dev

/// 가고 싶은 곳 지도 (GH-31 R-6~R-8, GH-64 TC-38·TC-1001~1002)
final class PlaceMapFeatureTests: ViewModelTestCase {
    private var mockRepository: MockWishRepository!
    private var sut: PlaceMapScreenViewModel!

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        sut = PlaceMapScreenViewModel(dependency: .init(wishRepository: mockRepository, logManager: logManager))
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
        super.tearDown()
    }

    private func place(_ name: String, latitude: Double = 33.4, longitude: Double = 126.5) -> WishPlace {
        WishPlace(name: name, address: "제주", latitude: latitude, longitude: longitude)
    }

    private func wish(id: String, place: WishPlace?, isSuccess: Bool = false) -> Wish {
        Wish(id: id, emoji: "🌅", category: .wantToGo, title: "위시 \(id)", isSuccess: isSuccess, place: place)
    }

    // MARK: GH-31 TC4

    func test_GH31_TC4_장소있는미완료3개_완료1개_장소없는1개면_핀은3개이고_3곳으로표시된다() {
        // Given
        mockRepository.fetchWishesResult = [
            wish(id: "1", place: place("성산일출봉")),
            wish(id: "2", place: place("한라산")),
            wish(id: "3", place: place("감귤농장")),
            wish(id: "4", place: place("우도"), isSuccess: true),
            wish(id: "5", place: nil)
        ]

        // When
        sut.send(.onAppear)

        // Then
        XCTAssertEqual(sut.state.wishes.map(\.id), ["1", "2", "3"])
        XCTAssertEqual(sut.state.count, 3)
        XCTAssertFalse(sut.state.isEmpty)
        XCTAssertEqual(sut.state.cameraFit?.wishIds, ["1", "2", "3"])
    }

    func test_GH31_TC4_상세에서돌아와다시불러오면_영역은다시맞추지않고_핀만갱신된다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉")), wish(id: "2", place: place("한라산"))]
        sut.send(.onAppear)
        let firstFit = sut.state.cameraFit
        sut.send(.selectPin(wishId: "2"))
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉"))]

        // When
        sut.send(.onAppear)

        // Then
        XCTAssertEqual(sut.state.cameraFit, firstFit)
        XCTAssertEqual(sut.state.count, 1)
        XCTAssertNil(sut.state.selectedWish)
    }

    // MARK: GH-31 TC5

    func test_GH31_TC5_핀을탭하고카드를탭하면_해당위시상세로이동한다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉")), wish(id: "2", place: place("한라산"))]
        sut.send(.onAppear)

        // When
        sut.send(.selectPin(wishId: "2"))
        sut.send(.tapCard)

        // Then
        XCTAssertEqual(sut.state.selectedWish?.id, "2")
        XCTAssertEqual(sut.route, .wishDetail(id: "2"))
    }

    func test_GH31_TC5_빈곳을눌러선택이풀리면_카드가사라진다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉"))]
        sut.send(.onAppear)
        sut.send(.selectPin(wishId: "1"))

        // When
        sut.send(.selectPin(wishId: nil))

        // Then
        XCTAssertNil(sut.state.selectedWish)
    }

    /// SwiftUI 에서는 상세에서 돌아오면 지도가 다시 나타나며 불러온다(홈도 나타날 때 다시 불러온다)
    func test_GH31_TC5_지도에서들어간상세에서장소가바뀌면_홈에알린다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉"))]
        sut.send(.onAppear)
        sut.send(.selectPin(wishId: "1"))
        sut.send(.tapCard)
        sut.send(.routeHandled)
        mockRepository.fetchWishesResult = [wish(id: "1", place: nil)]

        // When
        sut.send(.onAppear)

        // Then
        XCTAssertNil(sut.route)
        XCTAssertTrue(sut.state.isEmpty)
        XCTAssertNil(sut.state.selectedWishId)
    }

    // MARK: GH-31 TC6

    func test_GH31_TC6_장소가붙은위시가없으면_빈상태안내가보인다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: nil), wish(id: "2", place: place("우도"), isSuccess: true)]

        // When
        sut.send(.onAppear)

        // Then
        XCTAssertTrue(sut.state.isEmpty)
        XCTAssertEqual(sut.state.count, 0)
        XCTAssertEqual(sut.state.wishes, [])
    }

    // MARK: GH-31 TC14

    func test_GH31_TC14_지도아래위시카드를탭하면_place_map_wish클릭로그가1건전송된다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉"))]
        sut.send(.onAppear)
        sut.send(.selectPin(wishId: "1"))

        // When
        sut.send(.tapCard)

        // Then
        let clickEvents = logManager.sentEvents.compactMap { $0 as? ClickEvent }
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.screen, .placeMap)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectType] as? LogObjectType, .card)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectId] as? LogObjectId, .placeMapWish)
    }

    func test_GH31_TC14_선택한핀이없으면_카드탭로그를보내지않는다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉"))]
        sut.send(.onAppear)

        // When
        sut.send(.tapCard)

        // Then
        XCTAssertTrue(logManager.sentEvents.isEmpty)
        XCTAssertNil(sut.route)
    }

    // MARK: GH-64 TC38

    func test_GH64_TC38_장소붙은가고싶어요3개에서_핀을누르면_카드가그위시로바뀌고_카드탭이상세로간다() {
        // Given
        mockRepository.fetchWishesResult = [
            wish(id: "a", place: place("성산일출봉")),
            wish(id: "b", place: place("한라산")),
            wish(id: "c", place: place("감귤농장"))
        ]
        sut.send(.onAppear)
        XCTAssertEqual(sut.state.count, 3)

        // When
        sut.send(.selectPin(wishId: "b"))

        // Then
        XCTAssertEqual(sut.state.selectedWish?.title, "위시 b")

        // When
        sut.send(.selectPin(wishId: "c"))
        sut.send(.tapCard)

        // Then
        XCTAssertEqual(sut.state.selectedWishId, "c")
        XCTAssertEqual(sut.route, .wishDetail(id: "c"))
        XCTAssertEqual(clickEvents(objectId: .placeMapWish).count, 1)
    }

    // MARK: GH-64 TC1001

    func test_GH64_TC1001_핀3개의영역은_세좌표를모두담고_위아래좌우여백이있다() {
        // Given
        let coordinates = [
            CLLocationCoordinate2D(latitude: 33.458, longitude: 126.942),
            CLLocationCoordinate2D(latitude: 33.361, longitude: 126.533),
            CLLocationCoordinate2D(latitude: 33.250, longitude: 126.560)
        ]

        // When
        let rect = PlaceMapCamera.fittingRect(for: coordinates)

        // Then
        let points = coordinates.map(MKMapPoint.init)
        for point in points {
            XCTAssertTrue(rect.contains(point))
        }
        XCTAssertLessThan(rect.minX, points.map(\.x).min() ?? 0)
        XCTAssertGreaterThan(rect.maxX, points.map(\.x).max() ?? 0)
        XCTAssertLessThan(rect.minY, points.map(\.y).min() ?? 0)
        XCTAssertGreaterThan(rect.maxY, points.map(\.y).max() ?? 0)
    }

    func test_GH64_TC1001_핀이하나면_반경3km_영역으로_없으면_영역이없다() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 33.458, longitude: 126.942)

        // When
        let single = PlaceMapCamera.region(for: [coordinate])
        let none = PlaceMapCamera.region(for: [])

        // Then
        XCTAssertEqual(single?.center.latitude ?? 0, coordinate.latitude, accuracy: 0.000_001)
        XCTAssertEqual(single?.center.longitude ?? 0, coordinate.longitude, accuracy: 0.000_001)
        // 위도 1도 ≈ 111km → 3km ≈ 0.027도
        XCTAssertEqual(single?.span.latitudeDelta ?? 0, 0.027, accuracy: 0.002)
        XCTAssertNil(none)
    }

    // MARK: GH-64 TC1002

    func test_GH64_TC1002_핀선택후빈곳을누르면_해제되고_목록에없는핀id는무시한다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉"))]
        sut.send(.onAppear)

        // When
        sut.send(.selectPin(wishId: "1"))
        sut.send(.selectPin(wishId: "unknown"))

        // Then
        XCTAssertEqual(sut.state.selectedWishId, "1")

        // When
        sut.send(.selectPin(wishId: nil))

        // Then
        XCTAssertNil(sut.state.selectedWish)
        let didChange = observeChange { _ = self.sut.state.selectedWishId }
        sut.send(.selectPin(wishId: "1"))
        XCTAssertTrue(didChange())
    }
}
