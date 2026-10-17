import XCTest

@testable import seep_ios_dev

/// 홈 그리드 열 수·셀 크기 계산 (GH-11). 입력은 컬렉션뷰 폭 - 섹션 좌우 inset(20 * 2)
final class HomeWishGridLayoutTests: XCTestCase {
    private typealias Layout = HomeWishGridCell.Layout

    private func availableWidth(containerWidth: CGFloat) -> CGFloat {
        return containerWidth - 40
    }

    func test_GH11_TC1_듀오바깥폭466_2열_간격15() {
        let width = availableWidth(containerWidth: 466)

        let columnCount = Layout.columnCount(availableWidth: width)
        let size = Layout.itemSize(availableWidth: width)

        XCTAssertEqual(columnCount, 2)
        XCTAssertEqual(Layout.spacing, 15)
        // 두 칸 + 간격이 사용 가능 폭을 넘지 않아야 한 줄에 들어간다
        XCTAssertLessThanOrEqual(size.width * 2 + Layout.spacing, width)
        XCTAssertEqual(size.width, 205.5, accuracy: 0.001)
    }

    func test_GH11_TC2_듀오안쪽폭951_3열이상_비율유지() {
        let width = availableWidth(containerWidth: 951)

        let columnCount = Layout.columnCount(availableWidth: width)
        let size = Layout.itemSize(availableWidth: width)

        XCTAssertGreaterThanOrEqual(columnCount, 3)
        XCTAssertEqual(size.height / size.width, 1.09, accuracy: 0.0001)
        XCTAssertLessThanOrEqual(
            size.width * CGFloat(columnCount) + Layout.spacing * CGFloat(columnCount - 1),
            width + 0.001
        )
    }

    func test_GH11_TC2_듀오안쪽_컬렉션뷰폭600제한_3열() {
        // GH-12에서 넓은 화면의 홈 컬렉션뷰 폭을 600으로 제한해도 3열을 유지한다
        let width = availableWidth(containerWidth: 600)

        XCTAssertEqual(Layout.columnCount(availableWidth: width), 3)
        XCTAssertEqual(Layout.itemSize(availableWidth: width).height / Layout.itemSize(availableWidth: width).width, 1.09, accuracy: 0.0001)
    }

    func test_GH11_TC3_아이폰18Pro폭402_기존과같은크기() {
        let width = availableWidth(containerWidth: 402)

        let size = Layout.itemSize(availableWidth: width)

        // 기존 계산: (화면 폭 - 40 - 15) / 2, 높이 = 폭 * 1.09
        XCTAssertEqual(Layout.columnCount(availableWidth: width), 2)
        XCTAssertEqual(size.width, (402 - 40 - 15) / 2, accuracy: 0.001)
        XCTAssertEqual(size.height, ((402 - 40 - 15) / 2) * 1.09, accuracy: 0.001)
    }

    func test_GH11_TC5_사용가능폭540미만은2열_540이상은3열() {
        XCTAssertEqual(Layout.columnCount(availableWidth: 539), 2)
        XCTAssertEqual(Layout.columnCount(availableWidth: 540), 3)
    }

    func test_GH11_TC5_폭0이하_최소2열_크기0() {
        XCTAssertEqual(Layout.columnCount(availableWidth: 0), 2)
        XCTAssertEqual(Layout.itemSize(availableWidth: -10), .zero)
    }
}
