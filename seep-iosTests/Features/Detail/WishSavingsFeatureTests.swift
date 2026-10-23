import XCTest

@testable import seep_ios_dev

/// 상세 "모은 돈" 섹션과 기록 시트 (GH-16 R-3·R-4·R-5·R-6·R-7, GH-64 TC-607)
final class WishSavingsFeatureTests: ViewModelTestCase {
    private var mockRepository: MockWishRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
    }

    override func tearDown() {
        mockRepository = nil
        super.tearDown()
    }

    private func makeWish(
        category: seep_ios_dev.Category = .wantToGet,
        targetAmount: Int,
        savings: [WishSaving] = []
    ) -> Wish {
        Wish(id: "wish-1", emoji: "🎧", category: category, title: "에어팟 맥스", targetAmount: targetAmount, savings: savings)
    }

    private func makeViewModel(wish: Wish) -> WishSavingsViewModel {
        WishSavingsViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: mockRepository, logManager: logManager)
        )
    }

    private func saving(_ id: String, _ amount: Int, daysAgo: Int) -> WishSaving {
        WishSaving(id: id, amount: amount, createdAt: Date(timeIntervalSince1970: 1_800_000_000 - Double(daysAgo) * 86_400))
    }

    // MARK: GH-16 TC3

    func test_GH16_TC3_목표금액이있는위시에_5만원을기록하면_금액퍼센트가갱신되고_목록맨위에추가된다() {
        // Given
        let old = saving("s-1", 300_000, daysAgo: 20)
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 769_000, savings: [old]))
        let new = saving("s-2", 50_000, daysAgo: 0)
        mockRepository.addSavingResult = .success([new, old])
        var updated: [WishSaving]?
        viewModel.onUpdate = { updated = $0 }

        // When
        viewModel.send(.saveAmount(50_000))

        // Then
        XCTAssertEqual(mockRepository.addSavingCalls.map(\.amount), [50_000])
        XCTAssertEqual(mockRepository.addSavingCalls.map(\.wishId), ["wish-1"])
        let progress = viewModel.state.progress
        XCTAssertEqual(progress?.savedAmount, 350_000)
        XCTAssertEqual(progress?.remainingAmount, 419_000)
        XCTAssertEqual(progress?.percent, 46)
        XCTAssertEqual(viewModel.state.savings.first?.id, "s-2")
        XCTAssertTrue(viewModel.state.isVisible)
        XCTAssertEqual(updated?.map(\.id), ["s-2", "s-1"])
    }

    // MARK: GH-16 TC4

    func test_GH16_TC4_목표금액이없는위시는_모으기섹션이보이지않는다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 0))

        // Then
        XCTAssertFalse(viewModel.state.isVisible)
        XCTAssertNil(viewModel.state.progress)
    }

    func test_GH16_TC4_갖고싶어요가아닌위시는_목표금액이있어도_모으기섹션이보이지않는다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(category: .wantToDo, targetAmount: 769_000))

        // Then
        XCTAssertFalse(viewModel.state.isVisible)
    }

    // MARK: GH-16 TC6

    func test_GH16_TC6_남은금액3만원에서_5만원을기록하면_토스트1번_진행도100_위시는완료되지않는다() {
        // Given
        let old = saving("s-1", 70_000, daysAgo: 3)
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 100_000, savings: [old]))
        mockRepository.addSavingResult = .success([saving("s-2", 50_000, daysAgo: 0), old])

        // When
        viewModel.send(.saveAmount(50_000))

        // Then
        XCTAssertEqual(viewModel.route, .toast(Strings.Detail.Saving.Toast.completed))
        let progress = viewModel.state.progress
        XCTAssertEqual(progress?.ratio, 1)
        XCTAssertEqual(progress?.percent, 100)
        XCTAssertEqual(progress?.savedAmount, 120_000)
        XCTAssertEqual(progress?.isCompleted, true)
        XCTAssertTrue(mockRepository.finishWishCalls.isEmpty)
    }

    func test_GH16_TC6_이미다모은상태에서_더기록하면_토스트가다시뜨지않는다() {
        // Given
        let old = saving("s-1", 100_000, daysAgo: 3)
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 100_000, savings: [old]))
        mockRepository.addSavingResult = .success([saving("s-2", 10_000, daysAgo: 0), old])

        // When
        viewModel.send(.saveAmount(10_000))

        // Then
        XCTAssertNil(viewModel.route)
        XCTAssertEqual(viewModel.state.progress?.percent, 100)
    }

    // MARK: GH-16 TC7

    func test_GH16_TC7_기록3건중1건을삭제하면_모은금액이줄고_목표미만이면_다시남은금액문구로돌아간다() {
        // Given
        let savings = [saving("s-3", 50_000, daysAgo: 0), saving("s-2", 30_000, daysAgo: 1), saving("s-1", 20_000, daysAgo: 2)]
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 100_000, savings: savings))
        XCTAssertEqual(viewModel.state.progress?.isCompleted, true)
        mockRepository.deleteSavingResult = .success([savings[1], savings[2]])

        // When
        viewModel.send(.confirmDelete(savingId: "s-3"))

        // Then
        XCTAssertEqual(mockRepository.deleteSavingCalls.map(\.savingId), ["s-3"])
        let progress = viewModel.state.progress
        XCTAssertEqual(progress?.savedAmount, 50_000)
        XCTAssertEqual(progress?.isCompleted, false)
        XCTAssertEqual(progress?.remainingAmount, 50_000)
        XCTAssertEqual(viewModel.state.savings.map(\.id), ["s-2", "s-1"])
    }

    func test_GH16_TC7_기록의X를누르면_바로지우지않고_확인알럿을띄운다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 100_000, savings: [saving("s-1", 10_000, daysAgo: 0)]))

        // When
        viewModel.send(.tapDelete(savingId: "s-1"))

        // Then
        XCTAssertEqual(viewModel.route, .deleteAlert(savingId: "s-1"))
        XCTAssertTrue(mockRepository.deleteSavingCalls.isEmpty)
    }

    // MARK: GH-16 TC9

    func test_GH16_TC9_모은돈기록을누르면_add_saving로그1건_기록하면_save_saving로그1건이_금액없이전송된다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 769_000))
        mockRepository.addSavingResult = .success([saving("s-1", 50_000, daysAgo: 0)])

        // When
        viewModel.send(.tapAdd)
        guard case .savingInput(let sheetViewModel) = viewModel.route else {
            return XCTFail("기록 시트 route 가 와야 한다")
        }
        sheetViewModel.send(.tapQuickAmount(.plus(50_000)))
        sheetViewModel.send(.tapSave)

        // Then
        let addEvents = clickEvents(objectId: .addSaving)
        XCTAssertEqual(addEvents.count, 1)
        XCTAssertEqual(addEvents.first?.screen, .wishDetail)
        XCTAssertEqual(addEvents.first?.extraParameters?[.objectType] as? LogObjectType, .button)
        let saveEvents = clickEvents(objectId: .saveSaving)
        XCTAssertEqual(saveEvents.count, 1)
        XCTAssertEqual(saveEvents.first?.screen, .wishDetail)
        XCTAssertEqual(saveEvents.first?.parameters.keys.sorted(), ["object_id", "object_type", "screen"])
        XCTAssertEqual(mockRepository.addSavingCalls.map(\.amount), [50_000])
    }

    func test_GH16_TC9_저장에실패하면_save_saving로그를보내지않고_에러알럿을띄운다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 769_000))
        mockRepository.addSavingResult = .failure(.writeFailed)

        // When
        viewModel.send(.saveAmount(10_000))

        // Then
        XCTAssertTrue(clickEvents(objectId: .saveSaving).isEmpty)
        guard case .errorAlert = viewModel.route else {
            return XCTFail("에러 알럿 route 가 와야 한다")
        }
    }

    // MARK: GH-16 TC12

    func test_GH16_TC12_수정화면에서목표금액을지우고돌아오면_기록은남고_섹션이숨겨진다() {
        // Given
        let savings = [saving("s-2", 50_000, daysAgo: 0), saving("s-1", 30_000, daysAgo: 1)]
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 769_000, savings: savings))
        XCTAssertTrue(viewModel.state.isVisible)

        // When
        viewModel.send(.reload(makeWish(targetAmount: 0, savings: savings)))

        // Then
        XCTAssertFalse(viewModel.state.isVisible)
        XCTAssertEqual(viewModel.state.savings.count, 2)
    }

    // MARK: GH-16 TC5 · TC14 — 기록 시트

    private func makeInput(targetAmount: Int = 769_000, savedAmount: Int = 461_400) -> SavingInputViewModel {
        SavingInputViewModel(config: .init(targetAmount: targetAmount, savedAmount: savedAmount))
    }

    func test_GH16_TC5_금액이0이면_기록하기버튼이비활성이고_눌러도저장되지않는다() {
        // Given
        let viewModel = makeInput()
        var saved: [Int] = []
        viewModel.onSave = { saved.append($0) }

        // When
        viewModel.send(.inputAmountText("0"))
        viewModel.send(.tapSave)

        // Then
        XCTAssertFalse(viewModel.state.isSaveEnabled)
        XCTAssertTrue(saved.isEmpty)
        XCTAssertEqual(viewModel.state.amountText, "")
    }

    func test_GH16_TC5_남은금액전부를누르면_남은금액이입력된다() {
        // Given
        let viewModel = makeInput()

        // When
        viewModel.send(.tapQuickAmount(.remainingAll))

        // Then
        XCTAssertEqual(viewModel.state.amountText, "307,600")
        XCTAssertTrue(viewModel.state.isSaveEnabled)
        XCTAssertEqual(viewModel.state.preview?.percent, 100)
    }

    func test_GH16_TC5_금액을입력하고_기록하기를누르면_금액을넘기고_시트를닫는다() {
        // Given
        let viewModel = makeInput()
        var saved: [Int] = []
        viewModel.onSave = { saved.append($0) }

        // When
        viewModel.send(.inputAmountText("50000"))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(saved, [50_000])
        XCTAssertEqual(viewModel.route, .dismiss)
    }

    func test_GH16_TC14_입력1만원에서_5만을누르면_6만원이되고_미리보기가갱신된다() {
        // Given
        let viewModel = makeInput()
        viewModel.send(.inputAmountText("10,000"))

        // When
        viewModel.send(.tapQuickAmount(.plus(50_000)))

        // Then
        XCTAssertEqual(viewModel.state.amountText, "60,000")
        let preview = viewModel.state.preview
        XCTAssertEqual(preview?.savedAmount, 521_400)
        XCTAssertEqual(preview?.targetAmount, 769_000)
        XCTAssertEqual(preview?.percent, 68)
    }

    func test_GH16_TC14_빠른버튼은_상한999999999를넘지않는다() {
        // Given
        let viewModel = makeInput()
        viewModel.send(.inputAmountText("999,950,000"))

        // When
        viewModel.send(.tapQuickAmount(.plus(100_000)))

        // Then
        XCTAssertEqual(viewModel.state.amountText, "999,999,999")
    }

    // MARK: GH-64 TC607

    func test_GH64_TC607_기록하면합계와남은금액이늘고_삭제하면줄어_상세위시에반영된다() {
        // Given
        let old = saving("s-1", 10_000, daysAgo: 1)
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 100_000, savings: [old]))
        var updates: [[WishSaving]] = []
        viewModel.onUpdate = { updates.append($0) }
        let new = saving("s-2", 3_000, daysAgo: 0)
        mockRepository.addSavingResult = .success([new, old])
        mockRepository.deleteSavingResult = .success([old])

        // When
        viewModel.send(.saveAmount(3_000))

        // Then
        XCTAssertEqual(viewModel.state.progress?.savedAmount, 13_000)
        XCTAssertEqual(viewModel.state.progress?.remainingAmount, 87_000)

        // When
        viewModel.send(.confirmDelete(savingId: "s-2"))

        // Then
        XCTAssertEqual(viewModel.state.progress?.savedAmount, 10_000)
        XCTAssertEqual(updates.map { $0.map(\.id) }, [["s-2", "s-1"], ["s-1"]])
    }
}
