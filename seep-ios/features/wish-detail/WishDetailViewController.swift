import UIKit

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
    
    init(wish: Wish, mode: DetailMode) {
        self.wishDetailReactor = WishDetailReactor(
            wish: wish,
            wishService: WishService()
        )
        self.mode = mode
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
        self.wishDetailView.containerView.isUserInteractionEnabled = false
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
                    mode: self.mode,
                    onTapShare: {
                        self.wishDetailReactor.action.onNext(.tapSharePhoto)
                    },
                    onTapDelete: {
                        self.wishDetailReactor.action.onNext(.tapDeleteButton)
                    },
                    onTapCancelFinish: {
//                        self.wishDetailReactor.action.onNext(.tapCancelFinish)
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
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: Wish())
            .drive(self.wishDetailView.rx.wish)
            .disposed(by: self.disposeBag)
    }
}

extension WishDetailViewController: SharePhotoDelegate {
    func onSuccessSave() {
        self.coordinator?.showToast(message: "👏이미지를 앨범에 저장했어요!")
    }
}
