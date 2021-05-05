import UIKit
import RxSwift
import RxCocoa

class CategoryView: BaseView {
  
  let categoryPublisher = PublishSubject<Category>()
  
  private let stackView = UIStackView().then {
    $0.alignment = .leading
    $0.axis = .horizontal
    $0.distribution = .equalSpacing
    $0.backgroundColor = .clear
  }
  
  private let wantToDoButton = UIButton().then {
    $0.setTitle("common_category_want_to_do".localized, for: .normal)
    $0.setTitleColor(UIColor(r: 136, g: 136, b: 136), for: .normal)
    $0.titleLabel?.font = .appleMedium(size: 14)
    $0.contentEdgeInsets = UIEdgeInsets(top: 6, left: 18, bottom: 4, right: 18)
    $0.setKern(kern: -0.28)
  }
  
  private let wantToGetButton = UIButton().then {
    $0.setTitle("common_category_want_to_get".localized, for: .normal)
    $0.setTitleColor(UIColor(r: 136, g: 136, b: 136), for: .normal)
    $0.titleLabel?.font = .appleMedium(size: 14)
    $0.contentEdgeInsets = UIEdgeInsets(top: 6, left: 18, bottom: 4, right: 18)
    $0.setKern(kern: -0.28)
  }
  
  private let wantToGoButton = UIButton().then {
    $0.setTitle("common_category_want_to_go".localized, for: .normal)
    $0.setTitleColor(UIColor(r: 136, g: 136, b: 136), for: .normal)
    $0.titleLabel?.font = .appleMedium(size: 14)
    $0.contentEdgeInsets = UIEdgeInsets(top: 6, left: 18, bottom: 4, right: 18)
    $0.setKern(kern: -0.28)
  }
  
  private let activeButton = UIButton().then {
    $0.backgroundColor = .seepBlue
    $0.layer.cornerRadius = 15
    $0.setTitleColor(.white, for: .normal)
    $0.layer.shadowOpacity = 0.15
    $0.layer.shadowColor = UIColor.black.cgColor
    $0.layer.shadowOffset = CGSize(width: 0, height: 2)
    $0.titleLabel?.font = .appleExtraBold(size: 14)
    $0.contentEdgeInsets = UIEdgeInsets(top: 4, left: 18, bottom: 4, right: 18)
    $0.setKern(kern: -0.28)
  }
  
  override func setup() {
    self.stackView.addArrangedSubview(wantToDoButton)
    self.stackView.addArrangedSubview(wantToGetButton)
    self.stackView.addArrangedSubview(wantToGoButton)
    self.addSubViews(stackView, activeButton)
    
    self.wantToGoButton.rx.tap
      .map { Category.wantToGo }
      .bind(to: self.categoryPublisher)
      .disposed(by: self.disposeBag)
    
    self.wantToDoButton.rx.tap
      .map { Category.wantToDo }
      .bind(to: self.categoryPublisher)
      .disposed(by: self.disposeBag)
    
    self.wantToGetButton.rx.tap
      .map { Category.wantToGet }
      .bind(to: self.categoryPublisher)
      .disposed(by: self.disposeBag)
  }
  
  override func bindConstraints() {
    self.stackView.snp.makeConstraints { make in
      make.left.equalToSuperview()
      make.top.equalToSuperview()
    }
    
    self.activeButton.snp.makeConstraints { make in
      make.centerY.equalTo(self.stackView)
      make.height.equalTo(30)
      make.centerX.equalTo(self.stackView.arrangedSubviews[0])
    }
    
    self.snp.makeConstraints { make in
      make.edges.equalTo(self.stackView)
    }
  }
  
  func moveActiveButton(category: Category) {
    let index = category.getIndex()

    self.activeButton.snp.remakeConstraints { make in
      make.centerY.equalTo(self.stackView)
      make.height.equalTo(30)
      make.centerX.equalTo(self.stackView.arrangedSubviews[index])
    }
    
    self.activeButton.setTitle(category.rawValue.localized, for: .normal)
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [weak self] in
      guard let self = self else { return }
      self.layoutIfNeeded()
    }
  }
}


extension Reactive where Base: CategoryView {
  
  var tapCategory: ControlEvent<Category>  {
    return .init(events: base.categoryPublisher)
  }
  
  var category: Binder<Category> {
    return Binder(self.base) { view, category in
      view.moveActiveButton(category: category)
    }
  }
}

