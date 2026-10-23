import Foundation

/// D-day 숫자의 색 규칙 (GH-59 R-3). 홈 셀 `DdayLabel`과 상세 D-day 줄·상단 바가 같이 쓴다.
/// 지난 날 보라 · 0~7일 빨강 · 8~30일 초록 · 31일 이상·먼훗날·일정없음 파랑. 실제 색은 UIKit 쪽(`DdayTone+Color`)에서 고른다.
enum DdayTone: Equatable {
    case past
    case urgent
    case soon
    case later
}

/// 마감일에서 D-day 종류·문구·색을 정한다. UIKit 을 모르는 순수 타입이라 ViewModel·테스트에서 바로 쓴다.
struct DdayStyle: Equatable {
    enum Kind: Equatable {
        case noDeadline
        case past(days: Int)
        case today
        case remaining(days: Int)
        case farFuture
    }

    /// 365일을 넘으면 숫자 대신 "먼훗날"
    static let farFutureThreshold = 365

    let kind: Kind

    init(endDate: Date?, now: Date = Date(), calendar: Calendar = .current) {
        guard let endDate else {
            self.kind = .noDeadline
            return
        }
        let remainDay = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: endDate)
        ).day ?? -1

        switch remainDay {
        case _ where remainDay < 0:
            self.kind = .past(days: -remainDay)
        case 0:
            self.kind = .today
        case _ where remainDay > Self.farFutureThreshold:
            self.kind = .farFuture
        default:
            self.kind = .remaining(days: remainDay)
        }
    }

    var tone: DdayTone {
        switch kind {
        case .past:
            return .past
        case .today:
            return .urgent
        case .remaining(let days):
            switch days {
            case ..<8:
                return .urgent
            case ..<31:
                return .soon
            default:
                return .later
            }
        case .farFuture, .noDeadline:
            return .later
        }
    }

    /// 숫자가 아니라 단어(일정없음·먼훗날)인지. 상세에서는 작게 쓰고 상단 바에는 넣지 않는다 (R-3, R-8)
    var isWord: Bool {
        switch kind {
        case .noDeadline, .farFuture:
            return true
        case .past, .today, .remaining:
            return false
        }
    }

    /// 상세 문서의 표기. 당일은 "D-Day" (사용자 결정)
    var text: String {
        switch kind {
        case .today:
            return Strings.Detail.Dday.today
        default:
            return labelText
        }
    }

    /// 홈 셀 배지 표기. 당일 "D-0" 은 그대로 둔다 (GH-59 범위 밖)
    var labelText: String {
        switch kind {
        case .noDeadline:
            return Strings.homeNoDeanline
        case .past(let days):
            return "D+\(days)"
        case .today:
            return "D-0"
        case .remaining(let days):
            return "D-\(days)"
        case .farFuture:
            return Strings.homeInFarFurture
        }
    }
}
