import XCTest

@testable import seep_ios

/// "누구랑 하고 싶어요?" 시트와 작성·수정 문서 (GH-122 R-1, R-2, R-6, R-11)
final class CompanionSheetFeatureTests: WishFormFeatureTestCase {
    private var finished: [[WishCompanion]] = []

    override func tearDown() {
        finished = []
        super.tearDown()
    }

    private func makeSheet(selected: [WishCompanion] = [], recent: [WishCompanion] = []) -> CompanionSheetViewModel {
        wishRepository.recentCompanionsResult = recent
        let sheet = CompanionSheetViewModel(
            config: .init(selected: selected),
            dependency: .init(wishRepository: wishRepository, logManager: logManager)
        )
        sheet.onFinish = { [unowned self] in finished.append($0) }
        sheet.send(.onAppear)
        return sheet
    }

    private func type(_ name: String, in sheet: CompanionSheetViewModel) {
        sheet.send(.inputName(name))
        sheet.send(.submitName)
    }

    /// 작성 문서에서 시트를 열어 둔 상태
    private func openSheet(in form: WishFormViewModel) throws -> CompanionSheetViewModel {
        form.send(.tapChip(.companion))
        guard case .companion(let sheet) = form.state.sheet else {
            throw XCTSkip("누구랑 시트가 열리지 않았다")
        }
        sheet.send(.onAppear)
        return sheet
    }

    // MARK: TC-1

    func test_GH122_TC1_작성문서시트에서엄마와지은을고르고저장하면_고른순서대로저장된다() throws {
        // Given
        let form = makeWrite(category: .wantToDo)
        form.send(.inputTitle("제주도 한 달 살기"))
        let sheet = try openSheet(in: form)

        // When
        type("엄마", in: sheet)
        type("지은", in: sheet)
        sheet.send(.tapDone)
        form.send(.dismissSheet)
        form.send(.tapSave)

        // Then
        XCTAssertEqual(form.visibleBlocks, [.companion])
        XCTAssertEqual(wishRepository.addedWishes.first?.companions.map(\.name), ["엄마", "지은"])
    }

    func test_GH122_TC1_수정문서는_붙어있던사람을그대로보여주고저장한다() {
        // Given
        let wish = Wish(id: "w", title: "제주", companions: [WishCompanion(personId: "p1", name: "엄마")])
        let form = makeViewModel(mode: .edit(wish))

        // When
        form.send(.tapSave)

        // Then
        XCTAssertTrue(form.visibleBlocks.contains(.companion))
        XCTAssertEqual(wishRepository.updatedWishes.first?.companions, wish.companions)
    }

    // MARK: TC-2

    func test_GH122_TC2_공백을지우고_이미있는이름은다시들어가지않는다() {
        // Given
        let sheet = makeSheet()

        // When
        type("  엄마 ", in: sheet)
        type("엄마", in: sheet)

        // Then
        XCTAssertEqual(sheet.state.selected.map(\.name), ["엄마"])
        XCTAssertEqual(sheet.state.nameInput, "")
    }

    func test_GH122_TC2_이름은20자에서잘린다() {
        // Given
        let sheet = makeSheet()

        // When
        sheet.send(.inputName(String(repeating: "가", count: 25)))

        // Then
        XCTAssertEqual(sheet.state.nameInput.count, WishCompanion.nameMaxLength)
    }

    // MARK: TC-3

    func test_GH122_TC3_빈문자열과공백만은_칩이생기지않는다() {
        // Given
        let sheet = makeSheet()

        // When
        type("", in: sheet)
        type("    ", in: sheet)

        // Then
        XCTAssertTrue(sheet.state.selected.isEmpty)
        XCTAssertNil(sheet.route)
    }

    // MARK: TC-4

    func test_GH122_TC4_5명이고른상태에서_6번째는들어가지않고토스트가뜬다() {
        // Given
        let sheet = makeSheet(recent: [WishCompanion(name: "아빠")])
        for name in ["엄마", "지은", "동생", "민수", "수아"] {
            type(name, in: sheet)
        }

        // When: 직접 입력
        type("대학 동기들", in: sheet)

        // Then
        XCTAssertEqual(sheet.state.selected.count, WishCompanion.maxCount)
        XCTAssertEqual(sheet.route, .toast(Strings.Companion.Sheet.maxCountFormat(WishCompanion.maxCount)))
        XCTAssertEqual(sheet.state.nameInput, "대학 동기들")

        // When: 전에 적은 사람 칩
        sheet.send(.routeHandled)
        sheet.send(.tapRecent(WishCompanion(name: "아빠")))

        // Then
        XCTAssertEqual(sheet.state.selected.count, WishCompanion.maxCount)
        XCTAssertEqual(sheet.route, .toast(Strings.Companion.Sheet.maxCountFormat(WishCompanion.maxCount)))
    }

    func test_GH122_TC4_치다만이름이있어도_칩으로5명을채우면_칸이비고정했어요로닫힌다() {
        // Given: 이름을 치다가 전에 적은 사람 칩으로 5명을 채운다(입력 칸이 사라진다)
        let recent = ["엄마", "지은", "동생", "민수", "수아"].map { WishCompanion(name: $0) }
        let sheet = makeSheet(recent: recent)
        sheet.send(.inputName("친구"))
        recent.forEach { sheet.send(.tapRecent($0)) }

        // Then
        XCTAssertEqual(sheet.state.nameInput, "")

        // When
        sheet.send(.tapDone)

        // Then: 보이지 않는 칸 때문에 막히지 않는다
        XCTAssertEqual(sheet.route, .dismiss)
        XCTAssertEqual(finished.last?.count, WishCompanion.maxCount)
    }

    func test_GH122_TC14_고른사람과이름이같은전에적은사람은_다시보이지않고눌러도두번들어가지않는다() {
        // Given: 이 위시의 "지은"(X)과 전에 적은 사람의 "지은"(대표 Y)이 id 가 다르다
        let sheet = makeSheet(selected: [WishCompanion(personId: "X", name: "지은")], recent: [WishCompanion(personId: "Y", name: "지은"), WishCompanion(name: "엄마")])

        // Then
        XCTAssertEqual(sheet.state.suggested.map(\.name), ["엄마"])

        // When
        sheet.send(.tapRecent(WishCompanion(personId: "Y", name: "지은")))

        // Then
        XCTAssertEqual(sheet.state.selected.map(\.name), ["지은"])
    }

    // MARK: TC-7

    func test_GH122_TC7_사람을넣어연작성화면은_그사람이들어간채로저장된다() {
        // Given
        let mom = WishCompanion(personId: "p-mom", name: "엄마")
        let form = WishFormViewModel(
            config: .init(mode: .add(.wantToDo), companions: [mom]),
            dependency: .init(
                wishRepository: wishRepository,
                notificationManager: notificationManager,
                logManager: logManager,
                userDefaults: userDefaults,
                photoStorage: photoStorage,
                photoTextRecognizer: photoTextRecognizer,
                linkPreviewDelay: nil,
                now: { [unowned self] in self.now }
            )
        )

        // Then
        XCTAssertEqual(form.state.companions, [mom])
        XCTAssertEqual(form.visibleBlocks, [.companion])

        // When
        form.send(.inputTitle("김치찌개 배우기"))
        form.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.first?.companions.map(\.personId), ["p-mom"])
    }

    // MARK: TC-12

    func test_GH122_TC12_정했어요를누르면_고른인원수로companion_save가1건가고이름은없다() {
        // Given
        let sheet = makeSheet()
        type("엄마", in: sheet)
        type("지은", in: sheet)

        // When
        sheet.send(.tapDone)

        // Then
        let events = clickEvents(objectId: .companionSave)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .companionBottomSheet)
        XCTAssertEqual(events.first?.extraParameters?[.count] as? Int, 2)
        let values = events.first?.extraParameters?.values.map { "\($0)" } ?? []
        XCTAssertFalse(values.contains { $0.contains("엄마") || $0.contains("지은") })
        XCTAssertEqual(finished.last?.map(\.name), ["엄마", "지은"])
        XCTAssertEqual(sheet.route, .dismiss)
    }

    // MARK: TC-14

    func test_GH122_TC14_전에적은사람과같은이름을직접적으면_그사람의personId를쓴다() {
        // Given
        let mom = WishCompanion(personId: "p-mom", name: "엄마")
        let sheet = makeSheet(recent: [mom, WishCompanion(personId: "p-jieun", name: "지은")])

        // When
        type(" 엄마 ", in: sheet)

        // Then
        XCTAssertEqual(sheet.state.selected, [mom])
        XCTAssertEqual(sheet.state.suggested.map(\.name), ["지은"])

        // When: 칩으로 고르면 그대로
        sheet.send(.tapRecent(WishCompanion(personId: "p-jieun", name: "지은")))

        // Then
        XCTAssertEqual(sheet.state.selected.map(\.personId), ["p-mom", "p-jieun"])
        XCTAssertTrue(sheet.state.suggested.isEmpty)
    }

    // MARK: TC-18

    func test_GH122_TC18_혼자할래요를누르면_사람이모두빠지고시트가닫힌다() throws {
        // Given
        let wish = Wish(id: "w", title: "제주", companions: [WishCompanion(name: "엄마"), WishCompanion(name: "지은")])
        let form = makeViewModel(mode: .edit(wish))
        form.send(.tapCompanions)
        guard case .companion(let sheet) = form.state.sheet else { return XCTFail("시트가 열리지 않았다") }

        // When
        sheet.send(.tapAlone)
        form.send(.dismissSheet)
        form.send(.tapSave)

        // Then
        XCTAssertEqual(sheet.route, .dismiss)
        XCTAssertTrue(form.state.companions.isEmpty)
        XCTAssertFalse(form.visibleBlocks.contains(.companion))
        XCTAssertEqual(wishRepository.updatedWishes.first?.companions, [])
        XCTAssertTrue(clickEvents(objectId: .companionSave).isEmpty)
    }
}
