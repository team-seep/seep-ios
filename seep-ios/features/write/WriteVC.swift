import RxSwift
import ReactorKit

protocol WriteDelegate: class {
  
  func onSuccessWrite()
}

class WriteVC: BaseVC, View {
  
  weak var delegate: WriteDelegate?
  private lazy var writeView = WriteView(frame: self.view.frame)
  private let writeReactor = WriteReactor(wishService: WishService())
  
  private let datePicker = UIDatePicker().then {
    $0.datePickerMode = .date
    $0.preferredDatePickerStyle = .wheels
    $0.locale = .init(identifier: "ko_KO")
  }
  
  static func instance() -> WriteVC {
    return WriteVC(nibName: nil, bundle: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view = writeView
    self.reactor = writeReactor
    self.setupKeyboardNotification()
    self.writeView.titleField.textField.delegate = self
    self.writeView.dateField.textField.inputView = datePicker
    Observable.just(WriteReactor.Action.viewDidLoad(()))
      .bind(to: self.writeReactor.action)
      .disposed(by: disposeBag)
  }
  
  override func bindEvent() {
    self.writeView.tapBackground.rx.event
      .observeOn(MainScheduler.instance)
      .bind(onNext: { [weak self] _ in
        guard let self = self else { return }
        self.writeView.endEditing(true)
      })
      .disposed(by: self.eventDisposeBag)
  }
  
  func bind(reactor: WriteReactor) {
    // MARK: Action
    self.writeView.emojiField.rx.text.orEmpty
      .map { Reactor.Action.inputEmoji($0) }
      .bind(to: self.writeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.writeView.randomButton.rx.tap
      .map { Reactor.Action.tapRandomEmoji(())}
      .bind(to: self.writeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.writeView.wantToDoButton.rx.tap
      .map { Reactor.Action.tapCategory(.wantToDo) }
      .bind(to: self.writeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.writeView.wantToGetButton.rx.tap
      .map { Reactor.Action.tapCategory(.wantToGet) }
      .bind(to: self.writeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.writeView.wantToGoButton.rx.tap
      .map { Reactor.Action.tapCategory(.wantToGo) }
      .bind(to: self.writeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.writeView.titleField.rx.text.orEmpty
      .map { Reactor.Action.inputTitle($0) }
      .bind(to: self.writeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.datePicker.rx.date
      .skip(1)
      .map { Reactor.Action.inputDate($0) }
      .bind(to: self.writeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.writeView.notificationButton.rx.tap
      .map { Reactor.Action.tapPushButton(()) }
      .bind(to: self.writeReactor.action)
      .disposed(by: disposeBag)
    
    self.writeView.memoField.rx.text.orEmpty
      .filter { $0 != "wrtie_placeholder_memo".localized }
      .map { Reactor.Action.inputMemo($0) }
      .bind(to: self.writeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.writeView.hashtagField.rx.text.orEmpty
      .map { Reactor.Action.inputHashtag($0) }
      .bind(to: self.writeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.writeView.writeButton.rx.tap
      .map { Reactor.Action.tapWriteButton(()) }
      .bind(to: self.writeReactor.action)
      .disposed(by: disposeBag)
    
    // MARK: State
    self.writeReactor.state
      .map { $0.emoji }
      .observeOn(MainScheduler.instance)
      .bind(to: self.writeView.emojiField.rx.text)
      .disposed(by: self.disposeBag)
    
    self.writeReactor.state
      .map { $0.category }
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .do(onNext: self.writeView.setTitlePlaceholder(by:))
      .bind(onNext: self.writeView.moveActiveButton(category:))
      .disposed(by: self.disposeBag)
    
    self.writeReactor.state
      .map { $0.titleError }
      .bind(to: self.writeView.titleField.rx.errorMessage)
      .disposed(by: self.disposeBag)
    
    self.writeReactor.state
      .filter { $0.date != nil }
      .map { DateUtils.toString(format: "yyyy년 MM월 dd일 eeee", date: $0.date ?? Date())}
      .observeOn(MainScheduler.instance)
      .bind(to: self.writeView.dateField.rx.text)
      .disposed(by: self.disposeBag)
    
    self.writeReactor.state
      .map { $0.dateError }
      .bind(to: self.writeView.dateField.rx.errorMessage)
      .disposed(by: self.disposeBag)
    
    self.writeReactor.state
      .map { $0.writeButtonState }
      .observeOn(MainScheduler.instance)
      .bind(to: self.writeView.writeButton.rx.state)
      .disposed(by: self.disposeBag)
    
    self.writeReactor.state
      .map { $0.isPushEnable }
      .observeOn(MainScheduler.instance)
      .bind(to: self.writeView.notificationButton.rx.isSelected)
      .disposed(by: self.disposeBag)
    
    self.writeReactor.state
      .map { $0.isPushButtonVisible }
      .filter { $0 == true }
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.writeView.showNotificationButton)
      .disposed(by: self.disposeBag)
    
    self.writeReactor.state
      .map { $0.emoji.isEmpty }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.writeView.setEmojiBackground(isEmpty:))
      .disposed(by: disposeBag)
    
    self.writeReactor.state
      .map { $0.shouldDismiss }
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .bind(onNext: { [weak self] shouldDismiss in
        guard let self = self else { return }
        if shouldDismiss {
          self.delegate?.onSuccessWrite()
          self.dismiss()
        }
      })
      .disposed(by: disposeBag)
  }
  
  private func setupKeyboardNotification() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow(_:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
  }
  
  private func dismiss() {
    self.dismiss(animated: true, completion: nil)
  }
  
  @objc private func keyboardWillShow(_ notification: Notification) {
    guard let userInfo = notification.userInfo as? [String: Any] else { return }
    guard let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
    let keyboardScreenEndFrame = keyboardFrame.cgRectValue
    let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
    
    self.writeView.scrollView.contentInset.bottom = keyboardViewEndFrame.height
    self.writeView.scrollView.scrollIndicatorInsets = self.writeView.scrollView.contentInset
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    self.writeView.scrollView.contentInset.bottom = .zero
  }
}

extension WriteVC: UITextFieldDelegate {
  
  func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    guard let text = textField.text else { return true }
    let newLength = text.count + string.count - range.length
    
    if newLength >= 18 {
      self.writeView.titleField.rx.errorMessage.onNext("write_error_max_length_title".localized)
    } else {
      self.writeView.titleField.rx.errorMessage.onNext(nil)
    }
    
    return newLength <= 18
  }
}
