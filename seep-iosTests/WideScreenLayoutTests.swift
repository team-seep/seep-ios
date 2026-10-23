import XCTest
import UIKit

@testable import seep_ios_dev

final class WideScreenLayoutTests: XCTestCase {
    // MARK: TC-5 폭 계산

    func test_GH12_TC5_화면폭이600이하면_콘텐츠폭은화면폭그대로다() {
        XCTAssertEqual(WideScreenLayout.contentWidth(containerWidth: 402), 402)
        XCTAssertEqual(WideScreenLayout.contentWidth(containerWidth: 600), 600)
        XCTAssertEqual(WideScreenLayout.horizontalInset(containerWidth: 402), 0)
        XCTAssertEqual(WideScreenLayout.horizontalInset(containerWidth: 600), 0)
    }

    func test_GH12_TC5_화면폭이600을넘으면_콘텐츠폭600에좌우여백이같다() {
        XCTAssertEqual(WideScreenLayout.contentWidth(containerWidth: 951), 600)
        XCTAssertEqual(WideScreenLayout.horizontalInset(containerWidth: 951), 175.5)
    }

    // MARK: TC-4 아이폰 폭은 그대로

    func test_GH12_TC4_아이폰폭에서_컨테이너가콘텐츠를화면전체로둔다() {
        for size in [CGSize(width: 402, height: 874), CGSize(width: 440, height: 956), CGSize(width: 466, height: 678)] {
            let (container, content) = makeContainer(size: size)

            XCTAssertEqual(content.frame, container.bounds, "\(size)")
        }
    }

    // MARK: TC-2, TC-3 듀오 안쪽(951×669)에서 작성·상세·수정 루트 뷰

    func test_GH12_TC2_듀오안쪽폭에서_화면콘텐츠가최대폭600으로가운데있다() {
        let (_, content) = makeContainer(size: CGSize(width: 951, height: 669))

        // 화면 배율(@3x) 픽셀 경계로 반올림되므로 1pt 이내로 본다
        XCTAssertEqual(content.frame.minX, 175.5, accuracy: 1)
        XCTAssertEqual(content.frame.width, 600)
        XCTAssertEqual(content.frame.height, 669)
    }

    func test_GH12_TC3_컨테이너배경색은_화면뷰배경색을따른다() {
        let content = UIView()
        content.backgroundColor = .white

        let container = WideScreenContainerView(contentView: content)

        XCTAssertEqual(container.backgroundColor, .white)
    }

    // MARK: Helpers

    private func makeContainer(size: CGSize) -> (WideScreenContainerView, UIView) {
        let content = UIView()
        let container = WideScreenContainerView(contentView: content)
        container.frame = CGRect(origin: .zero, size: size)
        container.layoutIfNeeded()
        return (container, content)
    }
}
