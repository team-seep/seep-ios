import UIKit
import RxSwift

class BaseVC: UIViewController {
  
  let disposeBag = DisposeBag()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    bindEvent()
  }
  
  func bindEvent() { }
}
