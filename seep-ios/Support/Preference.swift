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
    
    /// 화면 모드. 없으면 시스템 설정 따르기 (GH-85 R-3)
    var appearance: AppAppearance {
        set {
            instance.set(newValue.rawValue, forKey: AppAppearance.storageKey)
        }
        get {
            instance.string(forKey: AppAppearance.storageKey).flatMap(AppAppearance.init(rawValue:)) ?? .system
        }
    }

    /// 앱을 켤 때 홈이 처음 보일 카테고리. nil 이면 마지막으로 본 카테고리 (GH-86 R-1)
    var startCategory: Category? {
        set {
            instance.set(newValue?.rawValue, forKey: "startCategory")
        }
        get {
            instance.string(forKey: "startCategory").flatMap(Category.init(rawValue:))
        }
    }

    /// 홈에서 마지막으로 본 카테고리 (GH-86 R-2)
    var lastHomeCategory: Category {
        set {
            instance.set(newValue.rawValue, forKey: "lastHomeCategory")
        }
        get {
            instance.string(forKey: "lastHomeCategory").flatMap(Category.init(rawValue:)) ?? .wantToDo
        }
    }

    /// 홈 정렬. 없으면 완료일 가까운순 (GH-73 R-2)
    var homeSortOrder: HomeSortOrder {
        set {
            instance.set(newValue.rawValue, forKey: "homeSortOrder")
        }
        get {
            instance.string(forKey: "homeSortOrder").flatMap(HomeSortOrder.init(rawValue:)) ?? .deadlineOrder
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
    
    /// 홈 연말 회고 배너를 X로 닫은 대상 연도들 (GH-34 R-2)
    var closedYearReviewYears: [Int] {
        set {
            instance.set(newValue, forKey: "closedYearReviewYears")
        }
        get {
            instance.array(forKey: "closedYearReviewYears") as? [Int] ?? []
        }
    }
    
    /// 축하 시트를 이미 보여준(또는 업데이트 직후 축하 없이 넘긴) 배지 id. 완료 취소로 잠겨도 지우지 않는다 (GH-35 R-7, R-9)
    var celebratedBadgeIds: Set<String> {
        set {
            instance.set(newValue.sorted(), forKey: "celebratedBadgeIds")
        }
        get {
            Set(instance.stringArray(forKey: "celebratedBadgeIds") ?? [])
        }
    }
    
    /// 앱 잠금(Face ID·기기 암호)을 켰는지 (GH-46 R-9)
    var isAppLockEnabled: Bool {
        set {
            instance.set(newValue, forKey: "isAppLockEnabled")
        }
        get {
            instance.bool(forKey: "isAppLockEnabled")
        }
    }

    /// 마지막으로 백그라운드에 들어간 시각. 돌아올 때 60초가 지났으면 잠근다 (GH-46 R-5)
    var appLockBackgroundAt: Date? {
        set {
            instance.set(newValue, forKey: "appLockBackgroundAt")
        }
        get {
            instance.object(forKey: "appLockBackgroundAt") as? Date
        }
    }

    /// 업데이트 직후 이미 얻은 배지를 축하함으로 넘기는 처리를 했는지 (GH-35 R-8)
    var isBadgeInitialized: Bool {
        set {
            instance.set(newValue, forKey: "isBadgeInitialized")
        }
        get {
            instance.bool(forKey: "isBadgeInitialized")
        }
    }
}
