import UIKit

import PanModal
import CombineCocoa

final class SortOrderBottomSheetViewController: BaseViewController {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    private let indicatorView = BottomSheetIndicator()
    
    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2
        return view
    }()
    
    private let deadlineOrderButton: UIButton = {
        let button = UIButton()
        button.setTitle("완료일 가까운순", for: .normal)
        button.titleLabel?.font = .appleSemiBold(size: 16)
        button.setTitleColor(.gray5, for: .normal)
        return button
    }()
    
    private let latestOrderButton: UIButton = {
        let button = UIButton()
        button.setTitle("최근 생성순", for: .normal)
        button.titleLabel?.font = .appleSemiBold(size: 16)
        button.setTitleColor(.gray5, for: .normal)
        return button
    }()
    
    private let viewModel: SortOrderBottomSheetViewModel
    
    init(viewModel: SortOrderBottomSheetViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bind()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        stackView.addArrangedSubview(indicatorView)
        stackView.addArrangedSubview(deadlineOrderButton)
        stackView.addArrangedSubview(divider)
        stackView.addArrangedSubview(latestOrderButton)
        view.addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-20)
        }
        
        deadlineOrderButton.snp.makeConstraints {
            $0.height.equalTo(56)
        }
        
        divider.snp.makeConstraints {
            $0.height.equalTo(1)
        }
        
        latestOrderButton.snp.makeConstraints {
            $0.height.equalTo(56)
        }
    }
    
    private func bind() {
        deadlineOrderButton.tapPublisher
            .map { HomeSortOrder.deadlineOrder }
            .subscribe(viewModel.input.didTapSortOrder)
            .store(in: &cancellables)
        
        latestOrderButton.tapPublisher
            .map { HomeSortOrder.latestOrder }
            .subscribe(viewModel.input.didTapSortOrder)
            .store(in: &cancellables)
        
        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: SortOrderBottomSheetViewController, route: SortOrderBottomSheetViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }
}

extension SortOrderBottomSheetViewController {
    private func handleRoute(_ route: SortOrderBottomSheetViewModel.Route) {
        switch route {
        case .dismiss:
            dismiss(animated: true)
        }
    }
}

extension SortOrderBottomSheetViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var shortFormHeight: PanModalHeight {
        return .contentHeight(133)
    }
    
    var longFormHeight: PanModalHeight {
        shortFormHeight
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var cornerRadius: CGFloat {
        return 16
    }
}
