import XCTest
import UIKit

@testable import seep_ios_dev

final class ToastManagerTests: XCTestCase {
    /// 듀오 바깥(접힘) 화면: 466×678pt, 오른쪽 위 센서·상태 표시 영역 때문에 safe area 오른쪽 inset 84pt
    private let duoOuterBounds = CGRect(x: 0, y: 0, width: 466, height: 678)
    private let duoOuterInsets = UIEdgeInsets(top: 0, left: 0, bottom: 34, right: 84)

    // MARK: GH-10 TC6

    func test_GH10_TC6_듀오바깥화면에서_토스트가_safeArea오른쪽inset을침범하지않는다() {
        // Given
        let bounds = duoOuterBounds
        let insets = duoOuterInsets

        // When
        let frame = ToastManager.frame(in: bounds, safeAreaInsets: insets)

        // Then
        XCTAssertEqual(frame.minX, 20)
        XCTAssertEqual(frame.maxX, bounds.width - insets.right - 20)
        XCTAssertGreaterThanOrEqual(frame.minY, insets.top)
        XCTAssertEqual(frame.height, 58)
    }

    func test_GH10_TC6_아이폰18Pro에서는_토스트위치가_기존과같다() {
        // Given: 기존 계산식 x 20, y safeTop + 14, 폭 화면 - 40
        let bounds = CGRect(x: 0, y: 0, width: 402, height: 874)
        let insets = UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0)

        // When
        let frame = ToastManager.frame(in: bounds, safeAreaInsets: insets)

        // Then
        XCTAssertEqual(frame, CGRect(x: 20, y: 62 + 14, width: 402 - 40, height: 58))
    }
}
