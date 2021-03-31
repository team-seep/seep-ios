import UIKit
import RxSwift
import ReactorKit

class PageItemVC: BaseVC, View {
  
  private lazy var pageItemView = PageItemView(frame: self.view.frame)
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
    
    Observable.just(PageItemReactor.Action.viewDidLoad(()))
      .bind(to: self.pageItemReactor.action)
      .disposed(by: self.disposeBag)
  }
  
  func bind(reactor: PageItemReactor) {
    // MARK: Action
    self.pageItemView.pullToRefresh.rx.controlEvent(.valueChanged)
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
      .bind(onNext: self.pageItemView.pullToRefresh.endRefreshing)
      .disposed(by: self.disposeBag)
  }
  
  func setViewType(viewType: ViewType) {
    Observable.just(PageItemReactor.Action.setViewType(viewType))
      .bind(to: self.pageItemReactor.action)
      .disposed(by: self.disposeBag)
  }
  
  private func setupTableView() {
    self.pageItemView.tableView.register(
      HomeWishCell.self,
      forCellReuseIdentifier: HomeWishCell.registerId
    )
  }
  
  private func setupCollectionView() {
    self.pageItemView.collectionView.register(
      HomeWishCollectionCell.self,
      forCellWithReuseIdentifier: HomeWishCollectionCell.registerId
    )
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
  }
}

