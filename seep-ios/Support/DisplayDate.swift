import Foundation

/// 사람에게 보여 주는 날짜·시간 (GH-100 R-10). 고정 패턴 대신 로케일 템플릿을 써서 언어마다 그 나라 순서로 나온다.
/// 한국어 결과는 예전 고정 패턴("M월 d일 (E)" 등)과 같다. 앱·위젯이 같이 쓴다
enum DisplayDate {
    /// "12월 25일" / "Dec 25"
    static func monthDay(_ date: Date, locale: Locale = AppLanguage.shared.locale, calendar: Calendar = .current) -> String {
        return string(date, template: "MMMd", locale: locale, calendar: calendar)
    }

    /// "12월 25일 (금)" / "Fri, Dec 25"
    static func monthDayWeekday(_ date: Date, locale: Locale = AppLanguage.shared.locale, calendar: Calendar = .current) -> String {
        return string(date, template: "MMMEd", locale: locale, calendar: calendar)
    }

    /// "2027년 1월 3일" / "Jan 3, 2027"
    static func yearMonthDay(_ date: Date, locale: Locale = AppLanguage.shared.locale, calendar: Calendar = .current) -> String {
        return string(date, template: "yMMMd", locale: locale, calendar: calendar)
    }

    /// "2027년 1월 3일 (일)" / "Sun, Jan 3, 2027"
    static func yearMonthDayWeekday(_ date: Date, locale: Locale = AppLanguage.shared.locale, calendar: Calendar = .current) -> String {
        return string(date, template: "yMMMEd", locale: locale, calendar: calendar)
    }

    /// "2026. 12. 25." / "12/25/2026"
    static func numericYearMonthDay(_ date: Date, locale: Locale = AppLanguage.shared.locale, calendar: Calendar = .current) -> String {
        return string(date, template: "yMd", locale: locale, calendar: calendar)
    }

    /// "2026년 10월" / "October 2026" (GH-103)
    static func yearMonth(year: Int, month: Int, locale: Locale = AppLanguage.shared.locale, calendar: Calendar = .current) -> String {
        let date = calendar.date(from: DateComponents(year: year, month: month, day: 1, hour: 12)) ?? Date()
        return string(date, template: "yMMMM", locale: locale, calendar: calendar)
    }

    /// "10월" / "October" (GH-103)
    static func month(_ month: Int, locale: Locale = AppLanguage.shared.locale) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(year: 2001, month: month, day: 1, hour: 12)) ?? Date()
        return string(date, template: "MMMM", locale: locale, calendar: calendar)
    }

    /// "오후 9시 00분" / "9:00 PM" (TC-7)
    static func time(_ date: Date, locale: Locale = AppLanguage.shared.locale, calendar: Calendar = .current) -> String {
        let formatter = makeFormatter(locale: locale, calendar: calendar)
        // 한국어 템플릿은 "a h:mm"(오후 9:00)라, 지금까지 써 온 "오후 9시 00분"을 그대로 둔다
        if locale.language.languageCode == .korean {
            formatter.dateFormat = "a h시 mm분"
        } else {
            formatter.setLocalizedDateFormatFromTemplate("jmm")
        }
        return formatter.string(from: date)
    }

    static func string(_ date: Date, template: String, locale: Locale = AppLanguage.shared.locale, calendar: Calendar = .current) -> String {
        let formatter = makeFormatter(locale: locale, calendar: calendar)
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }

    /// 화면 디자인으로 정한 숫자 표기("2026.12.25", "12.25")처럼 언어와 상관없이 같은 모양이어야 하는 날짜.
    /// 기기 달력이 일본 연호·불교력이어도 그레고리력 숫자로 나온다
    static func fixed(_ date: Date, pattern: String, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }

    private static func makeFormatter(locale: Locale, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        return formatter
    }
}
