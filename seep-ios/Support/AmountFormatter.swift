import Foundation

/// 금액 입력·표시 (GH-16 R-2·R-4). 천 단위 구분, 상한 `WishSaving.maxAmount`.
/// 금액은 통화의 최소 단위(원·센트·엔) 정수로 다룬다. 통화는 위시마다 정한다 (GH-103 R-13~R-17)
enum AmountFormatter {
    static let krw = "KRW"

    /// 고를 수 있는 통화. 기기 지역 통화가 여기 없으면 원화로 시작한다 (R-15)
    static let supportedCurrencies = ["KRW", "USD", "EUR", "JPY", "CNY", "TWD", "HKD", "GBP", "CAD", "AUD", "SGD"]

    /// 새로 적는 위시의 기본 통화 (R-15)
    static func defaultCurrency(locale: Locale = .current) -> String {
        guard let code = locale.currency?.identifier, supportedCurrencies.contains(code) else { return krw }
        return code
    }

    /// 소수 자릿수. KRW·JPY 0, USD·EUR 2
    static func fractionDigits(_ currency: String) -> Int {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.maximumFractionDigits
    }

    /// 769000 → "769,000" (한국어·영어), "769.000" (독일어)
    static func string(from amount: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: amount)) ?? String(amount)
    }

    /// 최소 단위 금액을 통화 표기로. 한국어 원화는 지금처럼 "769,000원", 그 밖은 "$12.50", "₩769,000" (R-16, TC-13)
    static func money(_ amount: Int, currency: String, locale: Locale = .current) -> String {
        if currency == krw, locale.language.languageCode == .korean {
            return Strings.Common.wonFormat(string(from: amount, locale: locale))
        }
        let digits = fractionDigits(currency)
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        // 소수점 아래가 0 이면 줄여 쓴다($12, $12.50)
        formatter.minimumFractionDigits = amount % pow10(digits) == 0 ? 0 : digits
        let value = NSDecimalNumber(value: amount).multiplying(byPowerOf10: Int16(-digits))
        return formatter.string(from: value) ?? String(amount)
    }

    /// 입력 칸 옆 단위. 한국어 원화는 "원", 그 밖은 통화 기호
    static func unit(currency: String, locale: Locale = .current) -> String {
        if currency == krw, locale.language.languageCode == .korean {
            return Strings.Common.wonUnit
        }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.currencySymbol
    }

    /// 입력 문자열에서 숫자만 읽는다. 상한을 넘게 만드는 뒤쪽 자릿수는 버린다(입력되지 않은 것처럼).
    static func amount(from text: String?) -> Int {
        var amount = 0
        for character in text ?? "" {
            guard character.isASCII, let digit = character.wholeNumberValue else { continue }
            let next = amount * 10 + digit
            guard next <= WishSaving.maxAmount else { break }
            amount = next
        }
        return amount
    }

    /// 입력 칸에 다시 써 줄 문자열. 0 이면 비워서 placeholder 가 보이게 한다.
    static func inputText(from amount: Int) -> String {
        return amount > 0 ? string(from: amount) : ""
    }

    /// 사용자가 친 문자열 → (칸에 다시 보일 문자열, 최소 단위 금액).
    /// 소수가 없는 통화는 지금처럼 콤마를 넣어 다시 쓰고, 소수가 있는 통화는 치는 중인 소수점("12.")을 지우지 않는다 (R-17, TC-12)
    static func input(_ text: String, currency: String, locale: Locale = .current) -> (text: String, amount: Int) {
        let digits = fractionDigits(currency)
        guard digits > 0 else {
            let amount = amount(from: text)
            return (inputText(from: amount), amount)
        }
        let separator = locale.decimalSeparator ?? "."
        // 키보드에 따라 "." 이나 "," 가 들어오므로 둘 다 소수점으로 받는다
        let normalized = text.replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: separator, with: ".")
        let parts = normalized.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integerDigits = String((parts.first ?? "").filter { $0.isASCII && $0.isNumber }.drop { $0 == "0" })
        let fraction = parts.count > 1 ? String(parts[1].filter { $0.isASCII && $0.isNumber }.prefix(digits)) : nil

        let integer = Int(integerDigits.isEmpty ? "0" : integerDigits) ?? 0
        let fractionValue = Int((fraction ?? "").padding(toLength: digits, withPad: "0", startingAt: 0)) ?? 0
        let total = integer.multipliedReportingOverflow(by: pow10(digits))
        guard !total.overflow, total.partialValue + fractionValue <= WishSaving.maxAmount else {
            // 상한을 넘기는 입력은 받지 않는다
            return input(String(text.dropLast()), currency: currency, locale: locale)
        }
        var shown = integerDigits.isEmpty && fraction != nil ? "0" : integerDigits
        if let fraction { shown += separator + fraction }
        return (shown, total.partialValue + fractionValue)
    }

    /// 저장된 금액을 입력 칸에 처음 보일 문자열로 (수정 화면). 0 이면 빈 문자열
    static func inputText(from amount: Int, currency: String, locale: Locale = .current) -> String {
        guard amount > 0 else { return "" }
        let digits = fractionDigits(currency)
        guard digits > 0 else { return inputText(from: amount) }
        let integer = amount / pow10(digits)
        let fraction = amount % pow10(digits)
        guard fraction > 0 else { return String(integer) }
        let fractionText = String(fraction).leftPadded(to: digits)
        return "\(integer)\(locale.decimalSeparator ?? ".")\(fractionText)"
    }

    /// 저금 시트의 빠른 금액(최소 단위). 원화는 1만·5만·10만 (GH-16), 그 밖은 통화 크기에 맞춘 10·50·100 단위
    static func quickAmounts(currency: String) -> [Int] {
        switch currency {
        case krw:
            return [10_000, 50_000, 100_000]
        case "JPY":
            return [1_000, 5_000, 10_000]
        case "CNY", "TWD", "HKD":
            return [100, 500, 1_000].map { $0 * pow10(fractionDigits(currency)) }
        default:
            return [10, 50, 100].map { $0 * pow10(fractionDigits(currency)) }
        }
    }

    private static func pow10(_ exponent: Int) -> Int {
        (0..<exponent).reduce(1) { value, _ in value * 10 }
    }
}

private extension String {
    func leftPadded(to length: Int) -> String {
        count >= length ? self : String(repeating: "0", count: length - count) + self
    }
}
