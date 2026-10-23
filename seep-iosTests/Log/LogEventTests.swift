import XCTest
import Combine

@testable import seep_ios_dev

final class LogEventTests: XCTestCase {
    // MARK: 회귀 — 이벤트 형식 (가슴속 3천원과 동일)

    func test_회귀_클릭이벤트는_click이름과_screen_objectType_objectId를담는다() {
        // Given
        let event = ClickEvent(screen: .home, objectType: .button, objectId: .write, extraParameters: [.category: "c"])

        // When
        let parameters = event.parameters

        // Then
        XCTAssertEqual(event.name.rawValue, "click")
        XCTAssertEqual(parameters["screen"] as? String, "home")
        XCTAssertEqual(parameters["object_type"] as? String, "button")
        XCTAssertEqual(parameters["object_id"] as? String, "write")
        XCTAssertEqual(parameters["category"] as? String, "c")
    }

    // MARK: 회귀 — 홈 클릭 로그

    func test_회귀_홈에서작성탭을누르면_tab_write클릭로그가한건전송된다() {
        // Given: 작성 버튼은 탭 바의 적기 탭으로 옮겨 갔다 (GH-64 R-11)
        let logManager = MockLogManager()
        let router = AppRouter(dependency: .init(wishRepository: MockWishRepository(), deepLinkStore: Preference(name: "test")))
        let viewModel = MainTabViewModel(dependency: .init(router: router, logManager: logManager))

        // When
        viewModel.send(.tapTab(.write))

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        XCTAssertEqual(logManager.sentEvents.first?.parameters["object_id"] as? String, "tab_write")
        XCTAssertEqual(logManager.sentEvents.first?.parameters["screen"] as? String, "home")
    }
}
