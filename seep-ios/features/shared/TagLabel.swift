import UIKit

class TagLabel: PaddingLabel {
  
  init() {
    super.init(topInset: 3, bottomInset: 1, leftInset: 6, rightInset: 6)
    self.setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.font = UIFont.appleBold(size: 11)
    self.textColor = UIColor(r: 153, g: 153, b: 153)
    self.backgroundColor = UIColor(r: 241, g: 241, b: 241)
    self.layer.cornerRadius = 4
    self.layer.masksToBounds = true
  }
}
