import Foundation

struct DateUtils {
    static func toDate(dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return dateFormatter.date(from: dateString) ?? Date()
    }

    static func toString(format: String, date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "ko")
        return dateFormatter.string(from: date)
    }

    static func todayString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter.string(from: Date())
    }

    static func now() -> Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.startOfDay(for: Date())
    }
}
