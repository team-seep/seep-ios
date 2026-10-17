import UIKit
import Combine

import CombineCocoa
import PanModal
import RxSwift
import ReactorKit

protocol WishDetailDelegate: AnyObject {
    func onUpdateCategory(category: Category)
}

enum DetailMode {
    case fromHome
    case fromFinish
}

final class WishDetailViewController: BaseVC, View, WishDetailCoordinator {
    weak var delegate: WishDetailDelegate?
    private let wishDetailView = WishDetailView()
    private let wishDetailReactor: WishDetailReactor
    private weak var coordinator: WishDetailCoordinator?
    private let mode: DetailMode
    private let stepsViewModel: WishStepsViewModel
    private let savingsViewModel: WishSavingsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(wish: Wish, mode: DetailMode) {
        self.wishDetailReactor = WishDetailReactor(
            wish: wish,
            wishService: WishService()
        )
        self.mode = mode
        self.stepsViewModel = WishStepsViewModel(config: .init(mode: .persisted(wish)))
        self.savingsViewModel = WishSavingsViewModel(config: .init(wish: wish))
        super.init(nibName: nil, bundle: nil)
    }
    
    init(reactor: WishDetailReactor, mode: DetailMode) {
        self.wishDetailReactor = reactor
        self.mode = mode
        self.stepsViewModel = WishStepsViewModel(config: .init(mode: .persisted(reactor.initialState.wish)))
        self.savingsViewModel = WishSavingsViewModel(config: .init(wish: reactor.initialState.wish))
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func instance(wish: Wish, mode: DetailMode) -> WishDetailViewController {
        return WishDetailViewController(wish: wish, mode: mode)
    }
    
    override func loadView() {
        self.view = WideScreenContainerView(contentView: self.wishDetailView)
    }
  
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // 폴더블 접기/펴기·회전으로 창 폭이 바뀌면 해시태그 줄바꿈을 새 폭으로 다시 계산한다
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.wishDetailView.hashtagCollectionView.collectionViewLayout.invalidateLayout()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = self.wishDetailReactor
        self.coordinator = self
        // 상세는 읽기 전용이지만 단계 섹션(체크)과 모으기 섹션(기록)은 바로 쓸 수 있다
        self.wishDetailView.containerView.subviews
            .filter { $0 !== self.wishDetailView.stepsView && $0 !== self.wishDetailView.savingsView }
            .forEach { $0.isUserInteractionEnabled = false }
        self.bindSteps()
        self.bindSavings()
    }
  
    override func bindEvent() {
        self.wishDetailView.moreButton.rx.tap
            .asDriver()
            .compactMap { [weak self] in
                return self?.mode
            }
            .drive(onNext: { [weak self] mode in
                guard let self = self else { return }
                self.coordinator?.showActionSheet(
                    wish: self.wishDetailReactor.currentState.wish,
                    mode: self.mode,
                    onTapShare: {
                        self.wishDetailReactor.action.onNext(.tapSharePhoto)
                    },
                    onTapDelete: {
                        self.wishDetailReactor.action.onNext(.tapDeleteButton)
                    },
                    onTapCancelFinish: {
                        self.wishDetailReactor.action.onNext(.tapCancelFinish)
                    })
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishDetailView.backButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishDetailReactor.popupWithCategoryPublisher
            .asDriver(onErrorJustReturn: .wantToDo)
            .drive(onNext: { [weak self] category in
                self?.delegate?.onUpdateCategory(category: category)
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishDetailReactor.presentSharePhotoPublisher
            .asDriver(onErrorJustReturn: Wish())
            .drive(onNext: { [weak self] wish in
                self?.coordinator?.presentSharePhoto(wish: wish)
            })
            .disposed(by: self.eventDisposeBag)
    }
    
    func bind(reactor: WishDetailReactor) {
        // MARK: State
        reactor.state
            .map { $0.wish }
            .asDriver(onErrorJustReturn: Wish())
            .drive(self.wishDetailView.rx.wish)
            .disposed(by: self.disposeBag)
    }
}

// MARK: Steps
extension WishDetailViewController {
    private func bindSteps() {
        let stepsView = wishDetailView.stepsView
        
        stepsView.didTapStepPublisher
            .subscribe(stepsViewModel.input.didTapStep)
            .store(in: &cancellables)
        
        stepsViewModel.output.steps
            .main
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, steps: [WishStep]) in
                stepsView.bind(steps: steps)
                owner.wishDetailView.setStepsHidden(steps.isEmpty)
            }
            .store(in: &cancellables)
        
        stepsViewModel.output.progress
            .main
            .sink { progress in
                stepsView.bind(progress: progress)
            }
            .store(in: &cancellables)
        
        stepsViewModel.output.isAddEnabled
            .main
            .sink { isAddEnabled in
                stepsView.bind(isAddEnabled: isAddEnabled)
            }
            .store(in: &cancellables)
        
        stepsViewModel.output.didUpdateSteps
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, steps: [WishStep]) in
                owner.wishDetailReactor.action.onNext(.updateSteps(steps))
            }
            .store(in: &cancellables)
        
        stepsViewModel.output.toast
            .main
            .sink { message in
                ToastManager.shared.show(message: message)
            }
            .store(in: &cancellables)
        
        stepsViewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, route: WishStepsViewModel.Route) in
                owner.handleStepsRoute(route)
            }
            .store(in: &cancellables)
    }
}

// MARK: Savings
extension WishDetailViewController {
    private func bindSavings() {
        let savingsView = wishDetailView.savingsView
        
        savingsView.addButton.tapPublisher
            .subscribe(savingsViewModel.input.didTapAdd)
            .store(in: &cancellables)
        
        savingsView.deleteSavingPublisher
            .subscribe(savingsViewModel.input.didTapDelete)
            .store(in: &cancellables)
        
        savingsViewModel.output.isVisible
            .main
            .sink { isVisible in
                savingsView.setCollapsed(!isVisible)
            }
            .store(in: &cancellables)
        
        savingsViewModel.output.progress
            .main
            .sink { progress in
                savingsView.bind(progress: progress)
            }
            .store(in: &cancellables)
        
        savingsViewModel.output.savings
            .main
            .sink { savings in
                savingsView.bind(savings: savings)
            }
            .store(in: &cancellables)
        
        savingsViewModel.output.didUpdateSavings
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, savings: [WishSaving]) in
                owner.wishDetailReactor.action.onNext(.updateSavings(savings))
            }
            .store(in: &cancellables)
        
        savingsViewModel.output.toast
            .main
            .sink { message in
                ToastManager.shared.show(message: message)
            }
            .store(in: &cancellables)
        
        savingsViewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, route: WishSavingsViewModel.Route) in
                owner.handleSavingsRoute(route)
            }
            .store(in: &cancellables)
    }
}

// MARK: Route
extension WishDetailViewController {
    private func handleSavingsRoute(_ route: WishSavingsViewModel.Route) {
        switch route {
        case .presentSavingInput(let viewModel):
            presentPanModal(SavingInputBottomSheetViewController(viewModel: viewModel))
        case .showDeleteAlert(let savingId):
            AlertUtils.showWithCancel(
                viewController: self,
                title: Strings.Detail.Saving.DeleteAlert.title,
                okButton: Strings.Detail.Saving.DeleteAlert.confirm
            ) { [weak self] in
                self?.savingsViewModel.input.confirmDelete.send(savingId)
            }
        case .showErrorAlert(let error):
            AlertUtils.show(viewController: self, title: nil, message: error.localizedDescription)
        }
    }
    
    private func handleStepsRoute(_ route: WishStepsViewModel.Route) {
        switch route {
        case .presentAddStepInput:
            break // 상세에서는 단계를 추가하지 않는다 (R-1). 추가는 수정 화면에서.
        case .showErrorAlert(let error):
            AlertUtils.show(viewController: self, title: nil, message: error.localizedDescription)
        }
    }
}

extension WishDetailViewController: SharePhotoDelegate {
    func onSuccessSave() {
        self.coordinator?.showToast(message: "👏이미지를 앨범에 저장했어요!")
    }
}

extension WishDetailViewController: WishEditViewControllerDelegate {
    func onUpdateWish(wish: Wish) {
        self.wishDetailReactor.action.onNext(.updateWish(wish: wish))
        self.stepsViewModel.input.reloadSteps.send(wish.steps)
        self.savingsViewModel.input.reloadWish.send(wish)
    }
}
