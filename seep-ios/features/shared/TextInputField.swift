import UIKit
import RxSwift
import RxCocoa

class TextInputField: BaseView {
  
  let containerView = UIView().then {
    $0.backgroundColor = UIColor(r: 246, g: 247, b: 249)
    $0.layer.cornerRadius = 6
  }
  
  let titleLabel = PaddingLabel(
    topInset: 0,
    bottomInset: 0,
    leftInset: 4,
    rightInset: 4
  ).then {
    $0.text = "write_placeholder_title".localized
    $0.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 12)
    $0.textColor = UIColor(r: 47, g: 168, b: 249)
    $0.setKern(kern: -0.24)
    $0.backgroundColor = .white
    $0.alpha = 0.0
  }
  
  let textField = UITextField().then {
    $0.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 16)
    $0.textColor = UIColor(r: 51, g: 51, b: 51)
    $0.attributedPlaceholder = NSAttributedString(
      string: "write_placeholder_title".localized,
      attributes: [.foregroundColor: UIColor(r: 186, g: 186, b: 186)]
    )
  }
  
  let errorLabel = UILabel().then {
    $0.textColor = .optionRed
    $0.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 12)
  }
  
  
  override func setup() {
    self.backgroundColor = .clear
    self.addSubViews(containerView, titleLabel, textField)
    self.textField.rx.text.orEmpty.skip(1)
      .map { $0.isEmpty }
      .bind(to: self.rx.isEmpty)
      .disposed(by: disposeBag)
    self.textField.rx.controlEvent(.editingDidBegin)
      .bind { [weak self] _ in
        guard let self = self else { return }
        UIView.animate(withDuration: 0.3) {
          self.containerView.backgroundColor = .white
        }
      }
      .disposed(by: disposeBag)
    self.textField.rx.controlEvent(.editingDidEnd)
      .bind { [weak self] _ in
        guard let self = self else { return }
        UIView.animate(withDuration: 0.3) {
          self.containerView.layer.borderColor = UIColor(r: 186, g: 186, b: 186).cgColor
          self.titleLabel.alpha = 0.0
        }
      }
      .disposed(by: disposeBag)
  }
  
  override func bindConstraints() {
    self.titleLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(16)
      make.top.equalToSuperview()
    }
    
    self.containerView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.bottom.equalTo(self.textField).offset(16)
      make.top.equalTo(self.titleLabel).offset(8)
    }
    
    self.textField.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
      make.top.equalTo(self.containerView).offset(16)
    }
  }
  
  func showError(message: String?) {
    if let message = message {
      self.addSubViews(self.errorLabel)
      self.errorLabel.text = message
      self.containerView.snp.remakeConstraints { make in
        make.left.right.equalToSuperview()
        make.bottom.equalTo(self.textField).offset(16)
        make.top.equalTo(self.titleLabel).offset(8)
      }
      self.errorLabel.snp.makeConstraints { make in
        make.left.bottom.equalToSuperview()
        make.top.equalTo(self.containerView.snp.bottom).offset(8)
      }
    } else {
      self.errorLabel.removeFromSuperview()
      self.containerView.snp.remakeConstraints { make in
        make.left.right.bottom.equalToSuperview()
        make.bottom.equalTo(self.textField).offset(16)
        make.top.equalTo(self.titleLabel).offset(8)
      }
    }
  }
}

extension Reactive where Base: TextInputField {
  
  var text: ControlProperty<String?> {
    return base.textField.rx.text
  }
  
  var isEmpty: Binder<Bool> {
    return Binder(self.base) { view, isEmpty in
      if isEmpty {
        UIView.animate(withDuration: 0.3) {
          view.containerView.layer.borderColor = UIColor(r: 186, g: 186, b: 186).cgColor
          view.containerView.layer.borderWidth = 1
          view.titleLabel.alpha = 0.0
        }
      } else {
        UIView.animate(withDuration: 0.3) {
          view.containerView.layer.borderColor = UIColor(r: 47, g: 168, b: 249).cgColor
          view.containerView.layer.borderWidth = 1
          view.titleLabel.alpha = 1.0
        }
      }
    }
  }
  
  var errorMessage: Binder<String?> {
    return Binder(self.base) { view, message in
      view.showError(message: message)
    }
  }
}
