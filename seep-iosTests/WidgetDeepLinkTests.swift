import XCTest

@testable import seep_ios

/// 위젯 링크(`widget://…`) 파싱·생성 (GH-47 R-11)
final class WidgetDeepLinkTests: XCTestCase {
    // MARK: GH-47 TC8

    func test_GH47_TC8_위시링크를파싱하면_wish와id와source() {
        // Given
        let link = "widget://wish?id=abc&source=lockscreen_dday"

        // When
        let deepLink = WidgetDeepLink(string: link)

        // Then
        XCTAssertEqual(deepLink, .wish(id: "abc", source: .lockscreenDday))
    }

    func test_GH47_TC8_위젯이만든URL을다시파싱하면_같은값이다() {
        // Given
        let links: [WidgetDeepLink] = [
            .wish(id: "8F1C-uuid", source: .lockscreenDday),
            .home(source: .lockscreenDday),
            .home(source: .lockscreenRemain),
            .add(.wantToGo)
        ]

        for link in links {
            // When
            let parsed = link.url.flatMap { WidgetDeepLink(string: $0.absoluteString) }

            // Then
            XCTAssertEqual(parsed, link)
        }
    }

    // MARK: GH-47 TC9

    func test_GH47_TC9_바로적기링크를파싱하면_add와카테고리() {
        // Given
        let link = "widget://add?category=category_want_to_do"

        // When
        let deepLink = WidgetDeepLink(string: link)

        // Then
        XCTAssertEqual(deepLink, .add(.wantToDo))
        XCTAssertNil(deepLink?.source)
    }

    func test_GH47_TC9_홈링크는home이고_모르는링크는nil() {
        // Given / When / Then
        XCTAssertEqual(WidgetDeepLink(string: "widget://home"), .home(source: nil))
        XCTAssertEqual(WidgetDeepLink(string: "widget://home?source=lockscreen_remain"), .home(source: .lockscreenRemain))
        XCTAssertNil(WidgetDeepLink(string: "widget://add?category=wrong"))
        XCTAssertNil(WidgetDeepLink(string: "widget://wish"))
        XCTAssertNil(WidgetDeepLink(string: "widget://unknown"))
        XCTAssertNil(WidgetDeepLink(string: "https://wish?id=abc"))
    }
}
