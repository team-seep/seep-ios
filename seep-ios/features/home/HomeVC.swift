import UIKit
import RxSwift

class HomeVC: BaseVC {
  
  private lazy var homeView = HomeView(frame: self.view.frame)
  
  
  static func instance() -> HomeVC {
    return HomeVC(nibName: nil, bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view = homeView
    self.setupTableView()
    self.homeView.startAnimation()
  }
  
  override func bindEvent() {
    self.homeView.wantToGetButton.rx.tap.observeOn(MainScheduler.instance)
      .map { 1 }
      .bind(onNext: self.homeView.moveActiveButton(index:))
      .disposed(by: disposeBag)
    
    self.homeView.wantToDoButton.rx.tap.observeOn(MainScheduler.instance)
      .map { 0 }
      .bind(onNext: self.homeView.moveActiveButton(index:))
      .disposed(by: disposeBag)
    
    self.homeView.wantToGoButton.rx.tap.observeOn(MainScheduler.instance)
      .map { 2 }
      .bind(onNext: self.homeView.moveActiveButton(index:))
      .disposed(by: disposeBag)
  }
  
  private func setupTableView() {
    self.homeView.tableView.dataSource = self
    self.homeView.tableView.delegate = self
    self.homeView.tableView.register(
      HomeWishCell.self,
      forCellReuseIdentifier: HomeWishCell.registerId
    )
  }
}

extension HomeVC: UITableViewDataSource, UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 20
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeWishCell.registerId, for: indexPath) as? HomeWishCell else { return BaseTableViewCell() }
    
    return cell
  }
  
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

