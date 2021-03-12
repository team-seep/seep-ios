import UIKit
import RxSwift
import RxCocoa
import ReactorKit

class BaseVC: UIViewController {
  
  var disposeBag = DisposeBag()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    bindEvent()
  }
  
  func bindEvent() { }
}
