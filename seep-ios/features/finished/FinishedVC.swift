import UIKit
import RxSwift
import ReactorKit

class FinishedVC: BaseVC {
  
  private lazy var finishedView = FinishedView(frame: self.view.frame)
  
  
  static func instance() -> FinishedVC {
    return FinishedVC(nibName: nil, bundle: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view = finishedView
  }
  
  override func bindEvent() {
    self.finishedView.backButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.popVC)
      .disposed(by: self.eventDisposeBag)
    
    self.finishedView.emptyBackButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.popVC)
      .disposed(by: self.eventDisposeBag)
  }
  
  private func popVC() {
    self.navigationController?.popViewController(animated: true)
  }
}
