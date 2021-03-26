import UIKit
import RxSwift
import ReactorKit

class DetailVC: BaseVC, View {
  
  private lazy var detailView = DetailView(frame: self.view.frame)
  private let detailReactor: DetailReactor
  
  
  init(wish: Wish) {
    self.detailReactor = DetailReactor(
      wish: wish,
      wishService: WishService()
    )
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
  }
  
  func bind(reactor: DetailReactor) {
    // MARK: Action
    self.detailView.titleField.rx.text.orEmpty
      .skip(1)
      .map { Reactor.Action.inputTitle($0) }
      .bind(to: self.detailReactor.action)
      .disposed(by: self.disposeBag)
    
    
    // MARK: State
    self.detailReactor.state
      .map { $0.emoji }
      .bind(to: self.detailView.emojiField.rx.text)
      .disposed(by: self.disposeBag)
    
    self.detailReactor.state
      .map { $0.category }
      .bind(onNext: self.detailView.moveActiveButton(category:))
      .disposed(by: self.disposeBag)
    
    self.detailReactor.state
      .map { $0.title }
      .bind(to: self.detailView.titleField.rx.text)
      .disposed(by: self.disposeBag)
    
    self.detailReactor.state
      .map { DateUtils.toString(format: "yyyy년 MM월 dd일 eeee", date: $0.date) }
      .bind(to: self.detailView.dateField.rx.text)
      .disposed(by: self.disposeBag)
    
    self.detailReactor.state
      .map { $0.isPushEnable }
      .bind(to: self.detailView.notificationButton.rx.isSelected)
      .disposed(by: self.disposeBag)
    
    self.detailReactor.state
      .map { $0.memo }
      .bind(to: self.detailView.memoField.rx.text)
      .disposed(by: self.disposeBag)
    
    self.detailReactor.state
      .map { $0.hashtag }
      .bind(to: self.detailView.hashtagField.rx.text)
      .disposed(by: self.disposeBag)
  }
}
