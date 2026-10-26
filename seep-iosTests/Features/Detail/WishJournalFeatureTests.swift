import XCTest

@testable import seep_ios_dev

/// 상세 "일지" 섹션 · 한 줄 남기기 시트 (GH-95 R-3 ~ R-7)
final class WishJournalFeatureTests: ViewModelTestCase {
    private var database: AppDatabase!
    private var repository: WishRepositoryImpl!
    private var clock = Date(timeIntervalSinceReferenceDate: 800_000_000)

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeInMemory()
        repository = WishRepositoryImpl(database: database, now: { [unowned self] in clock })
    }

    override func tearDown() {
        repository = nil
        database = nil
        super.tearDown()
    }

    private func addWish(_ wish: Wish = Wish(id: "wish-1", emoji: "🎸", title: "기타 배우기")) throws -> Wish {
        try repository.addWish(wish).get()
    }

    private func makeViewModel(wish: Wish, isEditable: Bool = true) -> WishJournalViewModel {
        WishJournalViewModel(
            config: .init(wish: wish, isEditable: isEditable),
            dependency: .init(wishRepository: repository, logManager: logManager, now: { [unowned self] in clock })
        )
    }

    private func addJournals(count: Int, to wishId: String) throws {
        for index in 1...count {
            clock = clock.addingTimeInterval(60)
            _ = try repository.addJournal(wishId: wishId, text: "일지 \(index)").get()
        }
    }

    // MARK: GH-95 TC1

    func test_GH95_TC1_일지가없는위시를홈에서열면_일지섹션에오늘한줄남기기만보인다() throws {
        // Given
        let wish = try addWish()

        // When
        let sections = DetailSectionBuilder.sections(for: wish, isJournalEditable: true)
        let viewModel = makeViewModel(wish: wish)

        // Then
        XCTAssertTrue(sections.contains(.journal))
        XCTAssertTrue(viewModel.state.journals.isEmpty)
        XCTAssertTrue(viewModel.state.isEditable)
        XCTAssertFalse(viewModel.state.isViewAllVisible)
    }

    func test_GH95_TC1_일지섹션은_단계와모은돈사이에있다() {
        // Given / When
        let order = DetailSection.allCases

        // Then
        let journalIndex = try? XCTUnwrap(order.firstIndex(of: .journal))
        XCTAssertEqual(journalIndex, order.firstIndex(of: .steps).map { $0 + 1 })
        XCTAssertEqual(journalIndex.map { $0 + 1 }, order.firstIndex(of: .savings))
    }

    // MARK: GH-95 TC2

    func test_GH95_TC2_일지가없는이룬위시를이룬싶탭에서열면_일지섹션이없다() {
        // Given
        let wish = Wish(id: "done", title: "이룬 위시", isSuccess: true)

        // When
        let sections = DetailSectionBuilder.sections(for: wish, isJournalEditable: false)

        // Then
        XCTAssertFalse(sections.contains(.journal))
    }

    func test_GH95_TC2_일지가있는이룬위시는_보기전용으로보이고추가할수없다() throws {
        // Given
        let wish = try addWish(Wish(id: "done", title: "이룬 위시"))
        try addJournals(count: 1, to: wish.id)
        let saved = try XCTUnwrap(repository.fetchWish(id: wish.id))

        // When
        let sections = DetailSectionBuilder.sections(for: saved, isJournalEditable: false)
        let viewModel = makeViewModel(wish: saved, isEditable: false)
        viewModel.send(.tapAdd)

        // Then
        XCTAssertTrue(sections.contains(.journal))
        XCTAssertFalse(viewModel.state.isEditable)
        XCTAssertNil(viewModel.route)
    }

    // MARK: GH-95 TC3

    func test_GH95_TC3_공백만입력하면_남기기가비활성이다() {
        // Given
        let input = JournalInputViewModel(config: .init(emoji: "🎸", title: "기타 배우기", date: clock))

        // When
        input.send(.inputText("   "))
        input.send(.tapSave)

        // Then
        XCTAssertFalse(input.state.isSaveEnabled)
        XCTAssertNil(input.route)
    }

    // MARK: GH-95 TC4

    func test_GH95_TC4_100자를넘게입력하면_100자에서더들어가지않는다() {
        // Given
        let input = JournalInputViewModel(config: .init(emoji: "🎸", title: "기타 배우기", date: clock))

        // When
        input.send(.inputText(String(repeating: "가", count: 130)))

        // Then
        XCTAssertEqual(input.state.text.count, 100)
        XCTAssertEqual(input.state.countText, "100/100")
    }

    // MARK: GH-95 TC5

    func test_GH95_TC5_남기기를누르면_일지가저장되고맨위에보이며토스트가뜬다() throws {
        // Given
        let wish = try addWish()
        try addJournals(count: 1, to: wish.id)
        let viewModel = makeViewModel(wish: try XCTUnwrap(repository.fetchWish(id: wish.id)))
        viewModel.send(.tapAdd)
        guard case .journalInput(let input) = viewModel.route else {
            return XCTFail("입력 시트가 떠야 한다")
        }
        viewModel.send(.routeHandled)
        clock = clock.addingTimeInterval(60)

        // When
        input.send(.inputText("F코드 성공"))
        input.send(.tapSave)

        // Then
        XCTAssertEqual(input.route, .dismiss)
        XCTAssertEqual(viewModel.state.journals.first?.text, "F코드 성공")
        XCTAssertEqual(viewModel.state.journals.first?.createdAt, clock)
        XCTAssertEqual(viewModel.route, .toast(Strings.Detail.Journal.Toast.saved))
        let rows = try database.snapshot().journals
        XCTAssertEqual(rows.count, 2)
        XCTAssertTrue(rows.contains { $0.text == "F코드 성공" && $0.wishId == wish.id && $0.deletedAt == nil })
    }

    func test_GH95_TC5_남기기를누르면_추가클릭과저장클릭이벤트가남는다() throws {
        // Given
        let viewModel = makeViewModel(wish: try addWish())

        // When
        viewModel.send(.tapAdd)
        viewModel.send(.saveText("오늘 연습"))

        // Then
        XCTAssertEqual(clickEvents(objectId: .addJournal).first?.parameters["screen"] as? String, "wish_detail")
        XCTAssertEqual(clickEvents(objectId: .saveJournal).first?.parameters["screen"] as? String, "journal_bottom_sheet")
    }

    func test_GH95_TC5_입력시트의날짜는오늘이다() {
        // Given
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000)

        // When
        let input = JournalInputViewModel(config: .init(emoji: "🎸", title: "기타 배우기", date: date))

        // Then
        XCTAssertEqual(input.dateText, DateUtils.toString(format: "M월 d일 (E)", date: date))
        XCTAssertEqual(input.titlePrefix, "오늘 🎸 ")
    }

    // MARK: GH-95 TC6

    func test_GH95_TC6_일지5개면_최신3개와모두보기가보이고누르면5개모두보인다() throws {
        // Given
        let wish = try addWish()
        try addJournals(count: 5, to: wish.id)
        let viewModel = makeViewModel(wish: try XCTUnwrap(repository.fetchWish(id: wish.id)))

        // When
        let collapsed = viewModel.state.visibleJournals.map(\.text)
        let isViewAllVisible = viewModel.state.isViewAllVisible
        viewModel.send(.tapViewAll)

        // Then
        XCTAssertEqual(collapsed, ["일지 5", "일지 4", "일지 3"])
        XCTAssertTrue(isViewAllVisible)
        XCTAssertEqual(viewModel.state.visibleJournals.count, 5)
        XCTAssertFalse(viewModel.state.isViewAllVisible)
        XCTAssertEqual(clickEvents(objectId: .viewAllJournals).count, 1)
    }

    // MARK: GH-95 TC7

    func test_GH95_TC7_일지를남기면_lastCheckedAt이갱신된다() throws {
        // Given: 61일 동안 점검하지 않은 위시
        let old = clock.addingTimeInterval(-61 * 86_400)
        _ = try addWish(Wish(id: "sleepy", title: "잠든 위시", lastCheckedAt: old, createdAt: old))

        // When
        _ = try repository.addJournal(wishId: "sleepy", text: "다시 시작").get()

        // Then
        XCTAssertEqual(repository.fetchWish(id: "sleepy")?.lastCheckedAt, clock)
    }

    // MARK: GH-95 TC8

    func test_GH95_TC8_길게눌러지우기를고르면_삭제표시되고목록에서빠진다() throws {
        // Given
        let wish = try addWish()
        try addJournals(count: 2, to: wish.id)
        let viewModel = makeViewModel(wish: try XCTUnwrap(repository.fetchWish(id: wish.id)))
        let target = try XCTUnwrap(viewModel.state.journals.first)

        // When
        viewModel.send(.tapDelete(journalId: target.id))

        // Then
        XCTAssertEqual(viewModel.state.journals.map(\.text), ["일지 1"])
        let row = try XCTUnwrap(database.snapshot().journals.first { $0.id == target.id })
        XCTAssertNotNil(row.deletedAt)
    }

    func test_GH95_TC8_이룬싶상세는보기전용이라_지울수없다() throws {
        // Given
        let wish = try addWish()
        try addJournals(count: 1, to: wish.id)
        let viewModel = makeViewModel(wish: try XCTUnwrap(repository.fetchWish(id: wish.id)), isEditable: false)
        let target = try XCTUnwrap(viewModel.state.journals.first)

        // When
        viewModel.send(.tapDelete(journalId: target.id))

        // Then
        XCTAssertNil(try database.snapshot().journals.first?.deletedAt)
    }

    // MARK: GH-95 TC9

    func test_GH95_TC9_위시를지우면_그위시의일지도삭제표시된다() throws {
        // Given
        let wish = try addWish()
        try addJournals(count: 2, to: wish.id)

        // When
        repository.deleteWish(id: wish.id)

        // Then
        let journals = try database.snapshot().journals
        XCTAssertEqual(journals.count, 2)
        XCTAssertTrue(journals.allSatisfy { $0.deletedAt != nil })
    }

    // MARK: GH-95 TC10

    func test_GH95_TC10_일지테이블이없는이전DB를올리면_기존위시가그대로이고일지는0개다() throws {
        // Given: v4 까지의 DB 에 위시 한 줄
        let seed = """
            INSERT INTO wish (id, category, title, createdAt, updatedAt, manualOrder) \
            VALUES ('old', 'category_want_to_do', '예전 위시', 790000000, 790000000, 1)
            """

        // When
        let migrated = try AppDatabase.makeInMemory(migratedUpTo: "v4", seedSQL: [seed])

        // Then
        let wish = try XCTUnwrap(WishRepositoryImpl(database: migrated).fetchWish(id: "old"))
        XCTAssertEqual(wish.title, "예전 위시")
        XCTAssertTrue(wish.journals.isEmpty)
        XCTAssertTrue(try migrated.snapshot().journals.isEmpty)
    }
}
