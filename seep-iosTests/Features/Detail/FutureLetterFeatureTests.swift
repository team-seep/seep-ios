import XCTest

@testable import seep_ios_dev

/// "미래의 나에게" 편지 — 상세 섹션·편지 시트·완료 소감 시트 (GH-61)
final class FutureLetterFeatureTests: ViewModelTestCase {
    private var repository: MockWishRepository!
    private let calendar = Calendar(identifier: .gregorian)

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    private func day(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: 9))!
    }

    private func makeSection(_ wish: Wish) -> DetailLetterViewModel {
        DetailLetterViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: repository, logManager: logManager)
        )
    }

    private func makeDetail(_ wish: Wish) -> WishDetailViewModel {
        repository.fetchWishResult = [wish]
        return WishDetailViewModel(
            config: .init(wishId: wish.id, mode: wish.isSuccess ? .fromFinish : .fromHome),
            dependency: .init(wishRepository: repository, logManager: logManager)
        )
    }

    private func makeFinishNote(_ wish: Wish) -> FinishNoteViewModel {
        FinishNoteViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: repository, logManager: logManager, now: { [day] in day(31) }, calendar: calendar)
        )
    }

    private func sheet(from section: DetailLetterViewModel) -> FutureLetterViewModel? {
        if case .writeSheet(let sheet) = section.route { return sheet }
        return nil
    }

    private func sealedWish(id: String = "wish-1", isSuccess: Bool = false, finishDate: Date? = nil) -> Wish {
        Wish(
            id: id,
            emoji: "🏔️",
            title: "한라산 백록담 올라가기",
            finishDate: finishDate,
            isSuccess: isSuccess,
            futureLetter: "왜 이걸 하고 싶었는지 잊지 마.",
            futureLetterSealedAt: day(8)
        )
    }

    // MARK: GH-61 TC1

    func test_GH61_TC1_편지없는미완료위시는_미래의나에게섹션이쓰기상태로보인다() {
        // Given
        let wish = Wish(id: "wish-1", title: "한라산 백록담 올라가기")

        // When
        let detail = makeDetail(wish)

        // Then
        XCTAssertEqual(detail.state.sections.last, .letter)
        XCTAssertEqual(detail.letter?.state.letter, .empty)
    }

    // MARK: GH-61 TC2

    func test_GH61_TC2_공백만입력하면_봉인하기가비활성이고_눌러도봉인되지않는다() {
        // Given
        let sheet = FutureLetterViewModel(dependency: .init(logManager: logManager))
        var sealed: [String] = []
        sheet.onSeal = { sealed.append($0) }

        // When
        sheet.send(.inputLetter("  \n  "))
        sheet.send(.tapSeal)

        // Then
        XCTAssertFalse(sheet.state.isSealEnabled)
        XCTAssertTrue(sealed.isEmpty)
        XCTAssertNil(sheet.route)
    }

    // MARK: GH-61 TC3

    func test_GH61_TC3_301자를입력하면_300자로잘리고카운터가300이다() {
        // Given
        let sheet = FutureLetterViewModel(dependency: .init(logManager: logManager))

        // When
        sheet.send(.inputLetter(String(repeating: "가", count: 301)))

        // Then
        XCTAssertEqual(sheet.state.letterText.count, 300)
        XCTAssertEqual(sheet.state.countText, "300/300")
    }

    // MARK: GH-61 TC4

    func test_GH61_TC4_내용을입력하고봉인하면_저장되고섹션이봉인상태가된다() {
        // Given
        let wish = Wish(id: "wish-1", title: "한라산 백록담 올라가기")
        let section = makeSection(wish)
        var updated: [Wish] = []
        section.onUpdate = { updated.append($0) }
        repository.sealFutureLetterResult = .success(sealedWish())
        section.send(.tapWrite)
        let sheet = sheet(from: section)

        // When
        sheet?.send(.inputLetter("  왜 이걸 하고 싶었는지 잊지 마.  "))
        sheet?.send(.tapSeal)

        // Then
        XCTAssertEqual(repository.sealFutureLetterCalls.map(\.letter), ["왜 이걸 하고 싶었는지 잊지 마."])
        XCTAssertEqual(section.state.letter, .sealed(caption: "10월 8일에 봉인했어요 · 18자"))
        XCTAssertEqual(updated.map(\.futureLetter), ["왜 이걸 하고 싶었는지 잊지 마."])
        XCTAssertEqual(sheet?.route, .dismiss)
    }

    // MARK: GH-61 TC5

    func test_GH61_TC5_봉인된미완료위시는_본문이섹션상태어디에도없다() {
        // Given / When
        let section = makeSection(sealedWish())

        // Then
        guard case .sealed(let caption) = section.state.letter else { return XCTFail("봉인 상태가 아니다") }
        XCTAssertFalse(caption.contains("잊지 마"))
    }

    // MARK: GH-61 TC6

    func test_GH61_TC6_다시쓰기는_확인뒤빈칸에서시작하고_새내용으로덮어쓴다() {
        // Given
        let section = makeSection(sealedWish())

        // When
        section.send(.tapRewrite)
        let routeBeforeConfirm = section.route
        section.send(.routeHandled)
        section.send(.confirmRewrite)
        let sheet = sheet(from: section)
        sheet?.send(.inputLetter("새 편지"))
        sheet?.send(.tapSeal)

        // Then
        XCTAssertEqual(routeBeforeConfirm, .rewriteAlert)
        XCTAssertEqual(sheet?.state.letterText, "새 편지")
        XCTAssertEqual(repository.sealFutureLetterCalls.map(\.letter), ["새 편지"])
    }

    func test_GH61_TC6_다시쓰기시트는_이전내용을보여주지않는다() {
        // Given
        let section = makeSection(sealedWish())

        // When
        section.send(.confirmRewrite)

        // Then
        XCTAssertEqual(sheet(from: section)?.state.letterText, "")
    }

    // MARK: GH-61 TC7

    func test_GH61_TC7_23일전에봉인한위시를완료하면_소감시트위에편지가열린다() {
        // Given: 10월 8일 봉인, 10월 31일 완료
        let wish = sealedWish(isSuccess: true, finishDate: calendar.startOfDay(for: day(31)))

        // When
        let viewModel = makeFinishNote(wish)

        // Then
        XCTAssertEqual(viewModel.state.openedLetter?.headline, "23일 전의 내가\n편지를 보냈어요")
        XCTAssertEqual(viewModel.state.openedLetter?.body, "왜 이걸 하고 싶었는지 잊지 마.")
        XCTAssertEqual(viewModel.state.openedLetter?.caption, "🏔️ 한라산 백록담 올라가기 · 10월 8일에 씀")
    }

    func test_GH61_TC7_봉인한날완료하면_오늘의내가로보인다() {
        // Given
        let wish = sealedWish(isSuccess: true, finishDate: calendar.startOfDay(for: day(8)))

        // When
        let viewModel = makeFinishNote(wish)

        // Then
        XCTAssertEqual(viewModel.state.openedLetter?.headline, "오늘의 내가\n편지를 보냈어요")
    }

    // MARK: GH-61 TC8

    func test_GH61_TC8_편지없는위시를완료하면_소감시트가기존과같다() {
        // Given
        let wish = Wish(id: "wish-1", title: "위시", isSuccess: true)

        // When
        let viewModel = makeFinishNote(wish)
        viewModel.send(.onAppear)

        // Then
        XCTAssertNil(viewModel.state.openedLetter)
        XCTAssertEqual(logManager.sentEvents.count, 1)
    }

    // MARK: GH-61 TC9

    func test_GH61_TC9_위젯에서완료한위시를상세로열면_편지가열린상태다() {
        // Given: 위젯 완료 = 저장소에 isSuccess 로 저장된 위시
        let wish = sealedWish(isSuccess: true, finishDate: day(20))

        // When
        let detail = makeDetail(wish)

        // Then
        XCTAssertEqual(detail.letter?.state.letter, .opened(body: "왜 이걸 하고 싶었는지 잊지 마.", writtenAt: "10월 8일에 씀"))
        XCTAssertTrue(detail.state.sections.contains(.letter))
    }

    func test_GH61_TC9_편지없는이룬위시는_섹션을그리지않는다() {
        // Given / When
        let detail = makeDetail(Wish(id: "wish-1", title: "위시", isSuccess: true))

        // Then
        XCTAssertFalse(detail.state.sections.contains(.letter))
    }

    // MARK: GH-61 TC10

    func test_GH61_TC10_완료를취소하면_다시봉인상태가된다() {
        // Given
        let section = makeSection(sealedWish(isSuccess: true, finishDate: day(20)))

        // When
        section.send(.reload(sealedWish(isSuccess: false)))

        // Then
        XCTAssertEqual(section.state.letter, .sealed(caption: "10월 8일에 봉인했어요 · 18자"))
    }

    // MARK: GH-61 R-7 (편지 지우기)

    func test_GH61_R7_편지가있으면_더보기메뉴에편지지우기가있고_확인하면지운다() {
        // Given
        let detail = makeDetail(sealedWish())

        // When
        detail.send(.tapMore)
        let items: [DetailMoreMenu.Item]
        if case .moreMenu(let menu) = detail.route { items = menu } else { items = [] }
        detail.send(.selectMoreItem(.deleteLetter))
        let letterRoute = detail.letter?.route
        detail.letter?.send(.confirmDelete)

        // Then
        XCTAssertTrue(items.contains(.deleteLetter))
        XCTAssertEqual(letterRoute, .deleteAlert)
        XCTAssertEqual(repository.deleteFutureLetterCalledIds, ["wish-1"])
        XCTAssertEqual(detail.letter?.state.letter, .empty)
        XCTAssertEqual(detail.state.wish?.futureLetter, "")
    }

    // MARK: GH-61 TC12

    func test_GH61_TC12_쓰기나다시쓰기를누르면_write_future_letter클릭로그가한번전송된다() {
        // Given
        let empty = makeSection(Wish(id: "wish-1", title: "위시"))
        let sealed = makeSection(sealedWish(id: "wish-2"))

        // When
        empty.send(.tapWrite)
        sealed.send(.tapRewrite)

        // Then
        let events = clickEvents(objectId: .writeFutureLetter)
        XCTAssertEqual(events.count, 2)
        XCTAssertTrue(events.allSatisfy { $0.screen == .wishDetail })
    }

    // MARK: GH-61 TC13

    func test_GH61_TC13_봉인하기를누르면_seal_future_letter클릭로그가한번전송된다() {
        // Given
        let sheet = FutureLetterViewModel(dependency: .init(logManager: logManager))
        sheet.send(.inputLetter("편지"))

        // When
        sheet.send(.tapSeal)

        // Then
        let events = clickEvents(objectId: .sealFutureLetter)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .futureLetterBottomSheet)
    }

    // MARK: GH-61 TC14

    func test_GH61_TC14_완료순간편지가열리면_future_letter노출로그가한번전송된다() {
        // Given
        let viewModel = makeFinishNote(sealedWish(isSuccess: true, finishDate: day(31)))

        // When
        viewModel.send(.onAppear)

        // Then
        let impressions = logManager.sentEvents.filter {
            $0.name == .impression && ($0.extraParameters?[.objectId] as? LogObjectId) == .futureLetter
        }
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.screen, .finishNoteBottomSheet)
        XCTAssertEqual(impressions.first?.extraParameters?[.objectType] as? LogObjectType, .card)
    }
}
