import UIKit

class HomeVC: BaseVC {
  
  private lazy var homeView = HomeView(frame: self.view.frame)
  
  
  static func instance() -> HomeVC {
    return HomeVC(nibName: nil, bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view = homeView
    self.setupTableView()
  }
  
  private func setupTableView() {
    self.homeView.tableView.dataSource = self
    self.homeView.tableView.delegate = self
    self.homeView.tableView.register(
      HomeCountCell.self,
      forCellReuseIdentifier: HomeCountCell.registerId
    )
    self.homeView.tableView.register(
      HomeWishCell.self,
      forCellReuseIdentifier: HomeWishCell.registerId
    )
  }
}

extension HomeVC: UITableViewDataSource, UITableViewDelegate {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if section == 0 {
      return UIView(frame: .zero)
    } else {
      return HomeCategoryHeaderView()
    }
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    } else {
      return 20
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeCountCell.registerId, for: indexPath) as? HomeCountCell else { return BaseTableViewCell() }
      
      return cell
    } else {
      guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeWishCell.registerId, for: indexPath) as? HomeWishCell else { return BaseTableViewCell() }
      
      return cell
    }
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

