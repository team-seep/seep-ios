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

    func test_GH144_TC1_할인쿠폰적립금액줄은_글자가커도금액후보가아니다() {
        // Given
        let lines = [line("10,000원 할인 쿠폰 받기", 22), line("89,000원", 18), line("배송비 3,000원", 12)]

        // When
        let suggestion = PhotoTextSuggester.suggest(lines: lines, currentCurrency: "KRW")

        // Then
        XCTAssertEqual(suggestion.amount, PhotoTextAmount(amount: 89_000, currency: "KRW"))
    }

    func test_GH144_TC1_상품이름에흔한말은남기고_UI문구는낱말단위로뺀다() {
        // Given
        let lines = [line("락앤락 밀폐 저장용기", 15), line("Preview Lens", 14), line("Add to cart", 20), line("Reviews (1,204)", 19)]

        // When
        let suggestion = PhotoTextSuggester.suggest(lines: lines, currentCurrency: "KRW")

        // Then
        XCTAssertEqual(suggestion.titles, ["락앤락 밀폐 저장용기", "Preview Lens"])
    }

    func test_GH144_TC1_할인가줄은가격이고_할인금액이나정가만있는줄보다앞선다() {
        // Given: 정가(작게) 위에 쿠폰할인가(크게)
        let lines = [line("89,000원", 14), line("쿠폰할인가 69,000원", 18), line("23% 할인 59,000원", 12)]

        // When
        let suggestion = PhotoTextSuggester.suggest(lines: lines, currentCurrency: "KRW")

        // Then
        XCTAssertEqual(suggestion.amount, PhotoTextAmount(amount: 69_000, currency: "KRW"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "23% 할인 59,000원", currentCurrency: "KRW"), PhotoTextAmount(amount: 59_000, currency: "KRW"))
    }

    func test_GH144_TC1_만원으로쓴가격과_모르는달러줄은_제목후보가아니다() {
        // Given
        let lines = [line("89만원", 20), line("R$ 1.299,00", 19), line("캠핑 의자", 12)]

        // When
        let suggestion = PhotoTextSuggester.suggest(lines: lines, currentCurrency: "KRW")

        // Then
        XCTAssertEqual(suggestion.titles, ["캠핑 의자"])
        XCTAssertEqual(suggestion.amount, PhotoTextAmount(amount: 890_000, currency: "KRW"))
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

    func test_GH144_TC3_한줄에금액이여럿이면_마지막금액을읽는다() {
        XCTAssertEqual(PhotoTextSuggester.amount(in: "정가 99,000원 → 69,000원", currentCurrency: "KRW"), PhotoTextAmount(amount: 69_000, currency: "KRW"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "Save $5 — now $49.99", currentCurrency: "KRW"), PhotoTextAmount(amount: 4_999, currency: "USD"))
    }

    func test_GH144_TC3_정가라벨이붙은금액보다_같은줄의가격을고른다() {
        XCTAssertEqual(PhotoTextSuggester.amount(in: "$49.99 List: $59.99", currentCurrency: "KRW"), PhotoTextAmount(amount: 4_999, currency: "USD"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "69,000원 정가 89,000원", currentCurrency: "KRW"), PhotoTextAmount(amount: 69_000, currency: "KRW"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "정가 89,000원", currentCurrency: "KRW"), PhotoTextAmount(amount: 89_000, currency: "KRW"))
        XCTAssertNil(PhotoTextSuggester.amount(in: "쿠폰 -3,000원", currentCurrency: "KRW"))
        XCTAssertNil(PhotoTextSuggester.amount(in: "$5 off", currentCurrency: "KRW"))
    }

    func test_GH144_TC3_만천억으로쓴원화를읽는다() {
        XCTAssertEqual(PhotoTextSuggester.amount(in: "89만원", currentCurrency: "KRW"), PhotoTextAmount(amount: 890_000, currency: "KRW"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "12.5만 원", currentCurrency: "KRW"), PhotoTextAmount(amount: 125_000, currency: "KRW"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "1만 2천원", currentCurrency: "KRW"), PhotoTextAmount(amount: 12_000, currency: "KRW"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "3억원", currentCurrency: "KRW"), PhotoTextAmount(amount: 300_000_000, currency: "KRW"))
    }

    func test_GH144_TC3_모르는달러기호는_미국달러로읽지않는다() {
        XCTAssertNil(PhotoTextSuggester.amount(in: "R$ 1.299,00", currentCurrency: "KRW"))
        XCTAssertNil(PhotoTextSuggester.amount(in: "NZ$49", currentCurrency: "KRW"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "HK$49", currentCurrency: "KRW"), PhotoTextAmount(amount: 4_900, currency: "HKD"))
    }

    func test_GH144_TC1_세로로긴캡처는_짧은변을남기도록줄인다() {
        XCTAssertEqual(PhotoTextRecognizer.thumbnailMaxPixelSize(width: 3024, height: 4032), 2048)
        XCTAssertEqual(PhotoTextRecognizer.thumbnailMaxPixelSize(width: 1179, height: 2556), 2341)
        XCTAssertEqual(PhotoTextRecognizer.thumbnailMaxPixelSize(width: 1179, height: 12_000), 10_992)
        XCTAssertEqual(PhotoTextRecognizer.thumbnailMaxPixelSize(width: 800, height: 600), 800)
        XCTAssertEqual(PhotoTextRecognizer.thumbnailMaxPixelSize(width: 1000, height: 30_000), 12_000)
    }

    func test_GH144_TC3_숫자뒤통화말은_낱말이끝나거나가격다운숫자일때만읽는다() {
        XCTAssertNil(PhotoTextSuggester.amount(in: "1+1 원두커피 세트", currentCurrency: "KRW"))
        XCTAssertNil(PhotoTextSuggester.amount(in: "2 엔진오일", currentCurrency: "KRW"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "89,000원부터", currentCurrency: "KRW"), PhotoTextAmount(amount: 89_000, currency: "KRW"))
        XCTAssertEqual(PhotoTextSuggester.amount(in: "5 원", currentCurrency: "KRW"), PhotoTextAmount(amount: 5, currency: "KRW"))
    }

    func test_GH144_TC3_통화표시가없거나_0이거나_상한을넘으면_금액이아니다() {
        XCTAssertNil(PhotoTextSuggester.amount(in: "리뷰 1,204", currentCurrency: "KRW"))
        XCTAssertNil(PhotoTextSuggester.amount(in: "20% 할인", currentCurrency: "KRW"))
        XCTAssertNil(PhotoTextSuggester.amount(in: "0원", currentCurrency: "KRW"))
        XCTAssertNil(PhotoTextSuggester.amount(in: "1,000,000,000원", currentCurrency: "KRW"))
        XCTAssertNil(PhotoTextSuggester.amount(in: "₹500", currentCurrency: "KRW"))
    }
}
