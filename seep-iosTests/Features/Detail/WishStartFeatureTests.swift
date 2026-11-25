import XCTest

@testable import seep_ios

/// 상세 상태 줄 — 시작했어요·되돌리기·자동 시작·이룬 싶의 시작 기록 (GH-143 R-2, R-3, R-6)
final class WishStartFeatureTests: ViewModelTestCase {
    private var repository: MockWishRepository!
    private var calendar: Calendar!
    /// 2026-11-19(목) 15:00 KST
    private var now: Date!
    /// 2026-11-08(일) 21:30 KST
    private var startedAt: Date!

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, hour: 15))
        startedAt = calendar.date(from: DateComponents(year: 2026, month: 11, day: 8, hour: 21, minute: 30))
        repository.updateStartedNow = now
    }

    override func tearDown() {
        repository = nil
        calendar = nil
        now = nil
        startedAt = nil
        super.tearDown()
    }

    private func makeWish(
        startedAt: Date? = nil,
        isSuccess: Bool = false,
        finishDate: Date? = nil,
        steps: [WishStep] = [],
        category: seep_ios.Category = .wantToDo,
        targetAmount: Int = 0,
        savings: [WishSaving] = []
    ) -> Wish {
        Wish(
            id: "surf",
            emoji: "🏄",
            category: category,
            title: "서핑 배워보기",
            finishDate: finishDate,
            steps: steps,
            targetAmount: targetAmount,
            savings: savings,
            isSuccess: isSuccess,
            startedAt: startedAt
        )
    }

    private func makeSut(wish: Wish, mode: DetailMode = .fromHome) -> WishDetailViewModel {
        repository.fetchWishResult = [wish]
        let now = self.now ?? Date()
        return WishDetailViewModel(
            config: .init(wishId: wish.id, mode: mode),
            dependency: .init(
                wishRepository: repository,
                notificationManager: MockNotificationManager(),
                logManager: logManager,
                preference: Preference(name: "test-gh143-detail-\(UUID().uuidString)"),
                photoStorage: MockWishPhotoStorage(),
                linkMetadataProvider: MockLinkMetadataProvider(),
                linkPreviewCache: MockLinkPreviewCache(),
                calendarManager: MockCalendarManager(),
                now: { now },
                calendar: calendar
            )
        )
    }

    private var steps: [WishStep] {
        [
            WishStep(id: "s1", title: "서핑 스쿨 예약", isDone: false, order: 0),
            WishStep(id: "s2", title: "웻슈트 사기", isDone: false, order: 1)
        ]
    }

    private func impressionEvents(objectId: LogObjectId) -> [any LogEventType] {
        logManager.sentEvents.filter { event in
            event.name == .impression && (event.extraParameters?[.objectId] as? LogObjectId) == objectId
        }
    }

    // MARK: GH-143 TC2

    func test_GH143_TC2_시작전싶에서시작했어요를누르면_시작시각이저장되고_오늘부터1일째가된다() {
        // Given
        let sut = makeSut(wish: makeWish())
        XCTAssertEqual(sut.state.startStatus, .notStarted)

        // When
        sut.send(.tapStart)

        // Then
        XCTAssertEqual(repository.updateStartedCalls.map(\.isStarted), [true])
        XCTAssertEqual(sut.state.wish?.startedAt, now)
        XCTAssertEqual(sut.state.startStatus, .doing(sinceText: "11월 19일부터 1일째", days: 1))
    }

    func test_GH143_TC2_이룬싶탭에서연상세는_시작했어요를눌러도바뀌지않는다() {
        // Given
        let sut = makeSut(wish: makeWish(), mode: .fromFinish)

        // When
        sut.send(.tapStart)

        // Then
        XCTAssertFalse(sut.isStartEditable)
        XCTAssertTrue(repository.updateStartedCalls.isEmpty)
    }

    // MARK: GH-143 TC3

    func test_GH143_TC3_하는중싶에서되돌리기를누르면_시작시각이지워지고_시작전으로돌아온다() {
        // Given
        let sut = makeSut(wish: makeWish(startedAt: startedAt))

        // When
        sut.send(.tapUnstart)

        // Then
        XCTAssertEqual(repository.updateStartedCalls.map(\.isStarted), [false])
        XCTAssertNil(sut.state.wish?.startedAt)
        XCTAssertEqual(sut.state.startStatus, .notStarted)
    }

    func test_GH143_TC3_저장에실패하면_에러알럿을띄우고_상태줄은그대로다() {
        // Given
        let sut = makeSut(wish: makeWish(startedAt: startedAt))
        repository.updateStartedResult = .failure(.noDatabase)

        // When
        sut.send(.tapUnstart)

        // Then
        guard case .errorAlert = sut.route else { return XCTFail("\(String(describing: sut.route))") }
        XCTAssertEqual(sut.state.wish?.startedAt, startedAt)
    }

    // MARK: GH-143 TC4

    func test_GH143_TC4_11월8일에시작한싶은_11월19일에12일째로보인다() {
        // When
        let sut = makeSut(wish: makeWish(startedAt: startedAt))

        // Then
        XCTAssertEqual(sut.state.startStatus, .doing(sinceText: "11월 8일부터 12일째", days: 12))
    }

    func test_GH143_TC4_시작한날당일은1일째이고_달력날짜로센다() {
        // Given: 11월 19일 00:05 시작, 지금은 같은 날 15:00 / 다음 날 00:01
        let earlyMorning = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, minute: 5)) ?? Date()
        let nextDay = calendar.date(from: DateComponents(year: 2026, month: 11, day: 20, minute: 1)) ?? Date()
        let lateNight = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, hour: 23, minute: 59)) ?? Date()

        // Then
        XCTAssertEqual(WishStartStatus.dayNumber(since: earlyMorning, on: now, calendar: calendar), 1)
        XCTAssertEqual(WishStartStatus.dayNumber(since: lateNight, on: nextDay, calendar: calendar), 2)
        XCTAssertEqual(WishStartStatus.dayNumber(since: startedAt, on: now, calendar: calendar), 12)
        // 다른 기기 시계가 앞서 미래 시각이 와도 1일째
        XCTAssertEqual(WishStartStatus.dayNumber(since: nextDay, on: now, calendar: calendar), 1)
    }

    // MARK: GH-143 TC5

    func test_GH143_TC5_시작전싶에서단계를처음체크하면_자동시작하고_되돌리기토스트가뜬다() {
        // Given
        let sut = makeSut(wish: makeWish(steps: steps))
        var checked = steps
        checked[0].isDone = true
        repository.toggleStepResult = .success(checked)

        // When
        sut.steps?.send(.tapStep(0))

        // Then
        XCTAssertEqual(repository.updateStartedCalls.map(\.isStarted), [true])
        XCTAssertEqual(sut.state.wish?.startedAt, now)
        XCTAssertEqual(sut.route, .autoStartToast("👏 시작했네요! '하는 중'에 담았어요"))
    }

    func test_GH143_TC5_자동시작토스트의되돌리기는_시작시각만지우고_단계는체크된채남는다() {
        // Given
        let sut = makeSut(wish: makeWish(steps: steps))
        var checked = steps
        checked[0].isDone = true
        repository.toggleStepResult = .success(checked)
        sut.steps?.send(.tapStep(0))
        sut.send(.routeHandled)
        // 저장소에는 체크한 단계와 시작 시각이 남아 있다 (목의 toggleStep 은 fetchWish 에 반영하지 않는다)
        repository.fetchWishResult = [makeWish(startedAt: now, steps: checked)]

        // When
        sut.send(.undoAutoStart)

        // Then
        XCTAssertEqual(repository.updateStartedCalls.map(\.isStarted), [true, false])
        XCTAssertEqual(repository.toggleStepCalls.count, 1)
        XCTAssertNil(sut.state.wish?.startedAt)
        XCTAssertEqual(sut.state.wish?.steps.filter(\.isDone).map(\.id), ["s1"])
        XCTAssertEqual(sut.state.startStatus, .notStarted)
    }

    @MainActor
    func test_GH143_TC5_버튼있는토스트는_버튼을누르면닫히고동작을부른다() {
        // Given
        let center = ToastCenter()
        var undoCount = 0
        center.show("👏 시작했네요! '하는 중'에 담았어요", actionTitle: "되돌리기") { undoCount += 1 }
        XCTAssertEqual(center.actionTitle, "되돌리기")

        // When
        center.performAction()

        // Then
        XCTAssertEqual(undoCount, 1)
        XCTAssertNil(center.message)
        XCTAssertNil(center.actionTitle)

        // When: 시간이 지나면 저절로 닫힌다
        center.show("👏 시작했네요! '하는 중'에 담았어요", actionTitle: "되돌리기", duration: .milliseconds(100)) { undoCount += 1 }

        // Then
        waitUntil(timeout: 1) { center.message == nil }
        XCTAssertNil(center.actionTitle)
        center.performAction()
        XCTAssertEqual(undoCount, 1)
    }

    func test_GH143_TC5_토스트가뜬뒤다른화면에서이룬싶은_토스트되돌리기가시작시각을지우지않는다() {
        // Given
        let sut = makeSut(wish: makeWish(steps: steps))
        var checked = steps
        checked[0].isDone = true
        repository.toggleStepResult = .success(checked)
        sut.steps?.send(.tapStep(0))
        // 홈으로 돌아가 이뤘다
        repository.fetchWishResult = [makeWish(startedAt: now, isSuccess: true, finishDate: now, steps: checked)]

        // When
        sut.send(.undoAutoStart)

        // Then
        XCTAssertEqual(repository.updateStartedCalls.map(\.isStarted), [true])
        XCTAssertTrue(clickEvents(objectId: .unstartWish).isEmpty)
    }

    @MainActor
    func test_GH143_TC5_첫저금이목표달성과자동시작을같이부르면_되돌리기토스트를먼저보이고_끝나면축하토스트를띄운다() {
        // Given: 축하(버튼 없음)가 먼저 와도
        let center = ToastCenter()
        center.show("🎉 목표 금액을 다 모았어요!")

        // When
        center.show("👏 시작했네요! '하는 중'에 담았어요", actionTitle: "되돌리기") {}

        // Then
        XCTAssertEqual(center.actionTitle, "되돌리기")
        center.dismiss()
        XCTAssertEqual(center.message, "🎉 목표 금액을 다 모았어요!")
        XCTAssertNil(center.actionTitle)

        // Given: 버튼 토스트가 먼저 와도
        center.dismiss()
        center.show("👏 시작했네요! '하는 중'에 담았어요", actionTitle: "되돌리기") {}

        // When
        center.show("🎉 목표 금액을 다 모았어요!")

        // Then: 버튼 토스트가 남고, 누르면 축하가 이어진다
        XCTAssertEqual(center.actionTitle, "되돌리기")
        center.performAction()
        XCTAssertEqual(center.message, "🎉 목표 금액을 다 모았어요!")
    }

    // MARK: GH-143 TC6

    func test_GH143_TC6_시작전싶에서모은돈을처음기록하면_자동시작된다() {
        // Given
        let sut = makeSut(wish: makeWish(category: .wantToGet, targetAmount: 300_000))
        repository.addSavingResult = .success([WishSaving(id: "saving-1", amount: 50_000, createdAt: now)])

        // When
        sut.savings?.send(.saveAmount(50_000))

        // Then
        XCTAssertEqual(repository.updateStartedCalls.map(\.isStarted), [true])
        XCTAssertEqual(sut.state.wish?.startedAt, now)
        XCTAssertEqual(sut.route, .autoStartToast("👏 시작했네요! '하는 중'에 담았어요"))
    }

    func test_GH143_TC6_이미하는중인싶은_단계를체크해도시작시각과토스트가바뀌지않는다() {
        // Given
        let sut = makeSut(wish: makeWish(startedAt: startedAt, steps: steps))
        var checked = steps
        checked[1].isDone = true
        repository.toggleStepResult = .success(checked)

        // When
        sut.steps?.send(.tapStep(1))

        // Then
        XCTAssertTrue(repository.updateStartedCalls.isEmpty)
        XCTAssertEqual(sut.state.wish?.startedAt, startedAt)
        XCTAssertNil(sut.route)
        XCTAssertTrue(impressionEvents(objectId: .autoStartWish).isEmpty)
    }

    func test_GH143_TC6_시작전싶에서단계체크를해제하거나저금을지우면_자동시작하지않는다() {
        // Given
        var doneSteps = steps
        doneSteps[0].isDone = true
        let saving = WishSaving(id: "saving-1", amount: 50_000, createdAt: now)
        let sut = makeSut(wish: makeWish(steps: doneSteps, category: .wantToGet, targetAmount: 300_000, savings: [saving]))
        repository.toggleStepResult = .success(steps)
        repository.deleteSavingResult = .success([])

        // When
        sut.steps?.send(.tapStep(0))
        sut.savings?.send(.confirmDelete(savingId: "saving-1"))

        // Then
        XCTAssertTrue(repository.updateStartedCalls.isEmpty)
        XCTAssertNil(sut.state.wish?.startedAt)
        XCTAssertNil(sut.route)
    }

    // MARK: GH-143 TC10

    func test_GH143_TC10_11월8일에시작해11월19일에이룬싶은_시작기록한줄이보인다() {
        // When
        let sut = makeSut(wish: makeWish(startedAt: startedAt, isSuccess: true, finishDate: now), mode: .fromFinish)

        // Then
        XCTAssertEqual(sut.state.startStatus, .finished(text: "11월 8일에 시작 · 12일 만에 이뤘어요"))
    }

    func test_GH143_TC10_시작기록이없는이룬싶은_상태줄이없고_되돌리기도안된다() {
        // Given
        let sut = makeSut(wish: makeWish(isSuccess: true, finishDate: now), mode: .fromFinish)

        // When
        sut.send(.tapUnstart)

        // Then
        XCTAssertNil(sut.state.startStatus)
        XCTAssertTrue(repository.updateStartedCalls.isEmpty)
    }

    func test_GH143_TC10_이룬싶은_단계를체크해도자동시작하지않는다() {
        // Given
        let sut = makeSut(wish: makeWish(isSuccess: true, finishDate: now, steps: steps), mode: .fromFinish)
        var checked = steps
        checked[0].isDone = true
        repository.toggleStepResult = .success(checked)

        // When
        sut.steps?.send(.tapStep(0))

        // Then
        XCTAssertTrue(repository.updateStartedCalls.isEmpty)
        XCTAssertNil(sut.state.startStatus)
    }

    // MARK: GH-143 TC12

    func test_GH143_TC12_시작했어요는start_wish_되돌리기는unstart_wish_클릭이1건씩전송된다() {
        // Given
        let sut = makeSut(wish: makeWish())

        // When
        sut.send(.tapStart)
        sut.send(.tapUnstart)

        // Then
        XCTAssertEqual(clickEvents(objectId: .startWish).count, 1)
        XCTAssertEqual(clickEvents(objectId: .unstartWish).count, 1)
        XCTAssertEqual(clickEvents(objectId: .startWish).first?.screen, .wishDetail)
        XCTAssertEqual(clickEvents(objectId: .unstartWish).first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }

    func test_GH143_TC12_자동시작은_auto_start_wish노출이trigger와함께1건_토스트되돌리기는unstart_wish다() {
        // Given
        let sut = makeSut(wish: makeWish(steps: steps))
        var checked = steps
        checked[0].isDone = true
        repository.toggleStepResult = .success(checked)

        // When
        sut.steps?.send(.tapStep(0))
        sut.send(.undoAutoStart)

        // Then
        let impressions = impressionEvents(objectId: .autoStartWish)
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.screen, .wishDetail)
        XCTAssertEqual(impressions.first?.extraParameters?[.objectType] as? LogObjectType, .banner)
        XCTAssertEqual(impressions.first?.extraParameters?[.trigger] as? String, "step")
        XCTAssertEqual(clickEvents(objectId: .unstartWish).count, 1)
        XCTAssertTrue(clickEvents(objectId: .startWish).isEmpty)
    }

    func test_GH143_TC12_저금으로자동시작하면_trigger는saving이다() {
        // Given
        let sut = makeSut(wish: makeWish(category: .wantToGet, targetAmount: 300_000))
        repository.addSavingResult = .success([WishSaving(id: "saving-1", amount: 50_000, createdAt: now)])

        // When
        sut.savings?.send(.saveAmount(50_000))

        // Then
        XCTAssertEqual(impressionEvents(objectId: .autoStartWish).first?.extraParameters?[.trigger] as? String, "saving")
    }
}
