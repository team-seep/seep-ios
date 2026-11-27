import Foundation

/// 사진에서 읽은 글자 한 줄 (GH-144). `height`는 사진 높이에 대한 글자 상자 높이 — 클수록 큰 글자다
struct RecognizedTextLine: Equatable {
    let text: String
    let height: Double
}

/// 사진 속 글자에서 찾은 목표 금액. `amount`는 통화의 최소 단위(원·센트·엔)
struct PhotoTextAmount: Equatable {
    let amount: Int
    let currency: String
}

/// 사진 속 글자로 채울 수 있는 제목·금액 후보 (GH-144 R-2)
struct PhotoTextSuggestion: Equatable {
    var titles: [String] = []
    var amount: PhotoTextAmount?

    var isEmpty: Bool { titles.isEmpty && amount == nil }
}

/// 인식한 글자 줄에서 제목·금액 후보를 고른다 (GH-144 R-2). Vision 과 떼어 둔 순수 함수라 유닛 테스트로 규칙을 고정한다
enum PhotoTextSuggester {
    static let maxTitleCount = 2
    static let titleLengthRange = 2...40

    /// 상품·지도 화면에 흔한 UI 문구. 이 말이 들어간 줄은 제목 후보가 아니다.
    /// 상품 이름에도 흔히 들어가는 말("저장용기", "공유기", "전화기")은 넣지 않는다
    static let uiPhrases: [String] = [
        // ko — 글자 안 어디든 들어 있으면 뺀다
        "장바구니", "구매", "리뷰", "후기", "배송", "쿠폰", "할인", "적립", "포인트", "찜하기", "좋아요", "팔로우",
        "더보기", "문의", "결제", "주문하기", "판매자", "오늘출발", "별점", "평점", "상품정보", "무이자", "로그인",
        "선물하기", "품절", "길찾기",
        // ja · zh
        "カート", "購入", "レビュー", "送料", "配送", "クーポン",
        "购物车", "購物車", "购买", "購買", "评价", "評價", "包邮", "优惠", "優惠"
    ]

    /// 영어 UI 문구. 낱말 단위로만 맞춘다("Preview"는 "review"가 아니다)
    static let uiWordPhrases: [String] = [
        "add to cart", "add to bag", "buy now", "shipping", "delivery", "reviews", "review", "ratings", "coupon",
        "checkout", "wishlist", "sign in", "sponsored", "in stock", "sold out", "directions", "follow"
    ]

    static func suggest(lines: [RecognizedTextLine], currentCurrency: String) -> PhotoTextSuggestion {
        // 큰 글자부터. 높이가 같으면 사진 위쪽(먼저 읽은 줄)부터
        let ordered = lines.enumerated()
            .sorted { lhs, rhs in
                lhs.element.height != rhs.element.height
                    ? lhs.element.height > rhs.element.height
                    : lhs.offset < rhs.offset
            }
            .map(\.element)

        var titles: [String] = []
        var seenKeys: Set<String> = []
        var amount: PhotoTextAmount?
        for line in ordered {
            let text = normalized(line.text)
            // 금액이 있는 줄은 제목 후보가 아니다. 할인·배송비만 있는 줄은 금액 후보도 아니다
            let reading = PhotoTextAmountReader.read(text, currentCurrency: currentCurrency)
            if reading.isAmountLine {
                if amount == nil { amount = reading.amount }
                continue
            }
            guard titles.count < maxTitleCount, isTitleCandidate(text) else { continue }
            let key = text.lowercased().filter { !$0.isWhitespace }
            guard seenKeys.insert(key).inserted else { continue }
            titles.append(text)
        }
        return PhotoTextSuggestion(titles: titles, amount: amount)
    }

    /// 통화 표시와 숫자가 함께 있는 줄에서 금액을 읽는다 (R-2). 규칙은 `PhotoTextAmountReader`
    static func amount(in text: String, currentCurrency: String) -> PhotoTextAmount? {
        PhotoTextAmountReader.read(text, currentCurrency: currentCurrency).amount
    }

    // MARK: 제목

    private static func normalized(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static func isTitleCandidate(_ text: String) -> Bool {
        guard titleLengthRange.contains(text.count), text.contains(where: \.isLetter) else { return false }
        return !containsAny(text, uiPhrases) && !containsWords(text, uiWordPhrases)
    }

    private static func containsAny(_ text: String, _ phrases: [String]) -> Bool {
        let lowered = text.lowercased()
        return phrases.contains { lowered.contains($0) }
    }

    /// 글자가 아닌 것으로 끊어 낱말 단위로 맞춘다
    private static func containsWords(_ text: String, _ phrases: [String]) -> Bool {
        let words = " " + text.lowercased().split { !$0.isLetter }.joined(separator: " ") + " "
        return phrases.contains { words.contains(" \($0) ") }
    }
}
