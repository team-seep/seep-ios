import XCTest

@testable import seep_ios

/// 기간 기한 표시(홈 뱃지·상세 D-day 줄)와 기간이 지난 싶의 "아직 하고 싶어요?" 카드 (GH-118 R-4~R-7)
final class WishDeadlineOverFeatureTests: ViewModelTestCase {
    private var repository: MockWishRepository!
    private var notificationManager: MockNotificationManager!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
        notificationManager = MockNotificationManager()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    }

    override func tearDown() {
        repository = nil
        notificationManager = nil
        calendar = nil
        super.tearDown()
    }

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? Date()
    }

    /// 그날 23:59:59 — 기간 기한이 저장하는 마감
    private func lastMoment(_ year: Int, _ month: Int, _ dayOfMonth: Int) -> Date {
        day(year, month, dayOfMonth, hour: 0).addingTimeInterval(86_400 - 1)
    }

    private func makeWish(
        endDate: Date?,
        kind: DeadlineKind,
        isSuccess: Bool = false,
        notifications: [SeepNotification] = [SeepNotification(id: "n1", type: .dayAgo, time: Date(timeIntervalSinceReferenceDate: 0))]
    ) -> Wish {
        Wish(
            id: "surf",
            emoji: "🏄",
            title: "서핑 배워보기",
            endDate: endDate,
            deadlineKind: kind,
            finishDate: isSuccess ? endDate : nil,
            notifications: notifications,
            isSuccess: isSuccess
        )
    }

    private func makeSut(wish: Wish, now: Date, mode: DetailMode = .fromHome) -> WishDetailViewModel {
        repository.fetchWishResult = [wish]
        return WishDetailViewModel(
            config: .init(wishId: wish.id, mode: mode),
            dependency: .init(
                wishRepository: repository,
                notificationManager: notificationManager,
                logManager: logManager,
                preference: Preference(name: "test-gh118-detail-\(UUID().uuidString)"),
                photoStorage: MockWishPhotoStorage(),
                linkMetadataProvider: MockLinkMetadataProvider(),
                linkPreviewCache: MockLinkPreviewCache(),
                calendarManager: MockCalendarManager(),
                now: { now },
                calendar: calendar
            )
        )
    }

    // MARK: GH-118 TC3

    func test_GH118_TC3_올해안기한이63일남으면_뱃지는올해안_파란톤이다() {
        // Given
        let today = day(2026, 10, 29)
        let wish = makeWish(endDate: lastMoment(2026, 12, 31), kind: .year)

        // When
        let style = DdayBadgeStyle(wish: wish, today: today, calendar: calendar)
        let line = WishDetailSummary(wish: wish, now: today, calendar: calendar).ddayLine

        // Then
        XCTAssertEqual(style.text(farFuture: "먼훗날", noDate: "일정없음"), "올해 안")
        XCTAssertEqual(style.kind, .distant(days: 63))
        XCTAssertEqual(style.textColor, .ddayBlueText)
        XCTAssertEqual(line.tone, .later)
        XCTAssertEqual(line.text, "올해 안에")
        XCTAssertEqual(line.dateText, "12월 31일까지")
        XCTAssertTrue(line.isWord, "단어라 작게 쓰고 상단 바에 넣지 않는다")
    }

    func test_GH118_TC3_날짜기한은지금처럼_D_n이다() {
        // Given
        let today = day(2026, 10, 29)
        let wish = makeWish(endDate: lastMoment(2026, 12, 31), kind: .date)

        // Then
        XCTAssertEqual(DdayBadgeStyle(wish: wish, today: today, calendar: calendar).text(farFuture: "", noDate: ""), "D-63")
        XCTAssertEqual(WishDetailSummary(wish: wish, now: today, calendar: calendar).ddayLine.text, "D-63")
    }

    // MARK: GH-118 TC4

    func test_GH118_TC4_이번달안기한이2일남으면_뱃지는이번달안_빨간톤이다() {
        // Given
        let today = day(2026, 10, 29)
        let wish = makeWish(endDate: lastMoment(2026, 10, 31), kind: .month)

        // When
        let style = DdayBadgeStyle(wish: wish, today: today, calendar: calendar)
        let line = WishDetailSummary(wish: wish, now: today, calendar: calendar).ddayLine

        // Then
        XCTAssertEqual(style.text(farFuture: "", noDate: ""), "이번 달 안")
        XCTAssertEqual(style.kind, .imminent(days: 2))
        XCTAssertEqual(style.textColor, .optionRed)
        XCTAssertEqual(line.tone, .urgent)
        XCTAssertEqual(line.text, "이번 달 안에")
        XCTAssertEqual(line.dateText, "10월 31일까지")
    }

    func test_GH118_TC4_내년까지기한은_뱃지가내년까지이고_날짜에연도가붙는다() {
        // Given
        let today = day(2026, 10, 29)
        let wish = makeWish(endDate: lastMoment(2027, 12, 31), kind: .nextYear)

        // When
        let line = WishDetailSummary(wish: wish, now: today, calendar: calendar).ddayLine

        // Then
        XCTAssertEqual(DdayBadgeStyle(wish: wish, today: today, calendar: calendar).text(farFuture: "", noDate: ""), "내년까지")
        XCTAssertEqual(line.text, "내년까지")
        XCTAssertEqual(line.dateText, "2027년 12월 31일까지")
    }

    // MARK: GH-118 TC17

    func test_GH118_TC17_내년까지로정한위시도_해가바뀌면올해안이다() {
        // Given
        let wish = makeWish(endDate: lastMoment(2027, 12, 31), kind: .nextYear)

        // When
        let style = DdayBadgeStyle(wish: wish, today: day(2027, 3, 1), calendar: calendar)

        // Then
        XCTAssertEqual(style.text(farFuture: "", noDate: ""), "올해 안")
    }

    // MARK: GH-118 TC5

    func test_GH118_TC5_올해안기한다음날상세를열면_올해가지났어요와미루기카드가보인다() {
        // Given
        let wish = makeWish(endDate: lastMoment(2026, 12, 31), kind: .year)

        // When
        let sut = makeSut(wish: wish, now: day(2027, 1, 1))

        // Then
        XCTAssertEqual(sut.state.summary?.ddayLine.text, "올해가 지났어요")
        XCTAssertEqual(sut.state.summary?.ddayLine.dateText, "2026년 안에 하기로 했어요")
        XCTAssertEqual(sut.state.summary?.ddayLine.tone, .past)
        XCTAssertEqual(sut.state.deadlineOver, .init(postponeTitle: "내년까지로 미루기"))
        XCTAssertEqual(DdayBadgeStyle(wish: wish, today: day(2027, 1, 1), calendar: calendar).textColor, .optionPurple)
    }

    func test_GH118_TC5_이번달안기한이지나면_이번달이지났어요와다음달미루기다() {
        // Given
        let wish = makeWish(endDate: lastMoment(2026, 10, 31), kind: .month)

        // When
        let sut = makeSut(wish: wish, now: day(2026, 11, 1))

        // Then
        XCTAssertEqual(sut.state.summary?.ddayLine.text, "이번 달이 지났어요")
        XCTAssertEqual(sut.state.summary?.ddayLine.dateText, "10월 안에 하기로 했어요")
        XCTAssertEqual(sut.state.deadlineOver, .init(postponeTitle: "다음 달까지로 미루기"))
    }

    func test_GH118_TC5_마감당일이거나이룬위시거나날짜기한이면_카드가없다() {
        // 마감 당일
        XCTAssertNil(makeSut(wish: makeWish(endDate: lastMoment(2026, 12, 31), kind: .year), now: day(2026, 12, 31)).state.deadlineOver)
        // 이룬 위시
        XCTAssertNil(makeSut(wish: makeWish(endDate: lastMoment(2026, 12, 31), kind: .year, isSuccess: true), now: day(2027, 1, 1)).state.deadlineOver)
        // 날짜 기한은 지나도 지금처럼 D+n
        let dateSut = makeSut(wish: makeWish(endDate: lastMoment(2026, 12, 31), kind: .date), now: day(2027, 1, 1))
        XCTAssertNil(dateSut.state.deadlineOver)
        XCTAssertEqual(dateSut.state.summary?.ddayLine.text, "D+1")
    }

    // MARK: GH-118 TC6

    func test_GH118_TC6_미루기를누르면_다음해12월31일로저장되고_알림이새날짜로다시예약된다() {
        // Given
        let wish = makeWish(endDate: lastMoment(2026, 12, 31), kind: .year)
        let sut = makeSut(wish: wish, now: day(2027, 1, 1))

        // When
        sut.send(.tapPostponeDeadline)

        // Then
        XCTAssertEqual(repository.updateDeadlineCalls.first?.endDate, lastMoment(2027, 12, 31))
        XCTAssertEqual(repository.updateDeadlineCalls.first?.kind, .year)
        XCTAssertEqual(notificationManager.cancelledWishes.map(\.endDate), [lastMoment(2026, 12, 31)])
        XCTAssertEqual(notificationManager.reservedWishes.map(\.endDate), [lastMoment(2027, 12, 31)])
        XCTAssertEqual(notificationManager.reservedWishes.first?.notifications.map(\.id), ["n1"], "알림 설정은 그대로다 (R-8)")
        XCTAssertEqual(sut.state.wish?.endDate, lastMoment(2027, 12, 31))
        XCTAssertEqual(sut.state.summary?.ddayLine.text, "올해 안에")
        XCTAssertNil(sut.state.deadlineOver)
        XCTAssertEqual(sut.route, .toast("👏 2027년 12월 31일까지로 미뤘어요"))
    }

    // MARK: GH-118 TC15

    func test_GH118_TC15_한참지나미뤄도_오늘이든기간까지민다() {
        // Given: 8월 말이 마감인 이번 달 안 — 11월에 열었다
        let wish = makeWish(endDate: lastMoment(2026, 8, 31), kind: .month)
        let sut = makeSut(wish: wish, now: day(2026, 11, 10))

        // When
        sut.send(.tapPostponeDeadline)

        // Then
        XCTAssertEqual(repository.updateDeadlineCalls.first?.endDate, lastMoment(2026, 11, 30))
        XCTAssertNil(sut.state.deadlineOver)
    }

    func test_GH118_TC15_내년까지기한이지나면_마감다음해12월31일로민다() {
        // Given
        let deadline = lastMoment(2027, 12, 31)

        // Then: 지나자마자 미루면 그다음 해
        XCTAssertEqual(DeadlineKind.nextYear.postponedEnd(from: deadline, now: day(2028, 1, 1), calendar: calendar), lastMoment(2028, 12, 31))
        // 이번 달 안: 1월 31일 → 2월 말일
        XCTAssertEqual(DeadlineKind.month.postponedEnd(from: lastMoment(2027, 1, 31), now: day(2027, 2, 1), calendar: calendar), lastMoment(2027, 2, 28))
        XCTAssertNil(DeadlineKind.date.postponedEnd(from: deadline, now: day(2028, 1, 1), calendar: calendar))
    }

    // MARK: GH-118 TC7

    func test_GH118_TC7_기한없애기를누르면_날짜없음으로저장되고_알림이취소되며_카드가사라진다() {
        // Given
        let wish = makeWish(endDate: lastMoment(2026, 12, 31), kind: .year)
        let sut = makeSut(wish: wish, now: day(2027, 1, 1))

        // When
        sut.send(.tapClearDeadline)

        // Then
        XCTAssertEqual(repository.updateDeadlineCalls.count, 1)
        XCTAssertNil(repository.updateDeadlineCalls.first?.endDate)
        XCTAssertNil(sut.state.wish?.endDate)
        XCTAssertEqual(sut.state.wish?.deadlineKind, .date)
        XCTAssertEqual(sut.state.wish?.notifications, [])
        XCTAssertEqual(notificationManager.cancelledWishes.map(\.id), ["surf"])
        XCTAssertTrue(notificationManager.reservedWishes.isEmpty)
        XCTAssertNil(sut.state.deadlineOver)
        XCTAssertEqual(sut.state.summary?.ddayLine.text, "일정없음")
    }

    func test_GH118_TC7_저장에실패하면_알림을건드리지않고_에러알럿을띄운다() {
        // Given
        let wish = makeWish(endDate: lastMoment(2026, 12, 31), kind: .year)
        let sut = makeSut(wish: wish, now: day(2027, 1, 1))
        repository.updateDeadlineResult = .failure(.noDatabase)

        // When
        sut.send(.tapPostponeDeadline)

        // Then
        XCTAssertTrue(notificationManager.cancelledWishes.isEmpty)
        XCTAssertTrue(notificationManager.reservedWishes.isEmpty)
        XCTAssertNotNil(sut.state.deadlineOver)
        if case .errorAlert = sut.route {} else { XCTFail("에러 알럿이어야 한다: \(String(describing: sut.route))") }
    }

    // MARK: GH-118 TC11

    func test_GH118_TC11_카드가보이면노출로그1건_다시읽어도1건_미루기를누르면클릭로그1건() {
        // Given
        let wish = makeWish(endDate: lastMoment(2026, 12, 31), kind: .year)
        let sut = makeSut(wish: wish, now: day(2027, 1, 1))

        // When
        sut.send(.onAppear)
        sut.send(.onAppear)

        // Then
        let impressions = logManager.sentEvents.filter {
            $0.name == .impression && ($0.extraParameters?[.objectId] as? LogObjectId) == .deadlineOverCard
        }
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.screen, .wishDetail)
        XCTAssertEqual(impressions.first?.extraParameters?[.objectType] as? LogObjectType, .card)
        XCTAssertEqual(impressions.first?.extraParameters?[.type] as? String, "year")

        // When
        sut.send(.tapPostponeDeadline)

        // Then
        let clicks = clickEvents(objectId: .postponeDeadline)
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.screen, .wishDetail)
        XCTAssertEqual(clicks.first?.extraParameters?[.type] as? String, "year")
    }

    func test_GH118_TC11_기간이안지난위시는_노출로그가없다() {
        // When
        _ = makeSut(wish: makeWish(endDate: lastMoment(2026, 12, 31), kind: .year), now: day(2026, 10, 29))

        // Then
        XCTAssertTrue(logManager.sentEvents.filter { $0.name == .impression }.isEmpty)
    }

    // MARK: GH-118 TC14

    func test_GH118_TC14_기한없애기를누르면_clear_deadline클릭로그1건() {
        // Given
        let sut = makeSut(wish: makeWish(endDate: lastMoment(2026, 10, 31), kind: .month), now: day(2026, 11, 1))

        // When
        sut.send(.tapClearDeadline)

        // Then
        let clicks = clickEvents(objectId: .clearDeadline)
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.extraParameters?[.type] as? String, "month")
    }
}
