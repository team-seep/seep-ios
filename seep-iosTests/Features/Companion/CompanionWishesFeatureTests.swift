import XCTest

@testable import seep_ios

/// 사람별 모아보기 (GH-122 R-5 ~ R-7, R-9)와 상세 "누구랑" 섹션 (R-4)
final class CompanionWishesFeatureTests: ViewModelTestCase {
    private var database: AppDatabase!
    private var repository: WishRepositoryImpl!
    private var clock = Date(timeIntervalSinceReferenceDate: 800_000_000)

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeInMemory()
        repository = WishRepositoryImpl(database: database, now: { [unowned self] in self.clock })
    }

    override func tearDown() {
        database = nil
        repository = nil
        super.tearDown()
    }

    @discardableResult
    private func add(_ wish: Wish) throws -> Wish {
        clock = clock.addingTimeInterval(1)
        return try repository.addWish(wish).get()
    }

    private func makeViewModel(_ person: WishCompanion, repository: WishRepository? = nil) -> CompanionWishesViewModel {
        let viewModel = CompanionWishesViewModel(
            config: .init(person: person),
            dependency: .init(wishRepository: repository ?? self.repository, logManager: logManager)
        )
        viewModel.send(.onAppear)
        return viewModel
    }

    private func day(_ offset: Int) -> Date {
        clock.addingTimeInterval(TimeInterval(offset) * 86_400)
    }

    // MARK: TC-6

    func test_GH122_TC6_남은싶3개와완료1개는_헤드라인3개_D_day가까운순_같이이룬것1개() throws {
        // Given: 세 카테고리에 섞인 남은 싶 3개(하나는 날짜 없음) + 이룬 싶 1개 + 다른 사람 싶
        let mom = WishCompanion(name: "엄마")
        try add(Wish(id: "kimchi", category: .wantToDo, title: "김치찌개 배우기", companions: [mom]))
        try add(Wish(id: "jeju", category: .wantToGo, title: "제주도 한 달 살기", endDate: day(61), companions: [mom]))
        try add(Wish(id: "jinhae", category: .wantToGo, title: "진해 군항제", endDate: day(5), companions: [mom]))
        let photo = try add(Wish(id: "photo", category: .wantToGet, title: "가족사진", companions: [mom]))
        _ = try repository.finishWish(wish: photo).get()
        try add(Wish(id: "camp", title: "캠핑", companions: [WishCompanion(name: "지은")]))

        // When
        let viewModel = makeViewModel(mom)

        // Then
        XCTAssertEqual(viewModel.state.remainingText, Strings.Companion.Wishes.remainingFormat(3))
        XCTAssertEqual(viewModel.state.remaining.map(\.id), ["jinhae", "jeju", "kimchi"])
        XCTAssertEqual(viewModel.state.finished.map(\.id), ["photo"])
        XCTAssertEqual(viewModel.state.finishedTitle, "같이 이룬 것 1개")
        XCTAssertEqual(viewModel.state.remainingText, "3개 남았어요!")
        XCTAssertTrue(viewModel.state.remainingText.contains(viewModel.state.remainingHighlight))
    }

    func test_GH122_TC6_남은싶을누르면_그싶의상세로간다() throws {
        // Given
        let mom = WishCompanion(name: "엄마")
        try add(Wish(id: "jeju", title: "제주", companions: [mom]))
        let viewModel = makeViewModel(mom)

        // When
        viewModel.send(.tapWish(id: "jeju"))

        // Then
        XCTAssertEqual(viewModel.route, .wishDetail(id: "jeju", isFinished: false))
    }

    // MARK: TC-7

    func test_GH122_TC7_CTA를누르면_그사람으로작성화면을연다() throws {
        // Given
        let mom = WishCompanion(name: "엄마")
        try add(Wish(id: "jeju", title: "제주", companions: [mom]))
        let viewModel = makeViewModel(mom)

        // When
        viewModel.send(.tapWrite)

        // Then
        XCTAssertEqual(viewModel.route, .write(mom))
        XCTAssertEqual(viewModel.state.writeTitle, "📝 엄마랑 하고 싶은 것 적기")
    }

    // MARK: TC-10

    func test_GH122_TC10_받침있는이름은이랑_없는이름은랑() throws {
        // Given
        let jieun = WishCompanion(name: "지은")
        let mom = WishCompanion(name: "엄마")
        let tom = WishCompanion(name: "Tom")
        try add(Wish(id: "a", title: "캠핑", companions: [jieun, mom, tom]))

        // When / Then
        XCTAssertEqual(makeViewModel(jieun).state.headline, "지은이랑 하고 싶은 것")
        XCTAssertEqual(makeViewModel(mom).state.headline, "엄마랑 하고 싶은 것")
        XCTAssertEqual(makeViewModel(tom).state.headline, "Tom랑 하고 싶은 것")
        XCTAssertEqual(makeViewModel(jieun).state.writeTitle, "📝 지은이랑 하고 싶은 것 적기")
    }

    func test_GH122_TC10_받침판정() {
        XCTAssertTrue(WishCompanion.hasFinalConsonant("지은"))
        XCTAssertTrue(WishCompanion.hasFinalConsonant("동생"))
        XCTAssertFalse(WishCompanion.hasFinalConsonant("엄마"))
        XCTAssertFalse(WishCompanion.hasFinalConsonant("아빠"))
        XCTAssertFalse(WishCompanion.hasFinalConsonant("Tom"))
        XCTAssertTrue(WishCompanion.hasFinalConsonant("친구1"))
        XCTAssertFalse(WishCompanion.hasFinalConsonant("친구2"))
        XCTAssertFalse(WishCompanion.hasFinalConsonant(""))
    }

    // MARK: TC-11

    func test_GH122_TC11_사람이없는위시는_누구랑섹션이없고_있으면단계앞에보인다() {
        // Given
        let alone = Wish(id: "a", title: "혼자", steps: [WishStep(title: "준비", order: 0)])
        let together = Wish(id: "b", title: "같이", steps: [WishStep(title: "준비", order: 0)], companions: [WishCompanion(name: "엄마")])

        // When / Then
        XCTAssertFalse(DetailSectionBuilder.sections(for: alone).contains(.companion))
        XCTAssertEqual(DetailSectionBuilder.sections(for: together), [.companion, .steps])
    }

    // MARK: TC-12

    func test_GH122_TC12_공유를누르면_companion_share가1건간다() throws {
        // Given
        let mom = WishCompanion(name: "엄마")
        try add(Wish(id: "jeju", title: "제주", companions: [mom]))
        let viewModel = makeViewModel(mom)

        // When
        viewModel.send(.tapShare)

        // Then
        let events = clickEvents(objectId: .companionShare)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .companionWishes)
        XCTAssertEqual(viewModel.screenName, .companionWishes)
    }

    // MARK: TC-14

    func test_GH122_TC14_칩과직접입력으로붙인위시가_한모아보기에모두나온다() throws {
        // Given
        try add(Wish(id: "a", title: "효도 여행", companions: [WishCompanion(name: "엄마")]))
        let mom = try XCTUnwrap(repository.fetchRecentCompanions().first)
        try add(Wish(id: "b", title: "김치찌개", companions: [mom]))
        try add(Wish(id: "c", title: "꽃구경", companions: [WishCompanion(name: " 엄마 ")]))

        // When
        let viewModel = makeViewModel(mom)

        // Then
        XCTAssertEqual(Set(viewModel.state.remaining.map(\.id)), ["a", "b", "c"])
    }

    func test_GH122_TC14_모아보기를연id가_고쳐저장해대표id로합쳐져도_같은싶이보인다() throws {
        // Given: 같은 이름 "지은"이 id 둘(Y가 먼저, X가 나중)로 붙어 있다 — 두 기기가 따로 적은 것처럼 줄을 직접 넣는다
        try add(Wish(id: "b", title: "캠핑", companions: [WishCompanion(personId: "Y", name: "지은")]))
        try add(Wish(id: "a", title: "서핑"))
        try database.insertRecord(WishCompanionRecord(companion: WishCompanion(personId: "X", name: "지은"), wishId: "a", order: 0, now: clock))
        let viewModel = makeViewModel(WishCompanion(personId: "X", name: "지은"))
        XCTAssertEqual(Set(viewModel.state.remaining.map(\.id)), ["a", "b"])

        // When: 위시 a 를 고쳐 저장하면 X 줄이 대표 id Y 로 바뀐다
        var wishA = try XCTUnwrap(repository.fetchWish(id: "a"))
        wishA.memo = "보드 빌리기"
        clock = clock.addingTimeInterval(1)
        _ = try repository.updateWish(wishA).get()
        viewModel.send(.onAppear)

        // Then: 그대로 두 싶이 보이고, 화면의 사람은 대표 id 를 따라간다
        XCTAssertEqual(Set(try database.snapshot().companions.filter { $0.deletedAt == nil }.map(\.personId)), ["Y"])
        XCTAssertEqual(Set(viewModel.state.remaining.map(\.id)), ["a", "b"])
        XCTAssertEqual(viewModel.state.person?.personId, "Y")
    }

    func test_GH122_TC14_한위시에같은사람줄이둘이어도_한번만보인다() throws {
        // Given: 두 기기가 오프라인에서 같은 위시에 같은 사람을 붙여 줄이 둘
        try add(Wish(id: "w", title: "제주", companions: [WishCompanion(personId: "P", name: "엄마")]))
        try database.insertRecord(WishCompanionRecord(companion: WishCompanion(personId: "P", name: "엄마"), wishId: "w", order: 0, now: clock))
        try database.insertRecord(WishCompanionRecord(companion: WishCompanion(personId: "Q", name: "엄마"), wishId: "w", order: 1, now: clock))

        // Then
        XCTAssertEqual(repository.fetchWish(id: "w")?.companions.map(\.name), ["엄마"])
    }

    // MARK: TC-19

    func test_GH122_TC19_상세에서사람칩을누르면_그사람모아보기로가고companion_chip이1건간다() {
        // Given
        let mom = WishCompanion(personId: "p-mom", name: "엄마")
        let wish = Wish(id: "w", title: "제주", companions: [mom])
        let mockRepository = MockWishRepository()
        mockRepository.fetchWishResult = [wish]
        let detail = WishDetailViewModel(
            config: .init(wishId: "w", mode: .fromHome),
            dependency: .init(
                wishRepository: mockRepository,
                notificationManager: MockNotificationManager(),
                logManager: logManager,
                preference: Preference(name: "test-gh122-detail-\(UUID().uuidString)"),
                photoStorage: MockWishPhotoStorage(),
                linkMetadataProvider: MockLinkMetadataProvider(),
                linkPreviewCache: MockLinkPreviewCache(),
                calendarManager: MockCalendarManager()
            )
        )
        detail.send(.onAppear)

        // When
        detail.send(.tapCompanion(mom))

        // Then
        XCTAssertTrue(detail.state.sections.contains(.companion))
        XCTAssertEqual(detail.route, .companionWishes(mom))
        let events = clickEvents(objectId: .companionChip)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        let values = events.first?.extraParameters?.values.map { "\($0)" } ?? []
        XCTAssertFalse(values.contains { $0.contains("엄마") })
    }
}
