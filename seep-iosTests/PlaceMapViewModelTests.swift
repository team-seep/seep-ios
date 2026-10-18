import XCTest
import Combine

@testable import seep_ios_dev

/// 가고 싶은 곳 지도 (GH-31 R-6~R-8).
final class PlaceMapViewModelTests: XCTestCase {
    private var mockRepository: MockWishRepository!
    private var mockLogManager: MockLogManager!
    private var sut: PlaceMapViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        mockLogManager = MockLogManager()
        cancellables = []
        sut = PlaceMapViewModel(dependency: .init(
            wishRepository: mockRepository,
            logManager: mockLogManager,
            wishService: MockWishService()
        ))
    }

    override func tearDown() {
        mockRepository = nil
        mockLogManager = nil
        sut = nil
        cancellables = nil
        super.tearDown()
    }

    private func place(_ name: String) -> WishPlace {
        return WishPlace(name: name, address: "제주", latitude: 33.4, longitude: 126.5)
    }

    private func wish(id: String, place: WishPlace?, isSuccess: Bool = false) -> Wish {
        return Wish(id: id, emoji: "🌅", category: .wantToGo, title: "위시 \(id)", isSuccess: isSuccess, place: place)
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
        var fittedWishIds: [[String]] = []
        sut.output.fitAllPins.sink { fittedWishIds.append($0.map(\.id)) }.store(in: &cancellables)

        // When
        sut.input.viewWillAppear.send(())

        // Then
        XCTAssertEqual(sut.output.wishes.value.map(\.id), ["1", "2", "3"])
        XCTAssertEqual(sut.output.count.value, 3)
        XCTAssertFalse(sut.output.isEmpty.value)
        XCTAssertEqual(fittedWishIds, [["1", "2", "3"]])
    }

    func test_GH31_TC4_상세에서돌아와다시불러오면_영역은다시맞추지않고_핀만갱신된다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉")), wish(id: "2", place: place("한라산"))]
        var fitCount = 0
        sut.output.fitAllPins.sink { _ in fitCount += 1 }.store(in: &cancellables)
        sut.input.viewWillAppear.send(())
        sut.input.didSelectPin.send("2")
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉"))]

        // When
        sut.input.viewWillAppear.send(())

        // Then
        XCTAssertEqual(fitCount, 1)
        XCTAssertEqual(sut.output.count.value, 1)
        XCTAssertNil(sut.output.selectedWish.value)
    }

    // MARK: GH-31 TC5

    func test_GH31_TC5_핀을탭하고카드를탭하면_해당위시상세로이동한다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉")), wish(id: "2", place: place("한라산"))]
        sut.input.viewWillAppear.send(())
        var pushedWishIds: [String] = []
        sut.output.route.sink { route in
            if case .pushWishDetail(let reactor) = route { pushedWishIds.append(reactor.initialState.wish.id) }
        }.store(in: &cancellables)

        // When
        sut.input.didSelectPin.send("2")
        sut.input.didTapCard.send(())

        // Then
        XCTAssertEqual(sut.output.selectedWish.value?.id, "2")
        XCTAssertEqual(pushedWishIds, ["2"])
    }

    func test_GH31_TC5_빈곳을눌러선택이풀리면_카드가사라진다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉"))]
        sut.input.viewWillAppear.send(())
        sut.input.didSelectPin.send("1")

        // When
        sut.input.didDeselectPin.send(())

        // Then
        XCTAssertNil(sut.output.selectedWish.value)
    }

    func test_GH31_TC5_지도에서들어간상세에서장소가바뀌면_홈에알린다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉"))]
        sut.input.viewWillAppear.send(())
        var reactor: WishDetailReactor?
        sut.output.route.sink { route in
            if case .pushWishDetail(let pushed) = route { reactor = pushed }
        }.store(in: &cancellables)
        var changeCount = 0
        sut.output.didChangeWishes.sink { changeCount += 1 }.store(in: &cancellables)
        sut.input.didSelectPin.send("1")
        sut.input.didTapCard.send(())

        // When
        reactor?.updateWishPublisher.send(wish(id: "1", place: nil))

        // Then
        XCTAssertEqual(changeCount, 1)
    }

    // MARK: GH-31 TC6

    func test_GH31_TC6_장소가붙은위시가없으면_빈상태안내가보인다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: nil), wish(id: "2", place: place("우도"), isSuccess: true)]

        // When
        sut.input.viewWillAppear.send(())

        // Then
        XCTAssertTrue(sut.output.isEmpty.value)
        XCTAssertEqual(sut.output.count.value, 0)
        XCTAssertEqual(sut.output.wishes.value, [])
    }

    // MARK: GH-31 TC14

    func test_GH31_TC14_지도아래위시카드를탭하면_place_map_wish클릭로그가1건전송된다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉"))]
        sut.input.viewWillAppear.send(())
        sut.input.didSelectPin.send("1")

        // When
        sut.input.didTapCard.send(())

        // Then
        let clickEvents = mockLogManager.sentEvents.compactMap { $0 as? ClickEvent }
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.screen, .placeMap)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectType] as? LogObjectType, .card)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectId] as? LogObjectId, .placeMapWish)
    }

    func test_GH31_TC14_선택한핀이없으면_카드탭로그를보내지않는다() {
        // Given
        mockRepository.fetchWishesResult = [wish(id: "1", place: place("성산일출봉"))]
        sut.input.viewWillAppear.send(())

        // When
        sut.input.didTapCard.send(())

        // Then
        XCTAssertTrue(mockLogManager.sentEvents.isEmpty)
    }
}
