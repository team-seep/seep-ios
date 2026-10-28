import Foundation

/// 원화 금액 입력·표시 (GH-16 R-2·R-4). 천 단위 구분, 상한 `WishSaving.maxAmount`.
/// 통화는 원화 그대로이고, 천 단위 구분자만 로케일을 따른다 (GH-100 R-13)
enum AmountFormatter {
    /// 769000 → "769,000" (한국어·영어), "769.000" (독일어)
    static func string(from amount: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: amount)) ?? String(amount)
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
}
