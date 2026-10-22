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

final class SafeAreaTopButtonTests: XCTestCase {
    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    // MARK: GH-10 TC7

    func test_GH10_TC7_작성화면_닫기버튼이_safeArea안에있고_44pt이상이다() {
        // Given
        let view = WriteView()

        // When
        layoutLikeDuoOuter(view)

        // Then
        assertTappableInSafeArea(view.closeButton, in: view)
    }

    func test_GH10_TC7_수정화면_뒤로버튼이_safeArea안에있고_44pt이상이다() {
        // Given
        let view = WishEditView()

        // When
        layoutLikeDuoOuter(view)

        // Then
        assertTappableInSafeArea(view.backButton, in: view)
    }

    func test_GH10_TC7_알림화면_뒤로·삭제버튼과_목록이_safeArea안에있다() {
        // Given
        let view = NotificationView()

        // When
        layoutLikeDuoOuter(view)

        // Then
        assertTappableInSafeArea(view.backButton, in: view)
        assertTappableInSafeArea(view.deleteButton, in: view)
        let groupFrame = view.notificationGroupView.convert(view.notificationGroupView.bounds, to: view)
        XCTAssertLessThanOrEqual(groupFrame.maxX, view.bounds.width - view.safeAreaInsets.right + 0.5)
    }

    /// 듀오 바깥 화면처럼 오른쪽에 84pt safe area inset이 생기게 한 뒤 레이아웃한다
    private func layoutLikeDuoOuter(_ view: UIView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 466, height: 678))
        let viewController = UIViewController()
        viewController.view = view
        viewController.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 84)
        window.rootViewController = viewController
        window.isHidden = false
        self.window = window
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func assertTappableInSafeArea(
        _ button: UIView,
        in view: UIView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let frame = button.convert(button.bounds, to: view)
        let safeFrame = view.bounds.inset(by: view.safeAreaInsets)
        XCTAssertGreaterThanOrEqual(view.safeAreaInsets.right, 84, "듀오 inset이 적용되지 않음", file: file, line: line)
        XCTAssertTrue(safeFrame.insetBy(dx: -0.5, dy: -0.5).contains(frame), "\(frame) ⊄ \(safeFrame)", file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.width, 44, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.height, 44, file: file, line: line)
    }
}
