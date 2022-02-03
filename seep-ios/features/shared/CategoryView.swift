import UIKit

import RxSwift
import RxCocoa

final class CategoryView: BaseView {
    let categoryPublisher = PublishSubject<Category>()
    
    var isEditable: Bool = true {
        didSet {
            if self.isEditable {
                self.containerView.backgroundColor = UIColor(r: 232, g: 246, b: 255)
            } else {
                self.containerView.backgroundColor = .gray2
            }
        }
    }
    
    let containerView = UIView().then {
        $0.layer.cornerRadius = 24
    }
    
    private let stackView = UIStackView().then {
        $0.alignment = .leading
        $0.axis = .horizontal
        $0.distribution = .equalSpacing
        $0.backgroundColor = .clear
    }
    
    private let wantToDoButton = UIButton().then {
        $0.setTitle("common_category_want_to_do".localized, for: .normal)
        $0.setKern(kern: -0.28)
    }
    
    private let wantToGetButton = UIButton().then {
        $0.setTitle("common_category_want_to_get".localized, for: .normal)
        $0.setKern(kern: -0.28)
    }
    
    private let wantToGoButton = UIButton().then {
        $0.setTitle("common_category_want_to_go".localized, for: .normal)
        $0.setKern(kern: -0.28)
    }
    
    private let activeButton = UIButton().then {
        $0.backgroundColor = .seepBlue
        $0.layer.cornerRadius = 15
        $0.setTitleColor(.clear, for: .normal)
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
        self.addSubViews([
            self.containerView,
            self.activeButton,
            self.stackView
        ])
        
        self.wantToGoButton.rx.tap
            .map { Category.wantToGo }
            .do(onNext: { [weak self] in
                self?.moveActiveButton(category: $0)
            })
            .bind(to: self.categoryPublisher)
            .disposed(by: self.disposeBag)
        
        self.wantToDoButton.rx.tap
            .map { Category.wantToDo }
            .do(onNext: { [weak self] in
                self?.moveActiveButton(category: $0)
            })
            .bind(to: self.categoryPublisher)
            .disposed(by: self.disposeBag)
        
        self.wantToGetButton.rx.tap
            .map { Category.wantToGet }
            .do(onNext: { [weak self] in
                self?.moveActiveButton(category: $0)
            })
            .bind(to: self.categoryPublisher)
            .disposed(by: self.disposeBag)
    }
    
    override func bindConstraints() {
        self.stackView.snp.makeConstraints { make in
            make.left.equalTo(self.containerView).offset(10)
            make.top.equalTo(self.containerView).offset(8)
        }
        
        self.activeButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.stackView)
            make.height.equalTo(30)
            make.centerX.equalTo(self.stackView.arrangedSubviews[0])
        }
        
        self.containerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalTo(self.stackView).offset(10)
            make.bottom.equalTo(self.stackView).offset(8)
            make.height.equalTo(48).priority(.high)
        }
        
        self.snp.makeConstraints { make in
            make.edges.equalTo(self.containerView)
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
            
            self.wantToDoButton.setTitleColor(category == .wantToDo ? .white : UIColor(r: 136, g: 136, b: 136), for: .normal)
            self.wantToDoButton.titleLabel?.font = category == .wantToDo ? .appleExtraBold(size: 14) : .appleMedium(size: 14)
            self.wantToDoButton.contentEdgeInsets = category == .wantToDo ? UIEdgeInsets(top: 6, left: 18, bottom: 6, right: 18) : UIEdgeInsets(top: 8, left: 18, bottom: 4, right: 18)
            self.wantToGetButton.setTitleColor(category == .wantToGet ? .white : UIColor(r: 136, g: 136, b: 136), for: .normal)
            self.wantToGetButton.titleLabel?.font = category == .wantToGet ? .appleExtraBold(size: 14) : .appleMedium(size: 14)
            self.wantToGetButton.contentEdgeInsets = category == .wantToGet ? UIEdgeInsets(top: 6, left: 18, bottom: 6, right: 18) : UIEdgeInsets(top: 8, left: 18, bottom: 4, right: 18)
            self.wantToGoButton.setTitleColor(category == .wantToGo ? .white : UIColor(r: 136, g: 136, b: 136), for: .normal)
            self.wantToGoButton.titleLabel?.font = category == .wantToGo ? .appleExtraBold(size: 14) : .appleMedium(size: 14)
            self.wantToGoButton.contentEdgeInsets = category == .wantToGo ? UIEdgeInsets(top: 6, left: 18, bottom: 6, right: 18) : UIEdgeInsets(top: 8, left: 18, bottom: 4, right: 18)
        }
    }
}


extension Reactive where Base: CategoryView {
    var tapCategory: ControlEvent<Category>  {
        return .init(events: base.categoryPublisher)
    }
}

