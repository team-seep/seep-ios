import XCTest

@testable import seep_ios

/// 동기화 v1 (GH-93 R-32 ~ R-39, 설계 §5·§6). 기기 두 대 = 메모리 DB 두 개 + 메모리 서버 하나
final class SyncEngineTests: XCTestCase {
    private var server: FakeSyncServer!
    private var photoServer: FakePhotoServer!
    private var deviceA: SyncTestDevice!
    private var deviceB: SyncTestDevice!
    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    override func setUpWithError() throws {
        try super.setUpWithError()
        server = FakeSyncServer()
        photoServer = FakePhotoServer()
        deviceA = try SyncTestDevice(server: server, photoServer: photoServer, clock: start)
        deviceB = try SyncTestDevice(server: server, photoServer: photoServer, clock: start.addingTimeInterval(5))
    }

    override func tearDown() {
        server = nil
        photoServer = nil
        deviceA = nil
        deviceB = nil
        super.tearDown()
    }

    private func signInBoth(uid: String = "uid-1") async {
        let outcomeA = await deviceA.engine.startSession(uid: uid) { _, _ in }
        let outcomeB = await deviceB.engine.startSession(uid: uid) { _, _ in }
        XCTAssertEqual(outcomeA, .merged)
        XCTAssertEqual(outcomeB, .merged)
    }

    // MARK: TC-23

    func test_GH93_TC23_앱과위젯어느경로로쓰든_아웃박스에줄이쌓인다() throws {
        // Given / When: 앱 저장소로 위시·단계·태그·저금·일지, 위젯 저장소로 단계 체크
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주", steps: [WishStep(id: "s1", title: "항공권", order: 0)], tags: ["여행"])).get()
        _ = try deviceA.repository.addSaving(wishId: "w1", amount: 1_000).get()
        _ = try deviceA.repository.addJournal(wishId: "w1", text: "오늘 검색").get()

        // Then
        XCTAssertEqual(deviceA.outboxTables(), ["wish", "wishStep", "wishTag", "wishSaving", "wishJournal"])

        // When: 위젯 프로세스의 쓰기만 따로
        deviceA.store.clearOutbox()
        let widgetRepository = WidgetCheckRepositoryImpl(database: deviceA.database)
        _ = try widgetRepository.checkStep(wishId: "w1", stepId: "s1").get()

        // Then
        XCTAssertTrue(deviceA.outboxTables().contains("wishStep"))
    }

    func test_GH93_TC23_태그가있는280기기에서올리면_v7v8v10이돌고_기존태그가큐에들어간다() throws {
        // Given: 2.8.0 기기 — v9(태그)까지만 돈 DB에 태그 달린 위시.
        // 지금 레코드에는 v9 뒤에 생긴 컬럼(v12 startedAt)이 있어 저장소로 쓰지 않고 그때 스키마대로 SQL 로 넣는다 (GH-143)
        let database = try AppDatabase.makeInMemory(migratedUpTo: "v9", seedSQL: [
            "INSERT INTO wish (id, category, title, hashtag, createdAt, updatedAt) VALUES ('w1', 'category_want_to_do', '제주', '여행', 100, 10)",
            "INSERT INTO wishTag (id, wishId, name, \"order\", createdAt, updatedAt) VALUES ('t1', 'w1', '여행', 0, 10, 10)"
        ])

        // When: 넣은 뒤 남은 마이그레이션(v7·v8·v10·v12)이 돈다
        try database.migrateToLatest()

        // Then: 트리거(v7)가 생기기 전에 쓴 위시는 큐에 없고, 태그만 v10이 넣는다
        let queued = SyncStore(database: database).pendingDocuments(limit: 100)?.documents.map(\.collection) ?? []
        XCTAssertEqual(queued, [.wishTag])
    }

    // MARK: TC-24

    func test_GH93_TC24_push가성공하면_아웃박스가비고_실패하면그대로남는다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()

        // When: 실패
        server.failPush = true
        let failed = await deviceA.engine.sync(trigger: .localChange)

        // Then
        XCTAssertEqual(failed.failedStage, "push")
        XCTAssertEqual(deviceA.store.pendingCount(), 1)

        // When: 성공
        server.failPush = false
        let succeeded = await deviceA.engine.sync(trigger: .localChange)

        // Then
        XCTAssertNil(succeeded.failedStage)
        XCTAssertEqual(succeeded.pushed, 1)
        XCTAssertEqual(deviceA.store.pendingCount(), 0)
        XCTAssertNotNil(server.documents[.wish]?["w1"])
    }

    // MARK: TC-25

    func test_GH93_TC25_A에서만든위시가_B에서받아진다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주", steps: [WishStep(id: "s1", title: "항공권", order: 0)], tags: ["여행", "봄"])).get()
        await deviceA.engine.sync(trigger: .manual)

        // When
        let report = await deviceB.engine.sync(trigger: .manual)

        // Then
        let wish = deviceB.repository.fetchWish(id: "w1")
        XCTAssertEqual(wish?.title, "제주")
        XCTAssertEqual(wish?.steps.map(\.title), ["항공권"])
        XCTAssertEqual(wish?.tags, ["여행", "봄"])
        XCTAssertEqual(report.changedWishIds, ["w1"])
        XCTAssertEqual(deviceB.widgetReloadCount, 1)
    }

    // MARK: TC-26

    func test_GH93_TC26_두기기에서같은위시를고치면_나중에고친쪽이이긴다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // When: A 가 먼저, B 가 나중에 고친다(오프라인), 그다음 A·B 순으로 올린다
        deviceA.tick(60)
        var fromA = try XCTUnwrap(deviceA.repository.fetchWish(id: "w1"))
        fromA.title = "A 제목"
        _ = try deviceA.repository.updateWish(fromA).get()
        deviceB.tick(120)
        var fromB = try XCTUnwrap(deviceB.repository.fetchWish(id: "w1"))
        fromB.title = "B 제목"
        _ = try deviceB.repository.updateWish(fromB).get()
        await deviceB.engine.sync(trigger: .manual)
        await deviceA.engine.sync(trigger: .manual) // A 의 옛 값이 서버의 B 값을 덮는다
        await deviceB.engine.sync(trigger: .manual) // B 는 받은 옛 값보다 자기 값이 새것이라 다시 올릴 줄을 쌓는다
        await deviceB.engine.sync(trigger: .localChange)

        // Then: 두 기기 모두 나중에 고친 B 값으로 맞춰진다
        await deviceA.engine.sync(trigger: .manual)
        XCTAssertEqual(deviceA.repository.fetchWish(id: "w1")?.title, "B 제목")
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w1")?.title, "B 제목")
    }

    // MARK: TC-27

    func test_GH93_TC27_한쪽이지우고다른쪽이나중에고쳐도_삭제가이긴다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // When: A 가 지우고, B 가 더 나중에 고친다
        deviceA.tick(60)
        deviceA.repository.deleteWish(id: "w1")
        deviceB.tick(600)
        var fromB = try XCTUnwrap(deviceB.repository.fetchWish(id: "w1"))
        fromB.title = "고침"
        _ = try deviceB.repository.updateWish(fromB).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual) // B 의 고친 값이 서버의 삭제 표시를 덮는다
        await deviceA.engine.sync(trigger: .manual) // A 는 지운 줄이 서버에 살아 있으면 삭제를 다시 올릴 줄을 쌓는다
        await deviceA.engine.sync(trigger: .localChange)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertNil(deviceA.repository.fetchWish(id: "w1"))
        XCTAssertNil(deviceB.repository.fetchWish(id: "w1"))
        XCTAssertFalse(server.documents[.wish]?["w1"]?.fields["deletedAt"]?.isNull ?? true)
    }

    // MARK: TC-28

    func test_GH93_TC28_받아서적용한줄은_다시올리지않는다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        await deviceA.engine.sync(trigger: .manual)
        let pushesBefore = server.pushCallCount

        // When
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(deviceB.store.pendingCount(), 0)
        let again = await deviceB.engine.sync(trigger: .manual)
        XCTAssertEqual(again.pushed, 0)
        XCTAssertEqual(server.pushCallCount, pushesBefore)
    }

    // MARK: TC-29

    func test_GH93_TC29_하위줄이부모보다먼저와도_다음사이클에적용된다() async throws {
        // Given: 서버에 단계만 먼저 있다
        await signInBoth()
        let stepFields: [String: SyncValue] = [
            "wishId": .text("w9"), "title": .text("항공권"), "isDone": .integer(0), "order": .integer(0),
            "updatedAt": .double(800_000_100), "deletedAt": .null
        ]
        server.put(.wishStep, id: "s9", fields: stepFields)
        let first = await deviceB.engine.sync(trigger: .manual)
        XCTAssertNil(first.failedStage)
        XCTAssertNil(deviceB.repository.fetchWish(id: "w9"))

        // When: 부모 위시가 나중에 온다
        _ = try deviceA.repository.addWish(Wish(id: "w9", title: "오사카")).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w9")?.steps.map(\.id), ["s9"])
    }

    // MARK: TC-30

    func test_GH93_TC30_비회원위시가있는기기에서처음로그인하면_로컬과서버위시가합쳐진다() async throws {
        // Given: A 는 로그인해서 올려 두었고, B 에는 비회원으로 적은 위시가 있다
        _ = try deviceA.repository.addWish(Wish(id: "from-a", title: "A 위시")).get()
        _ = await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        _ = try deviceB.repository.addWish(Wish(id: "from-b", title: "B 위시")).get()

        // When
        var progress: [Int] = []
        let outcome = await deviceB.engine.startSession(uid: "uid-1") { done, _ in progress.append(done) }

        // Then
        XCTAssertEqual(outcome, .merged)
        XCTAssertNotNil(deviceB.repository.fetchWish(id: "from-a"))
        XCTAssertNotNil(deviceB.repository.fetchWish(id: "from-b"))
        XCTAssertNotNil(server.documents[.wish]?["from-b"])
        XCTAssertEqual(progress.last, 1)
        await deviceA.engine.sync(trigger: .manual)
        XCTAssertNotNil(deviceA.repository.fetchWish(id: "from-b"))
    }

    // MARK: TC-31

    func test_GH93_TC31_다른계정위시가남은기기에서로그인하면_합치지않는다() async throws {
        // Given: uid-1 로 쓰다가 "남기기"로 로그아웃
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "1번 계정 위시")).get()
        _ = await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        await deviceA.engine.endSession(unbindDevice: false, flushPending: true)
        let pushesBefore = server.pushCallCount

        // When
        let outcome = await deviceA.engine.startSession(uid: "uid-2") { _, _ in }

        // Then
        XCTAssertEqual(outcome, .accountMismatch)
        XCTAssertEqual(server.pushCallCount, pushesBefore)

        // 같은 계정으로 돌아오면 합친다 (S7')
        let sameAccount = await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        XCTAssertEqual(sameAccount, .merged)
    }

    // MARK: TC-32

    func test_GH93_TC32_받은위시의알림은다시예약되고_삭제완료된위시알림은취소된다() async throws {
        // Given
        await signInBoth()
        let notification = SeepNotification(type: .targetDay, time: start)
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주", endDate: start.addingTimeInterval(86_400 * 10), notifications: [notification])).get()
        await deviceA.engine.sync(trigger: .manual)

        // When: 받으면 예약
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(deviceB.notifications.reservedWishes.map(\.id), ["w1"])

        // When: A 가 지운 것을 받으면 취소
        deviceA.tick(60)
        deviceA.repository.deleteWish(id: "w1")
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(deviceB.notifications.cancelledWishes.map(\.id), ["w1"])
        XCTAssertEqual(deviceB.notifications.reservedWishes.count, 1)
    }

    // MARK: TC-33

    func test_GH93_TC33_고정과내순서도_다른기기에반영된다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "하나")).get()
        _ = try deviceA.repository.addWish(Wish(id: "w2", title: "둘")).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // When
        deviceA.tick(60)
        _ = try deviceA.repository.updatePin(wishId: "w2", isPinned: true).get()
        _ = try deviceA.repository.moveWish(wishId: "w1", orderedIds: ["w2", "w1"]).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        let a1 = try XCTUnwrap(deviceA.repository.fetchWish(id: "w1"))
        let b1 = try XCTUnwrap(deviceB.repository.fetchWish(id: "w1"))
        XCTAssertNotNil(deviceB.repository.fetchWish(id: "w2")?.pinnedAt)
        XCTAssertEqual(b1.manualOrder, a1.manualOrder)
    }

    // MARK: GH-146 TC-12

    func test_GH146_TC12_A와A의체크위젯에서단계를체크하고동기화하면_B에서doneAt이같고잔디에들어간다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주", steps: [
            WishStep(id: "s1", title: "항공권", order: 0),
            WishStep(id: "s2", title: "숙소", order: 1)
        ])).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // When: A 앱에서 한 단계, A 의 체크 위젯에서 한 단계를 체크하고 동기화
        deviceA.tick(60)
        _ = try deviceA.repository.toggleStep(wishId: "w1", stepId: "s1").get()
        let widgetNow = deviceA.clock.addingTimeInterval(30)
        let suiteName = "test.syncEngine.gh146"
        UserDefaults().removePersistentDomain(forName: suiteName)
        defer { UserDefaults().removePersistentDomain(forName: suiteName) }
        let widget = WidgetCheckRepositoryImpl(
            database: deviceA.database,
            store: WidgetCheckStore(userDefaults: UserDefaults(suiteName: suiteName)),
            now: { widgetNow }
        )
        _ = try widget.checkStep(wishId: "w1", stepId: "s2").get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        let stepsA = try deviceA.database.snapshot().steps.sorted { $0.order < $1.order }
        let stepsB = try deviceB.database.snapshot().steps.sorted { $0.order < $1.order }
        XCTAssertEqual(stepsA.compactMap(\.doneAt).count, 2)
        XCTAssertEqual(stepsB.map(\.doneAt), stepsA.map(\.doneAt))
        let activitiesB = deviceB.repository.fetchActivities(from: .distantPast, to: .distantFuture)
        XCTAssertTrue(activitiesB.contains { $0.kind == .stepDone(stepTitle: "항공권") && $0.date == stepsA[0].doneAt })
        XCTAssertTrue(activitiesB.contains { $0.kind == .stepDone(stepTitle: "숙소") && $0.date == widgetNow })
    }

    func test_GH146_TC12_v11전앱이풀었다다시체크하면_서버doneAt을그대로따르고_기기마다같다() async throws {
        // Given: B(새 앱)에서 체크해 서버에 doneAt 이 있다
        await signInBoth()
        _ = try deviceB.repository.addWish(Wish(id: "w1", title: "제주", steps: [WishStep(id: "s1", title: "항공권", order: 0)])).get()
        deviceB.tick(60)
        _ = try deviceB.repository.toggleStep(wishId: "w1", stepId: "s1").get()
        let firstCheck = try XCTUnwrap(try deviceB.database.snapshot().steps.first?.doneAt)
        await deviceB.engine.sync(trigger: .manual)

        // When: v11 전 앱(doneAt 을 모름)이 풀었다가 다시 체크한다 — 서버는 merge 라 doneAt 을 그대로 둔다
        func oldAppWrite(isDone: Int64, at seconds: Double) throws {
            var fields = try XCTUnwrap(server.documents[.wishStep]?["s1"]?.fields)
            fields["isDone"] = .integer(isDone)
            fields["updatedAt"] = .double(seconds)
            server.put(.wishStep, id: "s1", fields: fields)
        }
        try oldAppWrite(isDone: 0, at: firstCheck.timeIntervalSinceReferenceDate + 86_400)
        await deviceB.engine.sync(trigger: .manual)
        // 안 된 단계는 doneAt 이 남아 있어도 잔디에 세지 않는다
        XCTAssertTrue(deviceB.repository.fetchActivities(from: .distantPast, to: .distantFuture).allSatisfy { $0.kind == .added })
        try oldAppWrite(isDone: 1, at: firstCheck.timeIntervalSinceReferenceDate + 2 * 86_400)
        await deviceB.engine.sync(trigger: .manual)
        await deviceA.engine.sync(trigger: .manual)

        // Then: 알려진 한계(R-10) — 다시 체크한 날을 알 수 없어 서버의 처음 체크 시각을 쓰고, 두 기기가 같은 날을 본다
        XCTAssertEqual(try deviceB.database.snapshot().steps.first?.doneAt, firstCheck)
        XCTAssertEqual(try deviceA.database.snapshot().steps.first?.doneAt, firstCheck)
    }

    // MARK: GH-143 TC13

    func test_GH143_TC13_A에서시작했어요를누르고동기화하면_B에서같은시작시각과하는중으로보이고_되돌리기도반영된다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "서핑")).get()
        _ = try deviceA.repository.addWish(Wish(id: "w2", title: "기타")).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // When
        deviceA.tick(60)
        let startedAt = try XCTUnwrap(deviceA.repository.updateStarted(wishId: "w1", isStarted: true).get().startedAt)
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then: 시작 시각이 같고, 칩 수·n일째가 같다
        let wishesA = deviceA.repository.fetchWishes(category: .wantToDo, sort: .deadlineOrder, isOnlyFinished: false)
        let wishesB = deviceB.repository.fetchWishes(category: .wantToDo, sort: .deadlineOrder, isOnlyFinished: false)
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w1")?.startedAt, startedAt)
        XCTAssertEqual(wishesB.filter(\.isInProgress).map(\.id), ["w1"])
        XCTAssertEqual(wishesB.filter(\.isInProgress).count, wishesA.filter(\.isInProgress).count)
        let today = start.addingTimeInterval(86_400 * 3)
        XCTAssertEqual(
            wishesB.compactMap { WishStartStatus.inProgressDays(of: $0, now: today) },
            wishesA.compactMap { WishStartStatus.inProgressDays(of: $0, now: today) }
        )

        // When: A에서 되돌린다
        deviceA.tick(60)
        _ = try deviceA.repository.updateStarted(wishId: "w1", isStarted: false).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertNil(deviceB.repository.fetchWish(id: "w1")?.startedAt)
    }

    // MARK: GH-139 TC14

    func test_GH139_TC14_A에서좋았어요를고르고동기화하면_B에서같은값이고_모아보기집계가A와같다() async throws {
        // Given: 같은 계정의 A·B에 이룬 싶 셋
        await signInBoth()
        for id in ["w1", "w2", "w3"] {
            let wish = try deviceA.repository.addWish(Wish(id: id, title: id)).get()
            _ = try deviceA.repository.finishWish(wish: wish).get()
        }
        _ = try deviceA.repository.updateFinishNote(wishId: "w2", note: "", feeling: .same).get()
        _ = try deviceA.repository.updateFinishNote(wishId: "w3", note: "무난", feeling: .worse).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // When: A에서 이룬 순간 "좋았어요"를 고르고 동기화
        deviceA.tick(60)
        _ = try deviceA.repository.updateFinishNote(wishId: "w1", note: "최고", feeling: .better).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w1")?.finishFeeling, .better)
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w1")?.finishNote, "최고")
        XCTAssertEqual(server.documents[.wish]?["w1"]?.fields["finishFeeling"], .text("better"))
        let summaryA = ExpectationSummary.make(finishedWishes: deviceA.repository.fetchAllFinishedWishes())
        let summaryB = ExpectationSummary.make(finishedWishes: deviceB.repository.fetchAllFinishedWishes())
        XCTAssertNotNil(summaryB)
        XCTAssertEqual(summaryB, summaryA)
        XCTAssertEqual(summaryB?.betterCount, 1)
    }

    func test_GH139_TC20_구버전앱이완료를취소해서버에옛답이남으면_받은기기가비우고서버에서도지운다() async throws {
        // Given: A에서 좋았어요로 이룬 싶
        await signInBoth()
        let wish = try deviceA.repository.addWish(Wish(id: "w1", title: "라멘")).get()
        _ = try deviceA.repository.finishWish(wish: wish).get()
        _ = try deviceA.repository.updateFinishNote(wishId: "w1", note: "", feeling: .better).get()
        await deviceA.engine.sync(trigger: .manual)

        // When: v13 전 앱이 완료를 취소해 올린다 — 모르는 finishFeeling 은 보내지 않아 서버에 그대로 남는다
        var fields = try XCTUnwrap(server.documents[.wish]?["w1"]?.fields)
        fields["isSuccess"] = .integer(0)
        fields["finishDate"] = .null
        fields["finishNote"] = .text("")
        fields["updatedAt"] = .double(900_000_000)
        server.put(.wish, id: "w1", fields: fields)
        await deviceB.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then: 받은 기기는 비우고, 다시 올려 서버의 옛 답도 지운다
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w1")?.isSuccess, false)
        XCTAssertNil(deviceB.repository.fetchWish(id: "w1")?.finishFeeling)
        XCTAssertEqual(server.documents[.wish]?["w1"]?.fields["finishFeeling"], .text(""))
        XCTAssertEqual(server.documents[.wish]?["w1"]?.fields["updatedAt"], .double(900_000_000))
    }

    // MARK: TC-34

    func test_GH93_TC34_더새앱이쓴문서는아는필드만적용하고_다시올려도모르는필드를지우지않는다() async throws {
        // Given: 더 새 앱이 모르는 필드와 함께 쓴 위시
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        await deviceA.engine.sync(trigger: .manual)
        var fields = try XCTUnwrap(server.documents[.wish]?["w1"]?.fields)
        fields["futureField"] = .text("v99 에서 추가")
        fields["title"] = .text("새 앱이 고침")
        fields["updatedAt"] = .double(900_000_000)
        server.put(.wish, id: "w1", fields: fields)

        // When
        await deviceB.engine.sync(trigger: .manual)

        // Then: 아는 필드는 적용
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w1")?.title, "새 앱이 고침")

        // When: B 가 고쳐서 다시 올린다
        deviceB.clock = Date(timeIntervalSinceReferenceDate: 900_000_100)
        var wish = try XCTUnwrap(deviceB.repository.fetchWish(id: "w1"))
        wish.memo = "B 메모"
        _ = try deviceB.repository.updateWish(wish).get()
        await deviceB.engine.sync(trigger: .localChange)

        // Then: 모르는 필드는 서버에 남는다
        XCTAssertEqual(server.documents[.wish]?["w1"]?.fields["futureField"], .text("v99 에서 추가"))
        XCTAssertEqual(server.documents[.wish]?["w1"]?.fields["memo"], .text("B 메모"))
    }

    // MARK: TC-35

    func test_GH93_TC35_한사이클마다_sync_push와sync_pull이1건씩_실패하면sync_error가1건간다() async throws {
        // Given
        await signInBoth()
        let before = deviceA.logManager.sentEvents.count

        // When
        await deviceA.engine.sync(trigger: .manual)

        // Then
        let events = deviceA.logManager.sentEvents.dropFirst(before)
        XCTAssertEqual(events.filter { $0.name == .syncPush }.count, 1)
        XCTAssertEqual(events.filter { $0.name == .syncPull }.count, 1)
        XCTAssertEqual(events.first { $0.name == .syncPush }?.extraParameters?[.trigger] as? String, "manual")

        // When: 실패
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        server.failPush = true
        let failedBefore = deviceA.logManager.sentEvents.count
        await deviceA.engine.sync(trigger: .manual)

        // Then
        let failedEvents = deviceA.logManager.sentEvents.dropFirst(failedBefore)
        XCTAssertEqual(failedEvents.filter { $0.name == .syncError }.count, 1)
        XCTAssertEqual(failedEvents.first?.extraParameters?[.errorType] as? String, "push")
    }

    // MARK: 로그인 전

    func test_GH93_TC23_로그인전에는_서버에붙지않고아웃박스를비운다() async throws {
        // Given
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()

        // When
        let report = await deviceA.engine.sync(trigger: .launch)

        // Then
        XCTAssertTrue(report.isSkipped)
        XCTAssertEqual(server.pushCallCount, 0)
        XCTAssertEqual(deviceA.store.pendingCount(), 0)
    }
}
