import XCTest

@testable import seep_ios

/// 금액 입력·표시 (GH-16 R-2·R-4).
final class AmountFormatterTests: XCTestCase {
    // MARK: GH-16 TC11

    func test_GH16_TC11_1234567을입력하면_천단위콤마로보인다() {
        // When
        let amount = AmountFormatter.amount(from: "1234567")

        // Then
        XCTAssertEqual(amount, 1_234_567)
        XCTAssertEqual(AmountFormatter.inputText(from: amount), "1,234,567")
    }

    func test_GH16_TC11_10자리이상입력하면_999999999를넘지않는다() {
        XCTAssertEqual(AmountFormatter.amount(from: "9999999999"), 999_999_999)
        XCTAssertEqual(AmountFormatter.amount(from: "1,000,000,000"), 100_000_000)
    }

    func test_GH16_TC11_숫자가아닌문자는_무시된다() {
        XCTAssertEqual(AmountFormatter.amount(from: "76a9,000원"), 769_000)
        XCTAssertEqual(AmountFormatter.amount(from: "٣"), 0)
        XCTAssertEqual(AmountFormatter.amount(from: nil), 0)
    }

    func test_GH16_TC11_0원이면_입력칸을비운다() {
        XCTAssertEqual(AmountFormatter.inputText(from: 0), "")
    }
}
