import UIKit

extension UIColor {
  
  convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
    self.init(red: r/255, green: g/255, blue: b/255, alpha: a)
  }
  
  public class var seepBlue: UIColor {
    return UIColor(r: 47, g: 168, b: 249)
  }
  
  public class var gray2: UIColor {
    return UIColor(r: 246, g: 247, b: 249)
  }
  
  public class var gray3: UIColor {
    return UIColor(r: 192, g: 197, b: 205)
  }
  
  public class var gray4: UIColor {
    return UIColor(r: 130, g: 137, b: 147)
  }
  
  public class var gray5: UIColor {
    return UIColor(r: 51, g: 51, b: 51)
  }
  
  public class var optionRed: UIColor {
    return UIColor(r: 255, g: 92, b: 82)
  }
  
  public class var tennisGreen: UIColor {
    return UIColor(r: 102, g: 223, b: 27)
  }
}
