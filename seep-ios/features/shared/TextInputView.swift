import UIKit
import RxSwift
import RxCocoa

class TextInputView: BaseView {
  
  let containerView = UIView().then {
    $0.backgroundColor = .gray2
    $0.layer.cornerRadius = 6
  }
  
  let titleLabel = PaddingLabel(
    topInset: 0,
    bottomInset: 0,
    leftInset: 4,
    rightInset: 4
  ).then {
    $0.text = "write_header_memo".localized
    $0.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 12)
    $0.textColor = .seepBlue
    $0.setKern(kern: -0.24)
    $0.backgroundColor = .white
    $0.alpha = 0.0
  }
  
  let textView = UITextView().then {
    $0.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 16)
    $0.backgroundColor = .clear
    $0.text = "wrtie_placeholder_memo".localized
    $0.textColor = .gray3
  }
  
  let errorLabel = UILabel().then {
    $0.textColor = .optionRed
    $0.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 12)
  }
  
  override func setup() {
    self.backgroundColor = .clear
    self.addSubViews(containerView, titleLabel, textView)
    self.textView.rx
      .setDelegate(self)
      .disposed(by: disposeBag)
  }
  
  override func bindConstraints() {
    self.titleLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(16)
      make.top.equalToSuperview()
    }
    
    self.containerView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.bottom.equalTo(self.textView).offset(16)
      make.top.equalTo(self.titleLabel).offset(8)
    }
    
    self.textView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
      make.top.equalTo(self.containerView).offset(16)
      make.height.equalTo(82)
    }
  }
  
  func showError(message: String?) {
    if let message = message {
      self.addSubViews(self.errorLabel)
      self.errorLabel.text = message
      self.containerView.snp.remakeConstraints { make in
        make.left.right.equalToSuperview()
        make.bottom.equalTo(self.textView).offset(16)
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
        make.bottom.equalTo(self.textView).offset(16)
        make.top.equalTo(self.titleLabel).offset(8)
      }
    }
  }
}

extension Reactive where Base: TextInputView {
  
  var text: ControlProperty<String?> {
    return base.textView.rx.text
  }
  
  var errorMessage: Binder<String?> {
    return Binder(self.base) { view, message in
      view.showError(message: message)
    }
  }
}

extension TextInputView: UITextViewDelegate {
  
  func textViewDidBeginEditing(_ textView: UITextView) {
    if textView.text == "wrtie_placeholder_memo".localized {
      textView.text = ""
      textView.textColor = .gray5
    }
    
    UIView.animate(withDuration: 0.3) {
      self.containerView.backgroundColor = .white
      self.containerView.layer.borderColor = UIColor.seepBlue.cgColor
      self.containerView.layer.borderWidth = 1
      self.titleLabel.alpha = 1.0
    }
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      textView.text = "wrtie_placeholder_memo".localized
      textView.textColor = .gray3
    }
    
    UIView.animate(withDuration: 0.3) {
      self.containerView.layer.borderWidth = 0
      self.containerView.backgroundColor = .gray2
      self.titleLabel.alpha = 0.0
    }
  }
  
  func textView(
    _ textView: UITextView,
    shouldChangeTextIn range: NSRange,
    replacementText text: String
  ) -> Bool {
    guard let str = textView.text else { return true }
    let newLength = str.count + text.count - range.length
    
    if newLength >= 300 {
      self.rx.errorMessage.onNext("write_error_max_length_memo".localized)
    } else {
      self.rx.errorMessage.onNext(nil)
    }
    
    return newLength <= 300
  }
}
