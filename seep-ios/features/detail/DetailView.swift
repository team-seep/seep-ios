import UIKit
import ISEmojiView
import RxSwift
import RxCocoa

class DetailView: BaseView {
  
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
  
  let moreButton = UIButton().then {
    $0.setImage(UIImage(named: "ic_more"), for: .normal)
  }
  
  let cancelButton = UIButton().then {
    $0.setTitle("detail_cancel".localized, for: .normal)
    $0.setTitleColor(.gray3, for: .normal)
    $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 16)
    $0.alpha = 0.0
  }
  
  let emojiBackground = UIImageView().then {
    $0.backgroundColor = .gray2
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
    $0.containerView.backgroundColor = .gray2
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
  
  let editButton = EditButton()
  
  let toast = ToastView(frame: CGRect(x: 20, y: -58, width: UIScreen.main.bounds.width - 40, height: 58)).then {
    $0.actionButton.isHidden = true
    $0.messageLabel.text = "share_photo_success".localized
  }
  
  
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
      emojiBackground, emojiField, randomButton, categoryView,
      titleField, dateField, notificationButton, memoField,
      hashtagField
    )
    self.scrollView.addSubview(containerView)
    self.addSubViews(topIndicator, moreButton, cancelButton, scrollView, editButton)
  }
  
  override func bindConstraints() {
    self.scrollView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.top.equalTo(self.moreButton.snp.bottom)
    }
    
    self.containerView.snp.makeConstraints { make in
      make.edges.equalTo(0)
      make.width.equalToSuperview()
      make.top.equalToSuperview()
      make.bottom.equalTo(self.notificationButton).offset(40)
    }
    
    self.topIndicator.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.width.equalTo(48)
      make.height.equalTo(4)
      make.top.equalToSuperview().offset(20)
    }
    
    self.moreButton.snp.makeConstraints { make in
      make.right.equalToSuperview().offset(-20)
      make.top.equalToSuperview().offset(10)
    }
    
    self.cancelButton.snp.makeConstraints { make in
      make.right.equalToSuperview().offset(-20)
      make.top.equalToSuperview().offset(10)
    }
    
    self.emojiBackground.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.width.height.equalTo(72)
      make.top.equalToSuperview().offset(42)
    }
    
    self.emojiField.snp.makeConstraints { make in
      make.center.equalTo(self.emojiBackground)
    }
    
    self.randomButton.snp.makeConstraints { make in
      make.width.height.equalTo(20)
      make.left.equalTo(self.emojiBackground.snp.right).offset(4)
      make.bottom.equalTo(self.emojiBackground)
    }
    
    self.categoryView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(self.emojiBackground.snp.bottom).offset(32)
    }
    
    self.titleField.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
      make.top.equalTo(self.categoryView.snp.bottom).offset(32)
    }
    
    self.dateField.snp.makeConstraints { make in
      make.left.right.equalTo(self.titleField)
      make.top.equalTo(self.titleField.snp.bottom).offset(16)
    }
    
    self.notificationButton.snp.makeConstraints { make in
      make.left.right.equalTo(self.titleField)
      make.top.equalTo(self.dateField.snp.bottom).offset(8)
    }
    
    self.editButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.bottom.equalTo(safeAreaLayoutGuide).offset(-35)
      make.height.equalTo(50)
    }
  }
  
  func bind(wish: Wish, mode: DetailMode) {
    self.moreButton.isHidden = (mode == .fromFinish)
    self.emojiField.text = wish.emoji
    self.categoryView.moveActiveButton(category: Category(rawValue: wish.category) ?? .wantToDo)
    self.titleField.textField.text = wish.title
    self.dateField.textField.text = DateUtils.toString(format: "yyyy년 MM월 dd일 eeee", date: wish.date)
    
    self.notificationButton.isHidden = !wish.isPushEnable
    self.notificationButton.isSelected = wish.isPushEnable
    if wish.isPushEnable {
      self.notificationButton.setTitle("detail_notification_on".localized, for: .normal)
    }
    
    if !wish.memo.isEmpty {
      self.addMemoField(memo: wish.memo)
    }
    
    if !wish.hashtag.isEmpty {
      self.addHashtagField(hashtag: wish.hashtag)
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
  
  func setTitlePlaceholder(by category: Category) {
    self.titleField.textField.attributedPlaceholder = NSAttributedString(
      string: "write_placeholder_title_\(category.rawValue)".localized,
      attributes: [.foregroundColor: UIColor.gray3]
    )
  }
  
  func setEditable(isEditable: Bool) {
    if isEditable {
      UIView.animate(withDuration: 0.3) { [weak self] in
        guard let self = self else { return }
        self.randomButton.alpha = 1.0
        self.editButton.alpha = 1.0
        self.cancelButton.alpha = 1.0
        self.moreButton.alpha = 0.0
      }
      self.notificationButton.isHidden = false
      
      self.memoField.isHidden = false
      if self.memoField.isHidden {
        self.addMemoField(memo: "")
      } else {
        self.memoField.snp.remakeConstraints { make in
          make.left.right.equalTo(self.titleField)
          make.top.equalTo(self.notificationButton.snp.bottom).offset(16)
        }
      }

      if self.hashtagField.isHidden {
        self.addHashtagField(hashtag: "")
      } else {
        self.hashtagField.clearButton.isHidden = false
        self.hashtagField.setContentsLayout()
        self.hashtagField.clearButton.alpha = 1.0
        self.hashtagField.snp.remakeConstraints { make in
          make.left.equalToSuperview().offset(20)
          make.right.equalTo(self.hashtagField.containerView)
          make.bottom.equalTo(self.hashtagField.errorLabel).offset(10)
          make.top.equalTo(self.memoField.snp.bottom).offset(16)
        }
        self.containerView.snp.remakeConstraints { make in
          make.edges.equalTo(0)
          make.width.equalToSuperview()
          make.top.equalToSuperview()
          make.bottom.equalTo(self.hashtagField).offset(20)
        }
      }
    } else {
      UIView.animate(withDuration: 0.3) { [weak self] in
        guard let self = self else { return }
        self.randomButton.alpha = 0.0
        self.editButton.alpha = 0.0
        self.moreButton.alpha = 1.0
        self.cancelButton.alpha = 0.0
      }
      self.notificationButton.isHidden = !self.notificationButton.isSelected
      
      self.hashtagField.clearButton.isHidden = true
      self.hashtagField.containerView.snp.remakeConstraints { make in
        make.left.equalToSuperview()
        make.top.equalToSuperview()
        make.right.equalTo(self.hashtagField.textField).offset(8)
        make.bottom.equalTo(self.hashtagField.textField).offset(8)
      }

      if self.memoField.textView.text == "wrtie_placeholder_memo".localized || self.memoField.textView.text.isEmpty {
        self.memoField.isHidden = true
        self.memoField.setText(text: "")
      } else {
        if self.notificationButton.isHidden {
          self.memoField.snp.remakeConstraints { make in
            make.left.right.equalTo(self.titleField)
            make.top.equalTo(self.dateField.snp.bottom).offset(16)
          }
        }
      }

      if self.hashtagField.textField.text!.isEmpty {
        self.hashtagField.isHidden = true
        self.hashtagField.bind(hashtag: "")
      } else {
        if self.notificationButton.isHidden {
          if self.memoField.isHidden {
            self.hashtagField.snp.remakeConstraints { make in
              make.left.equalToSuperview().offset(20)
              make.right.equalTo(self.hashtagField.containerView)
              make.top.equalTo(self.dateField.snp.bottom).offset(16)
              make.bottom.equalTo(self.hashtagField.errorLabel).offset(10)
            }
          } else {
            self.hashtagField.snp.remakeConstraints { make in
              make.left.equalToSuperview().offset(20)
              make.right.equalTo(self.hashtagField.containerView)
              make.top.equalTo(self.memoField.snp.bottom).offset(16)
              make.bottom.equalTo(self.hashtagField.errorLabel).offset(10)
            }
          }
        } else if self.memoField.isHidden {
          self.hashtagField.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(self.hashtagField.containerView)
            make.top.equalTo(self.notificationButton.snp.bottom).offset(16)
            make.bottom.equalTo(self.hashtagField.errorLabel).offset(10)
          }
        } else {
          self.hashtagField.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(self.hashtagField.containerView)
            make.top.equalTo(self.memoField.snp.bottom).offset(16)
            make.bottom.equalTo(self.hashtagField.errorLabel).offset(10)
          }
        }
      }
    }
  }
  
  func showEditButton() {
    UIView.transition(with: self.editButton, duration: 0.3, options: .curveEaseInOut) {
      self.editButton.alpha = 1.0
      self.editButton.transform = .identity
    }
  }
  
  func hideEditButton() {
    UIView.transition(with: self.editButton, duration: 0.3, options: .curveEaseInOut) {
      self.editButton.alpha = 0.0
      self.editButton.transform = .init(translationX: 0, y: 100)
    }
  }
  
  func showFinishToast() {
    let window = UIApplication.shared.windows[0]
    
    self.addSubViews(toast)
    
    UIView.transition(with: toast, duration: 0.5, options: .curveEaseInOut) { [weak self] in
      self?.toast.transform = .init(translationX: 0, y: 14 + 58)
    } completion: { isComplete in
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
        guard let self = self else { return }
        UIView.transition(with: self.toast, duration: 0.5, options: .curveEaseInOut) { [weak self] in
          self?.toast.transform = .identity
        } completion: { [weak self] isCompleteRemove in
          if isCompleteRemove {
            self?.toast.removeFromSuperview()
          }
        }
      }
    }
  }
  
  private func refreshLayout() {
    
  }
  
  private func setupEmojiKeyboard() {
    let keyboardSettings = KeyboardSettings(bottomType: .categories)
    let emojiView = EmojiView(keyboardSettings: keyboardSettings)
    
    emojiView.translatesAutoresizingMaskIntoConstraints = false
    emojiView.delegate = self
    self.emojiField.inputView = emojiView
  }
  
  private func addMemoField(memo: String) {
    if self.notificationButton.isHidden {
      self.memoField.snp.remakeConstraints { make in
        make.left.right.equalTo(self.titleField)
        make.top.equalTo(self.dateField.snp.bottom).offset(16)
      }
    } else {
      self.memoField.snp.remakeConstraints { make in
        make.left.right.equalTo(self.titleField)
        make.top.equalTo(self.notificationButton.snp.bottom).offset(16)
      }
    }
    
    self.containerView.snp.remakeConstraints { make in
      make.edges.equalTo(0)
      make.width.equalToSuperview()
      make.top.equalToSuperview()
      make.bottom.equalTo(self.memoField).offset(20)
    }
    
    if !memo.isEmpty {
      self.memoField.setText(text: memo)
    }
  }
  
  private func addHashtagField(hashtag: String) {
    self.hashtagField.isHidden = false
    if !hashtag.isEmpty {
      self.hashtagField.bind(hashtag: hashtag)
    }
    
    if self.notificationButton.isHidden {
      self.hashtagField.snp.remakeConstraints { make in
        make.left.equalToSuperview().offset(20)
        make.right.equalTo(self.hashtagField.containerView)
        make.top.equalTo(self.dateField.snp.bottom).offset(16)
        make.bottom.equalTo(self.hashtagField.errorLabel).offset(10)
      }
    } else if self.memoField.isHidden {
      self.hashtagField.snp.remakeConstraints { make in
        make.left.equalToSuperview().offset(20)
        make.right.equalTo(self.hashtagField.containerView)
        make.top.equalTo(self.notificationButton.snp.bottom).offset(16)
        make.bottom.equalTo(self.hashtagField.errorLabel).offset(10)
      }
    } else {
      self.hashtagField.snp.remakeConstraints { make in
        make.left.equalToSuperview().offset(20)
        make.right.equalTo(self.hashtagField.containerView)
        make.top.equalTo(self.memoField.snp.bottom).offset(16)
        make.bottom.equalTo(self.hashtagField.errorLabel).offset(10)
      }
    }
    
    self.containerView.snp.remakeConstraints { make in
      make.edges.equalTo(0)
      make.width.equalToSuperview()
      make.top.equalToSuperview()
      make.bottom.equalTo(self.hashtagField).offset(20)
    }
  }
}

extension DetailView: UIScrollViewDelegate {
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    if self.moreButton.alpha == 0 {
      self.hideEditButton()
    }
  }
  
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      if self.moreButton.alpha == 0 {
        self.showEditButton()
      }
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    if self.moreButton.alpha == 0 {
      self.showEditButton()
    }
  }
}

extension DetailView: UITextFieldDelegate {
  
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

extension DetailView: EmojiViewDelegate {
  
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

extension Reactive where Base: DetailView{
  
  var isEditable: Binder<Bool> {
    return Binder(self.base) { view, isEditable in
      view.setEditable(isEditable: isEditable)
    }
  }
}

