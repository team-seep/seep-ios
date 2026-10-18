import XCTest
import Combine

@testable import seep_ios_dev

/// 홈의 배지 진입점·축하 시점 (GH-35)
final class HomeViewModelBadgeTests: XCTestCase {
    private var sut: HomeViewModel!
    private var repository: MockWishRepository!
    private var preference: Preference!
    private var logManager: MockLogManager!
    private var routes: [HomeViewModel.Route] = []
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
        preference = Preference(name: "test-gh35-badge")
        logManager = MockLogManager()
        routes = []
    }

    override func tearDown() {
        sut = nil
        repository = nil
        preference = nil
        logManager = nil
        cancellables = []
        super.tearDown()
    }

    private func makeSut() {
        sut = HomeViewModel(dependency: .init(
            wishRepository: repository,
            preference: preference,
            notificationManager: MockNotificationManager(),
            logManager: logManager
        ))
        sut.output.route
            .sink { [weak self] in self?.routes.append($0) }
            .store(in: &cancellables)
    }

    private func finished(_ category: seep_ios_dev.Category = .wantToGet, endDate: Date? = nil, finishDate: Date = Date()) -> Wish {
        return Wish(category: category, endDate: endDate, finishDate: finishDate, isSuccess: true)
    }

    private var overviewBadgeCount: Int? {
        for section in sut.output.dataSource.value {
            for item in section.items {
                if case .overview(_, _, let badgeCount) = item { return badgeCount }
            }
        }
        return nil
    }

    private var celebrationViewModels: [BadgeCelebrationViewModel] {
        return routes.compactMap {
            if case .presentBadgeCelebration(let viewModel) = $0 { return viewModel }
            return nil
        }
    }

    /// 위시 하나를 홈에서 완료하고, 저장소의 완료 목록을 `finishedAfter`로 바꾼다
    private func finish(_ wish: Wish, finishedAfter: [Wish]) -> FinishNoteViewModel? {
        repository.fetchWishesResult = [wish]
        sut.input.updateCategory.send(wish.category)
        var finishedWish = wish
        finishedWish.isSuccess = true
        finishedWish.finishDate = Date()
        repository.finishWishResult = .success(finishedWish)
        repository.fetchAllFinishedWishesResult = finishedAfter
        sut.input.didTapFinish.send(wish)
        return routes.compactMap {
            if case .presentFinishNoteBottomSheet(let viewModel) = $0 { return viewModel }
            return nil
        }.last
    }

    // MARK: GH-35 TC1

    func test_GH35_TC1_완료위시가0개면_홈링크는배지0개다() {
        // Given
        repository.fetchAllFinishedWishesResult = []
        makeSut()

        // When
        sut.input.firstLoad.send(())

        // Then
        XCTAssertEqual(overviewBadgeCount, 0)
        XCTAssertEqual(Strings.Home.badgeLinkFormat(overviewBadgeCount ?? -1, BadgeType.allCases.count), "배지 0/8 모아보기")
    }

    // MARK: GH-35 TC5

    func test_GH35_TC5_새배지가생기면_소감시트가닫힌뒤에만_축하시트route가나오고_배지id가저장된다() {
        // Given: 완료 0개인 사용자
        makeSut()
        sut.input.firstLoad.send(())
        let wish = Wish(category: .wantToGet, title: "새 신발")

        // When: 완료 → 소감 시트
        let finishNote = finish(wish, finishedAfter: [finished(.wantToGet)])

        // Then: 소감 시트가 닫히기 전에는 축하 없음
        XCTAssertNotNil(finishNote)
        XCTAssertTrue(celebrationViewModels.isEmpty)
        XCTAssertTrue(preference.celebratedBadgeIds.isEmpty)
        XCTAssertEqual(overviewBadgeCount, 2)

        // When: 소감 시트 닫힘(건너뛰기)
        finishNote?.input.didTapSkip.send(())
        finishNote?.input.didDismiss.send(())

        // Then
        XCTAssertEqual(celebrationViewModels.count, 1)
        XCTAssertEqual(celebrationViewModels.first?.output.badges.map(\.type), [.finish1, .firstWantToGet])
        XCTAssertEqual(preference.celebratedBadgeIds, ["finish_1", "first_want_to_get"])
    }

    // MARK: GH-35 TC6

    func test_GH35_TC6_한번완료로배지3개를얻으면_축하시트1장에3개가모두나온다() {
        // Given
        makeSut()
        sut.input.firstLoad.send(())
        let today = Date()
        let wish = Wish(category: .wantToDo, endDate: today)

        // When
        let finishNote = finish(wish, finishedAfter: [finished(.wantToDo, endDate: today, finishDate: today)])
        finishNote?.input.didDismiss.send(())

        // Then
        XCTAssertEqual(celebrationViewModels.count, 1)
        XCTAssertEqual(celebrationViewModels.first?.output.badges.map(\.type), [.finish1, .firstWantToDo, .onTime])
        XCTAssertEqual(celebrationViewModels.first?.output.finishedCount, 1)
    }

    // MARK: GH-35 TC7

    func test_GH35_TC7_이미축하한배지만있으면_완료해도축하시트가뜨지않는다() {
        // Given: 첫 싶·첫 갖고 싶어요를 이미 축하함
        repository.fetchAllFinishedWishesResult = [finished(.wantToGet)]
        makeSut()
        sut.input.firstLoad.send(())
        preference.celebratedBadgeIds = ["finish_1", "first_want_to_get"]

        // When: 갖고 싶어요 하나 더 완료 (새 배지 없음)
        let finishNote = finish(Wish(category: .wantToGet), finishedAfter: [finished(.wantToGet), finished(.wantToGet)])
        finishNote?.input.didDismiss.send(())

        // Then
        XCTAssertNotNil(finishNote)
        XCTAssertTrue(celebrationViewModels.isEmpty)
    }

    // MARK: GH-35 TC8

    func test_GH35_TC8_기존사용자첫진입이면_축하없이얻은배지를축하함으로저장하고_이후완료에도다시뜨지않는다() {
        // Given: 완료 12개(모두 갖고 싶어요)인 기존 사용자, 첫 업데이트 실행
        let twelve = (0..<12).map { _ in finished(.wantToGet) }
        repository.fetchAllFinishedWishesResult = twelve
        makeSut()
        XCTAssertFalse(preference.isBadgeInitialized)

        // When
        sut.input.firstLoad.send(())

        // Then
        XCTAssertTrue(celebrationViewModels.isEmpty)
        XCTAssertTrue(preference.isBadgeInitialized)
        XCTAssertEqual(preference.celebratedBadgeIds, ["finish_1", "finish_5", "finish_10", "first_want_to_get"])

        // When: 갖고 싶어요 하나 더 완료 (13개, 새 배지 없음)
        let finishNote = finish(Wish(category: .wantToGet), finishedAfter: twelve + [finished(.wantToGet)])
        finishNote?.input.didDismiss.send(())

        // Then
        XCTAssertTrue(celebrationViewModels.isEmpty)
    }

    func test_GH35_TC8_초기화는한번만해서_이후에얻은배지는축하한다() {
        // Given: 이미 초기화한 사용자(완료 0개 때)
        preference.isBadgeInitialized = true
        repository.fetchAllFinishedWishesResult = [finished(.wantToGet)]
        makeSut()

        // When
        sut.input.firstLoad.send(())
        let finishNote = finish(Wish(category: .wantToGet), finishedAfter: [finished(.wantToGet)])
        finishNote?.input.didDismiss.send(())

        // Then
        XCTAssertEqual(celebrationViewModels.first?.output.badges.map(\.type), [.finish1, .firstWantToGet])
    }

    // MARK: GH-35 TC9

    func test_GH35_TC9_완료취소로4개가되면_다섯번째싶이잠기고_다시5개가되어도축하시트가뜨지않는다() {
        // Given: 완료 5개(갖고 싶어요), finish_5 까지 축하함
        let five = (0..<5).map { _ in finished(.wantToGet) }
        repository.fetchAllFinishedWishesResult = five
        makeSut()
        sut.input.firstLoad.send(())
        XCTAssertEqual(overviewBadgeCount, 3)
        XCTAssertTrue(preference.celebratedBadgeIds.contains("finish_5"))

        // When: 상세에서 완료 하나 취소 → 4개
        repository.fetchAllFinishedWishesResult = Array(five.prefix(4))
        sut.input.cancelFinish.send(five[4])

        // Then
        XCTAssertEqual(overviewBadgeCount, 2)

        // When: 다시 완료해 5개
        let finishNote = finish(Wish(category: .wantToGet), finishedAfter: five)
        finishNote?.input.didDismiss.send(())

        // Then
        XCTAssertEqual(overviewBadgeCount, 3)
        XCTAssertTrue(celebrationViewModels.isEmpty)
        XCTAssertTrue(preference.celebratedBadgeIds.contains("finish_5"))
    }

    // MARK: GH-35 TC10

    func test_GH35_TC10_배지모아보기를탭하면_배지모아보기route가나온다() {
        // Given
        makeSut()
        sut.input.firstLoad.send(())

        // When
        sut.input.didTapBadgeCollection.send(())

        // Then
        XCTAssertEqual(routes.count, 1)
        guard case .pushBadgeCollection = routes.first else {
            return XCTFail("배지 모아보기 route 가 아니다")
        }
    }

    // MARK: GH-35 TC11

    func test_GH35_TC11_축하시트에서배지모아보기를탭하면_배지모아보기route가나온다() {
        // Given
        makeSut()
        sut.input.firstLoad.send(())
        let finishNote = finish(Wish(category: .wantToGet), finishedAfter: [finished(.wantToGet)])
        finishNote?.input.didDismiss.send(())
        let celebration = celebrationViewModels.first

        // When
        celebration?.input.didTapViewBadges.send(())

        // Then
        guard case .pushBadgeCollection = routes.last else {
            return XCTFail("배지 모아보기 route 가 아니다")
        }
    }

    // MARK: GH-35 TC12

    func test_GH35_TC12_배지모아보기를탭하면_badge_collection클릭로그가1건전송된다() {
        // Given
        makeSut()
        sut.input.firstLoad.send(())

        // When
        sut.input.didTapBadgeCollection.send(())

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.parameters[ParameterName.screen.rawValue] as? String, "home")
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(event?.parameters[ParameterName.objectId.rawValue] as? String, "badge_collection")
    }
}
