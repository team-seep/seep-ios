import UIKit
import RxSwift
import ReactorKit

class FinishedVC: BaseVC, View {
  
  private lazy var finishedView = FinishedView(frame: self.view.frame)
  private let finishedReactor: FinishedReactor
  
  
  init(category: Category) {
    self.finishedReactor = FinishedReactor(
      category: category,
      wishService: WishService(),
      userDefaults: UserDefaultsUtils()
    )
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  static func instance(category: Category) -> FinishedVC {
    return FinishedVC(category: category)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view = finishedView
    self.reactor = self.finishedReactor
    self.setupTableView()
    self.setupCollectionView()
    
    Observable.just(FinishedReactor.Action.viewDidLoad(()))
      .bind(to: self.finishedReactor.action)
      .disposed(by: self.disposeBag)
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
  
  func bind(reactor: FinishedReactor) {
    // MARK: Action
    self.finishedView.viewTypeButton.rx.tap
      .map { FinishedReactor.Action.tapViewType(()) }
      .bind(to: self.finishedReactor.action)
      .disposed(by: self.disposeBag)
    
    // MARK: State
    self.finishedReactor.state
      .map { $0.finishedWishiList }
      .distinctUntilChanged()
      .bind(to: self.finishedView.tableView.rx.items(
        cellIdentifier: FinishedTableCell.registerId,
        cellType: FinishedTableCell.self
      )) { row, wish, cell in
        cell.bind(wish: wish)
      }
      .disposed(by: self.disposeBag)
    
    self.finishedReactor.state
      .map { $0.finishedWishiList }
      .distinctUntilChanged()
      .bind(to: self.finishedView.collectionView.rx.items(
        cellIdentifier: FinishedCollectionCell.registerId,
        cellType: FinishedCollectionCell.self
      )) { row, wish, cell in
        cell.bind(wish: wish)
      }
      .disposed(by: self.disposeBag)
    
    self.finishedReactor.state
      .map { $0.isHiddenEmptyView }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.finishedView.setEmptyViewHidden(isHidden:))
      .disposed(by: self.disposeBag)
    
    self.finishedReactor.state
      .map{ $0.viewType }
      .observeOn(MainScheduler.instance)
      .do(onNext: { _ in
        FeedbackUtils.feedbackInstance.impactOccurred()
      })
      .bind(onNext: self.finishedView.changeViewType(to:))
      .disposed(by: self.disposeBag)
    
    self.finishedReactor.state
      .map { (self.finishedReactor.category, $0.finishedCount) }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.finishedView.setFinishedCount)
      .disposed(by: self.disposeBag)
  }
  
  private func popVC() {
    self.navigationController?.popViewController(animated: true)
  }
  
  private func setupTableView() {
    self.finishedView.tableView.register(
      FinishedTableCell.self,
      forCellReuseIdentifier: FinishedTableCell.registerId
    )
    
    self.finishedView.tableView.rx.itemSelected
      .map { self.finishedReactor.currentState.finishedWishiList[$0.row] }
      .bind(onNext: self.showDetail(wish:))
      .disposed(by: self.disposeBag)
  }
  
  private func setupCollectionView() {
    self.finishedView.collectionView.register(
      FinishedCollectionCell.self,
      forCellWithReuseIdentifier: FinishedCollectionCell.registerId
    )
    
    self.finishedView.collectionView.rx.itemSelected
      .map { self.finishedReactor.currentState.finishedWishiList[$0.row] }
      .bind(onNext: self.showDetail(wish:))
      .disposed(by: self.disposeBag)
  }
  
  private func showDetail(wish: Wish) {
    let detailVC = DetailVC.instance(wish: wish, mode: .fromFinish).then {
      $0.view.isUserInteractionEnabled = false
    }
    
    self.present(detailVC, animated: true, completion: nil)
  }
}
