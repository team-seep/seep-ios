import XCTest

@testable import seep_ios

/// App Check 공급자 선택 (GH-145 R-10)
final class AppCheckSetupTests: XCTestCase {
    func test_GH145_TC7_실기기는AppAttest_시뮬레이터는디버그공급자를고른다() {
        XCTAssertEqual(AppCheckProviderKind.resolve(isSimulator: false), .appAttest)
        XCTAssertEqual(AppCheckProviderKind.resolve(isSimulator: true), .debug)
    }
}
