import Foundation

final class Preference {
    static let shared = Preference()
    
    private let instance: UserDefaults
    
    init(name: String? = nil) {
        if let name {
            UserDefaults().removePersistentDomain(forName: name)
            instance = UserDefaults(suiteName: name)!
        } else {
            instance = UserDefaults.standard
        }
    }
    
    var viewType: ViewType {
        set {
            instance.set(newValue.rawValue, forKey: "viewType")
        }
        get {
            let viewTypeRawValue = instance.integer(forKey: "viewType")
            
            return ViewType(rawValue: viewTypeRawValue) ?? .list
        }
    }
    
    var reservedDeepLink: String {
        set {
            instance.set(newValue, forKey: "reservedDeepLink")
        }
        get {
            instance.string(forKey: "reservedDeepLink") ?? ""
        }
    }
    
    /// 위시 id → 캘린더에 추가한 이벤트 id (GH-28 R-4). "캘린더에 추가됨" 표시에만 쓴다.
    func calendarEventId(wishId: String) -> String? {
        let eventIds = instance.dictionary(forKey: "calendarEventIds") as? [String: String]
        return eventIds?[wishId]
    }
    
    func setCalendarEventId(_ eventId: String?, wishId: String) {
        var eventIds = instance.dictionary(forKey: "calendarEventIds") as? [String: String] ?? [:]
        eventIds[wishId] = eventId
        instance.set(eventIds, forKey: "calendarEventIds")
    }
}
