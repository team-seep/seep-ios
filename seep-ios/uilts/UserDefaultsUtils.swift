import Foundation

struct UserDefaultsUtils {
    static let keyViewType = "keyViewType"
    static let keySharePhotoTooltipIsShow = "keySharePhotoTooltipIsShow"
    static let keyRandomEmojiTooltipIsShow = "keyRandomEmojiTooltipIsShow"
    static let keyNoticeDate = "keyNoticeDate"
    private let keyDeepLink = "keyDeepLink"
    private let keyToken = "keyToken"
    
    let instance: UserDefaults
    
    var token: String {
        get {
            return self.instance.string(forKey: self.keyToken) ?? ""
        }
        set {
            self.instance.set(newValue, forKey: self.keyToken)
        }
    }
    
    
    init(name: String? = nil) {
        if let name = name {
            UserDefaults().removePersistentDomain(forName: name)
            instance = UserDefaults(suiteName: name)!
        } else {
            instance = UserDefaults.standard
        }
    }
    
    func setViewType(viewType: ViewType) {
        self.instance.set(viewType.rawValue, forKey: UserDefaultsUtils.keyViewType)
    }
    
    func getViewType() -> ViewType {
        let viewTypeRawValue = self.instance.integer(forKey: UserDefaultsUtils.keyViewType)
        
        return ViewType(rawValue: viewTypeRawValue) ?? .list
    }
    
    func setSharePhotoTooltipIsShow(isShown: Bool) {
        self.instance.set(isShown, forKey: UserDefaultsUtils.keySharePhotoTooltipIsShow)
    }
    
    func getSharePhotoTooltipIsShow() -> Bool {
        return self.instance.bool(forKey: UserDefaultsUtils.keySharePhotoTooltipIsShow)
    }
    
    func setRandomEmojiTooltipIsShow(isShown: Bool) {
        self.instance.set(isShown, forKey: UserDefaultsUtils.keyRandomEmojiTooltipIsShow)
    }
    
    func getRandomEmojiTooltipIsShow() -> Bool {
        return self.instance.bool(forKey: UserDefaultsUtils.keyRandomEmojiTooltipIsShow)
    }
    
    func setDeepLink(deepLink: String) {
        self.instance.set(deepLink, forKey: self.keyDeepLink)
    }
    
    func getDeepLink() -> String {
        return self.instance.string(forKey: self.keyDeepLink) ?? ""
    }
    
    func setNoticeDisableToday() {
        self.instance.set(DateUtils.todayString() ,forKey: UserDefaultsUtils.keyNoticeDate)
    }
    
    func getNoticeDisableToday() -> String {
        return self.instance.string(forKey: UserDefaultsUtils.keyNoticeDate) ?? ""
    }
    
    func clear() {
        self.instance.set("", forKey: self.keyToken)
        self.setViewType(viewType: .grid)
        self.setSharePhotoTooltipIsShow(isShown: false)
        self.setRandomEmojiTooltipIsShow(isShown: false)
    }
}
