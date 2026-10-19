import UIKit
import Combine

import CombineCocoa

final class HomeFilterHeaderView: UICollectionReusableView {
    enum Layout {
        static let height: CGFloat = 86
    }
    
    private let categoryView = HomeCategoryView()
    
    private let sortButton: UIButton = {
        let button = UIButton()
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
    
    private let viewTypeButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icGrid.image, for: .normal)
        return button
    }()
    
    /// 세 카테고리 전체 검색 진입 (GH-32 R-1). 아이콘은 작아도 터치 영역은 44pt
    private let searchButton: UIButton = {
        let button = UIButton()
        let configuration = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        button.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: configuration), for: .normal)
        button.tintColor = .gray4
        button.accessibilityLabel = Strings.Home.Search.accessibility
        return button
    }()
    
    private let placeMapButton: UIButton = {
        let button = UIButton()
        let configuration = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        button.setImage(UIImage(systemName: "map", withConfiguration: configuration), for: .normal)
        button.tintColor = .gray4
        button.accessibilityLabel = Strings.Home.Filter.placeMap
        button.isHidden = true
        return button
    }()
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 246, g: 247, b: 249, a: 1)
        return view
    }()
    
    private lazy var gradientView: UIView = {
        let view = UIView()
        view.layer.insertSublayer(gradientLayer, at: 0)
        return view
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor(r: 246, g: 247, b: 249, a: 1).cgColor, UIColor(r: 246, g: 247, b: 249, a: 0).cgColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        // 헤더 폭은 섹션(컬렉션뷰) 폭을 따르므로 그라데이션도 실제 bounds로 맞춘다
        gradientLayer.frame = gradientView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables = Set<AnyCancellable>()
    }
    
    private func setupUI() {
        addSubViews(backgroundView)
        addSubview(categoryView)
        addSubview(sortButton)
        addSubview(onlyFinishedFilterButton)
        addSubview(viewTypeButton)
        addSubview(searchButton)
        addSubview(placeMapButton)
        addSubview(gradientView)
        
        backgroundView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalTo(gradientView.snp.top)
            $0.top.equalToSuperview()
        }
        
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
        
        searchButton.snp.makeConstraints {
            $0.trailing.equalTo(viewTypeButton.snp.leading).offset(-6)
            $0.size.equalTo(44)
            $0.centerY.equalTo(sortButton)
        }
        
        placeMapButton.snp.makeConstraints {
            $0.trailing.equalTo(viewTypeButton.snp.leading).offset(-12)
            $0.size.equalTo(24)
            $0.centerY.equalTo(sortButton)
        }
        
        gradientView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(10)
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
        
        searchButton.tapPublisher
            .subscribe(viewModel.input.didTapSearch)
            .store(in: &cancellables)
        
        placeMapButton.tapPublisher
            .subscribe(viewModel.input.didTapPlaceMap)
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
                owner.viewTypeButton.setImage(viewType.toggle().image, for: .normal)
            }
            .store(in: &cancellables)
        
        viewModel.output.isPlaceMapVisible
            .main
            .withUnretained(self)
            .sink { (owner: HomeFilterHeaderView, isVisible: Bool) in
                owner.placeMapButton.isHidden = !isVisible
            }
            .store(in: &cancellables)
    }
}
