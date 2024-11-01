import UIKit
import Combine

import CombineCocoa

final class HomeFilterHeaderView: UICollectionReusableView {
    enum Layout {
        static let size = CGSize(width: UIUtils.windowBounds.width, height: 86)
    }
    
    private let categoryView = HomeCategoryView()
    
    private let sortButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.Home.Filter.Sort.deadline, for: .normal)
        button.setTitleColor(.gray4, for: .normal)
        button.titleLabel?.font = .appleMedium(size: 14)
        button.setKern(kern: -0.02)
        
        let icon = Assets.Icons.icChevronDown.image
            .resizeImage(scaledTo: 16)
            .withRenderingMode(.alwaysTemplate)
        button.setImage(icon, for: .normal)
        button.tintColor = .gray4
        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()
    
    private let onlyFinishedFilterButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.Home.Filter.onlyFinished, for: .normal)
        button.setTitleColor(.gray4, for: .normal)
        button.titleLabel?.font = .appleMedium(size: 14)
        button.setKern(kern: -0.02)
        
        let normalIcon = Assets.Icons.icCheckOff.image
            .resizeImage(scaledTo: 24)
            .withRenderingMode(.alwaysTemplate)
        button.setImage(normalIcon, for: .normal)
        
        let selectedIcon = Assets.Icons.icCheckOn.image
            .resizeImage(scaledTo: 24)
        button.setImage(selectedIcon, for: .selected)
        button.tintColor = .gray3
        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()
    
    let viewTypeButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icGrid.image, for: .normal)
        return button
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables = Set<AnyCancellable>()
    }
    
    private func setupUI() {
        backgroundColor = HomeViewController.Constant.backgroundColor
        addSubview(categoryView)
        addSubview(sortButton)
        addSubview(onlyFinishedFilterButton)
        addSubview(viewTypeButton)
        
        categoryView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.top.equalToSuperview()
        }
        
        sortButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.top.equalTo(categoryView.snp.bottom).offset(18)
        }
        
        onlyFinishedFilterButton.snp.makeConstraints {
            $0.leading.equalTo(sortButton.snp.trailing).offset(12)
            $0.centerY.equalTo(sortButton)
        }
        
        viewTypeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.size.equalTo(24)
            $0.centerY.equalTo(sortButton)
        }
    }
    
    func bind(viewModel: HomeFilterHeaderViewModel) {
        // Input
        categoryView.didTapCategory
            .subscribe(viewModel.input.didTapCategory)
            .store(in: &cancellables)
        
        sortButton.tapPublisher
            .subscribe(viewModel.input.didTapSortOrder)
            .store(in: &cancellables)
        
        onlyFinishedFilterButton.tapPublisher
            .subscribe(viewModel.input.didTapOnlyFinished)
            .store(in: &cancellables)
        
        viewTypeButton.tapPublisher
            .subscribe(viewModel.input.didTapViewType)
            .store(in: &cancellables)
        
        // Output
        viewModel.output.category
            .main
            .withUnretained(self)
            .sink { (owner: HomeFilterHeaderView, category: Category) in
                owner.categoryView.moveActiveButton(category: category)
            }
            .store(in: &cancellables)
        
        viewModel.output.sortOrder
            .main
            .withUnretained(self)
            .sink { (owner: HomeFilterHeaderView, sortOrder: HomeSortOrder) in
                owner.sortButton.setTitle(sortOrder.title, for: .normal)
            }
            .store(in: &cancellables)
        
        viewModel.output.onlyFinished
            .main
            .withUnretained(self)
            .sink { (owner: HomeFilterHeaderView, onlyFinished: Bool) in
                owner.onlyFinishedFilterButton.isSelected = onlyFinished
            }
            .store(in: &cancellables)
        
        viewModel.output.viewType
            .main
            .withUnretained(self)
            .sink { (owner: HomeFilterHeaderView, viewType: ViewType) in
                owner.viewTypeButton.setImage(viewType.image, for: .normal)
            }
            .store(in: &cancellables)
    }
}
