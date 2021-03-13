import RxSwift
import ReactorKit

class WriteVC: BaseVC, View {
  
  private lazy var writeView = WriteView(frame: self.view.frame)
  private let writeReactor = WriteReactor()
  
  private let datePicker = UIDatePicker().then {
    $0.datePickerMode = .date
    $0.preferredDatePickerStyle = .wheels
  }
  
  static func instance() -> WriteVC {
    return WriteVC(nibName: nil, bundle: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view = writeView
    self.reactor = writeReactor
    
    self.writeView.dateField.textField.inputView = datePicker
    Observable.just(WriteReactor.Action.viewDidLoad(()))
      .bind(to: self.writeReactor.action)
      .disposed(by: disposeBag)
  }
  
  override func bindEvent() {
    self.writeView.closeButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind { _ in
        self.dismiss(animated: true, completion: nil)
      }
      .disposed(by: self.eventDisposeBag)
    
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
    
    
    // MARK: State
    self.writeReactor.state
      .map { $0.category }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.writeView.moveActiveButton(category:))
      .disposed(by: self.disposeBag)
    
    self.writeReactor.state
      .filter { $0.date != nil }
      .map { DateUtils.toString(format: "yyyy년 MM월 dd일 eeee", date: $0.date ?? Date())}
      .observeOn(MainScheduler.instance)
      .bind(to: self.writeView.dateField.rx.text)
      .disposed(by: self.disposeBag)
    
    self.writeReactor.state
      .map { $0.writeButtonEnable }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.writeView.writeButtonEnable(isEnable:))
      .disposed(by: self.disposeBag)
  }
}
