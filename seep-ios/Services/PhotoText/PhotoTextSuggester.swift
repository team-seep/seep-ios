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

    /// 할인·쿠폰·배송비·적립 금액 줄. 진짜 가격이 아니라 금액 후보에서 뺀다
    static let nonPriceAmountPhrases: [String] = [
        "할인", "쿠폰", "적립", "포인트", "배송비", "절약", "캐시백",
        "coupon", "shipping", "discount", "points", "cashback",
        "割引", "クーポン", "送料", "ポイント", "优惠", "優惠", "运费", "運費", "积分", "積分"
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
            if let found = self.amount(in: text, currentCurrency: currentCurrency) {
                if amount == nil, !containsAny(text, nonPriceAmountPhrases) { amount = found }
                continue
            }
            guard titles.count < maxTitleCount, isTitleCandidate(text) else { continue }
            let key = text.lowercased().filter { !$0.isWhitespace }
            guard seenKeys.insert(key).inserted else { continue }
            titles.append(text)
        }
        return PhotoTextSuggestion(titles: titles, amount: amount)
    }

    /// 통화 표시와 숫자가 함께 있는 줄에서 금액을 읽는다 (R-2). 통화는 GH-103 통화 목록 안에서만.
    /// 한 줄에 금액이 여럿이면 마지막 것 — "정가 99,000원 → 69,000원", "Save $5 — now $49.99"는 뒤가 내는 값이다
    static func amount(in text: String, currentCurrency: String) -> PhotoTextAmount? {
        var found: PhotoTextAmount?
        // "89,000", "12.99", "1.299,00", "3000". Swift 5 모드라 확장 구분자 리터럴을 쓴다
        for match in text.matches(of: #/[0-9]+(?:[.,][0-9]+)*/#) {
            let number = String(text[match.range])
            let before = text[..<match.range.lowerBound].trimmingCharacters(in: .whitespaces)
            let after = text[match.range.upperBound...].trimmingCharacters(in: .whitespaces)
            guard let currency = prefixCurrency(before, current: currentCurrency)
                    ?? suffixCurrency(after, number: number, current: currentCurrency),
                  AmountFormatter.supportedCurrencies.contains(currency),
                  let minor = minorUnits(number, currency: currency) else { continue }
            found = PhotoTextAmount(amount: minor, currency: currency)
        }
        return found
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

    // MARK: 금액

    /// 숫자 앞에 붙는 기호. 긴 것부터 맞춘다("US$"가 "$"보다 먼저)
    private static let prefixMarkers: [(marker: String, currency: Ambiguity)] = [
        ("US$", .fixed("USD")), ("NT$", .fixed("TWD")), ("HK$", .fixed("HKD")), ("CA$", .fixed("CAD")),
        ("AU$", .fixed("AUD")), ("C$", .fixed("CAD")), ("A$", .fixed("AUD")), ("S$", .fixed("SGD")),
        ("$", .dollar), ("₩", .fixed("KRW")), ("￦", .fixed("KRW")), ("€", .fixed("EUR")), ("£", .fixed("GBP")),
        ("¥", .yen), ("￥", .yen)
    ]

    /// 숫자 뒤에 붙는 말
    private static let suffixMarkers: [(marker: String, currency: Ambiguity)] = [
        ("원", .fixed("KRW")), ("円", .fixed("JPY")), ("엔", .fixed("JPY")), ("元", .yuan), ("위안", .fixed("CNY")),
        ("달러", .dollar), ("유로", .fixed("EUR")), ("€", .fixed("EUR")), ("$", .dollar), ("£", .fixed("GBP"))
    ]

    /// 여러 통화가 같이 쓰는 기호는 지금 목표 금액 통화가 그중 하나면 그 통화로 읽는다
    private enum Ambiguity {
        case fixed(String)
        case dollar
        case yen
        case yuan

        func resolve(current: String) -> String {
            switch self {
            case .fixed(let code): return code
            case .dollar: return ["USD", "CAD", "AUD", "SGD", "HKD", "TWD"].contains(current) ? current : "USD"
            case .yen: return current == "CNY" ? "CNY" : "JPY"
            case .yuan: return ["CNY", "TWD", "HKD"].contains(current) ? current : "CNY"
            }
        }
    }

    private static func prefixCurrency(_ before: String, current: String) -> String? {
        if let code = isoCode(at: before.suffix(3)), !(before.dropLast(3).last?.isLetter ?? false) {
            return code
        }
        return prefixMarkers.first { before.hasSuffix($0.marker) }?.currency.resolve(current: current)
    }

    /// 숫자 뒤 말은 낱말이 거기서 끝나야 통화다("1+1 원두커피"의 "원"은 아니다).
    /// 다만 "89,000원부터", "299元起"처럼 가격다운 숫자(구분자가 있거나 세 자리 이상)는 뒤에 말이 붙어도 받는다
    private static func suffixCurrency(_ after: String, number: String, current: String) -> String? {
        if let code = isoCode(at: after.prefix(3)), !(after.dropFirst(3).first?.isLetter ?? false) {
            return code
        }
        guard let marker = suffixMarkers.first(where: { after.hasPrefix($0.marker) }) else { return nil }
        let endsWord = !(after.dropFirst(marker.marker.count).first?.isLetter ?? false)
        let looksLikePrice = number.contains { $0 == "," || $0 == "." } || number.count >= 3
        guard endsWord || looksLikePrice else { return nil }
        return marker.currency.resolve(current: current)
    }

    private static func isoCode(at text: Substring) -> String? {
        let code = text.uppercased()
        return text.count == 3 && AmountFormatter.supportedCurrencies.contains(code) ? code : nil
    }

    /// 숫자 문자열 → 통화 최소 단위. 마지막 구분자 뒤가 1~2자리면 소수점, 3자리면 천 단위 구분으로 본다.
    /// 0 이거나 상한(`WishSaving.maxAmount`)을 넘으면 후보가 아니다
    private static func minorUnits(_ number: String, currency: String) -> Int? {
        var integerText = Substring(number)
        var fractionText: Substring = ""
        if let separator = number.lastIndex(where: { $0 == "," || $0 == "." }) {
            let tail = number[number.index(after: separator)...]
            if tail.count <= 2 {
                integerText = number[..<separator]
                fractionText = tail
            }
        }
        let digits = AmountFormatter.fractionDigits(currency)
        let integerDigits = integerText.filter { $0 != "," && $0 != "." }
        let paddedFraction = String(fractionText.prefix(digits)).padding(toLength: digits, withPad: "0", startingAt: 0)
        guard integerDigits.count <= 12, let integer = Int(integerDigits), let fraction = Int(paddedFraction.isEmpty ? "0" : paddedFraction) else {
            return nil
        }
        let scale = Int(pow(10, Double(digits)))
        let total = integer * scale + fraction
        guard total > 0, total <= WishSaving.maxAmount else { return nil }
        return total
    }
}
