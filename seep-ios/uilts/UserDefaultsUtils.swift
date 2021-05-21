import Foundation

struct UserDefaultsUtils {
  
  static let keyViewType = "keyViewType"
  static let keySharePhotoTooltipIsShow = "keySharePhotoTooltipIsShow"
  
  let instance: UserDefaults
  
  
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
}
