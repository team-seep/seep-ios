import UIKit
import RxSwift
import RxCocoa

class WriteButton: UIButton {
  
  var buttonState: WriteButtonState = .initial
  
  enum WriteButtonState {
    case initial
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
  
  func setState(state: WriteButtonState) {
    switch state {
    case .initial:
      self.setTitle("write_button_off".localized, for: .normal)
      self.backgroundColor = UIColor(r: 204, g: 207, b: 211)
    case .more:
      self.setTitle("write_button_more".localized, for: .normal)
      self.backgroundColor = UIColor(r: 204, g: 207, b: 211)
    case .active:
      self.setTitle("write_button_on".localized, for: .normal)
      self.backgroundColor = UIColor(r: 102, g: 223, b: 27)
    }
  }
  
  private func setup() {
    self.layer.cornerRadius = 25
    self.backgroundColor = UIColor(r: 102, g: 223, b: 27)
    self.titleLabel?.font = UIFont(name: "AppleSDGothicNeoEB00", size: 17)
    self.backgroundColor = UIColor(r: 204, g: 207, b: 211)
    self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32)
    self.setKern(kern: -0.51)
  }
}

extension Reactive where Base: WriteButton {
  
  var state: Binder<WriteButton.WriteButtonState> {
    return Binder(self.base) { view, state in
      view.setState(state: state)
    }
  }
}
