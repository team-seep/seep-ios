import XCTest

@testable import seep_ios

/// 완료 소감 시트의 기대 비교 세 칸 (GH-139 R-2 ~ R-4, TC-2 ~ TC-5, TC-11)
final class FinishFeelingFeatureTests: ViewModelTestCase {
    private var repository: MockWishRepository!
    private let wish = Wish(id: "ramen", emoji: "🍜", title: "삿포로 라멘 투어", isSuccess: true)

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    private func makeViewModel(_ wish: Wish? = nil) -> FinishNoteViewModel {
        FinishNoteViewModel(config: .init(wish: wish ?? self.wish), dependency: .init(wishRepository: repository, logManager: logManager))
    }

    private func clicks(objectId: LogObjectId) -> [any LogEventType] {
        logManager.sentEvents.filter {
            $0.name == .click && $0.parameters[ParameterName.objectId.rawValue] as? String == objectId.rawValue
        }
    }

    // MARK: GH-139 TC2

    func test_GH139_TC2_기대보다좋았어요만고르고저장하면_better와빈소감으로저장되고_시트가닫힌다() {
        // Given
        let viewModel = makeViewModel()
        var savedWishes: [Wish] = []
        viewModel.onSave = { savedWishes.append($0) }

        // When
        viewModel.send(.selectFeeling(.better))

        // Then: 칸만 골라도 저장이 켜진다 (R-3)
        XCTAssertEqual(viewModel.state.selectedFeeling, .better)
        XCTAssertTrue(viewModel.state.isSaveEnabled)

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(repository.updateFinishNoteCalls.count, 1)
        XCTAssertEqual(repository.updateFinishNoteCalls.first?.wishId, "ramen")
        XCTAssertEqual(repository.updateFinishNoteCalls.first?.note, "")
        XCTAssertEqual(repository.updateFinishNoteCalls.first?.feeling, .better)
        XCTAssertEqual(savedWishes.map(\.finishFeeling), [.better])
        XCTAssertEqual(viewModel.route, .dismiss)
    }

    func test_GH139_TC2_칸과소감을함께저장하면_둘다한번에저장된다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.send(.selectFeeling(.same))
        viewModel.send(.inputNote("  국물 한 숟갈에 피로가 다 풀렸다 "))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(repository.updateFinishNoteCalls.count, 1)
        XCTAssertEqual(repository.updateFinishNoteCalls.first?.note, "국물 한 숟갈에 피로가 다 풀렸다")
        XCTAssertEqual(repository.updateFinishNoteCalls.first?.feeling, .same)
    }

    func test_GH139_TC2_소감만쓰면_지금처럼저장되고기대비교는없다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.send(.inputNote("최고!"))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(repository.updateFinishNoteCalls.first?.note, "최고!")
        XCTAssertNil(repository.updateFinishNoteCalls.first?.feeling ?? nil)
    }

    // MARK: GH-139 TC3

    func test_GH139_TC3_고른칸을다시누르면_선택이풀리고_소감도없으면저장이꺼진다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.send(.selectFeeling(.worse))

        // When
        viewModel.send(.selectFeeling(.worse))
        viewModel.send(.tapSave)

        // Then
        XCTAssertNil(viewModel.state.selectedFeeling)
        XCTAssertFalse(viewModel.state.isSaveEnabled)
        XCTAssertTrue(repository.updateFinishNoteCalls.isEmpty)
    }

    func test_GH139_TC3_다른칸을누르면_하나만선택된다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.send(.selectFeeling(.worse))

        // When
        viewModel.send(.selectFeeling(.better))

        // Then
        XCTAssertEqual(viewModel.state.selectedFeeling, .better)
    }

    func test_GH139_TC3_칸을풀어도소감이있으면_저장이켜져있다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.send(.inputNote("좋았다"))
        viewModel.send(.selectFeeling(.same))

        // When
        viewModel.send(.selectFeeling(.same))

        // Then
        XCTAssertTrue(viewModel.state.isSaveEnabled)
    }

    func test_GH139_R3_칸만고르고입력칸에서Return을누르면_저장하지않고시트를유지한다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.send(.selectFeeling(.better))

        // When
        viewModel.send(.submitNote)

        // Then
        XCTAssertTrue(repository.updateFinishNoteCalls.isEmpty)
        XCTAssertNil(viewModel.route)
    }

    func test_GH139_R3_소감을쓰고Return을누르면_고른칸과함께저장한다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.send(.selectFeeling(.better))
        viewModel.send(.inputNote("최고"))

        // When
        viewModel.send(.submitNote)

        // Then
        XCTAssertEqual(repository.updateFinishNoteCalls.map(\.feeling), [.better])
        XCTAssertEqual(viewModel.route, .dismiss)
    }

    // MARK: GH-139 TC4

    func test_GH139_TC4_칸과소감을입력하고_다음에할게요를누르면_아무것도저장하지않는다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.send(.selectFeeling(.better))
        viewModel.send(.inputNote("최고"))

        // When
        viewModel.send(.tapSkip)

        // Then
        XCTAssertTrue(repository.updateFinishNoteCalls.isEmpty)
        XCTAssertEqual(viewModel.route, .dismiss)
    }

    // MARK: GH-139 TC5

    func test_GH139_TC5_칸을고르고이어서적기를누르면_고른값을저장한뒤_이어적기로간다() {
        // Given
        let viewModel = makeViewModel()
        var chained: [Wish] = []
        viewModel.onChainNext = { chained.append($0) }
        viewModel.send(.selectFeeling(.better))

        // When
        viewModel.send(.tapChainNext)

        // Then
        XCTAssertEqual(repository.updateFinishNoteCalls.map(\.feeling), [.better])
        XCTAssertEqual(repository.updateFinishNoteCalls.map(\.note), [""])
        XCTAssertEqual(chained.map(\.finishFeeling), [.better])
        XCTAssertEqual(viewModel.route, .dismiss)
    }

    func test_GH139_TC5_기대비교저장에실패하면_이어적지않고에러를띄운다() {
        // Given
        repository.updateFinishNoteResult = .failure(.writeFailed)
        let viewModel = makeViewModel()
        var chained: [Wish] = []
        viewModel.onChainNext = { chained.append($0) }
        viewModel.send(.selectFeeling(.worse))

        // When
        viewModel.send(.tapChainNext)

        // Then
        XCTAssertTrue(chained.isEmpty)
        guard case .errorAlert = viewModel.route else { return XCTFail("에러 알럿을 띄워야 한다") }
    }

    // MARK: GH-139 R-4

    func test_GH139_R4_편지가열린시트에서도_칸을골라저장할수있다() {
        // Given: 편지를 봉인해 둔 위시
        let sealed = Wish(
            id: "letter", title: "한라산", finishDate: Date(), isSuccess: true,
            futureLetter: "잊지 마", futureLetterSealedAt: Date().addingTimeInterval(-86_400)
        )
        let viewModel = makeViewModel(sealed)
        XCTAssertNotNil(viewModel.state.openedLetter)

        // When
        viewModel.send(.selectFeeling(.better))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(repository.updateFinishNoteCalls.map(\.feeling), [.better])
    }

    // MARK: GH-139 TC11

    func test_GH139_TC11_칸을고르면_select_expectation클릭이고른값과함께1건간다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.selectFeeling(.better))

        // Then
        let events = clicks(objectId: .selectExpectation)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .finishNoteBottomSheet)
        XCTAssertEqual(events.first?.parameters[ParameterName.screen.rawValue] as? String, "finish_note_bottom_sheet")
        XCTAssertEqual(events.first?.parameters[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(events.first?.parameters[ParameterName.objectId.rawValue] as? String, "select_expectation")
        XCTAssertEqual(events.first?.parameters[ParameterName.expectation.rawValue] as? String, "better")
    }

    func test_GH139_TC11_고른칸을다시눌러풀면_클릭을더보내지않는다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.send(.selectFeeling(.same))

        // When
        viewModel.send(.selectFeeling(.same))

        // Then
        XCTAssertEqual(clicks(objectId: .selectExpectation).count, 1)
    }
}
