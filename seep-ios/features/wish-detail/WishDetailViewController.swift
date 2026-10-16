import UIKit
import Combine

import CombineCocoa
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
    private var cancellables = Set<AnyCancellable>()
    
    init(wish: Wish, mode: DetailMode) {
        self.wishDetailReactor = WishDetailReactor(
            wish: wish,
            wishService: WishService()
        )
        self.mode = mode
        self.stepsViewModel = WishStepsViewModel(config: .init(wish: wish))
        super.init(nibName: nil, bundle: nil)
    }
    
    init(reactor: WishDetailReactor, mode: DetailMode) {
        self.wishDetailReactor = reactor
        self.mode = mode
        self.stepsViewModel = WishStepsViewModel(config: .init(wish: reactor.initialState.wish))
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func instance(wish: Wish, mode: DetailMode) -> WishDetailViewController {
        return WishDetailViewController(wish: wish, mode: mode)
    }
    
    override func loadView() {
        self.view = self.wishDetailView
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = self.wishDetailReactor
        self.coordinator = self
        // 상세는 읽기 전용이지만 단계 섹션만은 바로 체크·추가할 수 있다
        self.wishDetailView.containerView.subviews
            .filter { $0 !== self.wishDetailView.stepsView }
            .forEach { $0.isUserInteractionEnabled = false }
        self.bindSteps()
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
        
        stepsView.addButton.tapPublisher
            .subscribe(stepsViewModel.input.didTapAdd)
            .store(in: &cancellables)
        
        stepsView.didTapStepPublisher
            .subscribe(stepsViewModel.input.didTapStep)
            .store(in: &cancellables)
        
        stepsView.deleteStepPublisher
            .subscribe(stepsViewModel.input.deleteStep)
            .store(in: &cancellables)
        
        stepsViewModel.output.steps
            .main
            .sink { steps in
                stepsView.bind(steps: steps)
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

// MARK: Route
extension WishDetailViewController {
    private func handleStepsRoute(_ route: WishStepsViewModel.Route) {
        switch route {
        case .presentAddStepInput:
            presentAddStepInput()
        case .showErrorAlert(let error):
            AlertUtils.show(viewController: self, title: nil, message: error.localizedDescription)
        }
    }
    
    private func presentAddStepInput() {
        let alertController = UIAlertController(
            title: Strings.Detail.Step.AddAlert.title,
            message: nil,
            preferredStyle: .alert
        )
        alertController.addTextField { textField in
            textField.placeholder = Strings.Detail.Step.AddAlert.placeholder
            textField.returnKeyType = .done
        }
        let cancelAction = UIAlertAction(title: Strings.commonCancel, style: .cancel)
        let confirmAction = UIAlertAction(
            title: Strings.Detail.Step.AddAlert.confirm,
            style: .default
        ) { [weak self, weak alertController] _ in
            let title = alertController?.textFields?.first?.text ?? ""
            self?.stepsViewModel.input.addStep.send(title)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true)
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
    }
}
