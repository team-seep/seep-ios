import XCTest

@testable import seep_ios

/// 상세 "적금 계획" 줄과 계획 시트 (GH-121 R-1~R-6)
final class SavingPlanFeatureTests: ViewModelTestCase {
    private var mockRepository: MockWishRepository!
    private var mockNotificationManager: MockNotificationManager!
    private var calendar: Calendar!
    /// 2026-10-31(토) 10:00 KST
    private var now: Date!

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        mockNotificationManager = MockNotificationManager()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        now = date(2026, 10, 31, hour: 10)
    }

    override func tearDown() {
        mockRepository = nil
        mockNotificationManager = nil
        calendar = nil
        now = nil
        super.tearDown()
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? Date()
    }

    private var fridayPlan: SavingPlan {
        SavingPlan(cycle: .weekly, day: 6, amount: 30_000)!
    }

    /// 갖고 싶어요 · 목표 359,000원 · 모은 150,000원
    private func makeWish(
        category: seep_ios.Category = .wantToGet,
        targetAmount: Int = 359_000,
        savings: [WishSaving]? = nil,
        endDate: Date? = nil,
        isSuccess: Bool = false,
        plan: SavingPlan? = nil
    ) -> Wish {
        Wish(
            id: "wish-1",
            emoji: "🎧",
            category: category,
            title: "에어팟 프로 3",
            endDate: endDate,
            targetAmount: targetAmount,
            savings: savings ?? [WishSaving(id: "s-1", amount: 150_000, createdAt: date(2026, 10, 2, hour: 12))],
            isSuccess: isSuccess,
            savingPlan: plan
        )
    }

    private func makeViewModel(wish: Wish) -> WishSavingsViewModel {
        mockRepository.fetchWishResult = [wish]
        let now = self.now ?? Date()
        return WishSavingsViewModel(
            config: .init(wish: wish),
            dependency: .init(
                wishRepository: mockRepository,
                notificationManager: mockNotificationManager,
                logManager: logManager,
                now: { now },
                calendar: calendar
            )
        )
    }

    private func makeSheet(plan: SavingPlan? = nil, savedAmount: Int = 150_000) -> SavingPlanInputViewModel {
        SavingPlanInputViewModel(config: .init(
            plan: plan,
            targetAmount: 359_000,
            savedAmount: savedAmount,
            now: now,
            calendar: calendar
        ))
    }

    private func presentedSheet(_ viewModel: WishSavingsViewModel) -> SavingPlanInputViewModel? {
        if case .savingPlanInput(let sheet) = viewModel.route { return sheet }
        return nil
    }

    // MARK: GH-121 TC1

    func test_GH121_TC1_매주금요일3만원으로계획을세우면_저장되고_7번넣으면12월18일금에다모여요가보인다() throws {
        // Given
        let viewModel = makeViewModel(wish: makeWish())
        var updatedPlan: SavingPlan??
        viewModel.onPlanUpdate = { updatedPlan = $0 }
        viewModel.send(.tapPlan)
        let sheet = try XCTUnwrap(presentedSheet(viewModel))

        // When
        sheet.send(.selectCycle(.weekly))
        sheet.send(.selectDay(6))
        sheet.send(.inputAmountText("30000"))

        // Then: 시트 미리보기
        XCTAssertEqual(sheet.state.preview?.text, "7번 넣으면 12월 18일 (금)에 다 모여요")
        XCTAssertEqual(sheet.state.preview?.highlight, "12월 18일 (금)")

        // When
        sheet.send(.tapSave)

        // Then: 저장·상세 줄
        XCTAssertEqual(sheet.route, .dismiss)
        XCTAssertEqual(mockRepository.updateSavingPlanCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(mockRepository.updateSavingPlanCalls.map(\.plan), [fridayPlan])
        XCTAssertEqual(viewModel.state.planRow?.summary, "매주 금요일 30,000원씩")
        XCTAssertEqual(viewModel.state.planRow?.forecast, "7번 넣으면 12월 18일 (금)에 다 모여요")
        XCTAssertEqual(viewModel.state.planRow?.forecastHighlight, "12월 18일 (금)")
        XCTAssertEqual(updatedPlan, .some(fridayPlan))
    }

    // MARK: GH-121 TC2

    func test_GH121_TC2_기한12월31일이있으면_기한보다13일먼저예요와_다음넣는날11월6일이보인다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(endDate: date(2026, 12, 31, hour: 9), plan: fridayPlan))

        // Then
        XCTAssertEqual(viewModel.state.planRow?.forecast, "7번 넣으면 12월 18일 (금)에 다 모여요")
        XCTAssertEqual(viewModel.state.planRow?.meta, "기한보다 13일 먼저예요 · 다음 넣는 날 11월 6일")
    }

    func test_GH121_TC2_기한이없으면_다음넣는날만보인다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(plan: fridayPlan))

        // Then
        XCTAssertEqual(viewModel.state.planRow?.meta, "다음 넣는 날 11월 6일")
    }

    // MARK: GH-121 TC3

    func test_GH121_TC3_매달31일계획은_2월회차를2월28일로세고_다음은3월31일4월30일이다() throws {
        // Given
        let plan = try XCTUnwrap(SavingPlan(cycle: .monthly, day: 31, amount: 10_000))
        let today = date(2027, 2, 10, hour: 10)

        // When
        let dates = (0..<3).compactMap { SavingPlanSchedule.paymentDate(plan: plan, index: $0, now: today, calendar: calendar) }
        let forecast = SavingPlanForecast(plan: plan, remainingAmount: 25_000, deadline: nil, now: today, calendar: calendar)

        // Then
        XCTAssertEqual(dates, [date(2027, 2, 28), date(2027, 3, 31), date(2027, 4, 30)])
        XCTAssertEqual(forecast?.depositCount, 3)
        XCTAssertEqual(forecast?.completionDate, date(2027, 4, 30))
    }

    func test_GH121_TC3_오늘이넣는날이면_오늘부터센다() throws {
        // Given: 오늘 2026-10-31(토), 매주 토요일 / 매달 31일
        let saturday = try XCTUnwrap(SavingPlan(cycle: .weekly, day: 7, amount: 10_000))
        let monthly = try XCTUnwrap(SavingPlan(cycle: .monthly, day: 31, amount: 10_000))

        // When / Then
        XCTAssertEqual(SavingPlanSchedule.paymentDate(plan: saturday, index: 0, now: now, calendar: calendar), date(2026, 10, 31))
        XCTAssertEqual(SavingPlanSchedule.paymentDate(plan: monthly, index: 1, now: now, calendar: calendar), date(2026, 11, 30))
    }

    func test_GH121_TC3_넣는날에오늘기록이이미있으면_오늘회차는넣은것으로보고다음회차부터센다() throws {
        // Given: 오늘 2026-10-31(토) 매주 토요일 30,000원, 오늘 30,000원을 이미 기록해 남은 금액 179,000원
        let saturday = try XCTUnwrap(SavingPlan(cycle: .weekly, day: 7, amount: 30_000))
        let savings = [
            WishSaving(id: "s-2", amount: 30_000, createdAt: date(2026, 10, 31, hour: 9)),
            WishSaving(id: "s-1", amount: 150_000, createdAt: date(2026, 10, 2, hour: 12))
        ]

        // When
        let recorded = makeViewModel(wish: makeWish(savings: savings, plan: saturday))
        let notYet = makeViewModel(wish: makeWish(savings: [savings[1]], plan: saturday))

        // Then: 오늘 기록이 있으면 다음 토요일(11월 7일)부터 6번 → 12월 12일
        XCTAssertEqual(recorded.state.planRow?.forecast, "6번 넣으면 12월 12일 (토)에 다 모여요")
        XCTAssertEqual(recorded.state.planRow?.meta, "다음 넣는 날 11월 7일")
        // 아직 안 넣었으면 오늘부터 센다
        XCTAssertEqual(notYet.state.planRow?.meta, "다음 넣는 날 10월 31일")
    }

    func test_GH121_TC3_다모이는데10년넘게걸리는계획은_예측을숨긴다() throws {
        // Given: 남은 209,000원을 매주 100원씩 → 2,090번(약 40년)
        let tiny = try XCTUnwrap(SavingPlan(cycle: .weekly, day: 6, amount: 100))

        // When
        let viewModel = makeViewModel(wish: makeWish(plan: tiny))

        // Then
        XCTAssertEqual(viewModel.state.planRow?.summary, "매주 금요일 100원씩")
        XCTAssertNil(viewModel.state.planRow?.forecast)
        XCTAssertNil(viewModel.state.planRow?.meta)
    }

    // MARK: GH-121 TC4

    func test_GH121_TC4_계획없이기록이2건이상이면_지금속도라면날짜쯤다모여요가보인다() {
        // Given: 10월 21일 100,000원 + 10월 31일 50,000원 → 10일 동안 150,000원(하루 15,000원), 남은 209,000원 → 14일 뒤
        let savings = [
            WishSaving(id: "s-2", amount: 50_000, createdAt: date(2026, 10, 31, hour: 9)),
            WishSaving(id: "s-1", amount: 100_000, createdAt: date(2026, 10, 21, hour: 20))
        ]

        // When
        let viewModel = makeViewModel(wish: makeWish(savings: savings))

        // Then
        XCTAssertNil(viewModel.state.planRow?.summary)
        XCTAssertEqual(viewModel.state.planRow?.forecast, "지금 속도라면 11월 14일쯤 다 모여요")
        XCTAssertEqual(viewModel.state.planRow?.forecastHighlight, "11월 14일")
    }

    func test_GH121_TC4_기록이1건이하면_속도문구를숨긴다() {
        // Given / When
        let one = makeViewModel(wish: makeWish())
        let none = makeViewModel(wish: makeWish(savings: []))

        // Then: 계획 줄("＋ 계획 세우기")은 보이고 예측만 없다
        XCTAssertNotNil(one.state.planRow)
        XCTAssertNil(one.state.planRow?.forecast)
        XCTAssertNil(none.state.planRow?.forecast)
    }

    func test_GH121_TC4_계산한날이10년을넘으면_속도문구를숨긴다() {
        // Given: 10일 동안 2원 → 남은 금액을 모으는 데 10년 넘게 걸린다
        let savings = [
            WishSaving(id: "s-2", amount: 1, createdAt: date(2026, 10, 31, hour: 9)),
            WishSaving(id: "s-1", amount: 1, createdAt: date(2026, 10, 21, hour: 9))
        ]

        // When
        let viewModel = makeViewModel(wish: makeWish(savings: savings))

        // Then
        XCTAssertNil(viewModel.state.planRow?.forecast)
    }

    // MARK: GH-121 TC5

    func test_GH121_TC5_하고싶어요위시_목표금액0_이룬위시는_적금계획줄이없다() {
        // Given / When
        let wantToDo = makeViewModel(wish: makeWish(category: .wantToDo, plan: fridayPlan))
        let noTarget = makeViewModel(wish: makeWish(targetAmount: 0, plan: fridayPlan))
        let finished = makeViewModel(wish: makeWish(isSuccess: true, plan: fridayPlan))

        // Then
        XCTAssertNil(wantToDo.state.planRow)
        XCTAssertNil(noTarget.state.planRow)
        XCTAssertNil(finished.state.planRow)
        XCTAssertTrue(finished.state.isVisible, "모은 돈 섹션은 그대로 보인다")
    }

    func test_GH121_TC5_목표를다모았고계획이없으면_계획줄이없고_계획이있으면바꿀수있게남는다() {
        // Given / When
        let full = [WishSaving(id: "s-1", amount: 359_000, createdAt: date(2026, 10, 2, hour: 12))]
        let noPlan = makeViewModel(wish: makeWish(savings: full))
        let withPlan = makeViewModel(wish: makeWish(savings: full, plan: fridayPlan))

        // Then
        XCTAssertNil(noPlan.state.planRow)
        XCTAssertEqual(withPlan.state.planRow?.summary, "매주 금요일 30,000원씩")
        XCTAssertNil(withPlan.state.planRow?.forecast)
    }

    func test_GH121_TC5_계획줄이없으면_시트를열지않는다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(isSuccess: true))

        // When
        viewModel.send(.tapPlan)

        // Then
        XCTAssertNil(viewModel.route)
        XCTAssertTrue(clickEvents(objectId: .savingPlan).isEmpty)
    }

    // MARK: GH-121 TC6

    func test_GH121_TC6_계획을저장하면_넣는날알림을맞추고_지우면계획없는위시로다시맞춘다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish())

        // When
        viewModel.send(.savePlan(fridayPlan))

        // Then
        XCTAssertEqual(mockNotificationManager.savingPlanUpdatedWishes.map(\.savingPlan), [fridayPlan])

        // When
        viewModel.send(.deletePlan)

        // Then: 계획 없는 위시로 맞추면 NotificationManager 가 알림을 지운다
        XCTAssertEqual(mockRepository.updateSavingPlanCalls.map(\.plan), [fridayPlan, nil])
        XCTAssertEqual(mockNotificationManager.savingPlanUpdatedWishes.map(\.savingPlan), [fridayPlan, nil])
        XCTAssertNil(viewModel.state.planRow?.summary)
        XCTAssertNotNil(viewModel.state.planRow, "계획을 지워도 '＋ 계획 세우기' 줄은 남는다")
    }

    func test_GH121_TC6_기록으로목표를다모으면_다모은위시로알림을맞추고_예측문구를숨긴다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(plan: fridayPlan))
        let saved = [
            WishSaving(id: "s-2", amount: 209_000, createdAt: now),
            WishSaving(id: "s-1", amount: 150_000, createdAt: date(2026, 10, 2, hour: 12))
        ]
        mockRepository.addSavingResult = .success(saved)

        // When
        viewModel.send(.saveAmount(209_000))

        // Then
        let notified = mockNotificationManager.savingPlanUpdatedWishes
        XCTAssertEqual(notified.count, 1)
        XCTAssertEqual(notified.first?.savings.reduce(0) { $0 + $1.amount }, 359_000)
        XCTAssertFalse(notified.first.map(SavingPlanNotification.isActive) ?? true)
        XCTAssertEqual(viewModel.state.planRow?.summary, "매주 금요일 30,000원씩")
        XCTAssertNil(viewModel.state.planRow?.forecast)
    }

    func test_GH121_TC6_계획이없으면_기록해도알림을건드리지않는다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish())
        mockRepository.addSavingResult = .success([WishSaving(amount: 10_000)])

        // When
        viewModel.send(.saveAmount(10_000))

        // Then
        XCTAssertTrue(mockNotificationManager.savingPlanUpdatedWishes.isEmpty)
    }

    func test_GH121_TC6_저장에실패하면_알림을건드리지않고_에러알럿을띄운다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish())
        mockRepository.updateSavingPlanResult = .failure(.writeFailed)

        // When
        viewModel.send(.savePlan(fridayPlan))

        // Then
        XCTAssertTrue(mockNotificationManager.savingPlanUpdatedWishes.isEmpty)
        XCTAssertEqual(viewModel.route, .errorAlert(RepositoryError.writeFailed.localizedDescription))
        XCTAssertNil(viewModel.state.planRow?.summary)
        XCTAssertTrue(clickEvents(objectId: .saveSavingPlan).isEmpty)
    }

    // MARK: GH-121 TC9

    func test_GH121_TC9_시트에서계획세우기를누르면_save_saving_plan클릭로그1건_금액은보내지않는다() throws {
        // Given
        let viewModel = makeViewModel(wish: makeWish())
        viewModel.send(.tapPlan)
        let sheet = try XCTUnwrap(presentedSheet(viewModel))
        sheet.send(.inputAmountText("30000"))

        // When
        sheet.send(.tapSave)

        // Then
        let events = clickEvents(objectId: .saveSavingPlan)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        XCTAssertEqual(events.first?.extraParameters?[.objectType] as? LogObjectType, .button)
        XCTAssertEqual(events.first?.extraParameters?.count, 2, "object_type·object_id 만 보낸다")
    }

    // MARK: GH-121 TC12

    func test_GH121_TC12_계획세우기를누르면_시트가열리고_saving_plan클릭로그1건() throws {
        // Given
        let viewModel = makeViewModel(wish: makeWish())

        // When
        viewModel.send(.tapPlan)

        // Then
        let sheet = try XCTUnwrap(presentedSheet(viewModel))
        XCTAssertFalse(sheet.isDeletable)
        let events = clickEvents(objectId: .savingPlan)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        XCTAssertEqual(events.first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }

    func test_GH121_TC12_계획이있으면_변경으로열고_지금값으로채운다() throws {
        // Given
        let viewModel = makeViewModel(wish: makeWish(plan: fridayPlan))

        // When
        viewModel.send(.tapPlan)

        // Then
        let sheet = try XCTUnwrap(presentedSheet(viewModel))
        XCTAssertTrue(sheet.isDeletable)
        XCTAssertEqual(sheet.state.cycle, .weekly)
        XCTAssertEqual(sheet.state.weekday, 6)
        XCTAssertEqual(sheet.state.amountText, "30,000")
        XCTAssertEqual(clickEvents(objectId: .savingPlan).count, 1)
    }

    // MARK: GH-121 TC16

    func test_GH121_TC16_다모이는날이기한보다늦으면_기한보다n일늦어요() {
        // Given: 다 모이는 날 12월 18일, 기한 12월 10일
        let viewModel = makeViewModel(wish: makeWish(endDate: date(2026, 12, 10), plan: fridayPlan))

        // Then
        XCTAssertEqual(viewModel.state.planRow?.meta, "기한보다 8일 늦어요 · 다음 넣는 날 11월 6일")
    }

    func test_GH121_TC16_다모이는날이기한과같으면_기한에딱맞춰요() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(endDate: date(2026, 12, 18, hour: 23), plan: fridayPlan))

        // Then
        XCTAssertEqual(viewModel.state.planRow?.meta, "기한에 딱 맞춰요 · 다음 넣는 날 11월 6일")
    }

    func test_GH121_TC16_다모이는날이다음해면_연도까지보인다() throws {
        // Given: 매달 1일 10,000원, 남은 209,000원 → 21번째 = 2028년 7월 1일
        let plan = try XCTUnwrap(SavingPlan(cycle: .monthly, day: 1, amount: 10_000))

        // When
        let viewModel = makeViewModel(wish: makeWish(plan: plan))

        // Then
        XCTAssertEqual(viewModel.state.planRow?.summary, "매달 1일 10,000원씩")
        XCTAssertEqual(viewModel.state.planRow?.forecast, "21번 넣으면 2028년 7월 1일 (토)에 다 모여요")
        XCTAssertEqual(viewModel.state.planRow?.meta, "다음 넣는 날 11월 1일")
    }

    // MARK: GH-121 TC17

    func test_GH121_TC17_금액이비어있으면_CTA가꺼지고_저장하지않는다() {
        // Given
        let sheet = makeSheet()
        var saved: SavingPlan?
        sheet.onSave = { saved = $0 }

        // When
        sheet.send(.tapSave)

        // Then: 새 계획은 매주 · 오늘(토) 요일로 시작한다
        XCTAssertEqual(sheet.state.cycle, .weekly)
        XCTAssertEqual(sheet.state.weekday, 7)
        XCTAssertEqual(sheet.state.monthDay, 31)
        XCTAssertFalse(sheet.state.isSaveEnabled)
        XCTAssertNil(sheet.state.preview)
        XCTAssertNil(saved)
        XCTAssertNil(sheet.route)

        // When
        sheet.send(.inputAmountText("0"))

        // Then
        XCTAssertFalse(sheet.state.isSaveEnabled)
    }

    func test_GH121_TC17_계획이있으면_계획지우기가보이고_누르면지운다() {
        // Given
        let sheet = makeSheet(plan: fridayPlan)
        var deleted = false
        sheet.onDelete = { deleted = true }

        // When
        sheet.send(.tapDelete)

        // Then
        XCTAssertTrue(sheet.isDeletable)
        XCTAssertTrue(deleted)
        XCTAssertEqual(sheet.route, .dismiss)
    }

    func test_GH121_TC17_계획이없으면_다음에할게요로닫기만한다() {
        // Given
        let sheet = makeSheet()
        var deleted = false
        sheet.onDelete = { deleted = true }

        // When
        sheet.send(.tapDelete)
        sheet.send(.tapLater)

        // Then
        XCTAssertFalse(deleted)
        XCTAssertEqual(sheet.route, .dismiss)
    }

    func test_GH121_TC17_매달29일이상을고르면_마지막날안내를보이고_범위밖날은무시한다() {
        // Given
        let sheet = makeSheet()

        // When
        sheet.send(.selectCycle(.monthly))
        sheet.send(.selectDay(29))
        sheet.send(.selectDay(32))

        // Then
        XCTAssertEqual(sheet.state.monthDay, 29)
        XCTAssertTrue(sheet.state.showsMonthEndNotice)

        // When
        sheet.send(.selectCycle(.weekly))

        // Then
        XCTAssertFalse(sheet.state.showsMonthEndNotice)
    }
}
