import UIKit
import RxSwift
import ReactorKit

class HomeVC: BaseVC, View {
  
  private lazy var homeView = HomeView(frame: self.view.frame)
  private let homeReactor = HomeReactor(
    wishService: WishService(),
    userDefaults: UserDefaultsUtils()
  )
  private let tempDisposeBag = DisposeBag()
  
  static func instance() -> HomeVC {
    return HomeVC(nibName: nil, bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view = homeView
    self.reactor = homeReactor
    self.setupTableView()
    self.setupCollectionView()
    self.homeView.startAnimation() 
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    Observable.just(HomeReactor.Action.viewDidLoad(()))
      .bind(to: self.homeReactor.action)
      .disposed(by: disposeBag)
  }
  
  override func bindEvent() {
    self.homeView.writeButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.showWirteVC)
      .disposed(by: tempDisposeBag)
  }
  
  func bind(reactor: HomeReactor) {
    // MARK: Action
    self.homeView.wantToDoButton.rx.tap
      .map { HomeReactor.Action.tapCategory(Category.wantToDo) }
      .bind(to: self.homeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.homeView.wantToGoButton.rx.tap
      .map { HomeReactor.Action.tapCategory(Category.wantToGo) }
      .bind(to: self.homeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.homeView.wantToGetButton.rx.tap
      .map { HomeReactor.Action.tapCategory(Category.wantToGet) }
      .bind(to: self.homeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.homeView.viewTypeButton.rx.tap
      .map { HomeReactor.Action.tapViewType(())}
      .bind(to: self.homeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.homeView.pullToRefresh.rx.controlEvent(.valueChanged)
      .map { HomeReactor.Action.viewDidLoad(()) }
      .bind(to: self.homeReactor.action)
      .disposed(by: self.disposeBag)
    
    self.homeView.tableView.rx.itemSelected
      .map { self.homeReactor.currentState.wishiList[$0.row] }
      .bind(onNext: self.showDetail(wish:))
      .disposed(by: self.disposeBag)
    
    self.homeView.collectionView.rx.itemSelected
      .map { self.homeReactor.currentState.wishiList[$0.row] }
      .bind(onNext: self.showDetail(wish:))
      .disposed(by: self.disposeBag)
    
    // MARK: State
    self.homeReactor.state
      .map { $0.wishiList }
      .bind(to: self.homeView.tableView.rx.items(
        cellIdentifier: HomeWishCell.registerId,
        cellType: HomeWishCell.self
      )) { row, wish, cell in
        cell.bind(wish: wish)
      }
      .disposed(by: self.disposeBag)
    
    self.homeReactor.state
      .map { $0.wishiList }
      .bind(to: self.homeView.collectionView.rx.items(
              cellIdentifier: HomeWishCollectionCell.registerId,
              cellType: HomeWishCollectionCell.self
      )) { row, wish, cell in
        cell.bind(wish: wish)
      }
      .disposed(by: self.disposeBag)
    
    self.homeReactor.state
      .map { $0.successCount }
      .bind(onNext: self.homeView.setSuccessCount(count:))
      .disposed(by: self.disposeBag)
    
    self.homeReactor.state
      .map { ($0.category, $0.wishCount) }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.homeView.setWishCount)
      .disposed(by: self.disposeBag)
    
    self.homeReactor.state
      .map { $0.category }
      .skip(1)
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.homeView.moveActiveButton(category:))
      .disposed(by: self.disposeBag)
    
    self.homeReactor.state
      .map { $0.viewType }
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.homeView.changeViewType(to:))
      .disposed(by: self.disposeBag)
    
    self.homeReactor.state
      .map { $0.endRefresh }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.homeView.pullToRefresh.endRefreshing)
      .disposed(by: self.disposeBag)
  }
  
  private func setupTableView() {
    self.homeView.tableView.register(
      HomeWishCell.self,
      forCellReuseIdentifier: HomeWishCell.registerId
    )
    self.homeView.tableView.dragInteractionEnabled = true
    self.homeView.tableView.dragDelegate = self
    self.homeView.tableView.rx.itemMoved
      .bind { itemMoveEvent in
        print("Source index: \(itemMoveEvent.sourceIndex)")
        print("destenation index: \(itemMoveEvent.destinationIndex)")
      }
      .disposed(by: self.disposeBag)
  }
  
  private func setupCollectionView() {
    self.homeView.collectionView.register(
      HomeWishCollectionCell.self,
      forCellWithReuseIdentifier: HomeWishCollectionCell.registerId
    )
    self.homeView.collectionView.dragInteractionEnabled = true
    self.homeView.collectionView.dragDelegate = self
  }
  
  private func showWirteVC() {
    let writeVC = WriteVC.instance().then {
      $0.delegate = self
    }
    
    self.present(writeVC, animated: true, completion: nil)
  }
  
  private func showDetail(wish: Wish) {
    let detailVC = DetailVC.instance(wish: wish).then {
      $0.delegate = self
    }
    
    self.present(detailVC, animated: true, completion: nil)
  }
}

extension HomeVC: UITableViewDelegate {
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    self.homeView.hideWriteButton()
  }
  
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      self.homeView.showWriteButton()
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    self.homeView.showWriteButton()
  }
}

extension HomeVC: WriteDelegate {
  
  func onSuccessWrite() {
    Observable.just(HomeReactor.Action.viewDidLoad(()))
      .bind(to: self.homeReactor.action)
      .disposed(by: disposeBag)
  }
}

extension HomeVC: DetailDelegate {
  
  func onDismiss() {
    Observable.just(HomeReactor.Action.viewDidLoad(()))
      .bind(to: self.homeReactor.action)
      .disposed(by: disposeBag)
  }
}

extension HomeVC: UITableViewDragDelegate {
  
  func tableView(
    _ tableView: UITableView,
    itemsForBeginning session: UIDragSession,
    at indexPath: IndexPath
  ) -> [UIDragItem] {
    let wish = self.homeReactor.currentState.wishiList[indexPath.row]
    let dragItem = UIDragItem(itemProvider: NSItemProvider())
    
    dragItem.localObject = wish
    return [dragItem]
  }
}

extension HomeVC: UICollectionViewDragDelegate {
  
  func collectionView(
    _ collectionView: UICollectionView,
    itemsForBeginning session: UIDragSession,
    at indexPath: IndexPath
  ) -> [UIDragItem] {
    let wish = self.homeReactor.currentState.wishiList[indexPath.row]
    let dragItem = UIDragItem(itemProvider: NSItemProvider())
    
    dragItem.localObject = wish
    return [dragItem]
  }
}

