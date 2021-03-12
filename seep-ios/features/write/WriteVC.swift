import RxSwift
import ReactorKit

class WriteVC: BaseVC {
  
  private lazy var writeView = WriteView(frame: self.view.frame)
  
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
    
    
    self.writeView.dateField.textField.inputView = datePicker
  }
  
  override func bindEvent() {
    self.writeView.closeButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind { _ in
        self.dismiss(animated: true, completion: nil)
      }
      .disposed(by: disposeBag)
    
    self.writeView.tapBackground.rx.event
      .observeOn(MainScheduler.instance)
      .bind(onNext: { [weak self] _ in
        guard let self = self else { return }
        self.writeView.endEditing(true)
      })
      .disposed(by: disposeBag)
  }
}
