import UIKit
import Combine

import CombineCocoa

final class HomeCategoryView: BaseView {
    enum Layout {
        static let height: CGFloat = 30
    }
    
    let didTapCategory = PassthroughSubject<Category, Never>()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .leading
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.backgroundColor = .clear
        stackView.layoutMargins = .init(top: 0, left: 20, bottom: 0, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private let wantToDoButton: UIButton = {
        let button = UIButton()
        button.setTitle("common_category_want_to_do".localized, for: .normal)
        button.setKern(kern: -0.28)
        return button
    }()
    
    private let wantToGetButton: UIButton = {
        let button = UIButton()
        button.setTitle("common_category_want_to_get".localized, for: .normal)
        button.setKern(kern: -0.28)
        return button
    }()
    
    private let wantToGoButton: UIButton = {
        let button = UIButton()
        button.setTitle("common_category_want_to_go".localized, for: .normal)
        button.setKern(kern: -0.28)
        return button
    }()
    
    private let activeButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .seepBlue
        button.layer.cornerRadius = 15
        button.setTitleColor(.clear, for: .normal)
        button.layer.shadowOpacity = 0.15
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.titleLabel?.font = .appleExtraBold(size: 14)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 18, bottom: 4, right: 18)
        button.setKern(kern: -0.28)
        return button
    }()
    
    override func setup() {
        setupUI()
        bind()
        
        moveActiveButton(category: .wantToDo)
    }
    
    private func setupUI() {
        stackView.addArrangedSubview(wantToDoButton)
        stackView.addArrangedSubview(wantToGetButton)
        stackView.addArrangedSubview(wantToGoButton)
        addSubview(activeButton)
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        activeButton.snp.makeConstraints {
            $0.centerY.equalTo(stackView)
            $0.height.equalTo(30)
            $0.centerX.equalTo(stackView.arrangedSubviews[0])
        }
        
        snp.makeConstraints {
            $0.height.equalTo(Layout.height)
        }
    }
    
    private func bind() {
        let didTapWantToGo = wantToGoButton.tapPublisher
            .map { Category.wantToGo }
        
        let didTapWantToDo = wantToDoButton.tapPublisher
            .map { Category.wantToDo }
        
        let didTapWantToGet = wantToGetButton.tapPublisher
            .map { Category.wantToGet }
        
        Publishers.Merge3(didTapWantToGo, didTapWantToDo, didTapWantToGet)
            .withUnretained(self)
            .sink { (owner: HomeCategoryView, category: Category) in
                FeedbackUtils.feedbackInstance.impactOccurred()
                owner.moveActiveButton(category: category)
                owner.didTapCategory.send(category)
            }
            .store(in: &cancellables)
    }
    
    func moveActiveButton(category: Category) {
        let index = category.getIndex()
        
        activeButton.snp.remakeConstraints {
            $0.centerY.equalTo(stackView)
            $0.height.equalTo(30)
            $0.centerX.equalTo(stackView.arrangedSubviews[index])
        }
        
        activeButton.setTitle(category.rawValue.localized, for: .normal)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [weak self] in
            guard let self = self else { return }
            layoutIfNeeded()
            
            wantToDoButton.setTitleColor(category == .wantToDo ? .white : .gray4, for: .normal)
            wantToDoButton.titleLabel?.font = category == .wantToDo ? .appleExtraBold(size: 14) : .appleMedium(size: 14)
            wantToGetButton.setTitleColor(category == .wantToGet ? .white : .gray4, for: .normal)
            wantToGetButton.titleLabel?.font = category == .wantToGet ? .appleExtraBold(size: 14) : .appleMedium(size: 14)
            wantToGoButton.setTitleColor(category == .wantToGo ? .white : .gray4, for: .normal)
            wantToGoButton.titleLabel?.font = category == .wantToGo ? .appleExtraBold(size: 14) : .appleMedium(size: 14)
        }
    }
}

