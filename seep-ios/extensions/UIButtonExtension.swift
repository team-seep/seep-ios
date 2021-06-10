import UIKit

extension UIButton {
  
  func setKern(kern: Float) {
    guard let text = self.titleLabel?.text else { return }
    let attributedString = NSMutableAttributedString(string: text)
    
    attributedString.addAttribute(
      .kern,
      value: kern,
      range: .init(location: 0, length: text.count)
    )
    
    self.setAttributedTitle(attributedString, for: .normal)
  }
}
