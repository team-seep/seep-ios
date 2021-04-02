import Foundation
import Then

struct DateUtils {
  
  static func toDate(dateString: String) -> Date {
    let dateFormatter = DateFormatter().then {
      $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    }
    
    return dateFormatter.date(from: dateString) ?? Date()
  }
  
  static func toString(format: String, date: Date) -> String {
    let dateFormatter = DateFormatter().then {
      $0.dateFormat = format
      $0.locale = Locale(identifier: "ko")
    }
    
    return dateFormatter.string(from: date)
  }
  
  static func todayString() -> String {
    let dateFormatter = DateFormatter().then {
      $0.dateFormat = "yyyy-MM-dd"
      $0.timeZone = NSTimeZone(name: "UTC") as TimeZone?
    }
    
    return dateFormatter.string(from: Date())
  }
  
  static func now() -> Date {
    let nowDate = Date()
    let calendar = Calendar(identifier: .gregorian)
    let midnightDate = calendar.startOfDay(for: nowDate)
    
    return midnightDate
  }
}
