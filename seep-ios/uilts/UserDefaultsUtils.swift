import Foundation

struct UserDefaultsUtils {
  
  static let keyViewType = "keyViewType"
  
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
}
