import XCTest

@testable import seep_ios

/// 갖고 싶어요 탭 "다 합치면" 카드 (GH-148)
final class HomeWishTotalFeatureTests: HomeFeatureTestCase {
    private func wish(
        _ id: String,
        target: Int,
        saved: Int = 0,
        currency: String = AmountFormatter.krw,
        tags: [String] = [],
        isSuccess: Bool = false
    ) -> Wish {
        Wish(
            id: id,
            emoji: "🎁",
            category: .wantToGet,
            title: id,
            targetAmount: target,
            currency: currency,
            savings: saved > 0 ? [WishSaving(amount: saved)] : [],
            tags: tags,
            isSuccess: isSuccess
        )
    }

    /// 갖고 싶어요 탭으로 홈을 띄운다
    private func makeGetSut(defaultCurrency: String = AmountFormatter.krw) -> HomeViewModel {
        router.homeCategory = .wantToGet
        return makeSut(defaultCurrency: { defaultCurrency })
    }

    private var impressions: [any LogEventType] {
        logManager.sentEvents.filter { $0.name == .impression && objectId($0) == LogObjectId.wishTotalSummary.rawValue }
    }

    // MARK: GH-148 TC1

    func test_GH148_TC1_목표있는미완료싶2개_남은금액모은돈목표개수를합친다() {
        // Given
        let sut = makeGetSut()

        // When
        load(sut, wishes: [wish("A", target: 400_000, saved: 150_000), wish("B", target: 800_000)])

        // Then
        let primary = sut.state.visibleWishTotal?.primary
        XCTAssertEqual(primary?.remainingAmount, 1_050_000)
        XCTAssertEqual(primary?.savedAmount, 150_000)
        XCTAssertEqual(primary?.targetAmount, 1_200_000)
        XCTAssertEqual(primary?.count, 2)
        XCTAssertEqual(primary?.currency, "KRW")
        XCTAssertEqual(primary?.ratio ?? 0, 0.125, accuracy: 0.0001)
    }

    // MARK: GH-148 TC2

    func test_GH148_TC2_목표금액있는미완료싶이없으면_카드가없다() {
        // Given
        let sut = makeGetSut()

        // When
        load(sut, wishes: [wish("A", target: 0), wish("B", target: 0)])

        // Then
        XCTAssertNil(sut.state.visibleWishTotal)
        XCTAssertTrue(impressions.isEmpty)
    }

    // MARK: GH-148 TC3

    func test_GH148_TC3_하고싶어요탭에서는_카드가없다() {
        // Given
        router.homeCategory = .wantToDo
        let sut = makeSut()

        // When
        load(sut, wishes: [wish("A", target: 400_000)])

        // Then
        XCTAssertNil(sut.state.visibleWishTotal)
    }

    func test_GH148_TC3_갖고싶어요에서_다른탭으로옮기면_카드가없어진다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [wish("A", target: 400_000)])
        XCTAssertNotNil(sut.state.visibleWishTotal)

        // When
        sut.send(.selectCategory(.wantToGo))

        // Then
        XCTAssertNil(sut.state.visibleWishTotal)
    }

    // MARK: GH-148 TC4

    func test_GH148_TC4_홈에서방금이룬싶은_합계에서빠진다() {
        // Given
        let target = wish("A", target: 400_000)
        let other = wish("C", target: 300_000)
        var finished = other
        finished.isSuccess = true
        repository.finishWishResult = .success(finished)
        let sut = makeGetSut()
        load(sut, wishes: [target, other])

        // When: C를 이뤄 소감 시트 동안 흐리게 남아 있다
        sut.send(.tapFinish(other))

        // Then
        XCTAssertTrue(sut.state.items.contains { $0.id == "C" })
        XCTAssertEqual(sut.state.visibleWishTotal?.primary.targetAmount, 400_000)
        XCTAssertEqual(sut.state.visibleWishTotal?.includedCount, 1)
    }

    // MARK: GH-148 TC5

    func test_GH148_TC5_목표보다많이모은싶은_남은0이고모은돈은목표만큼만더한다() {
        // Given
        let sut = makeGetSut()

        // When
        load(sut, wishes: [wish("A", target: 100_000, saved: 120_000), wish("B", target: 200_000, saved: 50_000)])

        // Then
        let primary = sut.state.visibleWishTotal?.primary
        XCTAssertEqual(primary?.remainingAmount, 150_000)
        XCTAssertEqual(primary?.savedAmount, 150_000)
        XCTAssertEqual(primary?.targetAmount, 300_000)
    }

    // MARK: GH-148 TC6

    func test_GH148_TC6_통화가섞이면_통화별로따로합치고_많은통화가큰줄이다() {
        // Given
        let sut = makeGetSut()

        // When
        load(sut, wishes: [
            wish("usd", target: 12_000, currency: "USD"),
            wish("krw1", target: 400_000, saved: 150_000),
            wish("krw2", target: 800_000)
        ])

        // Then
        let summary = sut.state.visibleWishTotal
        XCTAssertEqual(summary?.groups.map(\.currency), ["KRW", "USD"])
        XCTAssertEqual(summary?.primary.remainingAmount, 1_050_000)
        XCTAssertEqual(summary?.primary.count, 2)
        XCTAssertEqual(summary?.secondaryGroups.first?.remainingAmount, 12_000)
        XCTAssertEqual(summary?.secondaryGroups.first?.count, 1)
    }

    func test_GH148_TC6_보조줄문구는_남은금액과개수를보여준다() {
        // Given
        let locale = Locale(identifier: "ko_KR")

        // When
        let line = Strings.Home.WishTotal.secondaryFormat(
            AmountFormatter.money(12_000, currency: "USD", locale: locale),
            Strings.Home.WishTotal.countFormat(1)
        )

        // Then
        XCTAssertTrue(line.contains("120"))
        XCTAssertTrue(line.contains("1"))
    }

    // MARK: GH-148 TC7

    func test_GH148_TC7_목표금액없는미완료싶수를_빠진싶으로센다() {
        // Given
        let sut = makeGetSut()

        // When
        load(sut, wishes: [
            wish("A", target: 400_000),
            wish("B", target: 0),
            wish("C", target: 0),
            wish("done", target: 0, isSuccess: true)
        ])

        // Then
        XCTAssertEqual(sut.state.visibleWishTotal?.excludedCount, 2)
        XCTAssertEqual(sut.state.visibleWishTotal?.includedCount, 1)
    }

    // MARK: GH-148 TC8

    func test_GH148_TC8_태그칩을고르면_그태그싶만합치고라벨태그가붙는다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [
            wish("tv", target: 800_000, tags: ["가전"]),
            wish("airpods", target: 400_000, saved: 150_000, tags: ["가전"]),
            wish("tent", target: 500_000, tags: ["여름"])
        ])
        XCTAssertNil(sut.state.visibleWishTotal?.tag)
        XCTAssertEqual(sut.state.visibleWishTotal?.includedCount, 3)

        // When
        sut.send(.selectTag("가전"))

        // Then
        XCTAssertEqual(sut.state.visibleWishTotal?.tag, "가전")
        XCTAssertEqual(sut.state.visibleWishTotal?.includedCount, 2)
        XCTAssertEqual(sut.state.visibleWishTotal?.primary.remainingAmount, 1_050_000)
    }

    func test_GH148_TC8_전체로돌아오면_태그없이전부합친다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [wish("tv", target: 800_000, tags: ["가전"]), wish("tent", target: 500_000, tags: ["여름"])])
        sut.send(.selectTag("가전"))

        // When
        sut.send(.selectTag(nil))

        // Then
        XCTAssertNil(sut.state.visibleWishTotal?.tag)
        XCTAssertEqual(sut.state.visibleWishTotal?.primary.remainingAmount, 1_300_000)
    }

    // MARK: GH-148 TC9

    func test_GH148_TC9_카드를누르면펼쳐지고_남은금액큰순이며_다시누르면접힌다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [
            wish("small", target: 300_000, saved: 50_000),
            wish("usd", target: 12_000, currency: "USD"),
            wish("big", target: 800_000),
            wish("mid", target: 400_000, saved: 100_000)
        ])
        XCTAssertFalse(sut.state.isWishTotalExpanded)

        // When
        sut.send(.toggleWishTotal)

        // Then: 통화 묶음(KRW → USD) 안에서 남은 금액 큰 순
        XCTAssertTrue(sut.state.isWishTotalExpanded)
        let ids = sut.state.visibleWishTotal?.groups.flatMap { $0.items.map(\.id) }
        XCTAssertEqual(ids, ["big", "mid", "small", "usd"])

        // When
        sut.send(.toggleWishTotal)

        // Then
        XCTAssertFalse(sut.state.isWishTotalExpanded)
    }

    // MARK: GH-148 TC10

    func test_GH148_TC10_펼친줄을누르면_그싶상세로간다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [wish("A", target: 400_000), wish("B", target: 800_000)])
        sut.send(.toggleWishTotal)

        // When
        sut.send(.tapWishTotalItem(id: "A"))

        // Then
        XCTAssertEqual(router.wishPath, [.wishDetail(id: "A", isFinished: false)])
    }

    func test_GH148_TC10_접힌상태에서는_줄을눌러도이동하지않는다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [wish("A", target: 400_000)])

        // When
        sut.send(.tapWishTotalItem(id: "A"))

        // Then
        XCTAssertTrue(router.wishPath.isEmpty)
        XCTAssertTrue(clickEvents(objectId: .wishTotalItem).isEmpty)
    }

    // MARK: GH-148 TC11

    func test_GH148_TC11_펼친상태에서태그를바꾸면_접힌다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [wish("tv", target: 800_000, tags: ["가전"]), wish("tent", target: 500_000, tags: ["여름"])])
        sut.send(.toggleWishTotal)

        // When
        sut.send(.selectTag("가전"))

        // Then
        XCTAssertFalse(sut.state.isWishTotalExpanded)
    }

    func test_GH148_TC11_펼친상태에서카테고리를바꾸면_접힌다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [wish("tv", target: 800_000)])
        sut.send(.toggleWishTotal)

        // When: 다른 탭에 갔다가 돌아온다
        sut.send(.selectCategory(.wantToDo))
        sut.send(.selectCategory(.wantToGet))

        // Then
        XCTAssertNotNil(sut.state.visibleWishTotal)
        XCTAssertFalse(sut.state.isWishTotalExpanded)
    }

    // MARK: GH-148 TC12

    func test_GH148_TC12_순서바꾸기모드에서는_카드를숨긴다() {
        // Given
        preference.homeSortOrder = .manualOrder
        let sut = makeGetSut()
        load(sut, wishes: [wish("A", target: 400_000), wish("B", target: 800_000)])
        XCTAssertNotNil(sut.state.visibleWishTotal)

        // When
        sut.send(.tapReorder)

        // Then
        XCTAssertTrue(sut.state.isReordering)
        XCTAssertNil(sut.state.visibleWishTotal)

        // When
        sut.send(.finishReorder)

        // Then
        XCTAssertNotNil(sut.state.visibleWishTotal)
    }

    func test_GH148_TC12_선택모드에서는_카드를숨긴다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [wish("A", target: 400_000)])

        // When
        sut.send(.tapSelect)

        // Then
        XCTAssertTrue(sut.state.isSelecting)
        XCTAssertNil(sut.state.visibleWishTotal)
    }

    // MARK: GH-148 TC13

    func test_GH148_TC13_상세에서모은돈을기록하고돌아오면_남은금액이줄어든다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [wish("A", target: 400_000, saved: 50_000), wish("B", target: 800_000)])
        XCTAssertEqual(sut.state.visibleWishTotal?.primary.remainingAmount, 1_150_000)

        // When: 상세에서 B에 100,000원을 모으고 홈으로 돌아온다
        var savedB = wish("B", target: 800_000)
        savedB.savings = [WishSaving(amount: 100_000)]
        repository.fetchWishesResult = [wish("A", target: 400_000, saved: 50_000), savedB]
        sut.send(.onAppear)

        // Then
        XCTAssertEqual(sut.state.visibleWishTotal?.primary.remainingAmount, 1_050_000)
        XCTAssertEqual(sut.state.visibleWishTotal?.primary.savedAmount, 150_000)
    }

    // MARK: GH-148 TC14

    func test_GH148_TC14_카드가처음보이면_노출로그를화면진입마다한번보낸다() {
        // Given
        let sut = makeGetSut()

        // When: 진입 후 태그·펼침으로 다시 그려도
        load(sut, wishes: [wish("A", target: 400_000, tags: ["가전"]), wish("B", target: 800_000)])
        sut.send(.selectTag("가전"))
        sut.send(.toggleWishTotal)

        // Then: 한 번만
        XCTAssertEqual(impressions.count, 1)
        let event = impressions.first
        XCTAssertEqual(event?.screen, .home)
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "card")
        XCTAssertEqual(event?.parameters[ParameterName.count.rawValue] as? Int, 2)

        // When: 상세에 갔다가 돌아와 다시 진입
        sut.send(.onAppear)

        // Then
        XCTAssertEqual(impressions.count, 2)
    }

    func test_GH148_TC14_다른탭에서시작해_갖고싶어요로오면_그때노출로그를보낸다() {
        // Given
        router.homeCategory = .wantToDo
        let sut = makeSut()
        load(sut, wishes: [wish("A", target: 400_000)])
        XCTAssertTrue(impressions.isEmpty)

        // When
        sut.send(.selectCategory(.wantToGet))

        // Then
        XCTAssertEqual(impressions.count, 1)
    }

    // MARK: GH-148 TC15

    func test_GH148_TC15_펼칠때만_펼치기클릭로그를보낸다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [wish("A", target: 400_000)])

        // When: 펼치고 접는다
        sut.send(.toggleWishTotal)
        sut.send(.toggleWishTotal)

        // Then
        let clicks = clickEvents(objectId: .expandWishTotal)
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.screen, .home)
        XCTAssertEqual(clicks.first?.parameters[ParameterName.objectType.rawValue] as? String, "card")
    }

    func test_GH148_TC15_펼친줄을누르면_줄클릭로그를보낸다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [wish("A", target: 400_000)])
        sut.send(.toggleWishTotal)

        // When
        sut.send(.tapWishTotalItem(id: "A"))

        // Then
        let clicks = clickEvents(objectId: .wishTotalItem)
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.parameters[ParameterName.objectType.rawValue] as? String, "button")
    }

    // MARK: GH-148 TC16

    func test_GH148_TC16_다모은싶은_펼친목록에서다모았어요로맨아래에놓인다() {
        // Given
        let sut = makeGetSut()
        load(sut, wishes: [wish("done", target: 100_000, saved: 100_000), wish("left", target: 200_000)])

        // When
        sut.send(.toggleWishTotal)

        // Then
        let items = sut.state.visibleWishTotal?.primary.items
        XCTAssertEqual(items?.map(\.id), ["left", "done"])
        XCTAssertEqual(items?.last?.isCompleted, true)
        XCTAssertEqual(items?.first?.isCompleted, false)
        XCTAssertEqual(Strings.Home.WishTotal.completed.isEmpty, false)
    }

    // MARK: GH-148 TC17

    func test_GH148_TC17_통화별싶수가같으면_앱언어기본통화가큰줄이다() {
        // Given
        let sut = makeGetSut(defaultCurrency: "USD")

        // When
        load(sut, wishes: [wish("krw", target: 400_000), wish("usd", target: 12_000, currency: "USD")])

        // Then
        XCTAssertEqual(sut.state.visibleWishTotal?.groups.map(\.currency), ["USD", "KRW"])
    }

    func test_GH148_TC17_기본통화가없으면_목록에먼저나온통화가큰줄이다() {
        // Given
        let sut = makeGetSut(defaultCurrency: "JPY")

        // When
        load(sut, wishes: [wish("usd", target: 12_000, currency: "USD"), wish("krw", target: 400_000)])

        // Then
        XCTAssertEqual(sut.state.visibleWishTotal?.groups.map(\.currency), ["USD", "KRW"])
    }
}
