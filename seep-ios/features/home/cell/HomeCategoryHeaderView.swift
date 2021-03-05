import UIKit

class HomeCategoryHeaderView: BaseView {
  
  let totalButton = UIButton().then {
    $0.setTitle("home_category_total".localized, for: .normal)
    $0.layer.cornerRadius = 6
    $0.backgroundColor = UIColor(r: 227, g: 230, b: 236)
    $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .light)
    $0.contentEdgeInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
    $0.setTitleColor(UIColor(r: 136, g: 136, b: 136), for: .normal)
  }
  
  let wantToDoButton = UIButton().then {
    $0.setTitle("home_category_want_to_do".localized, for: .normal)
    $0.layer.cornerRadius = 6
    $0.backgroundColor = UIColor(r: 227, g: 230, b: 236)
    $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .light)
    $0.contentEdgeInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
    $0.setTitleColor(UIColor(r: 136, g: 136, b: 136), for: .normal)
  }
  
  let wantToBuyButton = UIButton().then {
    $0.setTitle("home_category_want_to_buy".localized, for: .normal)
    $0.layer.cornerRadius = 6
    $0.backgroundColor = UIColor(r: 227, g: 230, b: 236)
    $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .light)
    $0.contentEdgeInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
    $0.setTitleColor(UIColor(r: 136, g: 136, b: 136), for: .normal)
  }
  
  let wantToGoButton = UIButton().then {
    $0.setTitle("home_category_want_to_go".localized, for: .normal)
    $0.layer.cornerRadius = 6
    $0.backgroundColor = UIColor(r: 227, g: 230, b: 236)
    $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .light)
    $0.contentEdgeInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
    $0.setTitleColor(UIColor(r: 136, g: 136, b: 136), for: .normal)
  }
  
  let successButton = UIButton().then {
    $0.setTitle("home_category_success".localized, for: .normal)
    $0.layer.cornerRadius = 6
    $0.backgroundColor = UIColor(r: 227, g: 230, b: 236)
    $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .light)
    $0.contentEdgeInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
    $0.setTitleColor(UIColor(r: 136, g: 136, b: 136), for: .normal)
  }
  
  override func setup() {
    self.backgroundColor = UIColor(r: 246, g: 246, b: 246)
    self.addSubViews(
      totalButton, wantToDoButton, wantToBuyButton, wantToGoButton,
      successButton
    )
  }
  
  override func bindConstraints() {
    self.totalButton.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(20)
      make.top.equalToSuperview().offset(10)
      make.bottom.equalToSuperview().offset(-10)
    }
    
    self.wantToDoButton.snp.makeConstraints { make in
      make.top.bottom.equalTo(self.totalButton)
      make.left.equalTo(self.totalButton.snp.right).offset(6)
    }

    self.wantToBuyButton.snp.makeConstraints { make in
      make.top.bottom.equalTo(self.totalButton)
      make.left.equalTo(self.wantToDoButton.snp.right).offset(6)
    }

    self.wantToGoButton.snp.makeConstraints { make in
      make.top.bottom.equalTo(self.totalButton)
      make.left.equalTo(self.wantToBuyButton.snp.right).offset(6)
    }

    self.successButton.snp.makeConstraints { make in
      make.top.bottom.equalTo(self.totalButton)
      make.left.equalTo(self.wantToGoButton.snp.right).offset(6)
    }
  }
}
