import XCTest

@testable import seep_ios_dev

/// 위시 상세 문서의 섹션 노출·순서 (GH-59 R-10).
final class DetailSectionBuilderTests: XCTestCase {
    private let steps = [WishStep(title: "가격 비교하기", order: 0)]

    // MARK: GH-59 TC4

    func test_GH59_TC4_메모가비면_메모섹션이없다() {
        // Given
        let empty = Wish(memo: "")
        let blank = Wish(memo: " \n ")

        // When
        let emptySections = DetailSectionBuilder.sections(for: empty)
        let blankSections = DetailSectionBuilder.sections(for: blank)

        // Then
        XCTAssertFalse(emptySections.contains(.memo))
        XCTAssertFalse(blankSections.contains(.memo))
        XCTAssertTrue(DetailSectionBuilder.sections(for: Wish(memo: "연말에 사기")).contains(.memo))
    }

    // MARK: GH-59 TC5

    func test_GH59_TC5_갖고싶어요는_모은돈링크까지_순서대로나온다() {
        // Given
        let wish = Wish(
            category: .wantToGet,
            steps: steps,
            targetAmount: 359_000,
            memo: "화이트로",
            link: "https://www.apple.com/kr/airpods-pro/"
        )

        // When
        let sections = DetailSectionBuilder.sections(for: wish)

        // Then
        XCTAssertEqual(sections, [.memo, .steps, .savings, .link, .photo])
    }

    func test_GH59_TC5_갖고싶어요도_목표금액링크가없으면_그섹션이없다() {
        // Given 링크 형식이 아닌 값도 상세에서는 숨긴다(WishLinkViewModel .detail 규칙)
        let wish = Wish(category: .wantToGet, targetAmount: 0, link: "not a link")

        // When
        let sections = DetailSectionBuilder.sections(for: wish)

        // Then
        XCTAssertEqual(sections, [.photo])
    }

    func test_GH59_TC5_가고싶어요는_장소섹션이_사진앞에나온다() {
        // Given 다른 카테고리 값(목표 금액·링크)이 남아 있어도 보이지 않는다
        let wish = Wish(category: .wantToGo, steps: steps, targetAmount: 10_000, memo: "아침 일찍", link: "https://a.com")

        // When
        let sections = DetailSectionBuilder.sections(for: wish)

        // Then
        XCTAssertEqual(sections, [.memo, .steps, .place, .photo])
    }

    func test_GH59_TC5_하고싶어요는_단계가없으면_사진만나온다() {
        // Given
        let wish = Wish(category: .wantToDo)

        // When
        let sections = DetailSectionBuilder.sections(for: wish)

        // Then
        XCTAssertEqual(sections, [.photo])
    }
}
