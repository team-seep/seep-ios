import CoreGraphics
import XCTest

@testable import seep_ios_dev

/// 홈 셀 값(단계 진행도·소감·핀·사진)과 그리드·카테고리 탭·지도 버튼 배치.
/// 기존 HomeWishCellViewModelTests·HomeWishGridLayoutTests·HomePlaceMapTests, WideScreenLayout·ToastManager 테스트의 홈 부분 이전
final class HomeWishItemFeatureTests: HomeFeatureTestCase {
    private func item(_ wish: Wish, storage: MockWishPhotoStorage = MockWishPhotoStorage()) -> HomeWishItem {
        HomeWishItem(wish: wish, photoStorage: storage)
    }

    // MARK: GH-5 TC6

    func test_GH5_TC6_단계0개인위시는_진행도가nil이라_숨겨진다() {
        // Given
        let wish = Wish(id: "wish-1", title: "단계 없는 위시")

        // When
        let item = item(wish)

        // Then
        XCTAssertNil(item.stepProgress)
    }

    func test_GH5_TC6_단계가있으면_완료수와전체수를표시한다() {
        // Given
        let steps = [
            WishStep(title: "날짜 정하기", isDone: true, order: 0),
            WishStep(title: "숙소 알아보기", isDone: true, order: 1),
            WishStep(title: "항공권 예약하기", order: 2),
            WishStep(title: "짐 싸기", order: 3)
        ]
        let wish = Wish(id: "wish-1", title: "제주도 한 달 살기", steps: steps)

        // When
        let item = item(wish)

        // Then
        XCTAssertEqual(item.stepProgress?.doneCount, 2)
        XCTAssertEqual(item.stepProgress?.totalCount, 4)
        XCTAssertEqual(Strings.Home.stepProgressFormat(2, 4), "2/4")
    }

    // MARK: GH-25 TC8

    func test_GH25_TC8_소감이있는완료위시는_소감을보여준다() {
        // Given
        let wish = Wish(id: "wish-1", title: "하프 마라톤 완주하기", isSuccess: true, finishNote: "끝까지 뛰었다!")

        // When
        let item = item(wish)

        // Then
        XCTAssertEqual(item.finishNote, "끝까지 뛰었다!")
        XCTAssertEqual(Strings.Home.FinishNote.cellFormat("끝까지 뛰었다!"), "“끝까지 뛰었다!”")
    }

    func test_GH25_TC8_소감이없거나_미완료위시는_소감이nil이라_뱃지줄그대로다() {
        // Given
        let finishedWithoutNote = Wish(id: "wish-1", title: "완료·소감 없음", isSuccess: true)
        let notFinishedWithNote = Wish(id: "wish-2", title: "미완료", isSuccess: false, finishNote: "남아 있으면 안 되는 소감")

        // When / Then
        XCTAssertNil(item(finishedWithoutNote).finishNote)
        XCTAssertNil(item(notFinishedWithNote).finishNote)
    }

    // MARK: GH-33 TC1

    func test_GH33_TC1_고정된위시는_셀에핀이보인다() {
        // Given
        let pinned = Wish(id: "wish-1", title: "고정", pinnedAt: Date())
        let notPinned = Wish(id: "wish-2", title: "미고정")

        // When / Then
        XCTAssertTrue(item(pinned).isPinned)
        XCTAssertFalse(item(notPinned).isPinned)
    }

    // MARK: GH-33 TC7

    func test_GH33_TC7_완료된위시는_고정메뉴를띄우지않고_메뉴입력도전달하지않는다() {
        // Given
        let finished = Wish(id: "wish-1", title: "완료", isSuccess: true)
        let sut = makeSut()
        load(sut, wishes: [finished])

        // When
        sut.send(.tapPinMenu(finished))

        // Then
        XCTAssertFalse(item(finished).canShowPinMenu)
        XCTAssertTrue(repository.updatePinCalls.isEmpty)
    }

    func test_GH33_TC7_미완료위시는_고정메뉴를띄우고_메뉴입력을위시와함께전달한다() {
        // Given
        let wish = Wish(id: "wish-1", title: "미완료")
        let sut = makeSut()
        load(sut, wishes: [wish])

        // When
        sut.send(.tapPinMenu(wish))

        // Then
        XCTAssertTrue(item(wish).canShowPinMenu)
        XCTAssertEqual(repository.updatePinCalls.map(\.wishId), ["wish-1"])
    }

    // MARK: GH-36 TC6

    func test_GH36_TC6_파일이름은있지만파일이없으면_그리드셀은사진없는상태다() {
        // Given
        photoStorage.existingFileNames = []
        let wish = Wish(id: "wish-1", title: "제주도 한 달 살기", photoFileName: "wish-1-restored.jpg")
        let sut = makeSut()
        load(sut, wishes: [wish])

        // When
        sut.send(.loadThumbnail(wishId: "wish-1", maxPixelSize: 600))

        // Then
        XCTAssertNil(sut.state.items.first?.photoFileName)
        XCTAssertTrue(photoStorage.loadThumbnailCalls.isEmpty)
    }

    // MARK: GH-36 TC7

    func test_GH36_TC7_사진있는위시만_사진파일이름을가지고_셀크기썸네일을요청한다() {
        // Given
        photoStorage.existingFileNames = ["wish-1-a.jpg"]
        photoStorage.thumbnailResult = Self.onePixelImage()
        let withPhoto = Wish(id: "wish-1", title: "제주도 한 달 살기", photoFileName: "wish-1-a.jpg")
        let withoutPhoto = Wish(id: "wish-2", title: "도쿄타워 야경 보기")
        let sut = makeSut()
        load(sut, wishes: [withPhoto, withoutPhoto])

        // When
        sut.send(.loadThumbnail(wishId: "wish-1", maxPixelSize: 696))
        sut.send(.loadThumbnail(wishId: "wish-2", maxPixelSize: 696))

        // Then
        XCTAssertEqual(sut.state.items.map(\.photoFileName), ["wish-1-a.jpg", nil])
        XCTAssertEqual(photoStorage.loadThumbnailCalls.map(\.fileName), ["wish-1-a.jpg"])
        XCTAssertEqual(photoStorage.loadThumbnailCalls.map(\.maxPixelSize), [696])
        XCTAssertEqual(sut.thumbnails.count, 1)
    }

    private static func onePixelImage() -> CGImage? {
        let context = CGContext(
            data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        return context?.makeImage()
    }

    // MARK: GH-31 TC8

    func test_GH31_TC8_가고싶어요탭이아니면_지도버튼이보이지않는다() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.selectCategory(.wantToDo))
        let wantToDo = sut.state.isPlaceMapVisible
        sut.send(.selectCategory(.wantToGet))
        let wantToGet = sut.state.isPlaceMapVisible

        // Then
        XCTAssertFalse(wantToDo)
        XCTAssertFalse(wantToGet)
    }

    func test_GH31_TC8_가고싶어요탭이면_지도버튼이보인다() {
        // Given
        let sut = makeSut()
        XCTAssertFalse(sut.state.isPlaceMapVisible)

        // When
        sut.send(.selectCategory(.wantToGo))

        // Then
        XCTAssertTrue(sut.state.isPlaceMapVisible)
    }

    // MARK: GH-31 TC13

    func test_GH31_TC13_지도버튼을탭하면_place_map클릭로그가1건전송되고_지도화면으로이동한다() {
        // Given
        let sut = makeSut()
        sut.send(.selectCategory(.wantToGo))

        // When
        sut.send(.tapPlaceMap)

        // Then
        let placeMapEvents = logManager.sentEvents
            .compactMap { $0 as? ClickEvent }
            .filter { ($0.extraParameters?[.objectId] as? LogObjectId) == .placeMap }
        XCTAssertEqual(placeMapEvents.count, 1)
        XCTAssertEqual(placeMapEvents.first?.screen, .home)
        XCTAssertEqual(placeMapEvents.first?.extraParameters?[.objectType] as? LogObjectType, .button)
        XCTAssertEqual(router.wishPath, [.placeMap])
    }
}

/// 홈 그리드 열 수·셀 크기 계산 (GH-11). 입력은 콘텐츠 폭 - 좌우 여백(20 * 2)
final class HomeGridLayoutFeatureTests: XCTestCase {
    private typealias Layout = HomeGridLayout

    private func availableWidth(containerWidth: CGFloat) -> CGFloat {
        containerWidth - 40
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
        // GH-12에서 넓은 화면의 홈 콘텐츠 폭을 600으로 제한해도 3열을 유지한다
        let width = availableWidth(containerWidth: HomeLayout.maxContentWidth)

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

    // MARK: GH-12 TC6 (카테고리 탭 줄)

    private let tabWidths: [CGFloat] = [70, 70, 70]

    func test_GH12_TC6_탭줄폭이400을넘어도_탭위치가400일때와같다() {
        // Given / When
        let wide = HomeCategoryTabLayout.tabOrigins(containerWidth: 951, tabWidths: tabWidths)
        let capped = HomeCategoryTabLayout.tabOrigins(containerWidth: 400, tabWidths: tabWidths)

        // Then
        XCTAssertEqual(wide, capped)
    }

    func test_GH12_TC6_아이폰폭에서는_탭이기존처럼양끝여백20안에균등분배된다() {
        // Given / When
        let origins = HomeCategoryTabLayout.tabOrigins(containerWidth: 390, tabWidths: tabWidths)

        // Then
        XCTAssertEqual(origins.first, 20)
        XCTAssertEqual((origins.last ?? 0) + (tabWidths.last ?? 0), 390 - 20, accuracy: 0.001)
        XCTAssertEqual(origins[1] - origins[0] - tabWidths[0], origins[2] - origins[1] - tabWidths[1], accuracy: 0.001)
    }

    // MARK: GH-10 TC7

    func test_GH10_TC7_홈헤더_일러스트가_safeArea오른쪽inset을침범하지않는다() {
        // Given / When / Then: 일러스트는 safe area 안쪽 콘텐츠 기준 오른쪽 20pt 여백에 둔다
        XCTAssertEqual(HomeHeaderLayout.illustrationTrailingInset, 20)
        XCTAssertEqual(HomeHeaderLayout.illustrationSize, 100)
    }
}
