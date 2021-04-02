import UIKit
import RxSwift
import ReactorKit

protocol PageItemDelegate: class {
  
  func onDismiss()
  func onFinishWish()
  func scrollViewWillBeginDragging()
  func scrollViewDidEndDragging()
}

class PageItemVC: BaseVC, View {
  
  weak var delegate: PageItemDelegate?
  lazy var pageItemView = PageItemView(frame: self.view.frame)
  private let pageItemReactor: PageItemReactor
  
  
  init(category: Category) {
    self.pageItemReactor = PageItemReactor(
      category: category,
      wishService: WishService(),
      userDefaults: UserDefaultsUtils()
    )
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  static func instance(category: Category) -> PageItemVC {
    return PageItemVC(category: category)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view = self.pageItemView
    self.reactor = self.pageItemReactor
    self.setupTableView()
    self.setupCollectionView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.actionFetchData()
  }
  
  func bind(reactor: PageItemReactor) {
    // MARK: Action
    self.pageItemView.pullToRefreshTableView.rx.controlEvent(.valueChanged)
      .map { PageItemReactor.Action.viewDidLoad(()) }
      .bind(to: self.pageItemReactor.action)
      .disposed(by: self.disposeBag)
    
    self.pageItemView.pullToRefreshCollectionView.rx.controlEvent(.valueChanged)
      .map { PageItemReactor.Action.viewDidLoad(()) }
      .bind(to: self.pageItemReactor.action)
      .disposed(by: self.disposeBag)
    
    self.pageItemView.tableView.rx.itemSelected
      .map { self.pageItemReactor.currentState.wishiList[$0.row] }
      .bind(onNext: self.showDetail(wish:))
      .disposed(by: self.disposeBag)
    
    self.pageItemView.collectionView.rx.itemSelected
      .map { self.pageItemReactor.currentState.wishiList[$0.row] }
      .bind(onNext: self.showDetail(wish:))
      .disposed(by: self.disposeBag)
    
    // MARK: State
    self.pageItemReactor.state
      .map { $0.wishiList }
      .bind(to: self.pageItemView.tableView.rx.items(
        cellIdentifier: HomeWishCell.registerId,
        cellType: HomeWishCell.self
      )) { row, wish, cell in
        cell.bind(wish: wish)
        cell.checkButton.rx.tap
          .map { PageItemReactor.Action.tapFinishButton(row) }
          .bind(to: self.pageItemReactor.action)
          .disposed(by: cell.disposeBag)
      }
      .disposed(by: self.disposeBag)

    self.pageItemReactor.state
      .map { $0.wishiList }
      .bind(to: self.pageItemView.collectionView.rx.items(
              cellIdentifier: HomeWishCollectionCell.registerId,
              cellType: HomeWishCollectionCell.self
      )) { row, wish, cell in
        cell.bind(wish: wish)
      }
      .disposed(by: self.disposeBag)
    
    self.pageItemReactor.state
      .map { $0.viewType }
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.pageItemView.changeViewType(to:))
      .disposed(by: self.disposeBag)
    
    self.pageItemReactor.state
      .map { $0.endRefresh }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.pageItemView.pullToRefreshTableView.endRefreshing)
      .disposed(by: self.disposeBag)
    
    self.pageItemReactor.state
      .map { $0.endRefresh }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.pageItemView.pullToRefreshCollectionView.endRefreshing)
      .disposed(by: self.disposeBag)
    
    self.pageItemReactor.state
      .map { $0.fetchHomeVC }
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .bind { [weak self] isFinish in
        if isFinish {
          self?.delegate?.onFinishWish()
        }
      }
      .disposed(by: self.disposeBag)
  }
  
  func setViewType(viewType: ViewType) {
    Observable.just(PageItemReactor.Action.setViewType(viewType))
      .bind(to: self.pageItemReactor.action)
      .disposed(by: self.disposeBag)
  }
  
  func actionFetchData() {
    Observable.just(PageItemReactor.Action.viewDidLoad(()))
      .bind(to: self.pageItemReactor.action)
      .disposed(by: self.disposeBag)
  }
  
  private func setupTableView() {
    self.pageItemView.tableView.register(
      HomeWishCell.self,
      forCellReuseIdentifier: HomeWishCell.registerId
    )
    self.pageItemView.tableView.rx
      .setDelegate(self)
      .disposed(by: self.disposeBag)
  }
  
  private func setupCollectionView() {
    self.pageItemView.collectionView.register(
      HomeWishCollectionCell.self,
      forCellWithReuseIdentifier: HomeWishCollectionCell.registerId
    )
    self.pageItemView.collectionView.rx
      .setDelegate(self)
      .disposed(by: self.disposeBag)
  }
  
  private func showDetail(wish: Wish) {
    let detailVC = DetailVC.instance(wish: wish).then {
      $0.delegate = self
    }
    
    self.present(detailVC, animated: true, completion: nil)
  }
}

extension PageItemVC: DetailDelegate {
  
  func onDismiss() {
    Observable.just(PageItemReactor.Action.viewDidLoad(()))
      .bind(to: self.pageItemReactor.action)
      .disposed(by: self.disposeBag)
    self.delegate?.onDismiss()
  }
}

extension PageItemVC: UITableViewDelegate, UICollectionViewDelegate {
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    self.delegate?.scrollViewWillBeginDragging()
  }
  
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      self.delegate?.scrollViewDidEndDragging()
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    self.delegate?.scrollViewDidEndDragging()
  }
}
