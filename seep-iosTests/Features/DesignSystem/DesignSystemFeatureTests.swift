import XCTest
import SwiftUI
import UIKit

@testable import seep_ios_dev

/// 앱·위젯 공용 SwiftUI 토큰과 D-day 뱃지 규칙 (GH-64 P0)
final class DesignSystemFeatureTests: XCTestCase {
    // MARK: GH-64 TC26

    func test_GH64_TC26_SwiftUI색토큰은_디자인시스템값과_RGB가같다() {
        // Given — 싶 디자인 시스템 tokens.json (UIKit 토큰은 GH-64 P3에서 지웠다)
        let expected: [(String, Color, Int)] = [
            ("gray1", .gray1, 0xFFFFFF),
            ("gray2", .gray2, 0xF6F7F9),
            ("gray2_5", .gray2_5, 0xE1E3E7),
            ("gray3", .gray3, 0xC0C5CD),
            ("gray4", .gray4, 0x828993),
            ("gray5", .gray5, 0x333333),
            ("seepBlue", .seepBlue, 0x2FA8F9),
            ("optionRed", .optionRed, 0xFF5C52),
            ("tennisGreen", .tennisGreen, 0x66DF1B),
            ("optionPurple", .optionPurple, 0xE773E2),
            ("categoryTrack", .categoryTrack, 0xE8F6FF)
        ]

        for (name, color, hex) in expected {
            // When
            let resolved = UIColor(color).rgba

            // Then
            XCTAssertEqual(resolved.r, CGFloat((hex >> 16) & 0xFF) / 255, accuracy: 0.002, name)
            XCTAssertEqual(resolved.g, CGFloat((hex >> 8) & 0xFF) / 255, accuracy: 0.002, name)
            XCTAssertEqual(resolved.b, CGFloat(hex & 0xFF) / 255, accuracy: 0.002, name)
            XCTAssertEqual(resolved.a, 1, accuracy: 0.002, name)
        }
    }

    func test_GH64_TC26_폰트이름은_AppleSDGothicNeo굵기별이름이고_기기에있다() {
        // Given
        let expected: [(SeepFontName, String)] = [
            (.ultraLight, "AppleSDGothicNeo-UltraLight"),
            (.light, "AppleSDGothicNeo-Light"),
            (.regular, "AppleSDGothicNeo-Regular"),
            (.medium, "AppleSDGothicNeo-Medium"),
            (.semiBold, "AppleSDGothicNeo-SemiBold"),
            (.bold, "AppleSDGothicNeo-Bold"),
            (.extraBold, "AppleSDGothicNeoEB00")
        ]

        for (name, fontName) in expected {
            // When — 토큰 이름이 기기에 실제로 있는 폰트인지 이름으로 직접 만들어 본다
            let font = UIFont(name: name.rawValue, size: 10)

            // Then
            XCTAssertEqual(name.rawValue, fontName)
            XCTAssertNotNil(font, "\(name.rawValue) 폰트가 없다")
        }
    }

    // MARK: GH-64 TC27

    private let calendar = Calendar(identifier: .gregorian)
    private let today = Date(timeIntervalSince1970: 1_792_540_800) // 2026-10-20

    private func style(daysFromToday days: Int?) -> DdayBadgeStyle {
        let endDate = days.flatMap { calendar.date(byAdding: .day, value: $0, to: today) }
        return DdayBadgeStyle(endDate: endDate, today: today, calendar: calendar)
    }

    func test_GH64_TC27_남은날수에따라_문구와색쌍이_DdayLabel규칙과같다() {
        // Given / When
        let cases: [(Int?, String, Color, Color)] = [
            (-2, "D+2", .optionPurple, .ddayPurpleBg),
            (0, "D-0", .optionRed, .ddayRedBg),
            (5, "D-5", .optionRed, .ddayRedBg),
            (7, "D-7", .optionRed, .ddayRedBg),
            (8, "D-8", .ddayGreenText, .ddayGreenBg),
            (23, "D-23", .ddayGreenText, .ddayGreenBg),
            (30, "D-30", .ddayGreenText, .ddayGreenBg),
            (31, "D-31", .ddayBlueText, .ddayBlueBg),
            (365, "D-365", .ddayBlueText, .ddayBlueBg),
            (366, "먼훗날", .ddayBlueText, .ddayBlueBg),
            (nil, "일정없음", .ddayBlueText, .ddayBlueBg)
        ]

        for (days, text, textColor, backgroundColor) in cases {
            let style = style(daysFromToday: days)

            // Then
            XCTAssertEqual(style.text(farFuture: "먼훗날", noDate: "일정없음"), text, "\(String(describing: days))")
            XCTAssertEqual(style.textColor, textColor, "\(String(describing: days))")
            XCTAssertEqual(style.backgroundColor, backgroundColor, "\(String(describing: days))")
        }
    }

    func test_GH64_TC27_뱃지색토큰은_DdayLabel의값과같다() {
        // Given / When / Then
        XCTAssertEqual(UIColor(Color.ddayRedBg).rgba.r, 255 / 255, accuracy: 0.002)
        XCTAssertEqual(UIColor(Color.ddayGreenText).rgba.g, 202 / 255, accuracy: 0.002)
        XCTAssertEqual(UIColor(Color.ddayBlueText).rgba.b, 254 / 255, accuracy: 0.002)
        XCTAssertEqual(UIColor(Color.ddayPurpleBg).rgba.a, 0.15, accuracy: 0.002)
    }
}

private extension UIColor {
    var rgba: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}
