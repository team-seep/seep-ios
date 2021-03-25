import UIKit

extension UIColor {
  
  convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
    self.init(red: r/255, green: g/255, blue: b/255, alpha: a)
  }
  
  public class var seepBlue: UIColor {
    return UIColor(r: 47, g: 168, b: 249)
  }
  
  public class var gray3: UIColor {
    return UIColor(r: 192, g: 197, b: 205)
  }
}
