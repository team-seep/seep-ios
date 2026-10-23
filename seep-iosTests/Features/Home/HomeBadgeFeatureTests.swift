import XCTest

@testable import seep_ios_dev

/// 홈의 배지 축하 시점·축하 시트 (GH-35). 기존 HomeViewModelBadgeTests·BadgeCelebrationViewModelTests 이전.
/// "배지 n/8 모아보기" 링크는 이룬 싶 탭으로 옮겨 갔다 (GH-64 R-12, R-18)
final class HomeBadgeFeatureTests: HomeFeatureTestCase {
    private var sut: HomeViewModel!

    override func setUp() {
        super.setUp()
        preference = Preference(name: "test-gh35-badge")
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    private func makeHome() {
        sut = makeSut()
    }

    private func finished(_ category: seep_ios_dev.Category = .wantToGet, endDate: Date? = nil, finishDate: Date = Date()) -> Wish {
        Wish(category: category, endDate: endDate, finishDate: finishDate, isSuccess: true)
    }

    private var earnedBadgeCount: Int {
        sut.state.badges.filter(\.isEarned).count
    }

    /// 위시 하나를 홈에서 완료하고, 저장소의 완료 목록을 `finishedAfter`로 바꾼다. 떠 있는 소감 시트를 돌려준다
    private func finish(_ wish: Wish, finishedAfter: [Wish]) -> FinishNoteViewModel? {
        repository.fetchWishesResult = [wish]
        sut.send(.selectCategory(wish.category))
        var finishedWish = wish
        finishedWish.isSuccess = true
        finishedWish.finishDate = Date()
        repository.finishWishResult = .success(finishedWish)
        repository.fetchAllFinishedWishesResult = finishedAfter
        sut.send(.tapFinish(wish))
        return finishNoteViewModel(of: sut)
    }

    // MARK: GH-35 TC1

    func test_GH35_TC1_완료위시가0개면_홈링크는배지0개다() {
        // Given
        repository.fetchAllFinishedWishesResult = []
        makeHome()

        // When
        sut.send(.onAppear)

        // Then
        XCTAssertEqual(earnedBadgeCount, 0)
        XCTAssertEqual(Strings.Home.badgeLinkFormat(earnedBadgeCount, BadgeType.allCases.count), "배지 0/8 모아보기")
    }

    // MARK: GH-35 TC5

    func test_GH35_TC5_새배지가생기면_소감시트가닫힌뒤에만_축하시트route가나오고_배지id가저장된다() {
        // Given: 완료 0개인 사용자
        makeHome()
        sut.send(.onAppear)
        let wish = Wish(category: .wantToGet, title: "새 신발")

        // When: 완료 → 소감 시트
        let finishNote = finish(wish, finishedAfter: [finished(.wantToGet)])

        // Then: 소감 시트가 닫히기 전에는 축하 없음
        XCTAssertNotNil(finishNote)
        XCTAssertNil(celebrationViewModel(of: sut))
        XCTAssertTrue(preference.celebratedBadgeIds.isEmpty)
        XCTAssertEqual(earnedBadgeCount, 2)

        // When: 소감 시트 닫힘(건너뛰기)
        finishNote?.send(.tapSkip)
        sut.send(.sheetDismissed)

        // Then
        XCTAssertEqual(celebrationViewModel(of: sut)?.badges.map(\.type), [.finish1, .firstWantToGet])
        XCTAssertEqual(preference.celebratedBadgeIds, ["finish_1", "first_want_to_get"])
    }

    // MARK: GH-35 TC6

    func test_GH35_TC6_한번완료로배지3개를얻으면_축하시트1장에3개가모두나온다() {
        // Given
        makeHome()
        sut.send(.onAppear)
        let today = Date()
        let wish = Wish(category: .wantToDo, endDate: today)

        // When
        _ = finish(wish, finishedAfter: [finished(.wantToDo, endDate: today, finishDate: today)])
        sut.send(.sheetDismissed)

        // Then
        XCTAssertEqual(celebrationViewModel(of: sut)?.badges.map(\.type), [.finish1, .firstWantToDo, .onTime])
        XCTAssertEqual(celebrationViewModel(of: sut)?.finishedCount, 1)
    }

    // MARK: GH-35 TC7

    func test_GH35_TC7_이미축하한배지만있으면_완료해도축하시트가뜨지않는다() {
        // Given: 첫 싶·첫 갖고 싶어요를 이미 축하함
        repository.fetchAllFinishedWishesResult = [finished(.wantToGet)]
        makeHome()
        sut.send(.onAppear)
        preference.celebratedBadgeIds = ["finish_1", "first_want_to_get"]

        // When: 갖고 싶어요 하나 더 완료 (새 배지 없음)
        let finishNote = finish(Wish(category: .wantToGet), finishedAfter: [finished(.wantToGet), finished(.wantToGet)])
        sut.send(.sheetDismissed)

        // Then
        XCTAssertNotNil(finishNote)
        XCTAssertNil(celebrationViewModel(of: sut))
    }

    // MARK: GH-35 TC8

    func test_GH35_TC8_기존사용자첫진입이면_축하없이얻은배지를축하함으로저장하고_이후완료에도다시뜨지않는다() {
        // Given: 완료 12개(모두 갖고 싶어요)인 기존 사용자, 첫 업데이트 실행
        let twelve = (0..<12).map { _ in finished(.wantToGet) }
        repository.fetchAllFinishedWishesResult = twelve
        makeHome()
        XCTAssertFalse(preference.isBadgeInitialized)

        // When
        sut.send(.onAppear)

        // Then
        XCTAssertNil(celebrationViewModel(of: sut))
        XCTAssertTrue(preference.isBadgeInitialized)
        XCTAssertEqual(preference.celebratedBadgeIds, ["finish_1", "finish_5", "finish_10", "first_want_to_get"])

        // When: 갖고 싶어요 하나 더 완료 (13개, 새 배지 없음)
        _ = finish(Wish(category: .wantToGet), finishedAfter: twelve + [finished(.wantToGet)])
        sut.send(.sheetDismissed)

        // Then
        XCTAssertNil(celebrationViewModel(of: sut))
    }

    func test_GH35_TC8_초기화는한번만해서_이후에얻은배지는축하한다() {
        // Given: 이미 초기화한 사용자(완료 0개 때)
        preference.isBadgeInitialized = true
        repository.fetchAllFinishedWishesResult = [finished(.wantToGet)]
        makeHome()

        // When
        sut.send(.onAppear)
        _ = finish(Wish(category: .wantToGet), finishedAfter: [finished(.wantToGet)])
        sut.send(.sheetDismissed)

        // Then
        XCTAssertEqual(celebrationViewModel(of: sut)?.badges.map(\.type), [.finish1, .firstWantToGet])
    }

    // MARK: GH-35 TC9

    func test_GH35_TC9_완료취소로4개가되면_다섯번째싶이잠기고_다시5개가되어도축하시트가뜨지않는다() {
        // Given: 완료 5개(갖고 싶어요), finish_5 까지 축하함
        let five = (0..<5).map { _ in finished(.wantToGet) }
        repository.fetchAllFinishedWishesResult = five
        makeHome()
        sut.send(.onAppear)
        XCTAssertEqual(earnedBadgeCount, 3)
        XCTAssertTrue(preference.celebratedBadgeIds.contains("finish_5"))

        // When: 상세에서 완료 하나 취소 → 4개, 싶 탭으로 돌아옴
        repository.fetchAllFinishedWishesResult = Array(five.prefix(4))
        sut.send(.onAppear)

        // Then
        XCTAssertEqual(earnedBadgeCount, 2)

        // When: 다시 완료해 5개
        _ = finish(Wish(category: .wantToGet), finishedAfter: five)
        sut.send(.sheetDismissed)

        // Then
        XCTAssertEqual(earnedBadgeCount, 3)
        XCTAssertNil(celebrationViewModel(of: sut))
        XCTAssertTrue(preference.celebratedBadgeIds.contains("finish_5"))
    }

    // MARK: GH-35 TC11

    func test_GH35_TC11_축하시트에서배지모아보기를탭하면_배지모아보기route가나온다() {
        // Given
        makeHome()
        sut.send(.onAppear)
        _ = finish(Wish(category: .wantToGet), finishedAfter: [finished(.wantToGet)])
        sut.send(.sheetDismissed)
        let celebration = celebrationViewModel(of: sut)

        // When
        celebration?.send(.tapViewBadges)

        // Then
        XCTAssertEqual(router.wishPath, [.badgeCollection])
        XCTAssertNil(sut.state.sheet)
    }

    // MARK: GH-64 TC802

    func test_GH64_TC802_새배지축하는한번만뜨고_배지보기를누르면_모아보기로가며_완료흐름이끝난다() {
        // Given
        makeHome()
        sut.send(.onAppear)
        let wish = Wish(id: "wish-1", category: .wantToGet)
        _ = finish(wish, finishedAfter: [finished(.wantToGet)])
        sut.send(.sheetDismissed)
        XCTAssertNotNil(celebrationViewModel(of: sut))

        // When
        celebrationViewModel(of: sut)?.send(.tapViewBadges)
        let second = finish(Wish(id: "wish-2", category: .wantToGet), finishedAfter: [finished(.wantToGet), finished(.wantToGet)])
        sut.send(.sheetDismissed)

        // Then
        XCTAssertNotNil(second)
        XCTAssertNil(celebrationViewModel(of: sut), "이미 축하한 배지는 다시 축하하지 않는다")
        XCTAssertEqual(router.wishPath, [.badgeCollection])
        XCTAssertTrue(router.showsFinishedDot)
    }
}

/// 새 배지 축하 시트 (기존 BadgeCelebrationViewModelTests 이전)
final class BadgeCelebrationFeatureTests: ViewModelTestCase {
    private func makeViewModel(badgeTypes: [BadgeType]) -> BadgeCelebrationViewModel {
        let badges = badgeTypes.map { Badge(type: $0, earnedDate: Date(), finishedCount: 1) }
        return BadgeCelebrationViewModel(
            config: .init(badges: badges, finishedCount: 1),
            dependency: .init(logManager: logManager)
        )
    }

    // MARK: GH-35 TC11

    func test_GH35_TC11_배지모아보기를탭하면_모아보기이동이벤트가나온다() {
        // Given
        let viewModel = makeViewModel(badgeTypes: [.finish1])
        var tapCount = 0
        viewModel.onViewBadges = { tapCount += 1 }

        // When
        viewModel.send(.tapViewBadges)

        // Then
        XCTAssertEqual(tapCount, 1)
    }

    func test_GH35_TC11_좋아요를탭하면_시트를닫는다() {
        // Given
        let viewModel = makeViewModel(badgeTypes: [.finish1])

        // When
        viewModel.send(.tapConfirm)

        // Then
        XCTAssertEqual(viewModel.route, .dismiss)
    }

    // MARK: GH-35 TC13

    func test_GH35_TC13_축하시트가뜨면_new_badge노출로그가배지id를쉼표로묶어1건전송된다() {
        // Given
        let viewModel = makeViewModel(badgeTypes: [.finish1, .firstWantToDo])

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
        XCTAssertEqual(event?.name, .impression)
        XCTAssertEqual(event?.parameters[ParameterName.screen.rawValue] as? String, "badge_bottom_sheet")
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "card")
        XCTAssertEqual(event?.parameters[ParameterName.objectId.rawValue] as? String, "new_badge")
        XCTAssertEqual(event?.parameters[ParameterName.badgeId.rawValue] as? String, "finish_1,first_want_to_do")
    }

    // MARK: GH-35 TC14

    func test_GH35_TC14_배지모아보기를탭하면_view_badges클릭로그가1건전송된다() {
        // Given
        let viewModel = makeViewModel(badgeTypes: [.finish1])

        // When
        viewModel.send(.tapViewBadges)

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.parameters[ParameterName.screen.rawValue] as? String, "badge_bottom_sheet")
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(event?.parameters[ParameterName.objectId.rawValue] as? String, "view_badges")
    }
}
