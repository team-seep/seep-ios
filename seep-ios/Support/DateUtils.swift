import Foundation

struct DateUtils {
    /// 저장·파싱용 날짜. 기기 언어·달력(일본 연호, 불교력)과 상관없이 같은 값으로 읽고 쓴다 (GH-100 R-11)
    static func toDate(dateString: String) -> Date {
        let dateFormatter = storageFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return dateFormatter.date(from: dateString) ?? Date()
    }

    /// 문구 파일에 둔 날짜 패턴(`detail.journal.row_date_format` 등)으로 보여 준다.
    /// 패턴은 언어마다 번역하고, 요일 이름은 지금 로케일을 따른다
    static func toString(format: String, date: Date, locale: Locale = .current) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        dateFormatter.locale = locale
        return dateFormatter.string(from: date)
    }

    static func todayString() -> String {
        let dateFormatter = storageFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter.string(from: Date())
    }

    static func now() -> Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.startOfDay(for: Date())
    }

    private static func storageFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        return dateFormatter
    }
}
