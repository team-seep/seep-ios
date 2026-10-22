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
    /// 문서형 머리·섹션 구성·상단 바(수정·⋯) (GH-59)
    private let viewModel: WishDetailViewModel
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
        self.viewModel = WishDetailViewModel(config: .init(wish: wish, mode: mode))
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
        self.viewModel = WishDetailViewModel(config: .init(wish: reactor.initialState.wish, mode: mode))
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
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = self.wishDetailReactor
        self.coordinator = self
        self.bindDocument()
        self.bindSteps()
        self.bindSavings()
        self.bindCalendar()
        self.bindLink()
        self.bindPlace()
        self.bindPhoto()
    }
  
    override func bindEvent() {
        self.wishDetailView.navigationBar.backButton.rx.tap
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
        // 단계 체크·기록·수정 저장으로 바뀐 위시를 문서 머리·섹션 구성에 반영한다 (R-11)
        reactor.state
            .map { $0.wish }
            .subscribe(onNext: { [weak self] wish in
                self?.viewModel.input.updateWish.send(wish)
            })
            .disposed(by: self.disposeBag)
    }
}

// MARK: Document
extension WishDetailViewController {
    private func bindDocument() {
        let detailView = wishDetailView
        detailView.navigationBar.setEditVisible(viewModel.output.isEditVisible)

        detailView.navigationBar.editButton.tapPublisher
            .subscribe(viewModel.input.didTapEdit)
            .store(in: &cancellables)

        detailView.navigationBar.moreButton.tapPublisher
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, _) in
                owner.viewModel.input.didTapMore.send(.init(
                    isCalendarVisible: owner.calendarViewModel.output.isVisible.value,
                    isCalendarAdded: owner.calendarViewModel.output.isAdded.value,
                    hasPhoto: owner.photoViewModel.hasPhoto
                ))
            }
            .store(in: &cancellables)

        viewModel.output.summary
            .main
            .sink { summary in
                detailView.bind(summary: summary)
            }
            .store(in: &cancellables)

        viewModel.output.sections
            .main
            .sink { sections in
                detailView.apply(sections: sections)
            }
            .store(in: &cancellables)

        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: WishDetailViewController, route: WishDetailViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }

    private func handleMoreMenu(item: DetailMoreMenu.Item) {
        switch item {
        case .addCalendar:
            calendarViewModel.input.didTapButton.send(())
        case .share:
            wishDetailReactor.action.onNext(.tapSharePhoto)
        case .deletePhoto:
            photoViewModel.input.didTapDelete.send(())
        case .delete:
            wishDetailReactor.action.onNext(.tapDeleteButton)
        case .cancelFinish:
            wishDetailReactor.action.onNext(.tapCancelFinish)
        }
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
            .sink { steps in
                stepsView.bind(steps: steps)
            }
            .store(in: &cancellables)
        
        let stepsSection = wishDetailView.stepsSection
        stepsViewModel.output.progress
            .main
            .sink { progress in
                stepsView.bind(progress: progress)
                // "단계 1/2" (R-6)
                stepsSection.setCount(progress.map {
                    Strings.Detail.Section.stepCountFormat($0.doneCount, $0.totalCount)
                })
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
        
        wishDetailView.savingsSection.actionButton.tapPublisher
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
    /// "캘린더에 추가"는 ⋯ 메뉴로 옮겼다 (GH-59 R-9). 상태(isVisible·isAdded)는 메뉴를 열 때 읽는다.
    private func bindCalendar() {
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

    /// 링크 (GH-29 R-4, R-5). 노출은 `DetailSectionBuilder`가 정한다
    private func bindLink() {
        let linkView = wishDetailView.linkView

        // 링크 줄 탭과 섹션 "열기" 모두 Safari 로 연다 (GH-59 R-6)
        linkView.didTapPublisher
            .merge(with: wishDetailView.linkSection.actionButton.tapPublisher)
            .subscribe(linkViewModel.input.didTapCard)
            .store(in: &cancellables)

        linkViewModel.output.preview
            .main
            .sink { preview in
                linkView.bind(state: preview)
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
        
        // 장소 없음 "＋ 장소 붙이기"와 섹션 "변경" (GH-59 R-6)
        placeView.tapPlacePublisher
            .merge(with: wishDetailView.placeSection.actionButton.tapPublisher)
            .subscribe(placeViewModel.input.didTapPlace)
            .store(in: &cancellables)
        
        placeView.deletePlacePublisher
            .subscribe(placeViewModel.input.didTapDelete)
            .store(in: &cancellables)
        
        placeViewModel.output.emoji
            .main
            .sink { emoji in
                placeView.bind(emoji: emoji)
            }
            .store(in: &cancellables)
        
        let placeSection = wishDetailView.placeSection
        placeViewModel.output.place
            .main
            .sink { place in
                placeView.bind(place: place)
                placeSection.setActionHidden(place == nil)
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
        
        let photoSection = wishDetailView.photoSection
        photoSection.actionButton.tapPublisher
            .subscribe(photoViewModel.input.didTapChange)
            .store(in: &cancellables)
        
        photoViewModel.output.photoURL
            .main
            .sink { photoURL in
                photoView.bind(photoURL: photoURL)
                photoSection.setActionHidden(photoURL == nil)
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
    private func handleRoute(_ route: WishDetailViewModel.Route) {
        switch route {
        case .pushEdit(let wish):
            coordinator?.pushEdit(wish: wish)
        case .showMoreMenu(let items):
            coordinator?.showMoreMenu(items: items) { [weak self] item in
                self?.handleMoreMenu(item: item)
            }
        }
    }

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
