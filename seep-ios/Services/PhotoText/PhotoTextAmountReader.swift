import Foundation

/// 글자 한 줄에서 가격을 읽는다 (GH-144 R-2). 통화는 GH-103 통화 목록 안에서만.
/// 한 줄의 금액마다 뜻(가격 / 정가 / 할인·배송비 같은 가격 아닌 금액)을 앞뒤 낱말로 가르고, 가격 → 정가 순으로 마지막 것을 고른다
enum PhotoTextAmountReader {
    struct Reading: Equatable {
        /// 통화가 붙은 숫자가 하나라도 있다. 이런 줄은 제목 후보가 아니다
        var isAmountLine = false
        var amount: PhotoTextAmount?
    }

    private enum Role {
        case price
        case listPrice
        case nonPrice
    }

    /// 금액 바로 뒤에 오면 그 금액은 가격이 아니다("10,000원 할인", "₩1,000 적립", "$5 off")
    private static let nonPriceNextWords = [
        "할인", "쿠폰", "적립", "포인트", "캐시백", "절약",
        "off", "coupon", "discount", "points", "cashback",
        "割引", "引き", "クーポン", "ポイント", "优惠", "優惠", "积分", "積分"
    ]
    /// 금액 바로 앞 낱말에 들어 있으면 가격이 아니다("배송비 3,000원")
    private static let nonPricePreviousWords = [
        "배송비", "적립", "포인트", "캐시백", "shipping", "points", "cashback", "送料", "运费", "運費", "积分", "積分", "ポイント"
    ]
    /// 금액 바로 앞 낱말이 이것뿐이면 할인 금액이다("쿠폰 3,000원", "Save $5"). "23% 할인 69,000원"처럼 %가 앞에 있으면 가격
    private static let discountPreviousWords = ["할인", "쿠폰", "save", "discount", "coupon", "割引", "优惠", "優惠"]
    /// 금액 바로 앞 낱말이 이것이면 정가다. 같은 줄에 다른 가격이 있으면 그쪽을 고른다("$49.99 List: $59.99")
    private static let listPriceWords = ["정가", "원가", "list", "was", "msrp", "rrp", "定価", "通常価格", "原价", "原價"]

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

    static func read(_ text: String, currentCurrency: String) -> Reading {
        var found: [(amount: PhotoTextAmount, role: Role)] = []
        var isAmountLine = false

        // "89만원", "12.5만원", "1만 2천원" — 원화를 만·천·억으로 쓴 가격
        var koreanRanges: [Range<String.Index>] = []
        for match in text.matches(of: #/([0-9]+(?:[.,][0-9]+)*)\s*(억|만|천)(?:\s*([0-9]+(?:[.,][0-9]+)*)\s*(만|천))?\s*원/#) {
            koreanRanges.append(match.range)
            isAmountLine = true
            var total = Decimal(0)
            let parts: [(number: Substring?, unit: Substring?)] = [(match.output.1, match.output.2), (match.output.3, match.output.4)]
            for (number, unit) in parts {
                guard let number, let unit, let value = decimal(String(number)) else { continue }
                total += value * unitValue(String(unit))
            }
            guard let amount = validAmount(total) else { continue }
            let role = role(before: String(text[..<match.range.lowerBound]), after: String(text[match.range.upperBound...]))
            found.append((PhotoTextAmount(amount: amount, currency: AmountFormatter.krw), role))
        }

        // "89,000", "12.99", "1.299,00", "3000". Swift 5 모드라 확장 구분자 리터럴을 쓴다
        for match in text.matches(of: #/[0-9]+(?:[.,][0-9]+)*/#) where !koreanRanges.contains(where: { $0.overlaps(match.range) }) {
            let number = String(text[match.range])
            let before = String(text[..<match.range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let after = String(text[match.range.upperBound...]).trimmingCharacters(in: .whitespaces)
            var context = (before: before, after: after)
            let currency: String
            if let prefix = prefixCurrency(before, current: currentCurrency) {
                currency = prefix.currency
                context.before = String(before.dropLast(prefix.markerLength))
            } else if let suffix = suffixCurrency(after, number: number, current: currentCurrency) {
                currency = suffix.currency
                context.after = String(after.dropFirst(suffix.markerLength))
            } else {
                // "R$ 1.299,00"처럼 모르는 통화 기호가 붙은 줄도 금액 줄이다 — 제목으로 내지 않는다
                if before.hasSuffix("$") { isAmountLine = true }
                continue
            }
            isAmountLine = true
            guard AmountFormatter.supportedCurrencies.contains(currency),
                  let minor = minorUnits(number, currency: currency) else { continue }
            let amountRole = role(before: context.before, after: context.after)
            found.append((PhotoTextAmount(amount: minor, currency: currency), amountRole))
        }

        let price = found.last { $0.role == .price }
        let listPrice = found.last { $0.role == .listPrice }
        return Reading(isAmountLine: isAmountLine, amount: (price ?? listPrice)?.amount)
    }

    // MARK: 뜻 가르기

    /// `before`·`after`는 통화 기호를 뺀 금액 앞뒤 글자
    private static func role(before: String, after: String) -> Role {
        let previous = before.trimmingCharacters(in: .whitespaces)
        // "쿠폰 -3,000원", "-₩3,000"
        if previous.hasSuffix("-") || previous.hasSuffix("−") { return .nonPrice }
        let previousWord = previous.split(whereSeparator: \.isWhitespace).last
            .map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) } ?? ""
        let nextWord = after.trimmingCharacters(in: .whitespaces).split(whereSeparator: \.isWhitespace).first
            .map { $0.lowercased() } ?? ""
        if nonPriceNextWords.contains(where: nextWord.hasPrefix) { return .nonPrice }
        if nonPricePreviousWords.contains(where: previousWord.contains) { return .nonPrice }
        if discountPreviousWords.contains(previousWord), !previous.contains("%") { return .nonPrice }
        if listPriceWords.contains(previousWord) { return .listPrice }
        return .price
    }

    // MARK: 통화

    private static func prefixCurrency(_ before: String, current: String) -> (currency: String, markerLength: Int)? {
        if let code = isoCode(at: before.suffix(3)), !(before.dropLast(3).last?.isLetter ?? false) {
            return (code, 3)
        }
        guard let marker = prefixMarkers.first(where: { before.hasSuffix($0.marker) }) else { return nil }
        // "R$", "NZ$", "MX$"처럼 모르는 달러는 미국 달러로 읽지 않는다
        if marker.marker == "$", before.dropLast().last?.isLetter ?? false { return nil }
        return (marker.currency.resolve(current: current), marker.marker.count)
    }

    /// 숫자 뒤 말은 낱말이 거기서 끝나야 통화다("1+1 원두커피"의 "원"은 아니다).
    /// 다만 "89,000원부터", "299元起"처럼 가격다운 숫자(구분자가 있거나 세 자리 이상)는 뒤에 말이 붙어도 받는다
    private static func suffixCurrency(_ after: String, number: String, current: String) -> (currency: String, markerLength: Int)? {
        if let code = isoCode(at: after.prefix(3)), !(after.dropFirst(3).first?.isLetter ?? false) {
            return (code, 3)
        }
        guard let marker = suffixMarkers.first(where: { after.hasPrefix($0.marker) }) else { return nil }
        let endsWord = !(after.dropFirst(marker.marker.count).first?.isLetter ?? false)
        let looksLikePrice = number.contains { $0 == "," || $0 == "." } || number.count >= 3
        guard endsWord || looksLikePrice else { return nil }
        return (marker.currency.resolve(current: current), marker.marker.count)
    }

    private static func isoCode(at text: Substring) -> String? {
        let code = text.uppercased()
        return text.count == 3 && AmountFormatter.supportedCurrencies.contains(code) ? code : nil
    }

    // MARK: 숫자

    /// 숫자 문자열 → 통화 최소 단위. 마지막 구분자 뒤가 1~2자리면 소수점, 3자리면 천 단위 구분으로 본다
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
        guard integerDigits.count <= 12, let integer = Int(integerDigits),
              let fraction = Int(paddedFraction.isEmpty ? "0" : paddedFraction) else { return nil }
        let scale = Int(pow(10, Double(digits)))
        return validAmount(Decimal(integer * scale + fraction))
    }

    /// "12.5" → 12.5, "1,200" → 1200 (만·천 앞 숫자)
    private static func decimal(_ number: String) -> Decimal? {
        guard number.count <= 12 else { return nil }
        return Decimal(string: number.replacingOccurrences(of: ",", with: ""), locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func unitValue(_ unit: String) -> Decimal {
        switch unit {
        case "억": return 100_000_000
        case "만": return 10_000
        default: return 1_000
        }
    }

    /// 0 이거나 상한(`WishSaving.maxAmount`)을 넘으면 후보가 아니다
    private static func validAmount(_ value: Decimal) -> Int? {
        var value = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 0, .plain)
        let amount = NSDecimalNumber(decimal: rounded).intValue
        guard rounded > 0, rounded <= Decimal(WishSaving.maxAmount) else { return nil }
        return amount
    }
}
