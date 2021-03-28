import UIKit
import RxSwift
import ReactorKit

class DetailVC: BaseVC, View {
  
  private lazy var detailView = DetailView(frame: self.view.frame)
  private let detailReactor: DetailReactor
  private let wish: Wish
  
  init(wish: Wish) {
    self.detailReactor = DetailReactor(
      wish: wish,
      wishService: WishService()
    )
    self.wish = wish
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  static func instance(wish: Wish) -> DetailVC {
    return DetailVC(wish: wish)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view = self.detailView
    self.reactor = self.detailReactor
    self.detailView.bind(wish: wish)
  }
  
  func bind(reactor: DetailReactor) {
    // MARK: Action
    self.detailView.titleField.rx.text.orEmpty
      .skip(1)
      .map { Reactor.Action.inputTitle($0) }
      .bind(to: self.detailReactor.action)
      .disposed(by: self.disposeBag)
        
    // MARK: State
  }
}
