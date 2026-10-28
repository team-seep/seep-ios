import XCTest

@testable import seep_ios

/// 상세 "이어지는 싶" 섹션과 이룬 싶 상세의 "이어서 적기" (GH-84 R-3~R-5)
final class DetailChainFeatureTests: ViewModelTestCase {
    private var repository: MockWishRepository!
    private let finishedAt = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 9))!

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    private var olle1: Wish {
        Wish(id: "a", emoji: "🥾", category: .wantToGo, title: "제주 올레길 1코스 걷기",
             finishDate: finishedAt, isSuccess: true, finishNote: "생각보다 훨씬 좋았어요")
    }

    private var olle21: Wish {
        Wish(id: "b", emoji: "🌊", category: .wantToGo, title: "올레길 21코스 완주하기", previousWishId: "a")
    }

    private func makeDetail(_ wish: Wish, mode: DetailMode = .fromHome) -> WishDetailViewModel {
        repository.fetchWishResult = [wish]
        return WishDetailViewModel(
            config: .init(wishId: wish.id, mode: mode),
            dependency: .init(wishRepository: repository, logManager: logManager, photoStorage: MockWishPhotoStorage())
        )
    }

    // MARK: GH-84 TC5

    func test_GH84_TC5_이룬A다음B의상세는_이어지는싶섹션에A와지금B가차례로있고_2번째다() {
        // Given
        repository.fetchWishChainResult = WishChain(previous: [olle1], current: olle21, next: [])

        // When
        let sut = makeDetail(olle21)
        let rows = sut.state.chain.map(DetailChainRow.rows) ?? []

        // Then
        XCTAssertEqual(sut.state.sections, [.chain, .journal, .place]) // 가고 싶어요는 장소, 홈에서 연 상세는 일지(GH-95) 섹션이 늘 있다
        XCTAssertEqual(sut.state.chain?.position, 2)
        XCTAssertEqual(rows.map(\.id), ["a", "b"])
        // 날짜 모양은 기기 로케일을 따른다 (GH-100). 한국어 형식("2026. 10. 24.")은 LocalizationFoundationTests 가 본다
        XCTAssertEqual(rows.first?.caption, "\(DisplayDate.numericYearMonthDay(finishedAt)) 이뤘어요 · “생각보다 훨씬 좋았어요”")
        XCTAssertTrue(rows.first?.isFinished ?? false)
        XCTAssertEqual(rows.last?.caption, "지금 이 싶")
        XCTAssertTrue(rows.last?.isCurrent ?? false)
    }

    // MARK: GH-84 TC7

    func test_GH84_TC7_이어진위시가없으면_섹션이없다() {
        // Given / When
        let sut = makeDetail(Wish(id: "solo", title: "혼자인 싶"))

        // Then
        XCTAssertNil(sut.state.chain)
        XCTAssertFalse(sut.state.sections.contains(.chain))
    }

    // MARK: GH-84 TC9

    func test_GH84_TC9_이룬위시상세의더보기에서이어서적기를누르면_같은위시로작성화면route가나온다() {
        // Given
        let sut = makeDetail(olle1, mode: .fromFinish)
        sut.send(.tapMore)
        guard case .moreMenu(let items) = sut.route else { return XCTFail("메뉴가 없다") }
        sut.send(.routeHandled)

        // When
        sut.send(.selectMoreItem(.chainNext))

        // Then
        XCTAssertEqual(items.prefix(2), [.cancelFinish, .chainNext])
        XCTAssertEqual(sut.route, .chainedWrite(olle1))
        XCTAssertEqual(clickEvents(objectId: .chainNextWish).first?.screen, .wishDetail)
    }

    func test_GH84_TC9_홈에서연상세의더보기에는_이어서적기가없다() {
        // Given
        let sut = makeDetail(olle21)

        // When
        sut.send(.tapMore)

        // Then
        guard case .moreMenu(let items) = sut.route else { return XCTFail("메뉴가 없다") }
        XCTAssertFalse(items.contains(.chainNext))
    }

    // MARK: GH-84 R-5

    func test_GH84_R5_섹션의앞위시줄을누르면_그위시상세로가고_지금위시줄은반응하지않는다() {
        // Given
        repository.fetchWishChainResult = WishChain(previous: [olle1], current: olle21, next: [])
        let sut = makeDetail(olle21)

        // When
        sut.send(.tapChainWish(id: "b"))
        let currentRoute = sut.route
        sut.send(.tapChainWish(id: "a"))

        // Then
        XCTAssertNil(currentRoute)
        XCTAssertEqual(sut.route, .wishDetail(id: "a", isFinished: true))
        XCTAssertEqual(clickEvents(objectId: .chainWishRow).count, 1)
    }
}
