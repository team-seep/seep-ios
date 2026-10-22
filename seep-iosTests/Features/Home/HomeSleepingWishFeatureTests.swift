import XCTest

@testable import seep_ios_dev

/// GH-30 오래 잠든 위시에 "아직 하고 싶어요?" 다시 묻기 — 홈 카드 동작 (기존 HomeViewModelSleepingWishTests 이전)
final class HomeSleepingWishFeatureTests: HomeFeatureTestCase {
    private var sut: HomeViewModel!
    private let calendar = Calendar.current
    private lazy var today: Date = {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 13)) ?? Date()
    }()

    override func setUp() {
        super.setUp()
        let fixedToday = today
        sut = makeSut(dateProvider: { fixedToday })
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: Helpers

    private func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: today) ?? today
    }

    private var card: SleepingWishCard? {
        sut.state.sleepingWishCard
    }

    private func load(_ wishes: [Wish], count: Int? = nil) {
        load(sut, wishes: wishes, notFinishedCount: count)
    }

    // MARK: GH-30 TC1

    func test_GH30_TC1_61일된일정없는위시가있으면_리스트맨위에카드가보이고_리스트에도그대로있다() {
        // Given
        let sleeping = Wish(id: "sleeping", emoji: "🎸", title: "기타 치기", createdAt: daysAgo(61))
        let fresh = Wish(id: "fresh", title: "새 위시", createdAt: daysAgo(1))

        // When
        load([fresh, sleeping])

        // Then
        XCTAssertEqual(card?.wish.id, "sleeping")
        XCTAssertEqual(card?.caption, "61일째 그대로예요")
        XCTAssertEqual(listedWishIds(of: sut), ["fresh", "sleeping"])
    }

    // MARK: GH-30 TC2

    func test_GH30_TC2_59일된위시만있으면_카드가보이지않는다() {
        // Given
        let wish = Wish(id: "young", createdAt: daysAgo(59))

        // When
        load([wish])

        // Then
        XCTAssertNil(card)
        XCTAssertEqual(listedWishIds(of: sut), ["young"])
    }

    // MARK: GH-30 TC3

    func test_GH30_TC3_마감일이다음달인오래된위시는_카드에오르지않는다() {
        // Given
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: today)
        let wish = Wish(id: "planned", endDate: nextMonth, createdAt: daysAgo(90))

        // When
        load([wish])

        // Then
        XCTAssertNil(card)
    }

    // MARK: GH-30 TC4

    func test_GH30_TC4_오래된완료위시는_카드에오르지않는다() {
        // Given
        let wish = Wish(id: "done", isSuccess: true, createdAt: daysAgo(90))

        // When
        load([wish])

        // Then
        XCTAssertNil(card)
    }

    // MARK: GH-30 TC5

    func test_GH30_TC5_잠든위시가70일과100일이면_100일된위시하나만카드로보인다() {
        // Given
        let seventy = Wish(id: "70", createdAt: daysAgo(70))
        let hundred = Wish(id: "100", createdAt: daysAgo(100))

        // When
        load([seventy, hundred])

        // Then
        XCTAssertEqual(card?.wish.id, "100")
        XCTAssertEqual(listedWishIds(of: sut), ["70", "100"])
    }

    // MARK: GH-30 TC6

    func test_GH30_TC6_여전히하고싶어요를탭하면_점검일을저장하고_카드를숨기고_토스트를띄운다() {
        // Given
        let wish = Wish(id: "sleeping", title: "기타 치기", createdAt: daysAgo(80))
        load([wish])

        // When
        sut.send(.keepSleepingWish(wish))

        // Then
        XCTAssertEqual(repository.markCheckedCalledIds, ["sleeping"])
        XCTAssertNil(card)
        XCTAssertEqual(sut.state.toast?.message, "좋아요! 두 달 뒤에 다시 물어볼게요")
        XCTAssertEqual(listedWishIds(of: sut), ["sleeping"])
    }

    func test_GH30_TC6_처리한뒤에는_같은실행에서_다음잠든위시를이어서띄우지않는다() {
        // Given
        let older = Wish(id: "older", createdAt: daysAgo(100))
        let younger = Wish(id: "younger", createdAt: daysAgo(70))
        load([older, younger])

        // When
        sut.send(.keepSleepingWish(older))
        sut.send(.selectCategory(.wantToDo))

        // Then
        XCTAssertNil(card)
    }

    func test_GH30_TC6_저장에실패하면_에러알럿을띄우고_카드를유지한다() {
        // Given
        let wish = Wish(id: "sleeping", createdAt: daysAgo(80))
        repository.markCheckedResult = .failure(.writeFailed)
        load([wish])

        // When
        sut.send(.keepSleepingWish(wish))

        // Then
        XCTAssertEqual(card?.wish.id, "sleeping")
        XCTAssertNil(sut.state.toast)
        XCTAssertNotNil(sut.state.errorMessage)
    }

    // MARK: GH-30 TC7

    func test_GH30_TC7_이제됐어요를탭하면_보내주기확인알럿을띄우고_아직지우지않는다() {
        // Given
        let wish = Wish(id: "sleeping", createdAt: daysAgo(80))
        load([wish])

        // When
        sut.send(.tapReleaseSleepingWish(wish))

        // Then
        XCTAssertEqual(sut.state.releaseAlertWish?.id, "sleeping")
        XCTAssertTrue(repository.deleteWishCalledIds.isEmpty)
    }

    func test_GH30_TC7_보내주기를확정하면_삭제하고_알림을취소하고_개수가1줄고_카드가사라진다() {
        // Given
        let sleeping = Wish(id: "sleeping", endDate: daysAgo(3), notifications: [SeepNotification(type: .dayAgo)], createdAt: daysAgo(80))
        let other = Wish(id: "other", createdAt: daysAgo(1))
        load([sleeping, other])
        XCTAssertEqual(sut.state.notFinishedCount, 2)
        repository.fetchNotFinishCountResult = 1

        // When
        sut.send(.confirmReleaseSleepingWish(sleeping))

        // Then
        XCTAssertEqual(repository.deleteWishCalledIds, ["sleeping"])
        XCTAssertEqual(notificationManager.cancelledWishes.map(\.id), ["sleeping"])
        XCTAssertEqual(sut.state.notFinishedCount, 1)
        XCTAssertNil(card)
        XCTAssertEqual(listedWishIds(of: sut), ["other"])
        XCTAssertEqual(sut.state.toast?.message, "위시를 보내줬어요")
    }

    // MARK: GH-30 TC8

    func test_GH30_TC8_이제됐어요후_취소하면_위시와카드가그대로다() {
        // Given
        let wish = Wish(id: "sleeping", createdAt: daysAgo(80))
        load([wish])

        // When
        sut.send(.tapReleaseSleepingWish(wish))
        sut.send(.cancelReleaseSleepingWish)

        // Then
        XCTAssertNil(sut.state.releaseAlertWish)
        XCTAssertTrue(repository.deleteWishCalledIds.isEmpty)
        XCTAssertTrue(notificationManager.cancelledWishes.isEmpty)
        XCTAssertEqual(card?.wish.id, "sleeping")
        XCTAssertEqual(listedWishIds(of: sut), ["sleeping"])
        XCTAssertEqual(sut.state.notFinishedCount, 1)
    }

    // MARK: GH-30 TC9

    func test_GH30_TC9_카드위시를수정해저장하고돌아오면_카드가사라진다() {
        // Given
        var wish = Wish(id: "sleeping", title: "기타 치기", createdAt: daysAgo(70))
        load([wish])
        XCTAssertNotNil(card)

        // When: 수정 화면이 lastCheckedAt 을 지금으로 저장하고, 싶 탭으로 돌아온다 (R-2)
        wish.title = "기타로 노래 한 곡 치기"
        wish.lastCheckedAt = today
        load([wish])

        // Then
        XCTAssertNil(card)
        XCTAssertEqual(listedWishIds(of: sut), ["sleeping"])
    }

    // MARK: GH-30 TC10

    func test_GH30_TC10_완료된위시는싶탭에없으니_카드는진행중위시에서만고른다() {
        // Given: "완료된 위시만" 필터는 이룬 싶 탭으로 옮겨 갔다 (GH-64 R-13)
        let finishedSleeping = Wish(id: "finished", isSuccess: true, createdAt: daysAgo(90))
        let sleeping = Wish(id: "sleeping", createdAt: daysAgo(80))

        // When
        load([finishedSleeping, sleeping])

        // Then
        XCTAssertEqual(card?.wish.id, "sleeping")
        XCTAssertEqual(listedWishIds(of: sut), ["sleeping"])
    }

    // MARK: GH-30 TC12

    func test_GH30_TC12_갖고싶어요탭의잠든위시는_갖고싶어요문구로묻는다() {
        // Given
        let wish = Wish(id: "camera", category: .wantToGet, title: "필름 카메라", createdAt: daysAgo(80))
        repository.fetchWishesResult = [wish]
        repository.fetchNotFinishCountResult = 1

        // When
        sut.send(.selectCategory(.wantToGet))

        // Then
        XCTAssertEqual(card?.question, "아직 갖고 싶어요?")
        XCTAssertEqual(card?.keepTitle, "여전히 갖고 싶어요")
    }

    func test_GH30_TC12_하고싶어요가고싶어요탭은_각카테고리문구로묻는다() {
        // Given
        let doWish = Wish(id: "do", category: .wantToDo, createdAt: daysAgo(80))
        let goWish = Wish(id: "go", category: .wantToGo, createdAt: daysAgo(80))

        // When
        let doCard = SleepingWishCard(wish: doWish, daysSinceTouched: 80)
        let goCard = SleepingWishCard(wish: goWish, daysSinceTouched: 80)

        // Then
        XCTAssertEqual(doCard.question, "아직 하고 싶어요?")
        XCTAssertEqual(doCard.keepTitle, "여전히 하고 싶어요")
        XCTAssertEqual(goCard.question, "아직 가고 싶어요?")
        XCTAssertEqual(goCard.keepTitle, "여전히 가고 싶어요")
        XCTAssertEqual(goCard.releaseTitle, "이제 됐어요")
    }

    // MARK: GH-30 TC13

    func test_GH30_TC13_카드가처음보이면_sleeping_wish_card노출로그가1건전송되고_다시그려도더보내지않는다() {
        // Given
        let wish = Wish(id: "sleeping", createdAt: daysAgo(80))

        // When
        load([wish])
        sut.send(.toggleViewType)
        sut.send(.selectSortOrder(.latestOrder))
        sut.send(.toggleViewType)

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
        sut.send(.keepSleepingWish(wish))

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
        sut.send(.confirmReleaseSleepingWish(wish))

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
        sut.send(.tapReleaseSleepingWish(wish))

        // Then
        XCTAssertTrue(events(objectId: "release_sleeping_wish").isEmpty)
    }

    // MARK: 회귀

    func test_회귀_카드가맨위에있으면_스와이프삭제인덱스가한칸밀려_해당위시를지운다() {
        // Given: SwiftUI 에서는 위치 대신 위시로 지우므로 카드가 있어도 고른 위시를 지운다
        let fresh = Wish(id: "fresh", createdAt: daysAgo(1))
        let sleeping = Wish(id: "sleeping", createdAt: daysAgo(80))
        load([fresh, sleeping])

        // When
        sut.send(.delete(fresh))

        // Then
        XCTAssertEqual(repository.deleteWishCalledIds, ["fresh"])
    }

    func test_회귀_카드를탭하면_상세로가지않는다() {
        // Given: 카드는 버튼만 받고 탭 동작이 없다. 목록의 위시를 누를 때만 상세로 간다
        let sleeping = Wish(id: "sleeping", createdAt: daysAgo(80))
        load([sleeping])

        // When
        sut.send(.keepSleepingWish(sleeping))

        // Then
        XCTAssertTrue(router.wishPath.isEmpty)
    }
}
