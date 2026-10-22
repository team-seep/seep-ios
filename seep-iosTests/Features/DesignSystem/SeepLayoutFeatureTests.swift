import XCTest

@testable import seep_ios_dev

/// 넓은 화면 기둥 규칙 (GH-12). 기존 WideScreenLayoutTests 이전 — UIKit 컨테이너 뷰 대신 SwiftUI 화면이 쓰는 `SeepLayout` 계산을 본다
final class SeepLayoutFeatureTests: XCTestCase {
    // MARK: GH-12 TC5

    func test_GH12_TC5_화면폭이600이하면_콘텐츠폭은화면폭그대로다() {
        // Given / When / Then
        XCTAssertEqual(SeepLayout.contentWidth(containerWidth: 402), 402)
        XCTAssertEqual(SeepLayout.contentWidth(containerWidth: 600), 600)
        XCTAssertEqual(SeepLayout.horizontalInset(containerWidth: 402), 0)
        XCTAssertEqual(SeepLayout.horizontalInset(containerWidth: 600), 0)
    }

    func test_GH12_TC5_화면폭이600을넘으면_콘텐츠폭600에좌우여백이같다() {
        // Given / When / Then
        XCTAssertEqual(SeepLayout.contentWidth(containerWidth: 951), 600)
        XCTAssertEqual(SeepLayout.horizontalInset(containerWidth: 951), 175.5)
    }

    // MARK: GH-12 TC4

    func test_GH12_TC4_아이폰폭에서_컨테이너가콘텐츠를화면전체로둔다() {
        // Given — 아이폰 17 Pro · Pro Max · 듀오 바깥 폭
        for width in [CGFloat(402), 440, 466] {
            // When
            let content = SeepLayout.contentWidth(containerWidth: width)
            let inset = SeepLayout.horizontalInset(containerWidth: width)

            // Then
            XCTAssertEqual(content, width, "\(width)")
            XCTAssertEqual(inset, 0, "\(width)")
        }
    }

    // MARK: GH-12 TC2

    func test_GH12_TC2_듀오안쪽폭에서_화면콘텐츠가최대폭600으로가운데있다() {
        // Given
        let duoInnerWidth: CGFloat = 951

        // When
        let content = SeepLayout.contentWidth(containerWidth: duoInnerWidth)
        let inset = SeepLayout.horizontalInset(containerWidth: duoInnerWidth)

        // Then
        XCTAssertEqual(content, 600)
        XCTAssertEqual(inset * 2 + content, duoInnerWidth)
    }

    // MARK: GH-11

    func test_GH11_카테고리탭줄은_가장넓은아이폰탭폭400을넘지않는다() {
        // Given / When / Then
        XCTAssertEqual(SeepLayout.maxCategoryTabWidth, 400)
        XCTAssertLessThanOrEqual(SeepLayout.maxCategoryTabWidth, SeepLayout.maxContentWidth)
    }
}
