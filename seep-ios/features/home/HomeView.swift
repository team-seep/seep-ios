import UIKit

class HomeView: BaseView {
  
  let tableView = UITableView().then {
    $0.tableFooterView = UIView()
    $0.backgroundColor = .clear
    $0.rowHeight = UITableView.automaticDimension
    $0.separatorStyle = .none
    $0.sectionHeaderHeight = UITableView.automaticDimension
    $0.estimatedSectionHeaderHeight = 1
    $0.showsVerticalScrollIndicator = false
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
  
  let writeButton = UIButton().then {
    $0.setTitle("home_write_button".localized, for: .normal)
    $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    $0.backgroundColor = UIColor(r: 56, g: 202, b: 79)
    $0.layer.cornerRadius = 25
    $0.contentEdgeInsets = UIEdgeInsets(top: 15, left: 30, bottom: 15, right: 30)
  }
  
  
  override func setup() {
    self.backgroundColor = UIColor(r: 246, g: 246, b: 246)
    self.addSubViews(tableView, gradientView, writeButton)
  }
  
  override func bindConstraints() {
    self.tableView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.top.equalTo(safeAreaLayoutGuide)
    }
    
    self.gradientView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.height.equalTo(150)
    }
    
    self.writeButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.height.equalTo(50)
      make.bottom.equalTo(safeAreaLayoutGuide).offset(-24)
    }
  }
  
  func showWriteButton() {
    UIView.transition(with: self.writeButton, duration: 0.3, options: .curveEaseInOut) {
      self.writeButton.alpha = 1.0
      self.writeButton.transform = .identity
    }
  }
  
  func hideWriteButton() {
    UIView.transition(with: self.writeButton, duration: 0.3, options: .curveEaseInOut) {
      self.writeButton.alpha = 0.0
      self.writeButton.transform = .init(translationX: 0, y: 100)
    }
  }
}
