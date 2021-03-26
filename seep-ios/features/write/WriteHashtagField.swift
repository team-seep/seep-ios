import UIKit
import RxSwift
import RxCocoa

class WriteHashtagField: BaseView {
  
  let containerView = UIView().then {
    $0.layer.cornerRadius = 6
  }
  
  let textField = UITextField().then {
    $0.textAlignment = .left
    $0.returnKeyType = .done
    $0.font = UIFont(name: "AppleSDGothicNeoEB00", size: 14)
    $0.attributedPlaceholder = NSAttributedString(
      string: "해시태그를 달아봐요 (선택)",
      attributes: [
        .foregroundColor: UIColor.gray3,
        .font: UIFont(name: "AppleSDGothicNeo-Regular", size: 14)!
      ]
    )
  }
  
  let clearButton = UIButton().then {
    $0.setImage(UIImage(named: "ic_close"), for: .normal)
  }
  
  let dashedBorderLayer = CAShapeLayer().then {
    $0.strokeColor = UIColor(r: 192, g: 197, b: 205).cgColor
    $0.lineDashPattern = [2, 2]
    $0.fillColor = nil
  }
  
  let errorLabel = UILabel().then {
    $0.textColor = .optionRed
    $0.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 12)
  }
  
  
  override func setup() {
    self.addSubViews(containerView, textField, clearButton, errorLabel)
    self.backgroundColor = .clear
    self.textField.delegate = self
    self.setupBorder()
    self.setupClearButton()
  }
  
  override func bindConstraints() {
    self.containerView.snp.makeConstraints { make in
      make.left.equalToSuperview()
      make.top.equalToSuperview()
      make.right.equalTo(self.textField).offset(8)
      make.bottom.equalTo(self.textField).offset(8)
    }
    
    self.textField.snp.makeConstraints { make in
      make.left.equalTo(self.containerView).offset(8)
      make.top.equalTo(self.containerView).offset(6)
    }
    
    self.clearButton.snp.makeConstraints { make in
      make.centerY.equalTo(self.containerView)
      make.right.equalTo(self.containerView).offset(-6)
    }
    
    self.errorLabel.snp.makeConstraints { make in
      make.left.equalTo(self.containerView)
      make.top.equalTo(self.containerView.snp.bottom).offset(8)
    }
    
    self.snp.makeConstraints { make in
      make.left.top.right.equalTo(self.containerView)
      make.bottom.equalTo(self.errorLabel).offset(10)
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    self.addDashedBorder()
  }
  
  private func addDashedBorder() {
    self.dashedBorderLayer.removeFromSuperlayer()
    self.dashedBorderLayer.frame = self.containerView.bounds
    self.dashedBorderLayer.path = UIBezierPath(
      roundedRect: self.containerView.bounds,
      cornerRadius: 6
    ).cgPath
    self.containerView.layer.addSublayer(self.dashedBorderLayer)
  }
  
  private func setupBorder() {
    self.textField.rx.text
      .observeOn(MainScheduler.instance)
      .bind { [weak self] text in
        guard let self = self else { return }
        if let text = text {
          self.setHiddenClearButton(isHidden: text.isEmpty)
          self.setHiddenDashedBorder(isHidden: !text.isEmpty)
          if !text.isEmpty {
            self.textField.frame.size.width = self.textField.intrinsicContentSize.width
            self.containerView.backgroundColor = .gray2
            self.textField.attributedPlaceholder = nil
            self.setContentsLayout()
          } else {
            self.containerView.backgroundColor = .clear
            self.textField.attributedPlaceholder = NSAttributedString(
              string: "write_placeholder_hashtag".localized,
              attributes: [
                .foregroundColor: UIColor.gray3,
                .font: UIFont(name: "AppleSDGothicNeo-Regular", size: 14)!
              ]
            )
            self.setPlaceHolderLayout()
          }
        }
      }
      .disposed(by: self.disposeBag)
  }
  
  private func setupClearButton() {
    self.clearButton.rx.tap
      .map { "" }
      .bind(to: self.textField.rx.text)
      .disposed(by: self.disposeBag)
    
    self.clearButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind { [weak self] _ in
        guard let self = self else { return }
        self.textField.text = ""
        self.setHiddenClearButton(isHidden: true)
        self.setHiddenDashedBorder(isHidden: false)
        self.containerView.backgroundColor = .clear
        self.textField.attributedPlaceholder = NSAttributedString(
          string: "write_placeholder_hashtag".localized,
          attributes: [
            .foregroundColor: UIColor.gray3,
            .font: UIFont(name: "AppleSDGothicNeo-Regular", size: 14)!
          ]
        )
        self.setPlaceHolderLayout()
      }
      .disposed(by: self.disposeBag)
  }
  
  private func setContentsLayout() {
    self.containerView.snp.remakeConstraints { make in
      make.left.equalToSuperview()
      make.top.equalToSuperview()
      make.right.equalTo(self.clearButton).offset(6)
      make.bottom.equalTo(self.textField).offset(8)
    }
    
    self.textField.snp.remakeConstraints { make in
      make.left.equalTo(self.containerView).offset(8)
      make.top.equalTo(self.containerView).offset(6)
    }
    
    self.clearButton.snp.remakeConstraints { make in
      make.centerY.equalTo(self.containerView)
      make.left.equalTo(self.textField.snp.right).offset(6)
    }
  }
  
  private func setPlaceHolderLayout() {
    self.containerView.snp.remakeConstraints { make in
      make.left.equalToSuperview()
      make.top.equalToSuperview()
      make.right.equalTo(self.textField).offset(8)
      make.bottom.equalTo(self.textField).offset(8)
    }
    
    self.textField.snp.remakeConstraints { make in
      make.left.equalTo(self.containerView).offset(8)
      make.top.equalTo(self.containerView).offset(6)
    }
    
    self.clearButton.snp.remakeConstraints { make in
      make.centerY.equalTo(self.containerView)
      make.right.equalTo(self.containerView).offset(-6)
    }
  }
  
  private func setHiddenClearButton(isHidden: Bool) {
    UIView.animate(withDuration: 0.3) { [weak self] in
      guard let self = self else { return }
      self.clearButton.alpha = isHidden ? 0.0 : 1.0
    }
  }
  
  private func setHiddenDashedBorder(isHidden: Bool) {
    UIView.animate(withDuration: 0.3) { [weak self] in
      guard let self = self else { return }
      self.dashedBorderLayer.opacity = isHidden ? 0.0 : 1.0
    }
  }
}

extension WriteHashtagField: UITextFieldDelegate {
  
  func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    guard let text = textField.text else { return true }
    
    let newLength = text.count + string.trimmingCharacters(in: .newlines).count - range.length
    
    if newLength >= 8 {
      self.errorLabel.text = "write_error_max_length_hashtag".localized
    } else {
      self.errorLabel.text = nil
    }
    
    return newLength <= 8
  }
}

extension Reactive where Base: WriteHashtagField {
  
  var text: ControlProperty<String?> {
    return base.textField.rx.text
  }
}

