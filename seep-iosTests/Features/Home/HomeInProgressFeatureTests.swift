import XCTest

@testable import seep_ios

/// 홈 "하는 중 n" 칩·셀 "n일째" (GH-143 R-4, R-5)
final class HomeInProgressFeatureTests: HomeFeatureTestCase {
    private var calendar: Calendar!
    /// 2026-11-19 15:00 KST
    private var now: Date!
    /// 2026-11-08 09:00 KST
    private var startedAt: Date!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, hour: 15))
        startedAt = calendar.date(from: DateComponents(year: 2026, month: 11, day: 8, hour: 9))
    }

    override func tearDown() {
        calendar = nil
        now = nil
        startedAt = nil
        super.tearDown()
    }

    private func loadedSut(_ wishes: [Wish]) -> HomeViewModel {
        let now = self.now ?? Date()
        let sut = makeSut(now: { now }, calendar: calendar)
        load(sut, wishes: wishes)
        return sut
    }

    private func doing(_ id: String, tags: [String] = []) -> Wish {
        Wish(id: id, title: "하는 중 \(id)", tags: tags, startedAt: startedAt)
    }

    private func notStarted(_ id: String, tags: [String] = []) -> Wish {
        Wish(id: id, title: "시작 전 \(id)", tags: tags)
    }

    // MARK: GH-143 TC7

    func test_GH143_TC7_하는중2개시작전4개면_하는중2칩이보이고_고르면2개만보인다() {
        // Given
        let sut = loadedSut([notStarted("a"), doing("b"), notStarted("c"), doing("d"), notStarted("e"), notStarted("f")])

        // Then
        XCTAssertEqual(sut.state.inProgressCount, 2)
        XCTAssertTrue(sut.state.isTagFilterVisible)
        XCTAssertEqual(sut.state.filter, .all)

        // When
        sut.send(.selectInProgressFilter)

        // Then
        XCTAssertEqual(sut.state.filter, .inProgress)
        XCTAssertEqual(listedWishIds(of: sut), ["b", "d"])
        XCTAssertNil(sut.state.selectedTag)
    }

    func test_GH143_TC7_하는중싶이없는카테고리에서는_칩이없고_태그도없으면칩줄이숨는다() {
        // Given
        let sut = loadedSut([notStarted("a"), notStarted("b")])

        // When
        sut.send(.selectInProgressFilter)

        // Then
        XCTAssertEqual(sut.state.inProgressCount, 0)
        XCTAssertFalse(sut.state.isTagFilterVisible)
        XCTAssertEqual(sut.state.filter, .all)
        XCTAssertTrue(clickEvents(objectId: .inProgressFilter).isEmpty)
    }

    func test_GH143_TC7_태그가없어도하는중싶이있으면_칩줄이보인다() {
        // When
        let sut = loadedSut([doing("a"), notStarted("b")])

        // Then
        XCTAssertTrue(sut.state.tagChips.isEmpty)
        XCTAssertTrue(sut.state.isTagFilterVisible)
    }

    func test_GH143_TC7_하는중과태그칩은하나만고르고_카테고리를옮기면전체로돌아간다() {
        // Given
        let sut = loadedSut([doing("a", tags: ["trip"]), notStarted("b", tags: ["trip"]), doing("c")])
        sut.send(.selectInProgressFilter)

        // When: 태그를 고르면 하는 중이 풀린다
        sut.send(.selectTag("trip"))

        // Then
        XCTAssertEqual(sut.state.filter, .tag("trip"))
        XCTAssertEqual(listedWishIds(of: sut), ["a", "b"])

        // When: 다시 하는 중
        sut.send(.selectInProgressFilter)

        // Then
        XCTAssertNil(sut.state.selectedTag)
        XCTAssertEqual(listedWishIds(of: sut), ["a", "c"])
        XCTAssertFalse(sut.state.isReorderButtonVisible)

        // When
        sut.send(.selectCategory(.wantToGet))

        // Then
        XCTAssertEqual(sut.state.filter, .all)
    }

    // MARK: GH-143 TC8

    func test_GH143_TC8_하는중칩을고른채_마지막하는중싶을되돌리면_칩이사라지고전체가선택된다() {
        // Given
        let sut = loadedSut([doing("a"), notStarted("b")])
        sut.send(.selectInProgressFilter)

        // When: 상세에서 되돌리고 홈으로 돌아왔다
        repository.fetchWishesResult = [notStarted("a"), notStarted("b")]
        sut.send(.onAppear)

        // Then
        XCTAssertEqual(sut.state.inProgressCount, 0)
        XCTAssertEqual(sut.state.filter, .all)
        XCTAssertEqual(listedWishIds(of: sut), ["a", "b"])
    }

    func test_GH143_TC8_하는중칩을고른채_마지막하는중싶을이루면_칩이사라지고전체가선택된다() {
        // Given
        let target = doing("a")
        let sut = loadedSut([target, notStarted("b")])
        sut.send(.selectInProgressFilter)
        var finished = target
        finished.isSuccess = true
        finished.finishDate = now
        repository.finishWishResult = .success(finished)

        // When
        sut.send(.tapFinish(target))

        // Then: 방금 이룬 싶은 흐리게 남고, 칩은 사라진다
        XCTAssertEqual(sut.state.inProgressCount, 0)
        XCTAssertEqual(sut.state.filter, .all)
        XCTAssertEqual(listedWishIds(of: sut), ["a", "b"])
    }

    // MARK: GH-143 TC9

    func test_GH143_TC9_하는중싶셀에만_n일째가붙는다() {
        // Given
        var finished = doing("c")
        finished.isSuccess = true

        // When
        let sut = loadedSut([doing("a"), notStarted("b")])
        let finishedItem = HomeWishItem(wish: finished, photoStorage: photoStorage, now: now, calendar: calendar)

        // Then
        XCTAssertEqual(sut.state.items.map(\.inProgressDays), [12, nil])
        XCTAssertNil(finishedItem.inProgressDays)
        XCTAssertEqual(Strings.Home.InProgress.daysFormat(12), "12일째")
        XCTAssertEqual(Strings.Home.InProgress.daysAccessibilityFormat(12), "하는 중, 12일째")
    }

    // MARK: GH-143 TC12

    func test_GH143_TC12_하는중칩을누르면_in_progress_filter클릭이1건전송된다() {
        // Given
        let sut = loadedSut([doing("a"), notStarted("b")])

        // When: 이미 고른 칩을 다시 눌러도 한 번
        sut.send(.selectInProgressFilter)
        sut.send(.selectInProgressFilter)

        // Then
        let events = clickEvents(objectId: .inProgressFilter)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .home)
        XCTAssertEqual(events.first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }
}
