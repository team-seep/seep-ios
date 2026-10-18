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
    
    /// 홈 연말 회고 배너를 X로 닫은 대상 연도들 (GH-34 R-2)
    var closedYearReviewYears: [Int] {
        set {
            instance.set(newValue, forKey: "closedYearReviewYears")
        }
        get {
            instance.array(forKey: "closedYearReviewYears") as? [Int] ?? []
        }
    }
}
