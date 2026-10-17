import XCTest
import Combine

@testable import seep_ios_dev

/// 상세 "모으기" 섹션 (GH-16 R-3·R-5·R-6·R-7).
final class WishSavingsViewModelTests: XCTestCase {
    private var mockRepository: MockWishRepository!
    private var mockLogManager: MockLogManager!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        mockLogManager = MockLogManager()
        cancellables = []
    }

    override func tearDown() {
        mockRepository = nil
        mockLogManager = nil
        cancellables = nil
        super.tearDown()
    }

    private func makeWish(
        category: seep_ios_dev.Category = .wantToGet,
        targetAmount: Int,
        savings: [WishSaving] = []
    ) -> Wish {
        return Wish(
            id: "wish-1",
            emoji: "🎧",
            category: category,
            title: "에어팟 맥스",
            targetAmount: targetAmount,
            savings: savings
        )
    }

    private func makeViewModel(wish: Wish) -> WishSavingsViewModel {
        return WishSavingsViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: mockRepository, logManager: mockLogManager)
        )
    }

    private func saving(_ id: String, _ amount: Int, daysAgo: Int) -> WishSaving {
        return WishSaving(id: id, amount: amount, createdAt: Date(timeIntervalSince1970: 1_800_000_000 - Double(daysAgo) * 86_400))
    }

    private func collectToasts(_ viewModel: WishSavingsViewModel) -> () -> [String] {
        var toasts: [String] = []
        viewModel.output.toast
            .sink { toasts.append($0) }
            .store(in: &cancellables)
        return { toasts }
    }

    private func clickEvents(objectId: LogObjectId) -> [ClickEvent] {
        return mockLogManager.sentEvents
            .compactMap { $0 as? ClickEvent }
            .filter { ($0.extraParameters?[.objectId] as? LogObjectId) == objectId }
    }

    // MARK: GH-16 TC3

    func test_GH16_TC3_목표금액이있는위시에_5만원을기록하면_금액퍼센트가갱신되고_목록맨위에추가된다() {
        // Given
        let old = saving("s-1", 300_000, daysAgo: 20)
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 769_000, savings: [old]))
        let new = saving("s-2", 50_000, daysAgo: 0)
        mockRepository.addSavingResult = .success([new, old])

        // When
        viewModel.input.saveAmount.send(50_000)

        // Then
        XCTAssertEqual(mockRepository.addSavingCalls.map(\.amount), [50_000])
        XCTAssertEqual(mockRepository.addSavingCalls.map(\.wishId), ["wish-1"])
        let progress = viewModel.output.progress.value
        XCTAssertEqual(progress?.savedAmount, 350_000)
        XCTAssertEqual(progress?.remainingAmount, 419_000)
        XCTAssertEqual(progress?.percent, 46)
        XCTAssertEqual(viewModel.output.savings.value.first?.id, "s-2")
        XCTAssertTrue(viewModel.output.isVisible.value)
    }

    // MARK: GH-16 TC4

    func test_GH16_TC4_목표금액이없는위시는_모으기섹션이보이지않는다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 0))

        // Then
        XCTAssertFalse(viewModel.output.isVisible.value)
        XCTAssertNil(viewModel.output.progress.value)
    }

    func test_GH16_TC4_갖고싶어요가아닌위시는_목표금액이있어도_모으기섹션이보이지않는다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(category: .wantToDo, targetAmount: 769_000))

        // Then
        XCTAssertFalse(viewModel.output.isVisible.value)
    }

    // MARK: GH-16 TC6

    func test_GH16_TC6_남은금액3만원에서_5만원을기록하면_토스트1번_진행도100_위시는완료되지않는다() {
        // Given
        let old = saving("s-1", 70_000, daysAgo: 3)
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 100_000, savings: [old]))
        let toasts = collectToasts(viewModel)
        let new = saving("s-2", 50_000, daysAgo: 0)
        mockRepository.addSavingResult = .success([new, old])

        // When
        viewModel.input.saveAmount.send(50_000)

        // Then
        XCTAssertEqual(toasts(), [Strings.Detail.Saving.Toast.completed])
        let progress = viewModel.output.progress.value
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
        let toasts = collectToasts(viewModel)
        mockRepository.addSavingResult = .success([saving("s-2", 10_000, daysAgo: 0), old])

        // When
        viewModel.input.saveAmount.send(10_000)

        // Then
        XCTAssertTrue(toasts().isEmpty)
        XCTAssertEqual(viewModel.output.progress.value?.percent, 100)
    }

    // MARK: GH-16 TC7

    func test_GH16_TC7_기록3건중1건을삭제하면_모은금액이줄고_목표미만이면_다시남은금액문구로돌아간다() {
        // Given
        let savings = [
            saving("s-3", 50_000, daysAgo: 0),
            saving("s-2", 30_000, daysAgo: 1),
            saving("s-1", 20_000, daysAgo: 2)
        ]
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 100_000, savings: savings))
        XCTAssertEqual(viewModel.output.progress.value?.isCompleted, true)
        mockRepository.deleteSavingResult = .success([savings[1], savings[2]])

        // When
        viewModel.input.confirmDelete.send("s-3")

        // Then
        XCTAssertEqual(mockRepository.deleteSavingCalls.map(\.savingId), ["s-3"])
        let progress = viewModel.output.progress.value
        XCTAssertEqual(progress?.savedAmount, 50_000)
        XCTAssertEqual(progress?.isCompleted, false)
        XCTAssertEqual(progress?.remainingAmount, 50_000)
        XCTAssertEqual(viewModel.output.savings.value.map(\.id), ["s-2", "s-1"])
    }

    func test_GH16_TC7_기록의X를누르면_바로지우지않고_확인알럿을띄운다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 100_000, savings: [saving("s-1", 10_000, daysAgo: 0)]))
        var routes: [WishSavingsViewModel.Route] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)

        // When
        viewModel.input.didTapDelete.send("s-1")

        // Then
        guard case .showDeleteAlert(let savingId) = routes.first else {
            return XCTFail("확인 알럿 route 가 와야 한다")
        }
        XCTAssertEqual(savingId, "s-1")
        XCTAssertTrue(mockRepository.deleteSavingCalls.isEmpty)
    }

    // MARK: GH-16 TC9

    func test_GH16_TC9_모은돈기록을누르면_add_saving로그1건_기록하면_save_saving로그1건이_금액없이전송된다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 769_000))
        var sheetViewModel: SavingInputViewModel?
        viewModel.output.route
            .sink { route in
                if case .presentSavingInput(let presented) = route {
                    sheetViewModel = presented
                }
            }
            .store(in: &cancellables)
        mockRepository.addSavingResult = .success([saving("s-1", 50_000, daysAgo: 0)])

        // When
        viewModel.input.didTapAdd.send(())
        sheetViewModel?.input.didTapQuickAmount.send(.plus(50_000))
        sheetViewModel?.input.didTapSave.send(())

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
        var routes: [WishSavingsViewModel.Route] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)
        mockRepository.addSavingResult = .failure(.writeFailed)

        // When
        viewModel.input.saveAmount.send(10_000)

        // Then
        XCTAssertTrue(clickEvents(objectId: .saveSaving).isEmpty)
        guard case .showErrorAlert = routes.first else {
            return XCTFail("에러 알럿 route 가 와야 한다")
        }
    }

    // MARK: GH-16 TC12

    func test_GH16_TC12_수정화면에서목표금액을지우고돌아오면_기록은남고_섹션이숨겨진다() {
        // Given
        let savings = [saving("s-2", 50_000, daysAgo: 0), saving("s-1", 30_000, daysAgo: 1)]
        let viewModel = makeViewModel(wish: makeWish(targetAmount: 769_000, savings: savings))
        XCTAssertTrue(viewModel.output.isVisible.value)

        // When
        viewModel.input.reloadWish.send(makeWish(targetAmount: 0, savings: savings))

        // Then
        XCTAssertFalse(viewModel.output.isVisible.value)
        XCTAssertEqual(viewModel.output.savings.value.count, 2)
    }
}
