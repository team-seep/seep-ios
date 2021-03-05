import UIKit

class BaseCollectionViewCell: UICollectionViewCell {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    self.setup()
    self.bindConstraints()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    self.setup()
    self.bindConstraints()
  }
  
  func setup() { }
  
  func bindConstraints() { }
}
