import UIKit

extension UIColor {
  
  convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
    self.init(red: r/255, green: g/255, blue: b/255, alpha: a)
  }
  
  static let gray1 = UIColor(r: 255, g: 255, b: 255)
  static let gray2 = UIColor(r: 246, g: 247, b: 249)
    static let gray2_5 = UIColor(r: 225, g: 227, b: 231, a: 1)
  static let gray3 = UIColor(r: 192, g: 197, b: 205)
  static let gray4 = UIColor(r: 130, g: 137, b: 147)
  static let gray5 = UIColor(r: 51, g: 51, b: 51)
  
  static let seepBlue = UIColor(r: 47, g: 168, b: 249)
  static let optionRed = UIColor(r: 255, g: 92, b: 82)
  static let tennisGreen = UIColor(r: 102, g: 223, b: 27)
  static let optionPurple = UIColor(r: 231, g: 115, b: 226)

    // D-day 글자·배지 바탕 (DdayLabel·상세 D-day 줄, GH-59 DdayStyle)
    static let ddayGreenText = UIColor(r: 56, g: 202, b: 79)
    static let ddayGreenBg = UIColor(r: 231, g: 251, b: 234)
    static let ddayBlueText = UIColor(r: 62, g: 163, b: 254)
    static let ddayBlueBg = UIColor(r: 236, g: 243, b: 250)
    static let ddayRedBg = UIColor(r: 255, g: 236, b: 235)
}
