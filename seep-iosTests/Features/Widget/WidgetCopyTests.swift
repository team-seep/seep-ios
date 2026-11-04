import XCTest

@testable import seep_ios

/// 예전 위젯 4종 정리 — kind·문구·링크 (GH-87)
final class WidgetCopyTests: XCTestCase {
    // MARK: GH-87 TC2

    func test_GH87_TC2_위젯kind는_예전타입이름그대로라_업데이트해도위젯이사라지지않는다() {
        // Given / When / Then
        XCTAssertEqual(WidgetKind.smallWrite, "SmallWriteWidget")
        XCTAssertEqual(WidgetKind.smallRemain, "SmallRemainWidget")
        XCTAssertEqual(WidgetKind.mediumHorizontal, "MediumHorizontalWidget")
        XCTAssertEqual(WidgetKind.mediumVertical, "MediumVerticalWidget")
    }

    // MARK: GH-87 TC3

    func test_GH87_TC3_남은위시가없으면_남은개수위젯에빈상태문구가있다() {
        // Given / When
        let empty = SmallRemainCopy(category: .wantToDo, count: 0)
        let some = SmallRemainCopy(category: .wantToGo, count: 3)

        // Then
        XCTAssertEqual(empty.count, "0")
        XCTAssertEqual(empty.emptyCaption, "새 싶을 적어봐요")
        XCTAssertNil(some.emptyCaption)
        XCTAssertEqual(some.headline, "가고 싶은 곳들이")
        XCTAssertEqual(some.suffix, "곳 남았어요!")
    }

    func test_GH87_TC3_중형위젯빈상태는_적어보라는문구다() {
        // Given / When / Then
        XCTAssertEqual(WidgetEmptyCopy.title, "하고 싶은 것들을")
        XCTAssertEqual(WidgetEmptyCopy.bold, "적어봐요.")
    }

    // MARK: GH-87 TC6

    func test_GH87_TC6_작게쓰기위젯을누르면_그카테고리작성화면링크다() throws {
        // Given / When
        let url = try XCTUnwrap(SmallWriteCopy(category: .wantToGet).url)

        // Then
        XCTAssertEqual(WidgetDeepLink(string: url.absoluteString), .add(.wantToGet))
        XCTAssertEqual(SmallWriteCopy(category: .wantToGet).question, "뭐 갖고 싶어요?")
    }

    func test_GH87_TC6_남은개수위젯을누르면_홈링크다() throws {
        // Given / When
        let url = try XCTUnwrap(SmallRemainCopy(category: .wantToDo, count: 2).url)

        // Then
        XCTAssertEqual(WidgetDeepLink(string: url.absoluteString), .home(source: nil))
    }
}
