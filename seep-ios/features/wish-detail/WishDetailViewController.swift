import UIKit
import Combine
import PhotosUI
import UniformTypeIdentifiers

import CombineCocoa
import PanModal
import SafariServices
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
    private let calendarViewModel: WishCalendarViewModel
    private let linkViewModel: WishLinkViewModel
    private let placeViewModel: WishPlaceViewModel
    private let photoViewModel: WishPhotoViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(wish: Wish, mode: DetailMode) {
        self.wishDetailReactor = WishDetailReactor(
            wish: wish,
            wishService: WishService()
        )
        self.mode = mode
        self.stepsViewModel = WishStepsViewModel(config: .init(mode: .persisted(wish)))
        self.savingsViewModel = WishSavingsViewModel(config: .init(wish: wish))
        self.calendarViewModel = WishCalendarViewModel(config: .init(wish: wish, isAddable: mode == .fromHome))
        self.linkViewModel = Self.makeLinkViewModel(wish: wish)
        self.placeViewModel = WishPlaceViewModel(config: .init(mode: .persisted(wish)))
        self.photoViewModel = WishPhotoViewModel(config: .init(wish: wish))
        super.init(nibName: nil, bundle: nil)
    }
    
    init(reactor: WishDetailReactor, mode: DetailMode) {
        self.wishDetailReactor = reactor
        self.mode = mode
        self.stepsViewModel = WishStepsViewModel(config: .init(mode: .persisted(reactor.initialState.wish)))
        self.savingsViewModel = WishSavingsViewModel(config: .init(wish: reactor.initialState.wish))
        self.calendarViewModel = WishCalendarViewModel(config: .init(
            wish: reactor.initialState.wish,
            isAddable: mode == .fromHome
        ))
        self.linkViewModel = Self.makeLinkViewModel(wish: reactor.initialState.wish)
        self.placeViewModel = WishPlaceViewModel(config: .init(mode: .persisted(reactor.initialState.wish)))
        self.photoViewModel = WishPhotoViewModel(config: .init(wish: reactor.initialState.wish))
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
        // 상세는 읽기 전용이지만 단계·모으기·캘린더 버튼·링크 카드·장소·사진 섹션은 바로 쓸 수 있다
        let interactiveViews: [UIView] = [
            self.wishDetailView.stepsView,
            self.wishDetailView.savingsView,
            self.wishDetailView.calendarButton,
            self.wishDetailView.linkSectionView,
            self.wishDetailView.placeView,
            self.wishDetailView.photoView
        ]
        self.wishDetailView.containerView.subviews
            .filter { subview in !interactiveViews.contains { $0 === subview } }
            .forEach { $0.isUserInteractionEnabled = false }
        self.bindSteps()
        self.bindSavings()
        self.bindCalendar()
        self.bindLink()
        self.bindPlace()
        self.bindPhoto()
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
                    },
                    onTapDeletePhoto: self.photoViewModel.hasPhoto ? { [weak self] in
                        self?.photoViewModel.input.didTapDelete.send(())
                    } : nil)
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

// MARK: Calendar
extension WishDetailViewController {
    private func bindCalendar() {
        let calendarButton = wishDetailView.calendarButton
        
        calendarButton.tapPublisher
            .subscribe(calendarViewModel.input.didTapButton)
            .store(in: &cancellables)
        
        calendarViewModel.output.isVisible
            .main
            .sink { isVisible in
                calendarButton.isHidden = !isVisible
            }
            .store(in: &cancellables)
        
        calendarViewModel.output.isAdded
            .main
            .sink { isAdded in
                calendarButton.bind(isAdded: isAdded)
            }
            .store(in: &cancellables)
        
        calendarViewModel.output.toast
            .main
            .sink { message in
                ToastManager.shared.show(message: message)
            }
            .store(in: &cancellables)
        
        calendarViewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, route: WishCalendarViewModel.Route) in
                owner.handleCalendarRoute(route)
            }
            .store(in: &cancellables)
    }
}

// MARK: Link
extension WishDetailViewController {
    private static func makeLinkViewModel(wish: Wish) -> WishLinkViewModel {
        return WishLinkViewModel(config: .init(
            mode: .detail,
            category: wish.category,
            wishId: wish.id,
            link: wish.link
        ))
    }

    /// 링크 카드 (GH-29 R-4, R-5)
    private func bindLink() {
        let linkSectionView = wishDetailView.linkSectionView

        linkSectionView.didTapCardPublisher
            .subscribe(linkViewModel.input.didTapCard)
            .store(in: &cancellables)

        linkViewModel.output.isVisible
            .main
            .sink { isVisible in
                linkSectionView.setCollapsed(!isVisible)
            }
            .store(in: &cancellables)

        linkViewModel.output.preview
            .main
            .sink { preview in
                linkSectionView.bind(preview: preview)
            }
            .store(in: &cancellables)

        linkViewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, route: WishLinkViewModel.Route) in
                owner.handleLinkRoute(route)
            }
            .store(in: &cancellables)

        linkViewModel.input.viewDidLoad.send(())
    }
}

// MARK: Place
extension WishDetailViewController {
    private func bindPlace() {
        let placeView = wishDetailView.placeView
        
        placeView.tapPlacePublisher
            .subscribe(placeViewModel.input.didTapPlace)
            .store(in: &cancellables)
        
        placeView.deletePlacePublisher
            .subscribe(placeViewModel.input.didTapDelete)
            .store(in: &cancellables)
        
        placeViewModel.output.isVisible
            .main
            .sink { isVisible in
                placeView.setCollapsed(!isVisible)
            }
            .store(in: &cancellables)
        
        placeViewModel.output.emoji
            .main
            .sink { emoji in
                placeView.bind(emoji: emoji)
            }
            .store(in: &cancellables)
        
        placeViewModel.output.place
            .main
            .sink { place in
                placeView.bind(place: place)
            }
            .store(in: &cancellables)
        
        placeViewModel.output.didUpdatePlace
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, place: WishPlace?) in
                owner.wishDetailReactor.action.onNext(.updatePlace(place))
            }
            .store(in: &cancellables)
        
        placeViewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, route: WishPlaceViewModel.Route) in
                owner.handlePlaceRoute(route)
            }
            .store(in: &cancellables)
    }
}

// MARK: Photo
extension WishDetailViewController {
    private func bindPhoto() {
        let photoView = wishDetailView.photoView
        
        photoView.emptyButton.tapPublisher
            .subscribe(photoViewModel.input.didTapAdd)
            .store(in: &cancellables)
        
        photoView.changeButton.tapPublisher
            .subscribe(photoViewModel.input.didTapChange)
            .store(in: &cancellables)
        
        photoViewModel.output.photoURL
            .main
            .sink { photoURL in
                photoView.bind(photoURL: photoURL)
            }
            .store(in: &cancellables)
        
        photoViewModel.output.didUpdatePhoto
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, fileName: String) in
                owner.wishDetailReactor.action.onNext(.updatePhoto(fileName: fileName))
            }
            .store(in: &cancellables)
        
        photoViewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, route: WishPhotoViewModel.Route) in
                owner.handlePhotoRoute(route)
            }
            .store(in: &cancellables)
    }
    
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension WishDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let itemProvider = results.first?.itemProvider,
              itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else { return }
        
        // 원본 데이터(HEIC·JPEG 등)를 넘기고, 줄이기·저장은 저장소가 메인 스레드 밖에서 한다 (R-3)
        itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                guard let data else {
                    self.handlePhotoRoute(.showErrorAlert(WishPhotoStorageError.invalidImage))
                    return
                }
                self.photoViewModel.input.didPickPhoto.send(data)
            }
        }
    }
}

// MARK: Route
extension WishDetailViewController {
    private func handleCalendarRoute(_ route: WishCalendarViewModel.Route) {
        switch route {
        case .showAddAgainAlert:
            AlertUtils.showWithCancel(
                viewController: self,
                title: Strings.Detail.Calendar.AgainAlert.title,
                message: Strings.Detail.Calendar.AgainAlert.message,
                okButton: Strings.Detail.Calendar.AgainAlert.confirm
            ) { [weak self] in
                self?.calendarViewModel.input.confirmAddAgain.send(())
            }
        case .showPermissionDeniedAlert:
            AlertUtils.showWithCancel(
                viewController: self,
                title: Strings.Detail.Calendar.DeniedAlert.title,
                message: Strings.Detail.Calendar.DeniedAlert.message,
                okButton: Strings.Detail.Calendar.DeniedAlert.settings
            ) {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
        case .showErrorAlert(let error):
            AlertUtils.show(viewController: self, title: nil, message: error.localizedDescription)
        }
    }
    

    private func handleLinkRoute(_ route: WishLinkViewModel.Route) {
        switch route {
        case .openSafari(let url):
            present(SFSafariViewController(url: url), animated: true)
        }
    }
    
    private func handlePlaceRoute(_ route: WishPlaceViewModel.Route) {
        switch route {
        case .presentPlaceSearch(let viewModel):
            presentPanModal(PlaceSearchBottomSheetViewController(viewModel: viewModel))
        case .showErrorAlert(let error):
            AlertUtils.show(viewController: self, title: nil, message: error.localizedDescription)
        }
    }
    
    private func handlePhotoRoute(_ route: WishPhotoViewModel.Route) {
        switch route {
        case .presentPhotoPicker:
            presentPhotoPicker()
        case .showErrorAlert(let error):
            AlertUtils.show(viewController: self, title: nil, message: error.localizedDescription)
        }
    }
    
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
        self.calendarViewModel.input.reloadWish.send(wish)
        self.linkViewModel.input.reloadWish.send(wish)
        self.placeViewModel.input.reloadWish.send(wish)
    }
}
