import XCTest

@testable import seep_ios

/// 사진 속 글자에서 제목·금액 후보 고르기 (GH-144 R-2)
final class PhotoTextSuggesterTests: XCTestCase {
    private func line(_ text: String, _ height: Double) -> RecognizedTextLine {
        RecognizedTextLine(text: text, height: height)
    }

    // MARK: GH-144 TC1

    func test_GH144_TC1_상품스크린샷줄에서_UI문구를빼고_제목과금액을고른다() {
        // Given
        let lines = [
            line("무료배송 · 오늘출발", 11),
            line("접이식 캠핑 체어 L", 15),
            line("89,000원", 18),
            line("장바구니", 12)
        ]

        // When
        let suggestion = PhotoTextSuggester.suggest(lines: lines, currentCurrency: "KRW")

        // Then
        XCTAssertEqual(suggestion.titles, ["접이식 캠핑 체어 L"])
        XCTAssertEqual(suggestion.amount, PhotoTextAmount(amount: 89_000, currency: "KRW"))
    }

    func test_GH144_TC1_제목후보는_큰글자순으로_최대2개이고_같은줄은하나만() {
        // Given
        let lines = [
            line("캠핑 체어", 13),
            line("접이식 캠핑 체어 L", 15),
            line("접이식  캠핑 체어 l", 14),
            line("경량 알루미늄", 12)
        ]

        // When
        let suggestion = PhotoTextSuggester.suggest(lines: lines, currentCurrency: "KRW")

        // Then
        XCTAssertEqual(suggestion.titles, ["접이식 캠핑 체어 L", "캠핑 체어"])
        XCTAssertNil(suggestion.amount)
    }

    func test_GH144_TC1_금액이여러개면_글자가가장큰것을고른다() {
        // Given
        let lines = [line("정가 99,000원", 11), line("69,000원", 20), line("₩1,000 적립", 10)]

        // When
        let suggestion = PhotoTextSuggester.suggest(lines: lines, currentCurrency: "KRW")

        // Then
        XCTAssertEqual(suggestion.amount, PhotoTextAmount(amount: 69_000, currency: "KRW"))
        XCTAssertEqual(suggestion.titles, [])
    }

    // MARK: GH-144 TC2

    func test_GH144_TC2_숫자기호만있는줄과_1자41자줄은_제목후보가아니다() {
        // Given
        let lines = [
            line("9:41", 30),
            line("1,204 · 4.8", 25),
            line("★", 24),
            line("가", 22),
            line(String(repeating: "가", count: 41), 21),
            line(String(repeating: "나", count: 40), 10)
        ]

        // When
        let suggestion = PhotoTextSuggester.suggest(lines: lines, currentCurrency: "KRW")

        // Then
        XCTAssertEqual(suggestion.titles, [String(repeating: "나", count: 40)])
    }

    func test_GH144_TC2_찾은글자가없으면_빈제안이다() {
        XCTAssertTrue(PhotoTextSuggester.suggest(lines: [], currentCurrency: "KRW").isEmpty)
        XCTAssertTrue(PhotoTextSuggester.suggest(lines: [line("구매하기", 20)], currentCurrency: "KRW").isEmpty)
    }

    // MARK: GH-144 TC3

    func test_GH144_TC3_통화기호와숫자를_통화최소단위로읽는다() {
        XCTAssertEqual(PhotoTextSuggester.amount(in: "$12.99", currentCurrency: "KRW"), PhotoTextAmount(amount: 1_299, currency: "USD"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "₩89,000", currentCurrency: "KRW"), PhotoTextAmount(amount: 89_000, currency: "KRW"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "3,000円", currentCurrency: "KRW"), PhotoTextAmount(amount: 3_000, currency: "JPY"))
    }

    func test_GH144_TC3_통화코드와_유럽식소수점과_천단위구분을읽는다() {
        XCTAssertEqual(PhotoTextSuggester.amount(in: "USD 1,299.00", currentCurrency: "KRW"), PhotoTextAmount(amount: 129_900, currency: "USD"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "12,99 €", currentCurrency: "KRW"), PhotoTextAmount(amount: 1_299, currency: "EUR"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "£20", currentCurrency: "KRW"), PhotoTextAmount(amount: 2_000, currency: "GBP"))
    }

    func test_GH144_TC3_여러통화가쓰는기호는_지금통화가그중하나면그통화로읽는다() {
        XCTAssertEqual(PhotoTextSuggester.amount(in: "$15", currentCurrency: "CAD"), PhotoTextAmount(amount: 1_500, currency: "CAD"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "¥128", currentCurrency: "CNY"), PhotoTextAmount(amount: 12_800, currency: "CNY"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "¥128", currentCurrency: "KRW"), PhotoTextAmount(amount: 128, currency: "JPY"))
    }

    func test_GH144_TC3_통화표시가없거나_0이거나_상한을넘으면_금액이아니다() {
        XCTAssertNil(PhotoTextSuggester.amount(in: "리뷰 1,204", currentCurrency: "KRW"))
        XCTAssertNil(PhotoTextSuggester.amount(in: "20% 할인", currentCurrency: "KRW"))
        XCTAssertNil(PhotoTextSuggester.amount(in: "0원", currentCurrency: "KRW"))
        XCTAssertNil(PhotoTextSuggester.amount(in: "1,000,000,000원", currentCurrency: "KRW"))
        XCTAssertNil(PhotoTextSuggester.amount(in: "₹500", currentCurrency: "KRW"))
    }
}
