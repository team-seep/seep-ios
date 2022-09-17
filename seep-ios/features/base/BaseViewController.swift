import UIKit

import RxSwift
import RxCocoa
import ReactorKit

class BaseViewController: UIViewController {
  var disposeBag = DisposeBag()
  var eventDisposeBag = DisposeBag()
  
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.bindEvent()
  }
  
  func bindEvent() { }
}
