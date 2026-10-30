import XCTest

@testable import seep_ios

/// 이모지 고르기 시트의 목록 (GH-64 R-40, TC-37)
final class EmojiPickerFeatureTests: XCTestCase {
    // MARK: GH-64 TC37

    func test_GH64_TC37_카테고리는9개이고_모두이모지가있다() {
        // Given / When
        let categories = EmojiCategory.allCases

        // Then
        XCTAssertEqual(categories.count, 9)
        for category in categories {
            XCTAssertGreaterThan(category.emojis.count, 20, category.rawValue)
            XCTAssertFalse(category.title.isEmpty)
        }
    }

    func test_GH64_TC37_목록에는_이모지가아닌글자가없고_한칸에한이모지다() {
        // Given / When
        let all = EmojiCategory.allCases.flatMap(\.emojis)

        // Then
        for emoji in all {
            XCTAssertEqual(emoji.count, 1, emoji)
            XCTAssertTrue(emoji.unicodeScalars.first?.properties.isEmoji ?? false, emoji)
            XCTAssertNotEqual(emoji, "#")
        }
    }

    func test_GH64_TC37_국기는지역표시문자두개로만든다() {
        // Given / When
        let flags = EmojiCatalog.flags(["KR", "JP"])

        // Then
        XCTAssertEqual(flags, ["🇰🇷", "🇯🇵"])
    }

    func test_GH64_TC37_무작위이모지는_한글자이모지다() {
        // Given / When
        let emoji = EmojiCatalog.randomEmoji()

        // Then
        XCTAssertEqual(emoji.count, 1)
        XCTAssertTrue(emoji.unicodeScalars.first?.properties.isEmoji ?? false)
    }
}
