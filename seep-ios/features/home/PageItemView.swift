import UIKit

class PageItemView: BaseView {
  
  let pullToRefreshTableView = UIRefreshControl()
  let pullToRefreshCollectionView = UIRefreshControl()
  
  let tableView = UITableView().then {
    $0.tableFooterView = UIView()
    $0.backgroundColor = .clear
    $0.rowHeight = UITableView.automaticDimension
    $0.separatorStyle = .none
    $0.showsVerticalScrollIndicator = false
    $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
  }

  let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  ).then {
    let layout = UICollectionViewFlowLayout()
    layout.itemSize = CGSize(
      width: (UIScreen.main.bounds.width - 40 - 15) / 2,
      height: (UIScreen.main.bounds.width - 40 - 15) / 2
    )
    layout.minimumInteritemSpacing = 15
    layout.minimumLineSpacing = 16
    layout.sectionInset = UIEdgeInsets(
      top: 0,
      left: 20,
      bottom: (UIScreen.main.bounds.width - 40 - 15) / 2,
      right: 20
    )

    $0.collectionViewLayout = layout
    $0.backgroundColor = .clear
    $0.showsVerticalScrollIndicator = false
    $0.alpha = 0.0
  }

  let gradientView = UIView().then {
    let gradientLayer = CAGradientLayer()
    let topColor = UIColor(r: 246, g: 247, b: 249, a: 0.0).cgColor
    let bottomColor = UIColor(r: 246, g: 247, b: 249, a: 1.0).cgColor

    gradientLayer.colors = [topColor, bottomColor]
    gradientLayer.locations = [0.0, 1.0]
    gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 150)
    $0.layer.addSublayer(gradientLayer)
  }
  
  override func setup() {
    self.backgroundColor = UIColor(r: 246, g: 246, b: 246)
    self.tableView.refreshControl = self.pullToRefreshTableView
    self.collectionView.refreshControl = self.pullToRefreshCollectionView
    self.addSubViews(tableView, collectionView, gradientView)
  }
  
  override func bindConstraints() {
    self.tableView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.top.equalToSuperview()
    }
    
    self.collectionView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.top.equalToSuperview()
    }
    
    self.gradientView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.height.equalTo(150)
    }
  }
  
  func changeViewType(to viewType: ViewType) {
    switch viewType {
    case .grid:
      UIView.animate(withDuration: 0.3) { [weak self] in
        guard let self = self else { return }
        self.collectionView.alpha = 1.0
        self.tableView.alpha = 0.0
      }
    case .list:
      UIView.animate(withDuration: 0.3) { [weak self] in
        guard let self = self else { return }
        self.collectionView.alpha = 0.0
        self.tableView.alpha = 1.0
      }
    }
  }
}
