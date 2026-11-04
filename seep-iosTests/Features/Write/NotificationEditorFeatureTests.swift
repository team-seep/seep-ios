import XCTest

@testable import seep_ios

/// 알림 추가·수정 시트 (GH-64 TC-1301, TC-1303, R-41)
final class NotificationEditorFeatureTests: ViewModelTestCase {
    // MARK: GH-64 TC1301

    func test_GH64_TC1301_알림날짜를고르면_그종류로저장된다() {
        // Given
        let viewModel = NotificationEditorViewModel(config: NotificationEditorConfig(notifications: [SeepNotification()], selectedIndex: nil))
        XCTAssertFalse(viewModel.state.isEditing)

        // When
        viewModel.send(.selectType(.twoDayAgo))
        viewModel.send(.tapSave)

        // Then
        guard case .saved(let notification, let index) = viewModel.route else {
            return XCTFail("저장 Route 가 나와야 한다")
        }
        XCTAssertEqual(notification.type, .twoDayAgo)
        XCTAssertNil(index)
    }

    func test_GH64_TC1301_고를수있는알림날짜는_당일_1일전_2일전_일주일전_매일이다() {
        // Given / When / Then
        XCTAssertEqual(NotificationEditorViewModel.types, [.targetDay, .dayAgo, .twoDayAgo, .weekAgo, .everyDay])
    }

    func test_GH64_TC1301_하나뿐인첫알림은_지울수없고_두번째부터는지울수있다() {
        // Given
        let single = NotificationEditorViewModel(config: NotificationEditorConfig(notifications: [SeepNotification()], selectedIndex: 0))
        let notifications = [SeepNotification(type: .targetDay), SeepNotification(type: .dayAgo)]
        let second = NotificationEditorViewModel(config: NotificationEditorConfig(notifications: notifications, selectedIndex: 1))

        // When
        single.send(.tapDelete)
        second.send(.tapDelete)

        // Then
        XCTAssertFalse(single.state.isDeletable)
        XCTAssertNil(single.route)
        XCTAssertTrue(second.state.isEditing)
        XCTAssertEqual(second.route, .deleted(index: 1))
    }

    // MARK: GH-64 TC1303

    func test_GH64_TC1303_같은종류·시각알림이이미있으면_저장하지않고_안내토스트가뜬다() {
        // Given
        let existing = SeepNotification(type: .dayAgo)
        let viewModel = NotificationEditorViewModel(config: NotificationEditorConfig(notifications: [existing], selectedIndex: nil))

        // When
        viewModel.send(.selectType(.dayAgo))
        viewModel.send(.inputTime(existing.time))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(viewModel.route, .toast(Strings.NotificationEditor.duplicate))
    }
}
