import UIKit
import RxSwift
import RxCocoa

class ShareCategoryButton: UIButton {
  
  let selectedIndicator = UIView().then {
    $0.backgroundColor = .tennisGreen
    $0.isHidden = true
    $0.layer.cornerRadius = 0.5
  }
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    self.setup()
    self.bindConstraints()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.addSubViews(selectedIndicator)
    self.backgroundColor = .white
    self.setTitleColor(.black, for: .normal)
    self.titleLabel?.font = .appleRegular(size: 16)
  }
  
  private func bindConstraints() {
    self.selectedIndicator.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(12)
      make.right.equalToSuperview().offset(-12)
      make.bottom.equalToSuperview()
      make.height.equalTo(1)
    }
  }
}

extension Reactive where Base: ShareCategoryButton {
  
  var isSelected: Binder<Bool> {
    return Binder(self.base) { view, isSelected in
      view.selectedIndicator.isHidden = !isSelected
    }
  }
}
