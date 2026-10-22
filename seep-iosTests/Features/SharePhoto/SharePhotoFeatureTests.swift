import XCTest
import SwiftUI

@testable import seep_ios_dev

private final class MockPhotoLibrary: PhotoLibraryProviding {
    var status: PhotoLibraryAuthorization = .authorized
    var statusAfterRequest: PhotoLibraryAuthorization = .authorized
    var photoIds: [String] = ["p1", "p2", "p3"]
    var saveError: Error?
    private(set) var requestCount = 0
    private(set) var savedData: [Data] = []

    func authorizationStatus() -> PhotoLibraryAuthorization { status }

    func requestAuthorization() async -> PhotoLibraryAuthorization {
        requestCount += 1
        status = statusAfterRequest
        return statusAfterRequest
    }

    func fetchPhotoIds() -> [String] { photoIds }

    func image(for photoId: String, maxPixelSize: CGFloat) async -> CGImage? { nil }

    func savePNG(_ data: Data) async throws {
        if let saveError { throw saveError }
        savedData.append(data)
    }
}

/// 사진 공유 (GH-64 TC-1201~1203, 기존 SharePhotoReactor·SharePhotoView GH-13)
final class SharePhotoFeatureTests: ViewModelTestCase {
    private var library: MockPhotoLibrary!
    private var userDefaults: UserDefaultsUtils!
    private let calendar = Calendar(identifier: .gregorian)
    private let today = Date(timeIntervalSince1970: 1_792_540_800)

    override func setUp() {
        super.setUp()
        library = MockPhotoLibrary()
        userDefaults = UserDefaultsUtils(name: "test-gh64-share-photo")
    }

    override func tearDown() {
        library = nil
        userDefaults = nil
        super.tearDown()
    }

    private func makeSut(wish: Wish = Wish(emoji: "🏄", title: "서핑 배우기")) -> SharePhotoViewModel {
        SharePhotoViewModel(
            config: .init(wish: wish),
            dependency: .init(
                photoLibrary: library,
                userDefaults: userDefaults,
                averageColor: { $0 == "😍" ? ShareCardRGB(red: 1, green: 0.5, blue: 0.5) : ShareCardRGB(red: 0.2, green: 0.2, blue: 0.2) },
                now: { [unowned self] in self.today },
                calendar: calendar
            )
        )
    }

    // MARK: GH-13 TC6

    func test_GH13_TC6_목록폭에따라_3_4_5열정사각형셀이된다() {
        // Given
        let cases: [(width: CGFloat, columns: CGFloat)] = [(402, 3), (700, 4), (892, 5)]

        for (width, columns) in cases {
            // When
            let side = SharePhotoLayout.cellSide(containerWidth: width)

            // Then
            XCTAssertEqual(CGFloat(SharePhotoLayout.columnCount(containerWidth: width)), columns, "width \(width)")
            let rowWidth = side * columns + SharePhotoLayout.gridSpacing * (columns - 1)
            XCTAssertLessThanOrEqual(rowWidth, width, "width \(width)")
            let oneMoreColumn = side * (columns + 1) + SharePhotoLayout.gridSpacing * columns
            XCTAssertGreaterThan(oneMoreColumn, width, "width \(width)")
        }
    }

    // MARK: GH-13 TC7

    func test_GH13_TC7_듀오안쪽시트에서_카드는시트안정사각형이고_사진목록이한줄이상보인다() {
        // Given
        let sheetSize = CGSize(width: 892, height: 620)

        // When
        let card = SharePhotoLayout.cardSide(containerSize: sheetSize)

        // Then
        XCTAssertGreaterThan(card, 0)
        XCTAssertLessThanOrEqual(card, sheetSize.width)
        let listHeight = sheetSize.height - SharePhotoLayout.headerHeight - card - SharePhotoLayout.switchHeight
        let cellHeight = SharePhotoLayout.cellSide(containerWidth: sheetSize.width)
        XCTAssertGreaterThanOrEqual(
            listHeight - SharePhotoLayout.shareButtonArea(bottomSafeArea: 0),
            cellHeight - 0.5
        )
    }

    @MainActor
    func test_GH13_TC7_큰사진을골라도_카드크기가시트를넘지않는다() {
        // Given
        let side = SharePhotoLayout.cardSide(containerSize: CGSize(width: 892, height: 620))
        var state = SharePhotoViewModel.State()
        state.title = "서핑 배우기"
        state.shareType = .photo
        state.selectedPhotoId = "big"
        let bigPhoto = Self.solidImage(side: 1200)

        // When
        let renderer = ImageRenderer(content: ShareCardView(state: state, side: side, photo: bigPhoto))
        renderer.scale = 1
        let rendered = renderer.cgImage

        // Then
        XCTAssertEqual(rendered?.width, Int(side))
        XCTAssertEqual(rendered?.height, Int(side))
    }

    // MARK: GH-13 TC8

    func test_GH13_TC8_아이폰18Pro시트에서_카드는기존처럼폭과같은정사각형이다() {
        // Given
        let sheetSize = CGSize(width: 402, height: 800)

        // When
        let card = SharePhotoLayout.cardSide(containerSize: sheetSize)

        // Then
        XCTAssertEqual(card, 402, accuracy: 0.5)
    }

    // MARK: 공유 이모지 탭 (NO-ISSUE)

    func test_공유이모지탭_키보드가공유버튼위를채우고_카드는기존폭을유지한다() {
        // Given / When
        let card = SharePhotoLayout.cardSide(containerSize: CGSize(width: 402, height: 780))

        // Then
        XCTAssertEqual(card, 402)
        // 목록 아래 여백 = 공유 버튼 영역(버튼에 가리는 곳 없이 위까지 채운다)
        XCTAssertEqual(SharePhotoLayout.shareButtonArea(bottomSafeArea: 0), 50 + 24 + 12)
        XCTAssertFalse(ShareEmojiCatalog.sections.isEmpty)
        XCTAssertTrue(ShareEmojiCatalog.sections.allSatisfy { !$0.emojis.isEmpty })
    }

    func test_공유이모지탭_이모지를고르면_카드이모지가바뀐다() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.selectEmoji("😍"))

        // Then
        XCTAssertEqual(sut.state.emoji, "😍")
        XCTAssertEqual(sut.state.emojiBackground, ShareCardRGB(red: 1, green: 0.5, blue: 0.5))
    }

    // MARK: GH-64 TC1201

    func test_GH64_TC1201_사진탭으로바꾸면_최근사진을불러와_첫사진이카드바탕이된다() {
        // Given
        let sut = makeSut()
        XCTAssertFalse(sut.state.showsPhotoBackground)

        // When
        sut.send(.tapPhotoTab)

        // Then
        waitUntil { sut.state.shareType == .photo }
        XCTAssertEqual(sut.state.photoIds, ["p1", "p2", "p3"])
        XCTAssertEqual(sut.state.selectedPhotoId, "p1")
        XCTAssertTrue(sut.state.showsPhotoBackground)
    }

    func test_GH64_TC1201_이모지탭으로돌아오면_카드는이모지바탕이다() {
        // Given
        let sut = makeSut()
        sut.send(.tapPhotoTab)
        waitUntil { sut.state.shareType == .photo }

        // When
        sut.send(.tapEmojiTab)

        // Then
        XCTAssertEqual(sut.state.shareType, .emoji)
        XCTAssertFalse(sut.state.showsPhotoBackground)
        XCTAssertEqual(sut.state.selectedPhotoId, "p1", "고른 사진은 기억한다")
    }

    // MARK: GH-64 TC1202

    func test_GH64_TC1202_사진을고르면_카드바탕사진이바뀐다() {
        // Given
        let sut = makeSut()
        sut.send(.tapPhotoTab)
        waitUntil { sut.state.shareType == .photo }

        // When
        sut.send(.selectPhoto("p3"))

        // Then
        XCTAssertEqual(sut.state.selectedPhotoId, "p3")
    }

    func test_GH64_TC1202_카드를두번탭하면_글자색이반전된다() {
        // Given
        let sut = makeSut()
        XCTAssertTrue(sut.state.isTextBlack)

        // When
        sut.send(.doubleTapCard)

        // Then
        XCTAssertFalse(sut.state.isTextBlack)

        // When
        sut.send(.doubleTapCard)

        // Then
        XCTAssertTrue(sut.state.isTextBlack)
    }

    // MARK: GH-64 TC1203

    func test_GH64_TC1203_권한이있으면_앨범에저장하고_saved로간다() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.tapShare(pngData: Data([1, 2, 3])))

        // Then
        waitUntil { sut.route == .saved }
        XCTAssertEqual(library.savedData, [Data([1, 2, 3])])
        XCTAssertFalse(sut.state.isSaving)
    }

    func test_GH64_TC1203_권한이거절돼있으면_저장하지않고_설정안내알럿을띄운다() {
        // Given
        library.status = .denied
        let sut = makeSut()

        // When
        sut.send(.tapShare(pngData: Data([1])))

        // Then
        waitUntil { sut.route != nil }
        XCTAssertEqual(sut.route, .permissionDeniedAlert(message: Strings.sharePhotoDenyMessage))
        XCTAssertTrue(library.savedData.isEmpty)
    }

    func test_GH64_TC1203_권한을아직안물었으면_물어보고_허용하면저장한다() {
        // Given
        library.status = .notDetermined
        library.statusAfterRequest = .authorized
        let sut = makeSut()

        // When
        sut.send(.tapShare(pngData: Data([9])))

        // Then
        waitUntil { sut.route == .saved }
        XCTAssertEqual(library.requestCount, 1)
        XCTAssertEqual(library.savedData.count, 1)
    }

    func test_GH64_TC1203_카드를그리지못하거나_저장에실패하면_오류알럿() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.tapShare(pngData: nil))

        // Then
        XCTAssertEqual(sut.route, .errorAlert(message: Strings.SharePhoto.saveFailed))

        // Given
        sut.send(.routeHandled)
        library.saveError = PhotoLibraryError.saveFailed

        // When
        sut.send(.tapShare(pngData: Data([1])))

        // Then
        waitUntil { sut.route != nil }
        XCTAssertEqual(sut.route, .errorAlert(message: Strings.SharePhoto.saveFailed))
    }

    func test_GH64_TC1203_사진탭도_권한이거절돼있으면_설정안내알럿을띄우고_탭은그대로다() {
        // Given
        library.status = .denied
        let sut = makeSut()

        // When
        sut.send(.tapPhotoTab)

        // Then
        waitUntil { sut.route != nil }
        XCTAssertEqual(sut.route, .permissionDeniedAlert(message: Strings.sharePhotoDenyMessage))
        XCTAssertEqual(sut.state.shareType, .emoji)
    }

    // MARK: 회귀

    func test_회귀_말풍선은처음한번만보인다() {
        // Given
        userDefaults.setSharePhotoTooltipIsShow(isShown: false)
        let sut = makeSut()

        // When
        sut.send(.onAppear)

        // Then
        XCTAssertTrue(sut.state.isTooltipVisible)

        // When
        sut.send(.tooltipDidDisappear)
        let next = makeSut()
        next.send(.onAppear)

        // Then
        XCTAssertFalse(sut.state.isTooltipVisible)
        XCTAssertFalse(next.state.isTooltipVisible)
    }

    func test_회귀_카드D_day는_당일D_Day_지나면D플러스_멀면먼훗날이고_날짜가없으면숨긴다() {
        // Given
        let day = { (offset: Int) in self.calendar.date(byAdding: .day, value: offset, to: self.today) }

        // When / Then
        XCTAssertEqual(makeSut(wish: Wish(title: "a", endDate: day(0))).state.ddayText, "D-Day")
        XCTAssertEqual(makeSut(wish: Wish(title: "a", endDate: day(-3))).state.ddayText, "D+3")
        XCTAssertEqual(makeSut(wish: Wish(title: "a", endDate: day(20))).state.ddayText, "D-20")
        XCTAssertEqual(makeSut(wish: Wish(title: "a", endDate: day(400))).state.ddayText, Strings.homeInFarFurture)
        let noDate = makeSut(wish: Wish(title: "a", endDate: nil)).state
        XCTAssertNil(noDate.ddayText)
        XCTAssertNil(noDate.dateText)
    }

    func test_회귀_카드바탕은이모지평균색을밝게띄운색이다() {
        // Given / When
        let color = ShareCardPalette.averageColor(of: "🍀")

        // Then
        XCTAssertNotNil(color)
        // 평균에 100/255 를 더해 띄우므로 어느 채널도 100/255 보다 어둡지 않다
        XCTAssertGreaterThanOrEqual(color?.red ?? 0, 100 / 255 - 0.001)
        XCTAssertGreaterThanOrEqual(color?.green ?? 0, 100 / 255 - 0.001)
        XCTAssertGreaterThanOrEqual(color?.blue ?? 0, 100 / 255 - 0.001)
        XCTAssertNil(ShareCardPalette.averageColor(of: ""))
    }

    func test_회귀_카드PNG는_ImageIO로만든다() {
        // Given
        let image = Self.solidImage(side: 10)

        // When
        let data = ShareImageEncoder.pngData(from: image)

        // Then
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.prefix(4), Data([0x89, 0x50, 0x4E, 0x47]))
    }

    private static func solidImage(side: Int) -> CGImage {
        let context = CGContext(
            data: nil,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context?.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context?.fill(CGRect(x: 0, y: 0, width: side, height: side))
        return context!.makeImage()!
    }
}
