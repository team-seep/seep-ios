import UIKit
import RxSwift
import ReactorKit

protocol DetailDelegate: AnyObject {
  
  func onDismiss()
}

enum DetailMode {
  case fromHome
  case fromFinish
  
}

class DetailVC: BaseVC, View {
  
  weak var delegate: DetailDelegate?
  private lazy var detailView = DetailView(frame: self.view.frame)
  private let detailReactor: DetailReactor
  private let wish: Wish
  private let mode: DetailMode
  private let datePicker = UIDatePicker().then {
    $0.datePickerMode = .date
    $0.preferredDatePickerStyle = .wheels
    $0.locale = .init(identifier: "ko_KO")
  }
  
  
  init(wish: Wish, mode: DetailMode) {
    self.detailReactor = DetailReactor(
      wish: wish,
      wishService: WishService()
    )
    self.wish = wish
    self.mode = mode
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  static func instance(wish: Wish, mode: DetailMode) -> DetailVC {
    return DetailVC(wish: wish, mode: mode)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view = self.detailView
    self.reactor = self.detailReactor
    self.setupKeyboardNotification()
    self.detailView.titleField.textField.delegate = self
    self.detailView.dateField.textField.inputView = datePicker
    self.detailView.bind(wish: wish, mode: mode)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    self.delegate?.onDismiss()
  }
  
  override func bindEvent() {
    self.detailView.tapBackground.rx.event
      .observeOn(MainScheduler.instance)
      .bind { [weak self] _ in
        guard let self = self else { return }
        self.detailView.endEditing(true)
      }
      .disposed(by: self.eventDisposeBag)
    
    self.detailView.moreButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.showActionSheet)
      .disposed(by: self.eventDisposeBag)
    
    self.detailView.accessoryView.finishButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind { [weak self] in
        self?.detailView.endEditing(true)
      }
      .disposed(by: self.eventDisposeBag)
    
    self.detailView.shareButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind { [weak self] _ in
        guard let self = self else { return }
        self.showSharePhoto(wish: self.wish)
      }
      .disposed(by: self.eventDisposeBag)
  }
  
  func bind(reactor: DetailReactor) {
    // MARK: Action
    self.detailView.cancelButton.rx.tap
      .map { DetailReactor.Action.tapCancelButton }
      .do(onNext: { [weak self] _ in
        self?.detailView.endEditing(true)
      })
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
    
    self.detailView.emojiField.rx.text.orEmpty
      .skip(1)
      .map { Reactor.Action.inputEmoji($0) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
    
    self.detailView.emojiField.rx.controlEvent(.editingDidBegin)
      .map { Reactor.Action.tapEditButton }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
    
    self.detailView.randomButton.rx.tap
      .map { Reactor.Action.tapRandomEmojiButton }
      .do(onNext: { _ in
        FeedbackUtils.feedbackInstance.impactOccurred()
      })
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
    
    self.detailView.categoryView.rx.tapCategory
      .map { Reactor.Action.tapCategory($0) }
      .do(onNext: { _ in
        FeedbackUtils.feedbackInstance.impactOccurred()
      })
      .bind(to: self.detailReactor.action)
      .disposed(by: self.disposeBag)
    
    self.detailView.titleField.rx.text.orEmpty
      .skip(1)
      .map { Reactor.Action.inputTitle($0) }
      .bind(to: self.detailReactor.action)
      .disposed(by: self.disposeBag)
    
    self.detailView.titleField.textField.rx.controlEvent(.editingDidBegin)
      .map { Reactor.Action.tapEditButton }
      .bind(to: self.detailReactor.action)
      .disposed(by: self.disposeBag)
    
    self.datePicker.rx.date
      .skip(1)
      .map { Reactor.Action.inputDate($0) }
      .bind(to: self.detailReactor.action)
      .disposed(by: self.disposeBag)
    
    self.detailView.dateField.textField.rx.controlEvent(.editingDidBegin)
      .map { Reactor.Action.tapEditButton }
      .bind(to: self.detailReactor.action)
      .disposed(by: self.disposeBag)
    
    self.detailView.notificationButton.rx.tap
      .map { Reactor.Action.tapPushButton(()) }
      .do(onNext: { _ in
        FeedbackUtils.feedbackInstance.impactOccurred()
      })
      .bind(to: self.detailReactor.action)
      .disposed(by: disposeBag)
    
    self.detailView.memoField.rx.text.orEmpty
      .filter { $0 != "wrtie_placeholder_memo".localized }
      .map { Reactor.Action.inputMemo($0) }
      .bind(to: self.detailReactor.action)
      .disposed(by: self.disposeBag)
    
    self.detailView.memoField.textView.rx.didBeginEditing
      .map { Reactor.Action.tapEditButton }
      .bind(to: self.detailReactor.action)
      .disposed(by: self.disposeBag)
    
    self.detailView.hashtagField.rx.text.orEmpty
      .map { Reactor.Action.inputHashtag($0) }
      .bind(to: self.detailReactor.action)
      .disposed(by: self.disposeBag)
    
    self.detailView.hashtagField.textField.rx.controlEvent(.editingDidBegin)
      .map { Reactor.Action.tapEditButton }
      .bind(to: self.detailReactor.action)
      .disposed(by: self.disposeBag)
    
    self.detailView.editButton.rx.tap
      .map { Reactor.Action.tapSaveButton }
      .bind(to: self.detailReactor.action)
      .disposed(by: self.disposeBag)
        
    // MARK: State
    self.detailReactor.state
      .map { $0.isEditable }
      .distinctUntilChanged()
      .delay(.milliseconds(10), scheduler: MainScheduler.instance) // 수정 취소시, 마지막에 editable이 변경되어야해서 딜레이 설정
      .bind(onNext: self.detailView.setEditable(isEditable:))
      .disposed(by: self.disposeBag)
    
    self.detailReactor.state
      .map { $0.emoji }
      .observeOn(MainScheduler.instance)
      .bind(to: self.detailView.emojiField.rx.text)
      .disposed(by: self.disposeBag)

    self.detailReactor.state
      .map { $0.category }
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .do(onNext: self.detailView.setTitlePlaceholder(by:))
      .bind(to: self.detailView.categoryView.rx.category)
      .disposed(by: self.disposeBag)
    
    self.detailReactor.state
      .map { $0.title }
      .bind(to: self.detailView.titleField.rx.text)
      .disposed(by: self.disposeBag)

    self.detailReactor.state
      .map { $0.titleError }
      .bind(to: self.detailView.titleField.rx.errorMessage)
      .disposed(by: self.disposeBag)

    self.detailReactor.state
      .map { DateUtils.toString(format: "yyyy년 MM월 dd일 eeee 까지", date: $0.date)}
      .observeOn(MainScheduler.instance)
      .bind(to: self.detailView.dateField.rx.text)
      .disposed(by: self.disposeBag)

    self.detailReactor.state
      .map { $0.dateError }
      .bind(to: self.detailView.dateField.rx.errorMessage)
      .disposed(by: self.disposeBag)
    
    self.detailReactor.state
      .map { $0.editButtonState }
      .observeOn(MainScheduler.instance)
      .bind(to: self.detailView.editButton.rx.state)
      .disposed(by: self.disposeBag)
    
    self.detailReactor.state
      .map { $0.isPushEnable }
      .bind(to: self.detailView.notificationButton.rx.isSelected)
      .disposed(by: self.disposeBag)
    
    self.detailReactor.state
      .map { $0.memo }
      .distinctUntilChanged()
      .filter { $0 != "wrtie_placeholder_memo".localized }
      .observeOn(MainScheduler.instance)
      .bind(to: self.detailView.memoField.rx.text)
      .disposed(by: self.disposeBag)

    self.detailReactor.state
      .map { $0.hashtag }
      .distinctUntilChanged()
      .bind(to: self.detailView.hashtagField.rx.text)
      .disposed(by: self.disposeBag)
    
    self.detailReactor.state
      .map { $0.shouldDismiss }
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .bind(onNext: { [weak self] shouldDismiss in
        guard let self = self else { return }
        if shouldDismiss {
          self.delegate?.onDismiss()
          self.dismiss()
        }
      })
      .disposed(by: disposeBag)
  }
  
  private func showActionSheet() {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let deleteAction = UIAlertAction(
      title: "detail_action_sheet_delete".localized,
      style: .destructive
    ) { [weak self] action in
      guard let self = self else { return }
      AlertUtils.showWithCancel(
        viewController: self,
        title: nil,
        message: "detail_delete_message".localized
      ) {
        Observable.just(Reactor.Action.tapDeleteButton)
          .bind(to: self.detailReactor.action)
          .disposed(by: self.disposeBag)
      }
    }
    let cancelAction = UIAlertAction(
      title: "detail_action_sheet_cancel".localized,
      style: .cancel,
      handler: nil
    )
    let shereAction = UIAlertAction(
      title: "detail_action_sheet_share".localized,
      style: .default
    ) { [weak self] action in
      guard let self = self else { return }
      
      self.showSharePhoto(wish: self.wish)
    }
    
    alertController.addAction(shereAction)
    alertController.addAction(deleteAction)
    alertController.addAction(cancelAction)
    
    self.present(alertController, animated: true, completion: nil)
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
    
    self.detailView.scrollView.contentInset.bottom = keyboardViewEndFrame.height
    self.detailView.scrollView.scrollIndicatorInsets = self.detailView.scrollView.contentInset
  }
  
  private func showSharePhoto(wish: Wish) {
    let sharePhotoVC = SharePhotoVC.instance(wish: self.wish)
    
    sharePhotoVC.delegate = self
    self.present(sharePhotoVC, animated: true, completion: nil)
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    self.detailView.scrollView.contentInset.bottom = .zero
  }
}

extension DetailVC: UITextFieldDelegate {
  
  func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    guard let text = textField.text else { return true }
    let newLength = text.count + string.count - range.length
    
    if newLength >= 18 {
      self.detailView.titleField.rx.errorMessage.onNext("write_error_max_length_title".localized)
    } else {
      self.detailView.titleField.rx.errorMessage.onNext(nil)
    }
    
    return newLength <= 18
  }
}

extension DetailVC: SharePhotoDelegate {
  
  func onSuccessSave() {
    self.detailView.showFinishToast()
  }
}
