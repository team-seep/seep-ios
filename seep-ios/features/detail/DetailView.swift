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
  
  let stackContainerView = UIView().then {
    $0.backgroundColor = UIColor(r: 232, g: 246, b: 255)
    $0.layer.cornerRadius = 24
  }
  
  let categoryStackView = UIStackView().then {
    $0.alignment = .leading
    $0.axis = .horizontal
    $0.distribution = .equalSpacing
  }
  
  let wantToDoButton = UIButton().then {
    $0.setTitle("common_category_want_to_do".localized, for: .normal)
    $0.setTitleColor(.gray4, for: .normal)
    $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 14)
    $0.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
    $0.setKern(kern: -0.28)
  }
  
  let wantToGetButton = UIButton().then {
    $0.setTitle("common_category_want_to_get".localized, for: .normal)
    $0.setTitleColor(.gray4, for: .normal)
    $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 14)
    $0.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
    $0.setKern(kern: -0.28)
  }
  
  let wantToGoButton = UIButton().then {
    $0.setTitle("common_category_want_to_go".localized, for: .normal)
    $0.setTitleColor(.gray4, for: .normal)
    $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 14)
    $0.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
    $0.setKern(kern: -0.28)
  }
  
  let activeButton = UIButton().then {
    $0.backgroundColor = .seepBlue
    $0.layer.cornerRadius = 16
    $0.setTitleColor(.clear, for: .normal)
    $0.layer.shadowOpacity = 0.15
    $0.layer.shadowColor = UIColor.black.cgColor
    $0.layer.shadowOffset = CGSize(width: 0, height: 2)
    $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeoEB00", size: 14)
    $0.contentEdgeInsets = UIEdgeInsets(top: 4, left: 18, bottom: 4, right: 18)
    $0.setKern(kern: -0.28)
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
    $0.setTitle("write_notification".localized, for: .normal)
    $0.setTitleColor(.gray4, for: .normal)
    $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 12)
    $0.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
    $0.setImage(UIImage(named: "img_check_on_20"), for: .selected)
    $0.setImage(UIImage(named: "img_check_off_20"), for: .normal)
    $0.contentHorizontalAlignment = .left
  }
  
  let memoField = TextInputView()
  
  let hashtagField = WriteHashtagField()
  
  let editButton = EditButton()
  
  
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
    self.categoryStackView.addArrangedSubview(wantToDoButton)
    self.categoryStackView.addArrangedSubview(wantToGetButton)
    self.categoryStackView.addArrangedSubview(wantToGoButton)
    self.containerView.addSubViews(
      emojiBackground, emojiField, randomButton, stackContainerView,
      activeButton, categoryStackView, titleField, dateField,
      notificationButton, memoField, hashtagField
    )
    self.scrollView.addSubview(containerView)
    self.addSubViews(topIndicator, moreButton, cancelButton, scrollView, editButton)
  }
  
  override func bindConstraints() {
    self.scrollView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.top.equalTo(self.topIndicator.snp.bottom)
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
    
    self.categoryStackView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(self.emojiBackground.snp.bottom).offset(32)
    }
    
    self.stackContainerView.snp.makeConstraints { make in
      make.left.equalTo(self.categoryStackView).offset(-8)
      make.right.equalTo(self.categoryStackView).offset(8)
      make.centerY.equalTo(self.categoryStackView)
      make.height.equalTo(48)
    }
    
    self.activeButton.snp.makeConstraints { make in
      make.centerY.equalTo(self.categoryStackView)
      make.height.equalTo(32)
      make.centerX.equalTo(self.categoryStackView.arrangedSubviews[0])
    }
    
    self.titleField.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
      make.top.equalTo(self.categoryStackView.snp.bottom).offset(32)
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
    self.moveActiveButton(category: Category(rawValue: wish.category) ?? .wantToDo)
    self.titleField.textField.text = wish.title
    self.dateField.textField.text = DateUtils.toString(format: "yyyy년 MM월 dd일 eeee", date: wish.date)
    self.notificationButton.isSelected = wish.isPushEnable
    if wish.isPushEnable {
      self.notificationButton.setTitle("detail_notification_on".localized, for: .normal)
    } else {
      
    }
    
    if !wish.memo.isEmpty {
      self.addMemoField(memo: wish.memo)
    }
    
    if !wish.hashtag.isEmpty {
      self.addHashtagField(hashtag: wish.hashtag)
    }
  }
  
  func moveActiveButton(category: Category) {
    var index = 0
    switch category {
    case .wantToDo:
      index = 0
    case .wantToGet:
      index = 1
    case .wantToGo:
      index = 2
    }
    self.activeButton.snp.remakeConstraints { make in
      make.centerY.equalTo(self.categoryStackView)
      make.height.equalTo(30)
      make.centerX.equalTo(self.categoryStackView.arrangedSubviews[index])
    }
    self.activeButton.setTitle(category.rawValue.localized, for: .normal)
    UIView.animate(withDuration: 0.3, delay: 0, options:.curveEaseOut, animations: { [weak self] in
      guard let self = self else { return }
      self.layoutIfNeeded()
      self.wantToDoButton.setTitleColor(category == .wantToDo ? UIColor.white : UIColor(r: 136, g: 136, b: 136), for: .normal)
      self.wantToDoButton.titleLabel?.font = category == .wantToDo ? UIFont(name: "AppleSDGothicNeoEB00", size: 14) : UIFont(name: "AppleSDGothicNeo-Medium", size: 14)
      self.wantToDoButton.contentEdgeInsets = category == .wantToDo ? UIEdgeInsets(top: 3, left: 18, bottom: 0, right: 18) : UIEdgeInsets(top: 6, left: 18, bottom: 4, right: 18)
      self.wantToGoButton.setTitleColor(category == .wantToGo ? UIColor.white : UIColor(r: 136, g: 136, b: 136), for: .normal)
      self.wantToGoButton.titleLabel?.font = category == .wantToGo ? UIFont(name: "AppleSDGothicNeoEB00", size: 14) : UIFont(name: "AppleSDGothicNeo-Medium", size: 14)
      self.wantToGoButton.contentEdgeInsets = category == .wantToGo ? UIEdgeInsets(top: 3, left: 18, bottom: 0, right: 18) : UIEdgeInsets(top: 6, left: 18, bottom: 4, right: 18)
      self.wantToGetButton.setTitleColor(category == .wantToGet ? UIColor.white : UIColor(r: 136, g: 136, b: 136), for: .normal)
      self.wantToGetButton.titleLabel?.font = category == .wantToGet ? UIFont(name: "AppleSDGothicNeoEB00", size: 14) : UIFont(name: "AppleSDGothicNeo-Medium", size: 14)
      self.wantToGetButton.contentEdgeInsets = category == .wantToGet ? UIEdgeInsets(top: 3, left: 18, bottom: 0, right: 18) : UIEdgeInsets(top: 6, left: 18, bottom: 4, right: 18)
    })
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
      if self.memoField.isHidden {
        self.addMemoField(memo: "")
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
      }

      if self.hashtagField.textField.text!.isEmpty {
        self.hashtagField.isHidden = true
        self.hashtagField.bind(hashtag: "")
      } else {
        if self.memoField.isHidden {
          self.hashtagField.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(self.hashtagField.containerView)
            make.top.equalTo(self.notificationButton.snp.bottom).offset(16)
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
  
  private func setupEmojiKeyboard() {
    let keyboardSettings = KeyboardSettings(bottomType: .categories)
    let emojiView = EmojiView(keyboardSettings: keyboardSettings)
    
    emojiView.translatesAutoresizingMaskIntoConstraints = false
    emojiView.delegate = self
    self.emojiField.inputView = emojiView
  }
  
  private func addMemoField(memo: String) {
    self.memoField.isHidden = false
    self.memoField.snp.makeConstraints { make in
      make.left.right.equalTo(self.titleField)
      make.top.equalTo(self.notificationButton.snp.bottom).offset(16)
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
    
    if self.memoField.superview != nil {
      self.hashtagField.snp.remakeConstraints { make in
        make.left.equalToSuperview().offset(20)
        make.right.equalTo(self.hashtagField.containerView)
        make.top.equalTo(self.memoField.snp.bottom).offset(16)
        make.bottom.equalTo(self.hashtagField.errorLabel).offset(10)
      }
    } else {
      self.hashtagField.snp.remakeConstraints { make in
        make.left.equalToSuperview().offset(20)
        make.right.equalTo(self.hashtagField.containerView)
        make.top.equalTo(self.notificationButton.snp.bottom).offset(16)
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

