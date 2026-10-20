import XCTest

@testable import seep_ios_dev

/// 백그라운드 복귀 시 잠금 판정 (GH-46 R-5, R-9)
final class AppLockPolicyTests: XCTestCase {
    private let backgroundAt = Date(timeIntervalSince1970: 1_800_000_000)

    // MARK: GH-46 TC5

    func test_GH46_TC5_잠금켜짐_백그라운드30초후복귀하면_잠그지않는다() {
        // Given
        let now = backgroundAt.addingTimeInterval(30)

        // When
        let shouldLock = AppLockPolicy.shouldLock(lastBackgroundAt: backgroundAt, now: now, isEnabled: true)

        // Then
        XCTAssertFalse(shouldLock)
    }

    func test_GH46_TC5_잠금켜짐_백그라운드59초후복귀하면_잠그지않는다() {
        // Given
        let now = backgroundAt.addingTimeInterval(59.9)

        // When
        let shouldLock = AppLockPolicy.shouldLock(lastBackgroundAt: backgroundAt, now: now, isEnabled: true)

        // Then
        XCTAssertFalse(shouldLock)
    }

    // MARK: GH-46 TC6

    func test_GH46_TC6_잠금켜짐_백그라운드61초후복귀하면_잠근다() {
        // Given
        let now = backgroundAt.addingTimeInterval(61)

        // When
        let shouldLock = AppLockPolicy.shouldLock(lastBackgroundAt: backgroundAt, now: now, isEnabled: true)

        // Then
        XCTAssertTrue(shouldLock)
    }

    func test_GH46_TC6_잠금켜짐_백그라운드정확히60초면_잠근다() {
        // Given
        let now = backgroundAt.addingTimeInterval(60)

        // When
        let shouldLock = AppLockPolicy.shouldLock(lastBackgroundAt: backgroundAt, now: now, isEnabled: true)

        // Then
        XCTAssertTrue(shouldLock)
    }

    func test_GH46_TC6_잠금켜짐_백그라운드기록이없으면_잠근다() {
        // Given
        let now = backgroundAt

        // When
        let shouldLock = AppLockPolicy.shouldLock(lastBackgroundAt: nil, now: now, isEnabled: true)

        // Then
        XCTAssertTrue(shouldLock)
    }

    func test_GH46_TC6_잠금켜짐_기기시간을되돌려경과가음수면_잠근다() {
        // Given
        let now = backgroundAt.addingTimeInterval(-3600)

        // When
        let shouldLock = AppLockPolicy.shouldLock(lastBackgroundAt: backgroundAt, now: now, isEnabled: true)

        // Then
        XCTAssertTrue(shouldLock)
    }

    // MARK: GH-46 TC8

    func test_GH46_TC8_잠금꺼짐_오래떠났다와도_잠그지않는다() {
        // Given
        let now = backgroundAt.addingTimeInterval(3600)

        // When
        let shouldLock = AppLockPolicy.shouldLock(lastBackgroundAt: backgroundAt, now: now, isEnabled: false)

        // Then
        XCTAssertFalse(shouldLock)
    }
}
