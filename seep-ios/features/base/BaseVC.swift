import UIKit
import RxSwift
import RxCocoa
import ReactorKit

class BaseVC: UIViewController {
  
  var disposeBag = DisposeBag()
  var eventDisposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    bindEvent()
  }
  
  func bindEvent() { }
}
