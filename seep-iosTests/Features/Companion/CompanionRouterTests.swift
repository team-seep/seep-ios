import XCTest

@testable import seep_ios

private final class StubDeepLinkStore: ReservedDeepLinkStoring {
    var reservedDeepLink = ""
}

/// 모아보기 "…랑 하고 싶은 것 적기" → 작성 화면 (GH-122 R-6, TC-7)
final class CompanionRouterTests: ViewModelTestCase {
    private var sut: AppRouter!
    private let mom = WishCompanion(personId: "p-mom", name: "엄마")

    override func setUp() {
        super.setUp()
        sut = AppRouter(dependency: .init(wishRepository: MockWishRepository(), deepLinkStore: StubDeepLinkStore()))
        sut.mainDidAppear()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_GH122_TC7_사람으로작성을열면_홈카테고리작성화면에그사람이실리고_닫으면비운다() {
        // Given
        sut.homeCategory = .wantToGo

        // When
        sut.openCompanionWrite(with: mom)

        // Then
        XCTAssertEqual(sut.writeCategory, .wantToGo)
        XCTAssertEqual(sut.writeCompanion, mom)
        XCTAssertNil(sut.writePreviousWishId)

        // When
        sut.writeCategory = nil

        // Then
        XCTAssertNil(sut.writeCompanion)
    }

    func test_GH122_TC7_시트가떠있어미뤄둔뒤단축어로적기를열면_그사람은싣지않는다() {
        // Given: 시트가 떠 있어 작성 화면을 미뤄 둔다
        sut.modalDidAppear()
        sut.openCompanionWrite(with: mom)

        // When: 그사이 단축어로 적기
        sut.openFromIntent(.add(.wantToGet, source: .shortcut))

        // Then
        XCTAssertNil(sut.writeCompanion)
    }

    func test_GH122_TC7_이어서적기는_미뤄둔사람을싣지않는다() {
        // Given
        sut.modalDidAppear()
        sut.openCompanionWrite(with: mom)
        sut.modalDidDisappear()
        sut.writeCategory = nil

        // When
        sut.openChainedWrite(from: Wish(id: "w", category: .wantToDo, title: "제주"))

        // Then
        XCTAssertNil(sut.writeCompanion)
        XCTAssertEqual(sut.writePreviousWishId, "w")
    }
}
