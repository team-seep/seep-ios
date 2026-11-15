import XCTest

@testable import seep_ios

/// 작성·수정 문서의 태그 시트 — 여러 개 고르기·최대 개수·중복·전에 쓴 태그 (GH-136 R-2), 태그 검색 (R-5)
final class WishTagFormFeatureTests: WishFormFeatureTestCase {
    private var maxCountMessage: String {
        Strings.WishDocument.HashtagSheet.maxCountFormat(WishTagSelection.maxCount)
    }

    // MARK: GH-136 TC2

    func test_GH136_TC2_기본태그2개와직접입력1개를골라저장하면_태그3개가순서대로저장된다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)
        viewModel.send(.tapHashtag)

        // When
        viewModel.send(.selectHashtag(.trip))
        viewModel.send(.selectHashtag(.life))
        viewModel.send(.inputCustomHashtag("독서"))
        viewModel.send(.submitCustomHashtag)
        viewModel.send(.dismissSheet)
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(viewModel.state.customTagInput, "")
        XCTAssertEqual(wishRepository.addedWishes.first?.tags, ["trip", "life", "독서"])
    }

    // MARK: GH-136 TC3

    func test_GH136_TC3_태그5개를고른상태에서_6번째는들어가지않고_최대개수안내가보인다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)
        for hashtag in [HashtagType.trip, .shopping, .sports, .career, .life] {
            viewModel.send(.selectHashtag(hashtag))
        }

        // When
        viewModel.send(.selectHashtag(.hobby))

        // Then
        XCTAssertEqual(viewModel.state.tagSelection.tags.count, 5)
        XCTAssertFalse(viewModel.state.tagSelection.contains(.hobby))
        XCTAssertEqual(viewModel.state.tagError, maxCountMessage)

        // When: 직접 입력도 넣지 않고 친 글자를 남긴다
        viewModel.send(.inputCustomHashtag("독서"))
        viewModel.send(.submitCustomHashtag)

        // Then
        XCTAssertEqual(viewModel.state.tagSelection.tags.count, 5)
        XCTAssertEqual(viewModel.state.customTagInput, "독서")
        XCTAssertEqual(viewModel.state.tagError, maxCountMessage)

        // When: 하나를 끄면 안내가 사라진다
        viewModel.send(.selectHashtag(.trip))

        // Then
        XCTAssertNil(viewModel.state.tagError)
    }

    // MARK: GH-136 TC4

    func test_GH136_TC4_같은태그를또입력하거나_기본태그이름을직접쳐도_한번만들어간다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)
        viewModel.send(.selectHashtag(.trip))
        viewModel.send(.inputCustomHashtag("독서"))
        viewModel.send(.submitCustomHashtag)

        // When
        viewModel.send(.inputCustomHashtag("독서"))
        viewModel.send(.submitCustomHashtag)
        viewModel.send(.inputCustomHashtag(HashtagType.trip.description))
        viewModel.send(.submitCustomHashtag)

        // Then
        XCTAssertEqual(viewModel.state.tagSelection.tags, ["trip", "독서"])
        XCTAssertEqual(viewModel.state.customTagInput, "")
    }

    // MARK: GH-136 TC5

    func test_GH136_TC5_수정에서태그하나를빼고저장하면_남은태그만넘긴다() {
        // Given
        let wish = Wish(id: "w", title: "제주", tags: ["trip", "life", "독서"])
        wishRepository.updateWishResult = .success(wish)
        let viewModel = makeViewModel(mode: .edit(wish))

        // When
        viewModel.send(.removeTag("life"))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.updatedWishes.first?.tags, ["trip", "독서"])
    }

    // MARK: GH-136 TC13

    func test_GH136_TC13_태그2개로저장하면_저장클릭로그에tag_count가담긴다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)
        viewModel.send(.selectHashtag(.trip))
        viewModel.send(.selectHashtag(.life))

        // When
        viewModel.send(.tapSave)

        // Then
        let events = clickEvents(objectId: .write)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.extraParameters?[.tagCount] as? Int, 2)
    }

    // MARK: GH-136 TC14

    func test_GH136_TC14_시트에서기본태그를눌러도닫히지않고_확인으로닫으면_치다만글자도태그가된다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)
        viewModel.send(.tapHashtag)

        // When
        viewModel.send(.selectHashtag(.trip))
        viewModel.send(.selectHashtag(.life))

        // Then
        XCTAssertEqual(viewModel.state.sheet, .hashtag)

        // When
        viewModel.send(.inputCustomHashtag("독서"))
        viewModel.send(.dismissSheet)

        // Then
        XCTAssertNil(viewModel.state.sheet)
        XCTAssertEqual(viewModel.state.tagSelection.tags, ["trip", "life", "독서"])
    }

    // MARK: GH-136 TC16

    func test_GH136_TC16_시트를열면_전에쓴태그를추천하고_고른태그는추천에서빠진다() {
        // Given
        wishRepository.recentCustomTagsResult = ["독서", "요리", "캠핑"]
        let viewModel = makeWrite(category: .wantToDo)

        // When
        viewModel.send(.tapHashtag)
        viewModel.send(.selectRecentTag("요리"))

        // Then
        XCTAssertEqual(viewModel.state.tagSelection.tags, ["요리"])
        XCTAssertEqual(viewModel.state.suggestedTags, ["독서", "캠핑"])
    }

    // MARK: GH-136 TC11

    func test_GH136_TC11_두번째태그로도_검색된다() {
        // Given
        let wish = Wish(id: "w", title: "북카페", tags: ["life", "독서"])

        // When
        let byCustom = WishSearchMatcher.matches(wish: wish, keyword: "독서")
        let byTitle = WishSearchMatcher.matches(wish: wish, keyword: "캠핑")

        // Then
        XCTAssertTrue(byCustom)
        XCTAssertFalse(byTitle)
    }
}
