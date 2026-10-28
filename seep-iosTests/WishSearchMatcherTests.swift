import XCTest

@testable import seep_ios

/// 위시 검색 일치 판단·강조 범위 (GH-32 R-3, R-6).
final class WishSearchMatcherTests: XCTestCase {
    private let titleWish = Wish(id: "title", category: .wantToDo, title: "제주도 한 달 살기", hashtag: "trip")
    private let memoWish = Wish(id: "memo", category: .wantToGet, title: "필름 카메라", memo: "제주 가기 전에 사서 연습하기")
    private let hashtagWish = Wish(id: "hashtag", category: .wantToGo, title: "을왕리 바다", hashtag: "trip")
    private let customHashtagWish = Wish(id: "custom", category: .wantToGo, title: "감귤 따기", hashtag: "제주여행")
    private let otherWish = Wish(id: "other", category: .wantToDo, title: "하프 마라톤 완주하기", memo: "10km 먼저", hashtag: "sports")

    private var allWishes: [Wish] {
        return [titleWish, memoWish, hashtagWish, customHashtagWish, otherWish]
    }

    private func matchedIds(_ keyword: String) -> [String] {
        guard let normalized = WishSearchMatcher.normalize(keyword) else { return [] }
        return allWishes
            .filter { WishSearchMatcher.matches(wish: $0, keyword: normalized) }
            .map(\.id)
    }

    // MARK: GH-32 TC1

    func test_GH32_TC1_제주를검색하면_제목메모해시태그중하나에제주가있는위시만일치한다() {
        // Given
        // allWishes: 제목·메모·직접 입력 해시태그에 "제주", 나머지는 없음

        // When
        let ids = matchedIds("제주")

        // Then
        XCTAssertEqual(ids, ["title", "memo", "custom"])
    }

    // MARK: GH-32 TC2

    func test_GH32_TC2_해시태그표시이름으로검색하면_해당위시가일치한다() {
        // Given
        // hashtagWish 의 해시태그 저장값은 trip, 표시 이름은 "여행"

        // When
        let ids = matchedIds("여행")

        // Then
        XCTAssertTrue(ids.contains("hashtag"))
        XCTAssertTrue(ids.contains("title"))
        XCTAssertFalse(ids.contains("other"))
    }

    // MARK: GH-32 TC3

    func test_GH32_TC3_메모에만검색어가있으면_메모한줄과일치범위를돌려준다() {
        // Given
        let keyword = "제주"

        // When
        let snippet = WishSearchMatcher.memoSnippet(wish: memoWish, keyword: keyword)

        // Then
        XCTAssertEqual(snippet?.text, "제주 가기 전에 사서 연습하기")
        XCTAssertEqual(snippet?.highlightRange, NSRange(location: 0, length: 2))
    }

    func test_GH32_TC3_제목에서찾으면_메모줄없이제목을강조한다() {
        // Given
        let wish = Wish(title: "제주도 한 달 살기", memo: "제주 숙소 알아보기")

        // When
        let snippet = WishSearchMatcher.memoSnippet(wish: wish, keyword: "제주")
        let titleRange = WishSearchMatcher.titleHighlightRange(title: wish.title, keyword: "제주")

        // Then
        XCTAssertNil(snippet)
        XCTAssertEqual(titleRange, NSRange(location: 0, length: 2))
    }

    func test_GH32_TC3_메모뒤쪽에서찾으면_앞을줄여일치글자가보이게한다() {
        // Given
        let wish = Wish(title: "카메라", memo: "언젠가 시간이 나면 꼭 제주 가서 찍기\n둘째 줄")

        // When
        let snippet = WishSearchMatcher.memoSnippet(wish: wish, keyword: "제주")

        // Then
        XCTAssertEqual(snippet?.text, "…나면 꼭 제주 가서 찍기 둘째 줄")
        if let snippet {
            XCTAssertEqual((snippet.text as NSString).substring(with: snippet.highlightRange), "제주")
        }
    }

    // MARK: GH-32 TC4

    func test_GH32_TC4_대소문자와앞뒤공백이달라도_같은위시가일치한다() {
        // Given
        let wish = Wish(title: "Nike 운동화")

        // When
        let results = ["nike", "  NIKE  ", "Nike"].map { keyword -> Bool in
            guard let normalized = WishSearchMatcher.normalize(keyword) else { return false }
            return WishSearchMatcher.matches(wish: wish, keyword: normalized)
        }

        // Then
        XCTAssertEqual(results, [true, true, true])
        XCTAssertEqual(WishSearchMatcher.normalize("  NIKE  "), "NIKE")
    }

    // MARK: GH-32 TC5

    func test_GH32_TC5_공백만입력하면_검색어가없다() {
        // Given
        let keyword = "   \n "

        // When
        let normalized = WishSearchMatcher.normalize(keyword)

        // Then
        XCTAssertNil(normalized)
    }
}
