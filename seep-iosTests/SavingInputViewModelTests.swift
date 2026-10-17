import XCTest
import Combine

@testable import seep_ios_dev

/// "모은 돈 기록" 바텀시트 (GH-16 R-4).
final class SavingInputViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    private func makeViewModel(targetAmount: Int = 769_000, savedAmount: Int = 461_400) -> SavingInputViewModel {
        return SavingInputViewModel(config: .init(targetAmount: targetAmount, savedAmount: savedAmount))
    }

    // MARK: GH-16 TC5

    func test_GH16_TC5_금액이0이면_기록하기버튼이비활성이고_눌러도저장되지않는다() {
        // Given
        let viewModel = makeViewModel()
        var saved: [Int] = []
        viewModel.output.didSave
            .sink { saved.append($0) }
            .store(in: &cancellables)

        // When
        viewModel.input.inputAmountText.send("0")
        viewModel.input.didTapSave.send(())

        // Then
        XCTAssertFalse(viewModel.output.isSaveEnabled.value)
        XCTAssertTrue(saved.isEmpty)
        XCTAssertEqual(viewModel.output.amountText.value, "")
    }

    func test_GH16_TC5_남은금액전부를누르면_남은금액이입력된다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.input.didTapQuickAmount.send(.remainingAll)

        // Then
        XCTAssertEqual(viewModel.output.amountText.value, "307,600")
        XCTAssertTrue(viewModel.output.isSaveEnabled.value)
        XCTAssertEqual(viewModel.output.preview.value?.percent, 100)
    }

    func test_GH16_TC5_금액을입력하고_기록하기를누르면_금액을넘기고_시트를닫는다() {
        // Given
        let viewModel = makeViewModel()
        var saved: [Int] = []
        var dismissCount = 0
        viewModel.output.didSave
            .sink { saved.append($0) }
            .store(in: &cancellables)
        viewModel.output.route
            .sink { route in
                if case .dismiss = route { dismissCount += 1 }
            }
            .store(in: &cancellables)

        // When
        viewModel.input.inputAmountText.send("50000")
        viewModel.input.didTapSave.send(())

        // Then
        XCTAssertEqual(saved, [50_000])
        XCTAssertEqual(dismissCount, 1)
    }

    // MARK: GH-16 TC14

    func test_GH16_TC14_입력1만원에서_5만을누르면_6만원이되고_미리보기가갱신된다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.input.inputAmountText.send("10,000")

        // When
        viewModel.input.didTapQuickAmount.send(.plus(50_000))

        // Then
        XCTAssertEqual(viewModel.output.amountText.value, "60,000")
        let preview = viewModel.output.preview.value
        XCTAssertEqual(preview?.savedAmount, 521_400)
        XCTAssertEqual(preview?.targetAmount, 769_000)
        XCTAssertEqual(preview?.percent, 68)
    }

    func test_GH16_TC14_빠른버튼은_상한999999999를넘지않는다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.input.inputAmountText.send("999,950,000")

        // When
        viewModel.input.didTapQuickAmount.send(.plus(100_000))

        // Then
        XCTAssertEqual(viewModel.output.amountText.value, "999,999,999")
    }
}
