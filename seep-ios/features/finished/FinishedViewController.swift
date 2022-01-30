import UIKit

import RxSwift
import ReactorKit

final class FinishedViewController: BaseVC, View, FinishedCoordinator {
    private let finishedView = FinishedView()
    private let finishedReactor: FinishedReactor
    private weak var coordinator: FinishedCoordinator?
    
    init(category: Category) {
        self.finishedReactor = FinishedReactor(
            category: category,
            wishService: WishService(),
            userDefaults: UserDefaultsUtils()
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = self.finishedView
    }
    
    static func instance(category: Category) -> FinishedViewController {
        return FinishedViewController(category: category)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = self.finishedReactor
        self.coordinator = self
        self.finishedReactor.action.onNext(.viewDidLoad)
    }
    
    override func bindEvent() {
        self.finishedView.backButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.finishedView.emptyBackButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.finishedReactor.pushWishDetailPublisher
            .asDriver(onErrorJustReturn: Wish())
            .drive(onNext: { [weak self] wish in
                self?.coordinator?.pushWishDetail(wish: wish)
            })
            .disposed(by: self.eventDisposeBag)
    }
    
    func bind(reactor: FinishedReactor) {
        // MARK: Action
        self.finishedView.viewTypeButton.rx.tap
            .map { FinishedReactor.Action.tapViewType }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.finishedView.tableView.rx.itemSelected
            .map { Reactor.Action.tapWish(index: $0.row) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.finishedView.collectionView.rx.itemSelected
            .map { Reactor.Action.tapWish(index: $0.row) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // MARK: State
        reactor.state
            .map { $0.finishedWishiList }
            .distinctUntilChanged()
            .bind(to: self.finishedView.tableView.rx.items(
                cellIdentifier: FinishedTableCell.registerId,
                cellType: FinishedTableCell.self
            )) { row, wish, cell in
                cell.bind(wish: wish)
            }
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.finishedWishiList }
            .distinctUntilChanged()
            .bind(to: self.finishedView.collectionView.rx.items(
                cellIdentifier: FinishedCollectionCell.registerId,
                cellType: FinishedCollectionCell.self
            )) { row, wish, cell in
                cell.bind(wish: wish)
            }
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.isHiddenEmptyView }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: true)
            .drive(onNext: { [weak self] isHiddenEmptyView in
                self?.finishedView.setEmptyViewHidden(isHidden: isHiddenEmptyView)
            })
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map{ $0.viewType }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .grid)
            .do(onNext: { _ in
                FeedbackUtils.feedbackInstance.impactOccurred()
            })
            .drive(onNext: { [weak self] viewType in
                self?.finishedView.changeViewType(to: viewType)
            })
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { (self.finishedReactor.category, $0.finishedCount) }
            .asDriver(onErrorJustReturn: (.wantToDo, 0))
            .drive(onNext: { [weak self] (category, count) in
                self?.finishedView.setFinishedCount(category: category, count: count)
            })
            .disposed(by: self.disposeBag)
    }
}

extension FinishedViewController: WishDetailDelegate {
    func onUpdateCategory(category: Category) {
        self.finishedReactor.action.onNext(.viewDidLoad)
    }
}
