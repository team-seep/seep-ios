import Foundation

/// 위시 검색의 일치 판단·강조 범위 계산 (GH-32 R-3, R-6). Realm 없이 테스트할 수 있게 순수 함수로 둔다.
enum WishSearchMatcher {
    /// 메모 줄에서 일치 글자 앞에 남겨 둘 글자 수. 이보다 뒤에서 일치하면 앞을 `…`로 줄인다
    static let memoLeadingContextLength = 6

    private static let compareOptions: String.CompareOptions = [.caseInsensitive]

    /// 앞뒤 공백을 지운 검색어. 비어 있으면(공백만 입력) nil — 검색하지 않는다
    static func normalize(_ keyword: String) -> String? {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// 제목·메모·해시태그(저장값과 표시 이름) 중 하나에 검색어가 들어 있으면 true. `keyword`는 normalize 된 값이다
    static func matches(wish: Wish, keyword: String) -> Bool {
        return contains(wish.title, keyword)
            || contains(wish.memo, keyword)
            || hashtagTexts(wish.hashtag).contains { contains($0, keyword) }
    }

    /// 제목에서 처음 일치한 범위. 없으면 nil
    static func titleHighlightRange(title: String, keyword: String) -> NSRange? {
        guard let range = title.range(of: keyword, options: compareOptions) else { return nil }
        return NSRange(range, in: title)
    }

    /// 제목이 아니라 메모에서만 찾았을 때 셀에 보여줄 메모 한 줄과 그 안의 일치 범위
    static func memoSnippet(wish: Wish, keyword: String) -> WishSearchMemoSnippet? {
        guard titleHighlightRange(title: wish.title, keyword: keyword) == nil else { return nil }

        // 셀에서 한 줄로 보여주므로 줄바꿈은 공백으로 바꾼다
        let memo = wish.memo.components(separatedBy: .newlines).joined(separator: " ")
        guard let range = memo.range(of: keyword, options: compareOptions) else { return nil }

        let leadingCount = memo.distance(from: memo.startIndex, to: range.lowerBound)
        guard leadingCount > memoLeadingContextLength else {
            return WishSearchMemoSnippet(text: memo, highlightRange: NSRange(range, in: memo))
        }

        // 일치 위치가 뒤쪽이면 꼬리 말줄임에 가려지지 않게 앞을 줄인다
        let start = memo.index(range.lowerBound, offsetBy: -memoLeadingContextLength)
        let tail = memo[start...].drop { $0.isWhitespace }
        let text = "…" + tail
        guard let highlight = text.range(of: keyword, options: compareOptions) else { return nil }
        return WishSearchMemoSnippet(text: text, highlightRange: NSRange(highlight, in: text))
    }

    private static func contains(_ text: String, _ keyword: String) -> Bool {
        return text.range(of: keyword, options: compareOptions) != nil
    }

    private static func hashtagTexts(_ hashtag: String) -> [String] {
        guard !hashtag.isEmpty else { return [] }
        guard let type = HashtagType(rawValue: hashtag) else { return [hashtag] }
        return [hashtag, type.description]
    }
}

struct WishSearchMemoSnippet: Equatable {
    let text: String
    /// `text` 기준 일치 범위
    let highlightRange: NSRange
}
