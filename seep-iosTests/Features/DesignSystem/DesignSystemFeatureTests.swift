import XCTest
import SwiftUI
import UIKit

@testable import seep_ios_dev

/// 앱·위젯 공용 SwiftUI 토큰과 D-day 뱃지 규칙 (GH-64 P0)
final class DesignSystemFeatureTests: XCTestCase {
    // MARK: GH-64 TC26

    func test_GH64_TC26_SwiftUI색토큰은_UIKit토큰과_RGB가같다() {
        // Given
        let pairs: [(String, Color, UIColor)] = [
            ("gray1", .gray1, .gray1),
            ("gray2", .gray2, .gray2),
            ("gray2_5", .gray2_5, .gray2_5),
            ("gray3", .gray3, .gray3),
            ("gray4", .gray4, .gray4),
            ("gray5", .gray5, .gray5),
            ("seepBlue", .seepBlue, .seepBlue),
            ("optionRed", .optionRed, .optionRed),
            ("tennisGreen", .tennisGreen, .tennisGreen),
            ("optionPurple", .optionPurple, .optionPurple)
        ]

        for (name, swiftUIColor, uiKitColor) in pairs {
            // When
            let resolved = UIColor(swiftUIColor).rgba

            // Then
            let expected = uiKitColor.rgba
            XCTAssertEqual(resolved.r, expected.r, accuracy: 0.002, name)
            XCTAssertEqual(resolved.g, expected.g, accuracy: 0.002, name)
            XCTAssertEqual(resolved.b, expected.b, accuracy: 0.002, name)
            XCTAssertEqual(resolved.a, expected.a, accuracy: 0.002, name)
        }
    }

    func test_GH64_TC26_폰트이름은_UIKit폰트와같고_기기에있다() {
        // Given
        let uiKitFonts: [(SeepFontName, UIFont?)] = [
            (.ultraLight, .appleUltraLight(size: 10)),
            (.light, .appleLight(size: 10)),
            (.regular, .appleRegular(size: 10)),
            (.medium, .appleMedium(size: 10)),
            (.semiBold, .appleSemiBold(size: 10)),
            (.bold, .appleBold(size: 10)),
            (.extraBold, .appleExtraBold(size: 10))
        ]

        for (name, uiKitFont) in uiKitFonts {
            // When
            // 토큰 이름이 기기에 실제로 있는 폰트인지 확인하려고 이름으로 직접 만든다
            // swiftlint:disable:next no_uifont_name
            let font = UIFont(name: name.rawValue, size: 10)

            // Then
            XCTAssertNotNil(font, "\(name.rawValue) 폰트가 없다")
            XCTAssertEqual(font?.fontName, uiKitFont?.fontName)
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
