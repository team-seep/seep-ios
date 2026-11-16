import XCTest

@testable import seep_ios

/// 홈 태그 필터 칩 (GH-136 R-3 ~ R-5)
final class HomeTagFilterFeatureTests: HomeFeatureTestCase {
    private let tripA = Wish(id: "trip-a", title: "제주", tags: ["trip"])
    private let tripB = Wish(id: "trip-b", title: "오사카", tags: ["trip", "life"])
    private let reading = Wish(id: "reading", title: "북카페", tags: ["life", "독서"])
    private let plain = Wish(id: "plain", title: "태그 없음")

    private func loadedSut(_ wishes: [Wish]) -> HomeViewModel {
        repository.fetchWishesResult = wishes
        let sut = makeSut()
        sut.send(.onAppear)
        return sut
    }

    // MARK: GH-136 TC6

    func test_GH136_TC6_칩줄은_지금카테고리태그를많이쓴순으로보이고_같으면먼저나온순이다() {
        // When
        let sut = loadedSut([tripA, reading, tripB, plain])

        // Then: trip 2, life 2(먼저 나온 건 reading), 독서 1
        XCTAssertEqual(sut.state.tagChips, ["trip", "life", "독서"])
        XCTAssertTrue(sut.state.isTagFilterVisible)
    }

    // MARK: GH-136 TC7

    func test_GH136_TC7_태그칩을고르면_그태그가두번째태그인위시까지보이고_전체를고르면다보인다() {
        // Given
        let sut = loadedSut([tripA, tripB, reading, plain])

        // When
        sut.send(.selectTag("life"))

        // Then
        XCTAssertEqual(sut.state.selectedTag, "life")
        XCTAssertEqual(sut.state.items.map(\.id), ["trip-b", "reading"])

        // When
        sut.send(.selectTag(nil))

        // Then
        XCTAssertEqual(sut.state.items.map(\.id), ["trip-a", "trip-b", "reading", "plain"])
    }

    // MARK: GH-136 TC8

    func test_GH136_TC8_태그로거른중_카테고리를바꾸면_전체로돌아간다() {
        // Given
        let sut = loadedSut([tripA, reading])
        sut.send(.selectTag("독서"))

        // When
        sut.send(.selectCategory(.wantToGet))

        // Then
        XCTAssertNil(sut.state.selectedTag)
        XCTAssertEqual(sut.state.items.count, 2)
    }

    func test_GH136_TC8_고른태그의위시가없어지면_전체로돌아간다() {
        // Given
        let sut = loadedSut([tripA, reading])
        sut.send(.selectTag("독서"))

        // When
        repository.fetchWishesResult = [tripA]
        sut.send(.onAppear)

        // Then
        XCTAssertNil(sut.state.selectedTag)
        XCTAssertEqual(sut.state.items.map(\.id), ["trip-a"])
    }

    // MARK: GH-136 TC9

    func test_GH136_TC9_태그가하나도없는카테고리는_칩줄이없다() {
        // When
        let sut = loadedSut([plain])

        // Then
        XCTAssertEqual(sut.state.tagChips, [])
        XCTAssertFalse(sut.state.isTagFilterVisible)
    }

    // MARK: GH-136 TC10

    func test_GH136_TC10_태그3개인위시는_셀에첫태그와더2개_상세에는모두보인다() {
        // Given
        let wish = Wish(title: "북카페", tags: ["life", "독서", "trip"])

        // When
        let item = HomeWishItem(wish: wish, photoStorage: photoStorage)
        let row = WishRowModel(wish: wish)
        let meta = WishDetailSummary(wish: wish, now: Date(), calendar: .current).metaItems

        // Then
        XCTAssertEqual(item.tagText, HashtagType.life.description)
        XCTAssertEqual(item.extraTagCount, 2)
        XCTAssertEqual(row.extraTagCount, 2)
        XCTAssertEqual(meta.last, .hashtag("#\(HashtagType.life.description) #독서 #\(HashtagType.trip.description)"))
    }

    // MARK: GH-136 TC12

    func test_GH136_TC12_태그칩을탭하면_tag_filter클릭로그에_기본태그는rawValue_직접입력은custom_전체는all이간다() {
        // Given
        let sut = loadedSut([tripB, reading])

        // When
        sut.send(.selectTag("trip"))
        sut.send(.selectTag("독서"))
        sut.send(.selectTag(nil))

        // Then
        let events = clickEvents(objectId: .tagFilter)
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events.map { $0.parameters[ParameterName.screen.rawValue] as? String }, ["home", "home", "home"])
        XCTAssertEqual(events.map { $0.extraParameters?[.tagType] as? String }, ["trip", "custom", "all"])
    }

    // MARK: GH-136 TC15

    func test_GH136_TC15_내가정한순서에서_태그로거르면_순서바꾸기가숨는다() {
        // Given
        preference.homeSortOrder = .manualOrder
        let sut = loadedSut([tripA, tripB, reading])
        XCTAssertTrue(sut.state.isReorderButtonVisible)

        // When
        sut.send(.selectTag("trip"))

        // Then
        XCTAssertFalse(sut.state.isReorderButtonVisible)
    }
}
