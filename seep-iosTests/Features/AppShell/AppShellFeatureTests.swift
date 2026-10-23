import XCTest

@testable import seep_ios_dev

/// 토스트·앱 잠금 오버레이·시트 높이·이모지 최근 사용·페이지뷰 (GH-64 P0)
final class AppShellFeatureTests: ViewModelTestCase {
    // MARK: GH-64 TC28

    func test_GH64_TC28_화면이다시나타나도_페이지뷰는처음한번만보낸다() {
        // Given
        let tracker = ScreenTracker()

        // When
        tracker.trackIfNeeded(screen: .finished, logManager: logManager)
        tracker.trackIfNeeded(screen: .finished, logManager: logManager)

        // Then
        XCTAssertEqual(logManager.pageViews.count, 1)
        XCTAssertEqual(logManager.pageViews.first?.screen, .finished)
    }

    // MARK: GH-64 TC45

    @MainActor
    func test_GH64_TC45_새토스트는이전것을바꾸고_시간이지나면사라진다() {
        // Given
        let center = ToastCenter()

        // When
        center.show("첫 번째", duration: .milliseconds(300))
        center.show("👏 이룬 싶에 담았어요", duration: .milliseconds(100))

        // Then
        XCTAssertEqual(center.message, "👏 이룬 싶에 담았어요")
        waitUntil(timeout: 1) { center.message == nil }
    }

    @MainActor
    func test_GH64_TC45_바뀐토스트는_이전토스트의시간에사라지지않는다() {
        // Given
        let center = ToastCenter()
        center.show("첫 번째", duration: .milliseconds(50))

        // When
        center.show("두 번째", duration: .seconds(5))
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        // Then
        XCTAssertEqual(center.message, "두 번째")
    }

    // MARK: GH-64 TC46, TC47

    private var now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeLockViewModel(isEnabled: Bool, authentication: MockAuthenticationManager) -> AppLockOverlayViewModel {
        let preference = Preference(name: "test-gh64-app-lock-overlay")
        preference.isAppLockEnabled = isEnabled
        return AppLockOverlayViewModel(dependency: .init(
            preference: preference,
            authenticationManager: authentication,
            logManager: logManager,
            now: { [unowned self] in self.now }
        ))
    }

    func test_GH64_TC46_60초이상백그라운드후돌아오면_잠기고_인증성공하면풀린다() {
        // Given
        let authentication = MockAuthenticationManager()
        authentication.authenticateResult = false
        let viewModel = makeLockViewModel(isEnabled: true, authentication: authentication)
        viewModel.send(.mainDidAppear)
        authentication.authenticateResult = true
        viewModel.send(.tapUnlock)
        XCTAssertEqual(viewModel.state.lockState, .unlocked)
        let unlockCountBefore = clickEvents(objectId: .unlockApp).count

        // When
        viewModel.send(.phaseChanged(.inactive))
        viewModel.send(.phaseChanged(.background))
        now = now.addingTimeInterval(61)
        authentication.authenticateResult = false
        viewModel.send(.phaseChanged(.inactive))
        viewModel.send(.phaseChanged(.active))

        // Then
        XCTAssertEqual(viewModel.state.lockState, .locked)

        // When
        authentication.authenticateResult = true
        viewModel.send(.tapUnlock)

        // Then
        XCTAssertEqual(viewModel.state.lockState, .unlocked)
        XCTAssertEqual(clickEvents(objectId: .unlockApp).count, unlockCountBefore + 1)
    }

    func test_GH64_TC46_60초안에돌아오면_잠기지않는다() {
        // Given
        let authentication = MockAuthenticationManager()
        let viewModel = makeLockViewModel(isEnabled: true, authentication: authentication)
        viewModel.send(.mainDidAppear)

        // When
        viewModel.send(.phaseChanged(.inactive))
        viewModel.send(.phaseChanged(.background))
        now = now.addingTimeInterval(30)
        viewModel.send(.phaseChanged(.inactive))
        viewModel.send(.phaseChanged(.active))

        // Then
        XCTAssertEqual(viewModel.state.lockState, .unlocked)
    }

    func test_GH64_TC46_콜드스타트면_메인이뜰때잠그고_바로인증을묻는다() {
        // Given
        let authentication = MockAuthenticationManager()
        authentication.authenticateResult = false
        let viewModel = makeLockViewModel(isEnabled: true, authentication: authentication)

        // When
        viewModel.send(.mainDidAppear)

        // Then
        XCTAssertEqual(viewModel.state.lockState, .locked)
        XCTAssertEqual(authentication.authenticateCallCount, 1)
        XCTAssertFalse(viewModel.state.unlockButtonTitle.isEmpty)
    }

    func test_GH64_TC46_잠금이꺼져있으면_잠그지도덮지도않는다() {
        // Given
        let viewModel = makeLockViewModel(isEnabled: false, authentication: MockAuthenticationManager())

        // When
        viewModel.send(.mainDidAppear)
        viewModel.send(.phaseChanged(.inactive))
        viewModel.send(.phaseChanged(.background))

        // Then
        XCTAssertEqual(viewModel.state.lockState, .unlocked)
    }

    func test_GH64_TC47_비활성이되면_전환기스냅샷을덮고_돌아오면걷는다() {
        // Given
        let viewModel = makeLockViewModel(isEnabled: true, authentication: MockAuthenticationManager())
        viewModel.send(.mainDidAppear)
        XCTAssertEqual(viewModel.state.lockState, .unlocked)

        // When
        viewModel.send(.phaseChanged(.inactive))

        // Then
        XCTAssertEqual(viewModel.state.lockState, .covered)

        // When
        viewModel.send(.phaseChanged(.active))

        // Then
        XCTAssertEqual(viewModel.state.lockState, .unlocked)
    }

    func test_GH64_TC47_앱이띄운인증창때문에비활성이되면_덮지않는다() {
        // Given
        let authentication = MockAuthenticationManager()
        let viewModel = makeLockViewModel(isEnabled: true, authentication: authentication)
        viewModel.send(.mainDidAppear)
        authentication.isAuthenticating = true

        // When
        viewModel.send(.phaseChanged(.inactive))

        // Then
        XCTAssertEqual(viewModel.state.lockState, .unlocked)
    }

    // MARK: GH-64 TC48

    func test_GH64_TC48_내용높이에_인디케이터영역을더해_올림한높이로시트를띄운다() {
        // Given / When / Then
        XCTAssertEqual(SeepSheetDetent.fitHeight(contentHeight: 320), 340)
        XCTAssertEqual(SeepSheetDetent.fitHeight(contentHeight: 320.2), 341)
    }

    // MARK: GH-64 TC49

    func test_GH64_TC49_새이모지는맨앞에_중복없이_최대16개() {
        // Given
        let suiteName = "test-gh64-emoji-recents"
        UserDefaults().removePersistentDomain(forName: suiteName)
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        let store = EmojiRecentStore(defaults: defaults)
        let emojis = ["😀", "🏄", "📚", "🎹", "🗻", "🍳", "🎧", "🏕️", "🎬", "⚽️", "🎨", "✈️", "🍕", "🐶", "🌸", "🎁"]
        emojis.forEach(store.add)
        XCTAssertEqual(store.recents.count, 16)

        // When
        store.add("🏄")
        store.add("🚀")

        // Then
        XCTAssertEqual(store.recents.first, "🚀")
        XCTAssertEqual(store.recents[1], "🏄")
        XCTAssertEqual(store.recents.filter { $0 == "🏄" }.count, 1)
        XCTAssertEqual(store.recents.count, 16)
        XCTAssertFalse(store.recents.contains("😀"), "가장 오래된 것이 빠진다")
    }
}
