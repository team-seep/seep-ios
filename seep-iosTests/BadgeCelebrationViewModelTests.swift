import XCTest
import Combine

@testable import seep_ios_dev

final class BadgeCelebrationViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    private func makeViewModel(
        badgeTypes: [BadgeType],
        logManager: MockLogManager
    ) -> BadgeCelebrationViewModel {
        let badges = badgeTypes.map { Badge(type: $0, earnedDate: Date(), finishedCount: 1) }
        return BadgeCelebrationViewModel(
            config: .init(badges: badges, finishedCount: 1),
            dependency: .init(logManager: logManager)
        )
    }

    // MARK: GH-35 TC11

    func test_GH35_TC11_배지모아보기를탭하면_모아보기이동이벤트가나온다() {
        // Given
        let viewModel = makeViewModel(badgeTypes: [.finish1], logManager: MockLogManager())
        var tapCount = 0
        viewModel.output.didTapViewBadges
            .sink { tapCount += 1 }
            .store(in: &cancellables)

        // When
        viewModel.input.didTapViewBadges.send(())

        // Then
        XCTAssertEqual(tapCount, 1)
    }

    func test_GH35_TC11_좋아요를탭하면_시트를닫는다() {
        // Given
        let viewModel = makeViewModel(badgeTypes: [.finish1], logManager: MockLogManager())
        var isDismissed = false
        viewModel.output.route
            .sink { route in
                if case .dismiss = route { isDismissed = true }
            }
            .store(in: &cancellables)

        // When
        viewModel.input.didTapConfirm.send(())

        // Then
        XCTAssertTrue(isDismissed)
    }

    // MARK: GH-35 TC13

    func test_GH35_TC13_축하시트가뜨면_new_badge노출로그가배지id를쉼표로묶어1건전송된다() {
        // Given
        let logManager = MockLogManager()
        let viewModel = makeViewModel(badgeTypes: [.finish1, .firstWantToDo], logManager: logManager)

        // When
        viewModel.input.viewDidLoad.send(())

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
        XCTAssertEqual(event?.name, .impression)
        XCTAssertEqual(event?.parameters[ParameterName.screen.rawValue] as? String, "badge_bottom_sheet")
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "card")
        XCTAssertEqual(event?.parameters[ParameterName.objectId.rawValue] as? String, "new_badge")
        XCTAssertEqual(event?.parameters[ParameterName.badgeId.rawValue] as? String, "finish_1,first_want_to_do")
    }

    // MARK: GH-35 TC14

    func test_GH35_TC14_배지모아보기를탭하면_view_badges클릭로그가1건전송된다() {
        // Given
        let logManager = MockLogManager()
        let viewModel = makeViewModel(badgeTypes: [.finish1], logManager: logManager)

        // When
        viewModel.input.didTapViewBadges.send(())

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.parameters[ParameterName.screen.rawValue] as? String, "badge_bottom_sheet")
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(event?.parameters[ParameterName.objectId.rawValue] as? String, "view_badges")
    }
}
