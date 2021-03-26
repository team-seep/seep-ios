import UIKit
import RxSwift
import RxCocoa

class EditButton: UIButton {
  
  var buttonState: EditButtonState = .active
  
  enum EditButtonState {
    case more
    case active
  }
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    self.setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setState(state: EditButtonState) {
    switch state {
    case .more:
      self.setTitle("detail_button_more".localized, for: .normal)
      self.backgroundColor = .gray3
    case .active:
      self.setTitle("detail_button_on".localized, for: .normal)
      self.backgroundColor = .tennisGreen
    }
  }
  
  private func setup() {
    self.layer.cornerRadius = 25
    self.backgroundColor = .tennisGreen
    self.titleLabel?.font = UIFont(name: "AppleSDGothicNeoEB00", size: 17)
    self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32)
    self.setKern(kern: -0.51)
  }
}

extension Reactive where Base: EditButton {
  
  var state: Binder<EditButton.EditButtonState> {
    return Binder(self.base) { view, state in
      view.setState(state: state)
    }
  }
}
