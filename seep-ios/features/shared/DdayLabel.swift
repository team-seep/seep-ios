import UIKit

class DdayLabel: PaddingLabel {
  
  init() {
    super.init(topInset: 3, bottomInset: 1, leftInset: 6, rightInset: 6)
    self.setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func bind(dday: Date) {
    let remainDay = Calendar.current.dateComponents([.day], from: Date(), to: dday).day ?? -1
    
    switch remainDay {
    case _ where remainDay < 0:
      self.textColor = .optionPurple
      self.backgroundColor = .optionPurple.withAlphaComponent(0.15)
    case 0..<8:
      self.textColor = .optionRed
      self.backgroundColor = UIColor(r: 255, g: 236, b: 235)
    case 8..<31:
      self.textColor = UIColor(r: 56, g: 202, b: 79)
      self.backgroundColor = UIColor(r: 231, g: 251, b: 234)
    default:
      self.textColor = UIColor(r: 62, g: 163, b: 254)
      self.backgroundColor = UIColor(r: 236, g: 243, b: 250)
    }
    
    if remainDay < 0 {
      self.text = "D+\(abs(remainDay))"
    } else if remainDay <= 365 {
      self.text = "D-\(remainDay)"
    } else {
      self.text = "home_in_far_furture".localized
    }
  }
  
  private func setup() {
    self.font = .appleBold(size: 11)
    self.layer.cornerRadius = 4
    self.layer.masksToBounds = true
  }
}
