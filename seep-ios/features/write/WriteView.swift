import UIKit
import ISEmojiView

class WriteView: BaseView {
  
  let tapBackground = UITapGestureRecognizer()
  
  let accessoryView = InputAccessoryView(frame: CGRect(
    x: 0,
    y: 0,
    width: UIScreen.main.bounds.width,
    height: 45
  ))
  
  let scrollView = UIScrollView().then {
    $0.backgroundColor = .clear
    $0.showsVerticalScrollIndicator = false
  }
  
  let containerView = UIView().then {
    $0.backgroundColor = .clear
  }
  
  let topIndicator = UIView().then {
    $0.backgroundColor = .gray3
    $0.layer.cornerRadius = 2
  }
  
  let titleLabel = UILabel().then {
    let text = "write_title".localized
    let attributedString = NSMutableAttributedString(string: text)
    let boldTextRange = (text as NSString).range(of: "차근차근 적어봐요!")
    
    attributedString.addAttribute(
      .font,
      value: UIFont(name: "AppleSDGothicNeo-Bold", size: 20) as Any,
      range: boldTextRange
    )
    attributedString.addAttribute(
      .kern,
      value: -0.6,
      range: .init(location: 0, length: text.count)
    )
    $0.font = UIFont(name: "AppleSDGothicNeo-Light", size: 20)
    $0.textColor = UIColor(r: 51, g: 51, b: 51)
    $0.numberOfLines = 0
    $0.attributedText = attributedString
  }
  
  let emojiBackground = UIImageView().then {
    $0.image = UIImage(named: "img_emoji_empty")
    $0.layer.cornerRadius = 36
  }
  
  let emojiField = UITextField().then {
    $0.tintColor = .clear
    $0.textAlignment = .center
    $0.font = .systemFont(ofSize: 36)
  }
  
  let randomButton = UIButton().then {
    $0.setTitle("write_random_button".localized, for: .normal)
    $0.layer.cornerRadius = 10
    $0.backgroundColor = UIColor.seepBlue
    $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 12)
    $0.contentEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
  }
    
  let categoryView = CategoryView().then {
    $0.containerView.backgroundColor = UIColor(r: 232, g: 246, b: 255)
  }
  
  let titleField = TextInputField().then {
    $0.titleLabel.text = "write_header_title".localized
    $0.titleLabel.setKern(kern: -0.24)
  }
  
  let dateField = TextInputField().then {
    $0.titleLabel.text = "write_header_date".localized
    $0.titleLabel.setKern(kern: -0.24)
    $0.textField.attributedPlaceholder = NSAttributedString(
      string: "write_placeholder_date".localized,
      attributes: [.foregroundColor: UIColor.gray3]
    )
    $0.textField.tintColor = .clear
  }
  
  let notificationButton = UIButton().then {
    $0.setTitle("write_notification_off".localized, for: .normal)
    $0.setTitle("write_notification_on".localized, for: .selected)
    $0.setTitleColor(.gray3, for: .normal)
    $0.setTitleColor(.gray5, for: .selected)
    $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 12)
    $0.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
    $0.setImage(.icCheckOn20, for: .selected)
    $0.setImage(.icCheckOff20, for: .normal)
    $0.contentHorizontalAlignment = .left
  }
  
  let memoField = TextInputView()
  
  let hashtagField = WriteHashtagField()
  
  let gradientView = UIView().then {
    let gradientLayer = CAGradientLayer()
    let topColor = UIColor(r: 246, g: 247, b: 249, a: 0.0).cgColor
    let bottomColor = UIColor(r: 246, g: 247, b: 249, a: 1.0).cgColor

    gradientLayer.colors = [topColor, bottomColor]
    gradientLayer.locations = [0.0, 1.0]
    gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 150)
    $0.layer.addSublayer(gradientLayer)
  }
  
  let writeButton = WriteButton()
  
  override func setup() {
    self.backgroundColor = .white
    self.addGestureRecognizer(self.tapBackground)
    self.scrollView.delegate = self
    self.emojiField.delegate = self
    self.emojiField.inputAccessoryView = self.accessoryView
    self.emojiField.rx.controlEvent(.editingDidBegin)
      .bind { _ in
        FeedbackUtils.feedbackInstance.impactOccurred()
      }
      .disposed(by: self.disposeBag)
    self.titleField.textField.inputAccessoryView = self.accessoryView
    self.dateField.textField.inputAccessoryView = self.accessoryView
    self.memoField.textView.inputAccessoryView = self.accessoryView
    self.hashtagField.textField.inputAccessoryView = self.accessoryView
    self.setupEmojiKeyboard()
    self.containerView.addSubViews(
      titleLabel, emojiBackground, emojiField, randomButton,
      categoryView, titleField, dateField, memoField,
      hashtagField
    )
    self.scrollView.addSubview(containerView)
    self.addSubViews(topIndicator, scrollView, gradientView, writeButton)
  }
  
  override func bindConstraints() {
    self.scrollView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.top.equalTo(self.topIndicator.snp.bottom)
    }
    
    self.containerView.snp.makeConstraints { make in
      make.edges.equalTo(0)
      make.width.equalToSuperview()
      make.top.equalTo(self.titleLabel).offset(-20)
      make.bottom.equalTo(self.hashtagField).offset(20)
    }
    
    self.topIndicator.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.width.equalTo(48)
      make.height.equalTo(4)
      make.top.equalToSuperview().offset(20)
    }
    
    self.titleLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(20)
      make.top.equalToSuperview().offset(42)
    }
    
    self.emojiBackground.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.width.height.equalTo(72)
      make.top.equalTo(self.titleLabel.snp.bottom).offset(24)
    }
    
    self.emojiField.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.width.height.equalTo(72)
      make.top.equalTo(self.titleLabel.snp.bottom).offset(24)
    }
    
    self.randomButton.snp.makeConstraints { make in
      make.width.height.equalTo(20)
      make.left.equalTo(self.emojiBackground.snp.right).offset(4)
      make.bottom.equalTo(self.emojiBackground)
    }
    
    self.categoryView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(self.emojiField.snp.bottom).offset(32)
    }
    
    self.titleField.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
      make.top.equalTo(self.categoryView.snp.bottom).offset(32)
    }
    
    self.dateField.snp.makeConstraints { make in
      make.left.right.equalTo(self.titleField)
      make.top.equalTo(self.titleField.snp.bottom).offset(8)
    }
    
    self.memoField.snp.makeConstraints { make in
      make.left.right.equalTo(self.titleField)
      make.top.equalTo(self.dateField.snp.bottom).offset(8)
    }
    
    self.hashtagField.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(20)
      make.top.equalTo(self.memoField.snp.bottom).offset(16)
    }
    
    self.gradientView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.height.equalTo(150)
    }
    
    self.writeButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.bottom.equalTo(safeAreaLayoutGuide).offset(-23)
      make.height.equalTo(50)
    }
  }
  
  func showWriteButton() {
    UIView.transition(with: self.writeButton, duration: 0.3, options: .curveEaseInOut) {
      self.writeButton.alpha = 1.0
      self.writeButton.transform = .identity
    }
  }
  
  func hideWriteButton() {
    UIView.transition(with: self.writeButton, duration: 0.3, options: .curveEaseInOut) {
      self.writeButton.alpha = 0.0
      self.writeButton.transform = .init(translationX: 0, y: 100)
    }
  }
    
  func setEmojiBackground(isEmpty: Bool) {
    if isEmpty {
      self.emojiBackground.image = UIImage(named: "img_emoji_empty")
      self.emojiBackground.backgroundColor = .clear
    } else {
      self.emojiBackground.image = nil
      self.emojiBackground.backgroundColor = UIColor(r: 246, g: 247, b: 249)
    }
  }
  
  func showNotificationButton(isVisible: Bool) {
    if isVisible == true {
      self.containerView.addSubViews(self.notificationButton)
      self.notificationButton.snp.makeConstraints { make in
        make.left.right.equalTo(self.titleField)
        make.top.equalTo(self.dateField.snp.bottom).offset(8)
      }
      
      self.memoField.snp.remakeConstraints { make in
        make.left.right.equalTo(self.titleField)
        make.top.equalTo(self.notificationButton.snp.bottom).offset(16)
      }
    }
  }
  
  func setTitlePlaceholder(by category: Category) {
    self.titleField.textField.attributedPlaceholder = NSAttributedString(
      string: "write_placeholder_title_\(category.rawValue)".localized,
      attributes: [.foregroundColor: UIColor.gray3]
    )
  }
  
  private func setupEmojiKeyboard() {
    let keyboardSettings = KeyboardSettings(bottomType: .categories)
    let emojiView = EmojiView(keyboardSettings: keyboardSettings)
    
    emojiView.translatesAutoresizingMaskIntoConstraints = false
    emojiView.delegate = self
    self.emojiField.inputView = emojiView
  }
}

extension WriteView: UIScrollViewDelegate {
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    self.hideWriteButton()
  }
  
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      self.showWriteButton()
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    self.showWriteButton()
  }
}

extension WriteView: UITextFieldDelegate {
  
  func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    let currentText = textField.text ?? ""
    guard let stringRange = Range(range, in: currentText) else { return false }
    let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
    
    return updatedText.count <= 1
  }
}

extension WriteView: EmojiViewDelegate {
  
  func emojiViewDidSelectEmoji(_ emoji: String, emojiView: EmojiView) {
    self.emojiField.text = emoji
    if self.emojiField.text?.count == 1 {
      self.emojiField.resignFirstResponder()
    }
  }
  
  func emojiViewDidPressChangeKeyboardButton(_ emojiView: EmojiView) {
    self.emojiField.inputView = nil
    self.emojiField.keyboardType = .default
    self.emojiField.reloadInputViews()
  }
  
  func emojiViewDidPressDeleteBackwardButton(_ emojiView: EmojiView) {
    self.emojiField.deleteBackward()
  }
  
  func emojiViewDidPressDismissKeyboardButton(_ emojiView: EmojiView) {
    self.emojiField.resignFirstResponder()
  }
}
