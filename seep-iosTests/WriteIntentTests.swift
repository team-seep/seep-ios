import XCTest

@testable import seep_ios_dev

/// 싶 적기 컨트롤·단축어 인텐트 (GH-49)
final class WriteIntentTests: XCTestCase {
    // MARK: GH-49 TC1

    func test_GH49_TC1_카테고리AppEnum세값은_Category와1대1로맞는다() {
        // Given
        let expected: [(WriteCategoryAppEnum, seep_ios_dev.Category)] = [
            (.wantToDo, .wantToDo),
            (.wantToGet, .wantToGet),
            (.wantToGo, .wantToGo)
        ]

        for (appEnum, category) in expected {
            // When
            let converted = appEnum.category
            let reversed = WriteCategoryAppEnum(category: category)

            // Then
            XCTAssertEqual(converted, category)
            XCTAssertEqual(reversed, appEnum)
        }
        XCTAssertEqual(WriteCategoryAppEnum.allCases.count, 3)
    }

    // MARK: GH-49 TC2

    func test_GH49_TC2_갖고싶어요컨트롤인텐트는_control출처의작성링크를만든다() {
        // Given
        let intent = OpenWriteIntent(target: .wantToGet, source: .control)

        // When
        let link = intent.deepLink.url?.absoluteString

        // Then
        XCTAssertEqual(link, "widget://add?category=category_want_to_get&source=control")
    }

    func test_GH49_TC2_단축어로만든인텐트는_shortcut출처가기본값이다() {
        // Given
        let intent = OpenWriteIntent()

        // When
        let deepLink = intent.deepLink

        // Then
        XCTAssertEqual(deepLink, .add(.wantToDo, source: .shortcut))
    }

    @MainActor
    func test_GH49_TC2_인텐트링크를넘기면_예약딥링크로남는다() async {
        // Given
        let preference = Preference(name: "test.writeIntent")
        let router = AppRouter(dependency: .init(wishRepository: MockWishRepository(), deepLinkStore: preference))
        let opener = WriteDeepLinkOpener(routerProvider: { router }, logManager: MockLogManager())

        // When
        await opener.open(OpenWriteIntent(target: .wantToGet, source: .control).deepLink)

        // Then
        XCTAssertEqual(preference.reservedDeepLink, "widget://add?category=category_want_to_get&source=control")
    }

    func test_GH49_TC2_작성링크를다시파싱하면_카테고리와출처가같다() {
        // Given
        let links: [WidgetDeepLink] = [
            .add(.wantToGo, source: .control),
            .add(.wantToDo, source: .shortcut),
            .add(.wantToGet)
        ]

        for link in links {
            // When
            let parsed = link.url.flatMap { WidgetDeepLink(string: $0.absoluteString) }

            // Then
            XCTAssertEqual(parsed, link)
        }
        XCTAssertEqual(WidgetDeepLink(string: "widget://add?category=category_want_to_do"), .add(.wantToDo, source: nil))
        XCTAssertNil(WidgetDeepLink(string: "widget://add?category=wrong&source=control"))
    }
}
