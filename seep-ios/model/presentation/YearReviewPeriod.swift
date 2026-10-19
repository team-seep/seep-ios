import Foundation

/// 연말 회고 배너를 띄우는 기간 (GH-34 R-9). 출시 없이 바꾸도록 Remote Config `year_review_period` 로 받는다.
struct YearReviewPeriod: Equatable {
    struct MonthDay: Equatable, Comparable {
        let month: Int
        let day: Int

        init(month: Int, day: Int) {
            self.month = month
            self.day = day
        }

        /// "MM-dd". 없는 날짜(13-01, 02-30 등)면 nil. 2월 29일은 윤년 기준으로 허용한다
        init?(text: String) {
            let parts = text.split(separator: "-")
            guard parts.count == 2,
                  let month = Int(parts[0]),
                  let day = Int(parts[1]),
                  DateComponents(calendar: Calendar(identifier: .gregorian), year: 2024, month: month, day: day).isValidDate
            else { return nil }
            self.init(month: month, day: day)
        }

        static func < (lhs: MonthDay, rhs: MonthDay) -> Bool {
            return (lhs.month, lhs.day) < (rhs.month, rhs.day)
        }
    }

    let isEnabled: Bool
    let start: MonthDay
    let end: MonthDay

    static let `default` = YearReviewPeriod(
        isEnabled: true,
        start: MonthDay(month: 12, day: 1),
        end: MonthDay(month: 1, day: 31)
    )

    /// `{"enabled":true,"start":"12-01","end":"01-31"}`. 비었거나 형식이 틀리면 기본값을 쓴다
    static func parse(_ json: String) -> YearReviewPeriod {
        struct Payload: Decodable {
            let enabled: Bool
            let start: String
            let end: String
        }

        guard let data = json.data(using: .utf8),
              let payload = try? JSONDecoder().decode(Payload.self, from: data),
              let start = MonthDay(text: payload.start),
              let end = MonthDay(text: payload.end) else { return .default }
        return YearReviewPeriod(isEnabled: payload.enabled, start: start, end: end)
    }

    /// 노출 기간이면 대상 연도를 돌려준다. 대상 연도는 기간이 시작한 해라서, 해를 넘긴 기간의 1월 쪽이면 지난해다
    func targetYear(now: Date, calendar: Calendar) -> Int? {
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard isEnabled,
              let year = components.year,
              let month = components.month,
              let day = components.day else { return nil }

        let today = MonthDay(month: month, day: day)
        if start <= end {
            return (start...end).contains(today) ? year : nil
        }
        if today >= start {
            return year
        }
        return today <= end ? year - 1 : nil
    }
}
