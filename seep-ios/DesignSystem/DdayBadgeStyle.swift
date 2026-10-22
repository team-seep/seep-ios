import SwiftUI

/// D-day 뱃지의 문구·색 규칙. 홈 셀 `DdayLabel`·위젯 `DdayView`와 같은 규칙이다 (GH-64 TC-27).
struct DdayBadgeStyle: Equatable {
    enum Kind: Equatable {
        /// 지난 날 (D+n)
        case passed(days: Int)
        /// 0~7일 남음
        case imminent(days: Int)
        /// 8~30일 남음
        case relaxed(days: Int)
        /// 31~365일 남음
        case distant(days: Int)
        /// 365일 넘게 남음 — "먼훗날"
        case farFuture
        /// 날짜 없음 — "일정없음"
        case noDate
    }

    let kind: Kind

    init(endDate: Date?, today: Date = Date(), calendar: Calendar = .current) {
        guard let endDate else {
            kind = .noDate
            return
        }
        let remainDay = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: today),
            to: calendar.startOfDay(for: endDate)
        ).day ?? -1

        switch remainDay {
        case ..<0:
            kind = .passed(days: -remainDay)
        case 0..<8:
            kind = .imminent(days: remainDay)
        case 8..<31:
            kind = .relaxed(days: remainDay)
        case 31...365:
            kind = .distant(days: remainDay)
        default:
            kind = .farFuture
        }
    }

    /// 문구. "먼훗날"·"일정없음"은 위젯과 앱이 문자열 출처가 달라 밖에서 받는다
    func text(farFuture: String, noDate: String) -> String {
        switch kind {
        case .passed(let days):
            return "D+\(days)"
        case .imminent(let days), .relaxed(let days), .distant(let days):
            return "D-\(days)"
        case .farFuture:
            return farFuture
        case .noDate:
            return noDate
        }
    }

    var textColor: Color {
        switch kind {
        case .passed:
            return .optionPurple
        case .imminent:
            return .optionRed
        case .relaxed:
            return .ddayGreenText
        case .distant, .farFuture, .noDate:
            return .ddayBlueText
        }
    }

    var backgroundColor: Color {
        switch kind {
        case .passed:
            return .ddayPurpleBg
        case .imminent:
            return .ddayRedBg
        case .relaxed:
            return .ddayGreenBg
        case .distant, .farFuture, .noDate:
            return .ddayBlueBg
        }
    }
}
