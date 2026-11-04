import XCTest

@testable import seep_ios

/// "미래의 나에게" 편지 — 상세 섹션·문서 블록·편지 시트·완료 소감 시트 (GH-61)
final class FutureLetterFeatureTests: WishFormFeatureTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func day(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: 9))!
    }

    private func makeDetail(_ wish: Wish) -> WishDetailViewModel {
        wishRepository.fetchWishResult = [wish]
        return WishDetailViewModel(
            config: .init(wishId: wish.id, mode: wish.isSuccess ? .fromFinish : .fromHome),
            dependency: .init(wishRepository: wishRepository, logManager: logManager, photoStorage: photoStorage)
        )
    }

    private func makeFinishNote(_ wish: Wish) -> FinishNoteViewModel {
        FinishNoteViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: wishRepository, logManager: logManager, now: { [day] in day(31) }, calendar: calendar)
        )
    }

    /// 문서에 떠 있는 편지 시트
    private func letterSheet(_ form: WishFormViewModel) -> FutureLetterViewModel? {
        if case .letter(let sheet) = form.state.sheet { return sheet }
        return nil
    }

    private func seal(_ text: String, in form: WishFormViewModel) {
        let sheet = letterSheet(form)
        sheet?.send(.inputLetter(text))
        sheet?.send(.tapSeal)
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

    func test_GH61_TC1_편지없는미완료위시는_상세에편지섹션이없고_수정문서칩에있다() {
        // Given
        let wish = Wish(id: "wish-1", title: "한라산 백록담 올라가기")

        // When
        let detail = makeDetail(wish)
        let form = makeEdit(wish)

        // Then
        XCTAssertFalse(detail.state.sections.contains(.letter))
        XCTAssertEqual(detail.state.letter, .hidden)
        XCTAssertEqual(form.chips.last, .letter)
        XCTAssertFalse(form.visibleBlocks.contains(.letter))
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

    func test_GH61_TC4_문서에서봉인하고저장하면_편지와저장시각이봉인일로저장된다() {
        // Given
        let form = makeWrite(category: .wantToDo)
        form.send(.tapChip(.letter))

        // When
        seal("  왜 이걸 하고 싶었는지 잊지 마.  ", in: form)
        let caption = form.letterCaption
        form.send(.tapSave)

        // Then
        XCTAssertNil(form.state.sheet)
        XCTAssertEqual(form.visibleBlocks.last, .letter)
        XCTAssertEqual(caption, "\(DisplayDate.monthDay(now))에 봉인했어요 · 18자")
        XCTAssertEqual(wishRepository.addedWishes.first?.futureLetter, "왜 이걸 하고 싶었는지 잊지 마.")
        XCTAssertEqual(wishRepository.addedWishes.first?.futureLetterSealedAt, now)
    }

    func test_GH61_TC4_봉인한위시의상세는_봉인상태로보인다() {
        // Given / When
        let detail = makeDetail(sealedWish())

        // Then
        XCTAssertEqual(detail.state.sections.last, .letter)
        XCTAssertEqual(detail.state.letter, .sealed(caption: "10월 8일에 봉인했어요 · 18자"))
    }

    // MARK: GH-61 TC5

    func test_GH61_TC5_봉인된미완료위시는_본문이상세와문서어디에도없다() {
        // Given / When
        let letter = DetailLetter(wish: sealedWish())
        let form = makeEdit(sealedWish())

        // Then
        guard case .sealed(let caption) = letter else { return XCTFail("봉인 상태가 아니다") }
        XCTAssertFalse(caption.contains("잊지 마"))
        XCTAssertFalse(form.letterCaption?.contains("잊지 마") ?? true)
    }

    // MARK: GH-61 TC6

    func test_GH61_TC6_봉인카드를누르면_확인뒤빈칸에서다시쓰고_새내용과새봉인일로저장된다() {
        // Given
        let form = makeEdit(sealedWish())

        // When
        form.send(.tapLetter)
        let routeBeforeConfirm = form.route
        form.send(.routeHandled)
        form.send(.confirmRewriteLetter)
        let startText = letterSheet(form)?.state.letterText
        seal("새 편지", in: form)
        form.send(.tapSave)

        // Then
        XCTAssertEqual(routeBeforeConfirm, .rewriteLetterAlert)
        XCTAssertEqual(startText, "")
        XCTAssertEqual(wishRepository.updatedWishes.first?.futureLetter, "새 편지")
        XCTAssertEqual(wishRepository.updatedWishes.first?.futureLetterSealedAt, now)
    }

    func test_GH61_TC6_다시쓰지않고저장하면_봉인일이그대로다() {
        // Given
        let form = makeEdit(sealedWish())

        // When
        form.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.updatedWishes.first?.futureLetterSealedAt, day(8))
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
        XCTAssertEqual(detail.state.letter, .opened(body: "왜 이걸 하고 싶었는지 잊지 마.", writtenAt: "10월 8일에 씀"))
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
        let opened = DetailLetter(wish: sealedWish(isSuccess: true, finishDate: day(20)))

        // When
        let restored = DetailLetter(wish: sealedWish(isSuccess: false))

        // Then
        XCTAssertEqual(opened, .opened(body: "왜 이걸 하고 싶었는지 잊지 마.", writtenAt: "10월 8일에 씀"))
        XCTAssertEqual(restored, .sealed(caption: "10월 8일에 봉인했어요 · 18자"))
    }

    // MARK: GH-61 TC12

    func test_GH61_TC12_미래의나에게칩을누르면_add_block클릭로그가한번전송된다() {
        // Given
        let form = makeWrite(category: .wantToDo)

        // When
        form.send(.tapChip(.letter))

        // Then
        let events = clickEvents(objectId: .addBlock)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.extraParameters?[.block] as? String, "future_letter")
        XCTAssertNotNil(letterSheet(form))
    }

    // MARK: GH-61 TC22

    func test_GH61_TC22_수정문서에서편지를지우고완료하면_편지없음으로저장된다() {
        // Given
        let form = makeEdit(sealedWish())

        // When
        form.send(.removeBlock(.letter))
        form.send(.tapSave)

        // Then
        XCTAssertEqual(form.chips.last, .letter)
        XCTAssertEqual(wishRepository.updatedWishes.first?.futureLetter, "")
        XCTAssertNil(wishRepository.updatedWishes.first?.futureLetterSealedAt)
    }

    // MARK: GH-61 TC24

    func test_GH61_TC24_홈에서연상세의더보기메뉴에는_사진편지지우기가없다() {
        // Given
        var wish = sealedWish()
        wish.photoFileName = "wish-1-a.jpg"
        photoStorage.existingFileNames = ["wish-1-a.jpg"]
        let detail = makeDetail(wish)

        // When
        detail.send(.tapMore)

        // Then
        guard case .moreMenu(let items) = detail.route else { return XCTFail("메뉴가 열리지 않았다") }
        XCTAssertFalse(items.contains(.deletePhoto))
        XCTAssertEqual(items, [.share, .delete])
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
