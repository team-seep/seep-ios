import Foundation

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    func toString(format: String) -> String {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        
        return dateFormatter.string(from: self)
    }
    
    func setDay(date: Date) -> Self {
        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: date
        )
        components.hour = Calendar.current.component(.hour, from: self)
        components.minute = Calendar.current.component(.minute, from: self)
        
        return Calendar.current.date(from: components) ?? Date()
    }
    
    func addDay(day: Int) -> Self {
        var components = DateComponents()
        
        components.day = day
        return Calendar.current.date(byAdding: components, to: self) ?? Date()
    }
}
