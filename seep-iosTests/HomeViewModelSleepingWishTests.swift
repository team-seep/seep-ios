import XCTest
import Combine

@testable import seep_ios_dev

/// GH-30 오래 잠든 위시에 "아직 하고 싶어요?" 다시 묻기 — 홈 카드 동작
final class HomeViewModelSleepingWishTests: XCTestCase {
    private var sut: HomeViewModel!
    private var mockRepository: MockWishRepository!
    private var mockNotificationManager: MockNotificationManager!
    private var mockLogManager: MockLogManager!
    private var cancellables: Set<AnyCancellable>!
    private var toasts: [String] = []
    private var routes: [HomeViewModel.Route] = []

    private let calendar = Calendar.current
    private lazy var today: Date = {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 13)) ?? Date()
    }()

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        mockNotificationManager = MockNotificationManager()
        mockLogManager = MockLogManager()
        cancellables = []
        toasts = []
        routes = []

        let fixedToday = today
        sut = HomeViewModel(dependency: .init(
            wishRepository: mockRepository,
            preference: Preference(name: "test"),
            notificationManager: mockNotificationManager,
            logManager: mockLogManager,
            dateProvider: { fixedToday }
        ))
        sut.output.toast
            .sink { [weak self] in self?.toasts.append($0) }
            .store(in: &cancellables)
        sut.output.route
            .sink { [weak self] in self?.routes.append($0) }
            .store(in: &cancellables)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockNotificationManager = nil
        mockLogManager = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: Helpers

    private func daysAgo(_ days: Int) -> Date {
        return calendar.date(byAdding: .day, value: -days, to: today) ?? today
    }

    private func wishSectionItems() -> [HomeSectionItem] {
        let section = sut.output.dataSource.value.first {
            if case .wish = $0.type { return true }
            return false
        }
        return section?.items ?? []
    }

    private func sleepingCard() -> HomeSleepingWishCardViewModel? {
        guard case .sleepingWish(let viewModel) = wishSectionItems().first else { return nil }
        return viewModel
    }

    private func listedWishIds() -> [String] {
        return wishSectionItems().compactMap {
            guard case .wish(let viewModel) = $0 else { return nil }
            return viewModel.output.wish.id
        }
    }

    private func overviewCount() -> Int? {
        guard case .overview(_, let count) = sut.output.dataSource.value.first?.items.first else { return nil }
        return count
    }

    private func events(objectId: String) -> [any LogEventType] {
        return mockLogManager.sentEvents.filter {
            $0.parameters[ParameterName.objectId.rawValue] as? String == objectId
        }
    }

    private func load(_ wishes: [Wish], count: Int? = nil) {
        mockRepository.fetchWishesResult = wishes
        mockRepository.fetchNotFinishCountResult = count ?? wishes.filter { !$0.isSuccess }.count
        sut.input.firstLoad.send()
    }

    // MARK: GH-30 TC1

    func test_GH30_TC1_61일된일정없는위시가있으면_리스트맨위에카드가보이고_리스트에도그대로있다() {
        // Given
        let sleeping = Wish(id: "sleeping", emoji: "🎸", title: "기타 치기", createdAt: daysAgo(61))
        let fresh = Wish(id: "fresh", title: "새 위시", createdAt: daysAgo(1))

        // When
        load([fresh, sleeping])

        // Then
        XCTAssertEqual(sleepingCard()?.output.wish.id, "sleeping")
        XCTAssertEqual(sleepingCard()?.output.caption, "61일째 그대로예요")
        XCTAssertEqual(listedWishIds(), ["fresh", "sleeping"])
    }

    // MARK: GH-30 TC2

    func test_GH30_TC2_59일된위시만있으면_카드가보이지않는다() {
        // Given
        let wish = Wish(id: "young", createdAt: daysAgo(59))

        // When
        load([wish])

        // Then
        XCTAssertNil(sleepingCard())
        XCTAssertEqual(listedWishIds(), ["young"])
    }

    // MARK: GH-30 TC3

    func test_GH30_TC3_마감일이다음달인오래된위시는_카드에오르지않는다() {
        // Given
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: today)
        let wish = Wish(id: "planned", endDate: nextMonth, createdAt: daysAgo(90))

        // When
        load([wish])

        // Then
        XCTAssertNil(sleepingCard())
    }

    // MARK: GH-30 TC4

    func test_GH30_TC4_오래된완료위시는_카드에오르지않는다() {
        // Given
        let wish = Wish(id: "done", isSuccess: true, createdAt: daysAgo(90))

        // When
        load([wish])

        // Then
        XCTAssertNil(sleepingCard())
    }

    // MARK: GH-30 TC5

    func test_GH30_TC5_잠든위시가70일과100일이면_100일된위시하나만카드로보인다() {
        // Given
        let seventy = Wish(id: "70", createdAt: daysAgo(70))
        let hundred = Wish(id: "100", createdAt: daysAgo(100))

        // When
        load([seventy, hundred])

        // Then
        XCTAssertEqual(sleepingCard()?.output.wish.id, "100")
        XCTAssertEqual(wishSectionItems().filter {
            if case .sleepingWish = $0 { return true }
            return false
        }.count, 1)
    }

    // MARK: GH-30 TC6

    func test_GH30_TC6_여전히하고싶어요를탭하면_점검일을저장하고_카드를숨기고_토스트를띄운다() {
        // Given
        let wish = Wish(id: "sleeping", title: "기타 치기", createdAt: daysAgo(80))
        load([wish])

        // When
        sleepingCard()?.input.didTapKeep.send()

        // Then
        XCTAssertEqual(mockRepository.markCheckedCalledIds, ["sleeping"])
        XCTAssertNil(sleepingCard())
        XCTAssertEqual(toasts, ["좋아요! 두 달 뒤에 다시 물어볼게요"])
        XCTAssertEqual(listedWishIds(), ["sleeping"])
    }

    func test_GH30_TC6_처리한뒤에는_같은실행에서_다음잠든위시를이어서띄우지않는다() {
        // Given
        let older = Wish(id: "older", createdAt: daysAgo(100))
        let younger = Wish(id: "younger", createdAt: daysAgo(70))
        load([older, younger])

        // When
        sleepingCard()?.input.didTapKeep.send()
        sut.input.updateCategory.send(.wantToDo)

        // Then
        XCTAssertNil(sleepingCard())
    }

    func test_GH30_TC6_저장에실패하면_에러알럿을띄우고_카드를유지한다() {
        // Given
        let wish = Wish(id: "sleeping", createdAt: daysAgo(80))
        mockRepository.markCheckedResult = .failure(.writeFailed)
        load([wish])

        // When
        sleepingCard()?.input.didTapKeep.send()

        // Then
        XCTAssertEqual(sleepingCard()?.output.wish.id, "sleeping")
        XCTAssertTrue(toasts.isEmpty)
        guard case .showErrorAlert = routes.last else { return XCTFail("에러 알럿 route 가 없다") }
    }

    // MARK: GH-30 TC7

    func test_GH30_TC7_이제됐어요를탭하면_보내주기확인알럿을띄우고_아직지우지않는다() {
        // Given
        let wish = Wish(id: "sleeping", createdAt: daysAgo(80))
        load([wish])

        // When
        sleepingCard()?.input.didTapRelease.send()

        // Then
        guard case .showReleaseSleepingWishAlert(let target) = routes.last else {
            return XCTFail("보내주기 확인 알럿 route 가 없다")
        }
        XCTAssertEqual(target.id, "sleeping")
        XCTAssertTrue(mockRepository.deleteWishCalledIds.isEmpty)
    }

    func test_GH30_TC7_보내주기를확정하면_삭제하고_알림을취소하고_개수가1줄고_카드가사라진다() {
        // Given
        let sleeping = Wish(
            id: "sleeping",
            endDate: daysAgo(3),
            notifications: [SeepNotification(type: .dayAgo)],
            createdAt: daysAgo(80)
        )
        let other = Wish(id: "other", createdAt: daysAgo(1))
        load([sleeping, other])
        XCTAssertEqual(overviewCount(), 2)
        mockRepository.fetchNotFinishCountResult = 1

        // When
        sut.input.didConfirmReleaseSleepingWish.send(sleeping)

        // Then
        XCTAssertEqual(mockRepository.deleteWishCalledIds, ["sleeping"])
        XCTAssertEqual(mockNotificationManager.cancelledWishes.map(\.id), ["sleeping"])
        XCTAssertEqual(overviewCount(), 1)
        XCTAssertNil(sleepingCard())
        XCTAssertEqual(listedWishIds(), ["other"])
        XCTAssertEqual(toasts, ["위시를 보내줬어요"])
    }

    // MARK: GH-30 TC8

    func test_GH30_TC8_이제됐어요후_취소하면_위시와카드가그대로다() {
        // Given
        let wish = Wish(id: "sleeping", createdAt: daysAgo(80))
        load([wish])

        // When: 알럿에서 취소하면 확정 입력이 오지 않는다
        sleepingCard()?.input.didTapRelease.send()

        // Then
        XCTAssertTrue(mockRepository.deleteWishCalledIds.isEmpty)
        XCTAssertTrue(mockNotificationManager.cancelledWishes.isEmpty)
        XCTAssertEqual(sleepingCard()?.output.wish.id, "sleeping")
        XCTAssertEqual(listedWishIds(), ["sleeping"])
        XCTAssertEqual(overviewCount(), 1)
    }

    // MARK: GH-30 TC9

    func test_GH30_TC9_카드위시를수정해저장하고돌아오면_카드가사라진다() {
        // Given
        var wish = Wish(id: "sleeping", title: "기타 치기", createdAt: daysAgo(70))
        load([wish])
        XCTAssertNotNil(sleepingCard())

        // When: 수정 화면이 lastCheckedAt 을 지금으로 담아 돌려준다 (R-2)
        wish.title = "기타로 노래 한 곡 치기"
        wish.lastCheckedAt = today
        sut.input.updateWish.send(wish)

        // Then
        XCTAssertNil(sleepingCard())
        XCTAssertEqual(listedWishIds(), ["sleeping"])
    }

    // MARK: GH-30 TC10

    func test_GH30_TC10_완료된위시만필터를켜면_카드가보이지않고_끄면다시보인다() {
        // Given
        let wish = Wish(id: "sleeping", createdAt: daysAgo(80))
        load([wish])

        // When
        sut.input.updateOnlyFinished.send(true)
        let cardWhileOnlyFinished = sleepingCard()
        sut.input.updateOnlyFinished.send(false)

        // Then
        XCTAssertNil(cardWhileOnlyFinished)
        XCTAssertEqual(sleepingCard()?.output.wish.id, "sleeping")
    }

    // MARK: GH-30 TC12

    func test_GH30_TC12_갖고싶어요탭의잠든위시는_갖고싶어요문구로묻는다() {
        // Given
        let wish = Wish(id: "camera", category: .wantToGet, title: "필름 카메라", createdAt: daysAgo(80))
        mockRepository.fetchWishesResult = [wish]
        mockRepository.fetchNotFinishCountResult = 1

        // When
        sut.input.updateCategory.send(.wantToGet)

        // Then
        XCTAssertEqual(sleepingCard()?.output.question, "아직 갖고 싶어요?")
        XCTAssertEqual(sleepingCard()?.output.keepTitle, "여전히 갖고 싶어요")
    }

    func test_GH30_TC12_하고싶어요가고싶어요탭은_각카테고리문구로묻는다() {
        // Given
        let doWish = Wish(id: "do", category: .wantToDo, createdAt: daysAgo(80))
        let goWish = Wish(id: "go", category: .wantToGo, createdAt: daysAgo(80))

        // When
        let doCard = HomeSleepingWishCardViewModel(config: .init(wish: doWish, daysSinceTouched: 80))
        let goCard = HomeSleepingWishCardViewModel(config: .init(wish: goWish, daysSinceTouched: 80))

        // Then
        XCTAssertEqual(doCard.output.question, "아직 하고 싶어요?")
        XCTAssertEqual(doCard.output.keepTitle, "여전히 하고 싶어요")
        XCTAssertEqual(goCard.output.question, "아직 가고 싶어요?")
        XCTAssertEqual(goCard.output.keepTitle, "여전히 가고 싶어요")
        XCTAssertEqual(goCard.output.releaseTitle, "이제 됐어요")
    }

    // MARK: GH-30 TC13

    func test_GH30_TC13_카드가처음보이면_sleeping_wish_card노출로그가1건전송되고_다시그려도더보내지않는다() {
        // Given
        let wish = Wish(id: "sleeping", createdAt: daysAgo(80))

        // When
        load([wish])
        sut.input.updateViewType.send(.grid)
        sut.input.updateSortOrder.send(.latestOrder)
        sut.input.updateViewType.send(.list)

        // Then
        let impressions = events(objectId: "sleeping_wish_card")
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.name, .impression)
        XCTAssertEqual(impressions.first?.parameters[ParameterName.screen.rawValue] as? String, "home")
        XCTAssertEqual(impressions.first?.parameters[ParameterName.objectType.rawValue] as? String, "card")
        XCTAssertEqual(impressions.first?.parameters[ParameterName.category.rawValue] as? String, seep_ios_dev.Category.wantToDo.rawValue)
    }

    func test_GH30_TC13_잠든위시가없으면_노출로그를보내지않는다() {
        // Given
        let wish = Wish(id: "fresh", createdAt: daysAgo(3))

        // When
        load([wish])

        // Then
        XCTAssertTrue(events(objectId: "sleeping_wish_card").isEmpty)
    }

    // MARK: GH-30 TC14

    func test_GH30_TC14_여전히하고싶어요가저장되면_keep_sleeping_wish클릭로그가1건전송된다() {
        // Given
        let wish = Wish(id: "sleeping", createdAt: daysAgo(80))
        load([wish])

        // When
        sleepingCard()?.input.didTapKeep.send()

        // Then
        let clicks = events(objectId: "keep_sleeping_wish")
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.name, .click)
        XCTAssertEqual(clicks.first?.parameters[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(clicks.first?.parameters[ParameterName.category.rawValue] as? String, seep_ios_dev.Category.wantToDo.rawValue)
    }

    // MARK: GH-30 TC15

    func test_GH30_TC15_보내주기를확정하면_release_sleeping_wish클릭로그가1건전송된다() {
        // Given
        let wish = Wish(id: "sleeping", createdAt: daysAgo(80))
        load([wish])

        // When
        sut.input.didConfirmReleaseSleepingWish.send(wish)

        // Then
        let clicks = events(objectId: "release_sleeping_wish")
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.name, .click)
        XCTAssertEqual(clicks.first?.parameters[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(clicks.first?.parameters[ParameterName.screen.rawValue] as? String, "home")
    }

    func test_GH30_TC15_이제됐어요만누르면_release로그를보내지않는다() {
        // Given
        let wish = Wish(id: "sleeping", createdAt: daysAgo(80))
        load([wish])

        // When
        sleepingCard()?.input.didTapRelease.send()

        // Then
        XCTAssertTrue(events(objectId: "release_sleeping_wish").isEmpty)
    }

    // MARK: 회귀

    func test_회귀_카드가맨위에있으면_스와이프삭제인덱스가한칸밀려_해당위시를지운다() {
        // Given
        let fresh = Wish(id: "fresh", createdAt: daysAgo(1))
        let sleeping = Wish(id: "sleeping", createdAt: daysAgo(80))
        load([fresh, sleeping])

        // When: 섹션 아이템 1 = 카드 다음 첫 위시
        sut.input.didTapDelete.send(1)

        // Then
        XCTAssertEqual(mockRepository.deleteWishCalledIds, ["fresh"])
    }

    func test_회귀_카드를탭하면_상세로가지않는다() {
        // Given
        let sleeping = Wish(id: "sleeping", createdAt: daysAgo(80))
        load([sleeping])

        // When
        sut.input.didTapWish.send(0)

        // Then
        XCTAssertFalse(routes.contains {
            if case .pushWishDetail = $0 { return true }
            return false
        })
    }
}
