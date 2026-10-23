import XCTest

@testable import seep_ios_dev

/// GRDB 저장소 (GH-79 R-4~R-6, R-13). 메모리 DB 로 실제 구현을 돌린다.
final class WishRepositoryTests: XCTestCase {
    private var database: AppDatabase!
    private var clock = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private var sut: WishRepositoryImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeInMemory()
        sut = WishRepositoryImpl(database: database, now: { [unowned self] in self.clock })
    }

    override func tearDown() {
        database = nil
        sut = nil
        super.tearDown()
    }

    private func tick() {
        clock = clock.addingTimeInterval(60)
    }

    private func add(_ wish: Wish) throws {
        _ = try sut.addWish(wish).get()
    }

    private static func day(_ day: Int) -> Date {
        Date(timeIntervalSinceReferenceDate: 790_000_000 + Double(day) * 86_400)
    }

    // MARK: GH-79 TC8

    func test_GH79_TC8_추가한위시를카테고리로읽으면_마감순으로보인다() throws {
        // Given
        try add(Wish(id: "late", title: "늦은 위시", endDate: Self.day(20)))
        try add(Wish(id: "soon", title: "가까운 위시", endDate: Self.day(5)))
        try add(Wish(id: "other", category: .wantToGet, title: "다른 카테고리"))

        // When
        let wishes = sut.fetchWishes(category: .wantToDo, sort: .deadlineOrder, isOnlyFinished: false)

        // Then
        XCTAssertEqual(wishes.map(\.id), ["soon", "late"])
        XCTAssertEqual(sut.fetchNotFinishCount(category: .wantToDo), 2)
    }

    func test_GH79_TC8_완료하고취소하면_완료일소감고정이규칙대로바뀐다() throws {
        // Given
        let wish = Wish(id: "wish-1", title: "위시", pinnedAt: Self.day(1))
        try add(wish)

        // When
        let finished = try sut.finishWish(wish: wish).get()
        _ = try sut.updateFinishNote(wishId: "wish-1", note: "해냈다").get()

        // Then
        XCTAssertTrue(finished.isSuccess)
        XCTAssertNotNil(finished.finishDate)
        XCTAssertNil(sut.fetchWish(id: "wish-1")?.pinnedAt)
        XCTAssertEqual(sut.fetchAllFinishedWishes().map(\.finishNote), ["해냈다"])

        // When
        let canceled = try sut.cancelFinish(wishId: "wish-1").get()

        // Then
        XCTAssertFalse(canceled.isSuccess)
        XCTAssertNil(canceled.finishDate)
        XCTAssertEqual(canceled.finishNote, "")
    }

    func test_GH79_TC8_수정하면_단계알림은바꾸고모은돈장소사진은그대로둔다() throws {
        // Given
        let original = Wish(
            id: "wish-1",
            title: "위시",
            notifications: [SeepNotification(id: "noti-1", type: .dayAgo, time: Self.day(3))],
            steps: [WishStep(id: "keep", title: "남길 단계", isDone: true, order: 0), WishStep(id: "drop", title: "뺄 단계", order: 1)],
            targetAmount: 100_000,
            savings: [WishSaving(id: "saving-1", amount: 5_000, createdAt: Self.day(2))],
            place: WishPlace(name: "카페", address: "서울", latitude: 37.5, longitude: 127.0),
            photoFileName: "photo.jpg"
        )
        try add(original)
        var edited = original
        edited.title = "고친 위시"
        edited.steps = [original.steps[0], WishStep(id: "new", title: "새 단계", order: 2)]
        edited.notifications = [SeepNotification(id: "noti-2", type: .weekAgo, time: Self.day(4))]
        edited.savings = []
        edited.place = nil
        edited.photoFileName = ""

        // When
        let updated = try sut.updateWish(edited).get()

        // Then
        XCTAssertEqual(updated.title, "고친 위시")
        XCTAssertEqual(updated.steps.map(\.id), ["keep", "new"])
        XCTAssertEqual(updated.steps.first?.isDone, true)
        XCTAssertEqual(updated.notifications.map(\.id), ["noti-2"])
        XCTAssertEqual(updated.savings.map(\.id), ["saving-1"])
        XCTAssertEqual(updated.place?.name, "카페")
        XCTAssertEqual(updated.photoFileName, "photo.jpg")
        XCTAssertNotNil(updated.lastCheckedAt)
    }

    func test_GH79_TC8_단계체크저금추가삭제고정점검장소사진이_저장된다() throws {
        // Given
        try add(Wish(id: "wish-1", title: "위시", steps: [WishStep(id: "step-1", title: "단계", order: 0)]))

        // When
        let steps = try sut.toggleStep(wishId: "wish-1", stepId: "step-1").get()
        let afterAdd = try sut.addSaving(wishId: "wish-1", amount: 3_000).get()
        let afterDelete = try sut.deleteSaving(wishId: "wish-1", savingId: afterAdd[0].id).get()
        _ = try sut.updatePin(wishId: "wish-1", isPinned: true).get()
        _ = try sut.markChecked(wishId: "wish-1").get()
        _ = try sut.updatePlace(wishId: "wish-1", place: WishPlace(name: "공원", address: "부산", latitude: 35, longitude: 129)).get()
        let wish = try sut.updatePhoto(wishId: "wish-1", fileName: "a.jpg").get()

        // Then
        XCTAssertEqual(steps.map(\.isDone), [true])
        XCTAssertEqual(afterAdd.map(\.amount), [3_000])
        XCTAssertTrue(afterDelete.isEmpty)
        XCTAssertEqual(wish.pinnedAt, clock)
        XCTAssertEqual(wish.lastCheckedAt, clock)
        XCTAssertEqual(wish.place?.name, "공원")
        XCTAssertEqual(wish.photoFileName, "a.jpg")
    }

    func test_GH79_TC8_검색과기간조회가_전과같게동작한다() throws {
        // Given
        try add(Wish(id: "trip", title: "제주 한 달 살기", hashtag: "trip"))
        try add(Wish(id: "memo", title: "책 읽기", memo: "제주에서 읽을 책"))
        try add(Wish(id: "in", title: "1월 완료", finishDate: Self.day(10), isSuccess: true))
        try add(Wish(id: "out", title: "2월 완료", finishDate: Self.day(40), isSuccess: true))

        // When
        let byTitle = sut.searchWishes(keyword: "제주")
        let byHashtag = sut.searchWishes(keyword: "여행")
        let inRange = sut.fetchFinishedWishes(from: Self.day(0), to: Self.day(30))

        // Then
        XCTAssertEqual(Set(byTitle.map(\.id)), ["trip", "memo"])
        XCTAssertEqual(byHashtag.map(\.id), ["trip"])
        XCTAssertEqual(inRange.map(\.id), ["in"])
    }

    // MARK: GH-79 TC9

    func test_GH79_TC9_위시를삭제하면_위시와하위레코드가모두보이지않는다() throws {
        // Given
        try add(Wish(
            id: "wish-1",
            title: "위시",
            notifications: [SeepNotification(type: .dayAgo)],
            steps: [WishStep(title: "단계", order: 0)],
            savings: [WishSaving(amount: 1_000)]
        ))

        // When
        sut.deleteWish(id: "wish-1")

        // Then
        XCTAssertNil(sut.fetchWish(id: "wish-1"))
        let snapshot = try database.snapshot()
        XCTAssertTrue(snapshot.wishes.allSatisfy { $0.deletedAt == clock })
        XCTAssertTrue(snapshot.steps.allSatisfy { $0.deletedAt == clock })
        XCTAssertTrue(snapshot.savings.allSatisfy { $0.deletedAt == clock })
        XCTAssertTrue(snapshot.notifications.allSatisfy { $0.deletedAt == clock })
    }

    // MARK: GH-79 TC12

    func test_GH79_TC12_체크위젯에서쓴내용이_앱저장소에서그대로보인다() throws {
        // Given
        try add(Wish(id: "wish-1", title: "위시", steps: [WishStep(id: "step-1", title: "단계", order: 0)]))
        let widget = WidgetCheckRepositoryImpl(
            database: database,
            store: WidgetCheckStore(userDefaults: UserDefaults(suiteName: "test.GH79.TC12")),
            now: { [unowned self] in self.clock }
        )

        // When
        _ = try widget.checkStep(wishId: "wish-1", stepId: "step-1").get()
        _ = try widget.finishWish(wishId: "wish-1", lastStepId: nil).get()

        // Then
        let wish = try XCTUnwrap(sut.fetchWish(id: "wish-1"))
        XCTAssertTrue(wish.isSuccess)
        XCTAssertEqual(wish.steps.map(\.isDone), [true])
        UserDefaults().removePersistentDomain(forName: "test.GH79.TC12")
    }

    // MARK: GH-79 TC15

    func test_GH79_TC15_없거나지운위시를바꾸면_실패하고DB는그대로다() throws {
        // Given
        try add(Wish(id: "deleted", title: "지운 위시"))
        sut.deleteWish(id: "deleted")
        let before = try database.snapshot().wishes

        // When
        let missing = sut.updateFinishNote(wishId: "missing", note: "소감")
        let deleted = sut.updatePin(wishId: "deleted", isPinned: true)

        // Then
        XCTAssertEqual(missing.failureError, .targetNotFound)
        XCTAssertEqual(deleted.failureError, .targetNotFound)
        XCTAssertEqual(try database.snapshot().wishes, before)
    }

    func test_GH79_TC15_DB를열지못하면_noDatabase를돌려준다() {
        // Given
        let noDatabase = WishRepositoryImpl(database: nil)

        // When
        let result = noDatabase.addWish(Wish(title: "위시"))

        // Then
        XCTAssertEqual(result.failureError, .noDatabase)
    }

    // MARK: GH-79 TC19

    func test_GH79_TC19_삭제한위시는_모든조회와위젯에서빠진다() throws {
        // Given
        try add(Wish(id: "alive", title: "제주 남은 위시"))
        try add(Wish(id: "gone", title: "제주 지운 위시"))
        try add(Wish(id: "gone-done", title: "제주 지운 완료", finishDate: Self.day(3), isSuccess: true))
        sut.deleteWish(id: "gone")
        sut.deleteWish(id: "gone-done")

        // When / Then
        XCTAssertEqual(sut.fetchWishes(category: .wantToDo, sort: .latestOrder, isOnlyFinished: false).map(\.id), ["alive"])
        XCTAssertEqual(sut.fetchNotFinishCount(category: .wantToDo), 1)
        XCTAssertEqual(sut.searchWishes(keyword: "제주").map(\.id), ["alive"])
        XCTAssertTrue(sut.fetchAllFinishedWishes().isEmpty)
        XCTAssertTrue(sut.fetchFinishedWishes(from: Self.day(0), to: Self.day(10)).isEmpty)
        let widgetRepository = WidgetWishRepositoryImpl(database: database)
        XCTAssertEqual(widgetRepository.fetchUnfinishedWishes().map(\.id), ["alive"])
        XCTAssertEqual(widgetRepository.fetchUnfinishedCount(category: .wantToDo), 1)
        let checkWidget = WidgetCheckRepositoryImpl(database: database, store: WidgetCheckStore(userDefaults: UserDefaults(suiteName: "test.GH79.TC19")))
        XCTAssertEqual(checkWidget.fetchCheckWidgetWishes(limit: 3).map(\.id), ["alive"])
        XCTAssertNil(checkWidget.fetchWish(id: "gone"))
        UserDefaults().removePersistentDomain(forName: "test.GH79.TC19")
    }

    // MARK: GH-79 TC20

    func test_GH79_TC20_하위레코드를바꾸면_그줄과부모위시의updatedAt이갱신된다() throws {
        // Given
        try add(Wish(id: "wish-1", title: "위시", steps: [WishStep(id: "step-1", title: "단계", order: 0)]))
        let createdAt = clock
        tick()

        // When
        _ = try sut.toggleStep(wishId: "wish-1", stepId: "step-1").get()

        // Then
        let snapshot = try database.snapshot()
        XCTAssertEqual(snapshot.steps.first?.updatedAt, clock)
        XCTAssertEqual(snapshot.wishes.first?.updatedAt, clock)
        XCTAssertNotEqual(clock, createdAt)
    }

    func test_GH79_TC20_지우면줄을남기고_deletedAt만기록한다() throws {
        // Given
        try add(Wish(id: "wish-1", title: "위시", steps: [WishStep(id: "step-1", title: "단계", order: 0)]))
        let saving = try sut.addSaving(wishId: "wish-1", amount: 1_000).get()[0]
        tick()

        // When
        _ = try sut.deleteSaving(wishId: "wish-1", savingId: saving.id).get()
        var edited = try XCTUnwrap(sut.fetchWish(id: "wish-1"))
        edited.steps = []
        _ = try sut.updateWish(edited).get()

        // Then
        let snapshot = try database.snapshot()
        XCTAssertEqual(snapshot.savings.map(\.deletedAt), [clock])
        XCTAssertEqual(snapshot.steps.map(\.deletedAt), [clock])
        XCTAssertEqual(snapshot.steps.map(\.updatedAt), [clock])
    }
}

private extension Result {
    var failureError: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
