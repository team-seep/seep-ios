import UIKit

class PaddingLabel: UILabel {
  
  let topInset: CGFloat
  let bottomInset: CGFloat
  let leftInset: CGFloat
  let rightInset: CGFloat
  
  init(
    topInset: CGFloat,
    bottomInset: CGFloat,
    leftInset: CGFloat,
    rightInset: CGFloat
  ) {
    self.topInset = topInset
    self.bottomInset = bottomInset
    self.leftInset = leftInset
    self.rightInset = rightInset
    super.init(frame: .zero)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func drawText(in rect: CGRect) {
    let insets = UIEdgeInsets(
      top: self.topInset,
      left: self.leftInset,
      bottom: self.bottomInset,
      right: self.rightInset
    )
    super.drawText(in: rect.inset(by: insets))
  }
  
  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    
    return CGSize(
      width: size.width + self.leftInset + self.rightInset,
      height: size.height + self.topInset + self.bottomInset
    )
  }
  
  override var bounds: CGRect {
    didSet {
      preferredMaxLayoutWidth = self.bounds.width - (self.leftInset + self.rightInset)
    }
  }
}
