import UIKit
import RxSwift
import ReactorKit

class HomeVC: BaseVC, View {
  
  private lazy var homeView = HomeView(frame: self.view.frame)
  private let homeReactor = HomeReactor(wishService: WishService())
  private let tempDisposeBag = DisposeBag()
  
  static func instance() -> HomeVC {
    return HomeVC(nibName: nil, bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view = homeView
    self.reactor = homeReactor
    self.setupTableView()
    self.homeView.startAnimation()
    
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
      .disposed(by: disposeBag)
    
    self.homeView.wantToGoButton.rx.tap
      .map { HomeReactor.Action.tapCategory(Category.wantToGo) }
      .bind(to: self.homeReactor.action)
      .disposed(by: disposeBag)
    
    self.homeView.wantToGetButton.rx.tap
      .map { HomeReactor.Action.tapCategory(Category.wantToGet) }
      .bind(to: self.homeReactor.action)
      .disposed(by: disposeBag)
    
    // MARK: State
    self.homeReactor.state
      .map { $0.wishiList }
      .bind(to: self.homeView.tableView.rx.items(
        cellIdentifier: HomeWishCell.registerId,
        cellType: HomeWishCell.self
      )) { row, wish, cell in
        cell.bind(wish: wish)
      }
      .disposed(by: disposeBag)
    
    self.homeReactor.state
      .map { $0.successCount }
      .bind(onNext: self.homeView.setSuccessCount(count:))
      .disposed(by: disposeBag)
    
    self.homeReactor.state
      .map { $0.category }
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.homeView.moveActiveButton(category:))
      .disposed(by: disposeBag)
  }
  
  private func setupTableView() {
    self.homeView.tableView.register(
      HomeWishCell.self,
      forCellReuseIdentifier: HomeWishCell.registerId
    )
  }
  
  private func showWirteVC() {
    let writeVC = WriteVC.instance().then {
      $0.delegate = self
    }
    
    self.present(writeVC, animated: true, completion: nil)
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

