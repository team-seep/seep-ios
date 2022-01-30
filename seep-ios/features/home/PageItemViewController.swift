import UIKit

import RxSwift
import ReactorKit

protocol PageItemDelegate: AnyObject {
    func onDismiss()
    
    func onFinishWish()
    
    func scrollViewWillBeginDragging()
    
    func scrollViewDidEndDragging()
}

final class PageItemViewController: BaseVC, View, PageItemCoordinator {
    weak var delegate: PageItemDelegate?
    private weak var coordinator: PageItemCoordinator?
    private let pageItemView = PageItemView()
    private let pageItemReactor: PageItemReactor
    
    init(category: Category) {
        self.pageItemReactor = PageItemReactor(
            category: category,
            wishService: WishService(),
            userDefaults: UserDefaultsUtils()
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func instance(category: Category) -> PageItemViewController {
        return PageItemViewController(category: category)
    }
    
    override func loadView() {
        self.view = self.pageItemView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = self.pageItemReactor
        self.coordinator = self
        self.setupTableView()
        self.setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.actionFetchData()
    }
    
    override func bindEvent() {
        self.pageItemReactor.fetchHomeViewControllerPublisher
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] in
                self?.delegate?.onFinishWish()
            })
            .disposed(by: self.eventDisposeBag)
        
        self.pageItemReactor.presentWishDetailPublisher
            .asDriver(onErrorJustReturn: Wish())
            .drive(onNext: { [weak self] wish in
                self?.coordinator?.presentWishDetail(wish: wish)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.pageItemReactor.endRefreshingPublisher
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] in
                self?.pageItemView.pullToRefreshTableView.endRefreshing()
                self?.pageItemView.pullToRefreshCollectionView.endRefreshing()
            })
            .disposed(by: self.eventDisposeBag)
    }
    
    func bind(reactor: PageItemReactor) {
        // MARK: Action
        self.pageItemView.pullToRefreshTableView.rx
            .controlEvent(.valueChanged)
            .map { PageItemReactor.Action.viewWillAppear }
            .bind(to: self.pageItemReactor.action)
            .disposed(by: self.disposeBag)
        
        self.pageItemView.pullToRefreshCollectionView.rx
            .controlEvent(.valueChanged)
            .map { PageItemReactor.Action.viewWillAppear }
            .bind(to: self.pageItemReactor.action)
            .disposed(by: self.disposeBag)
        
        self.pageItemView.tableView.rx.itemSelected
            .map { Reactor.Action.tapWish(index: $0.row) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.pageItemView.collectionView.rx.itemSelected
            .map { Reactor.Action.tapWish(index: $0.row) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // MARK: State
        self.pageItemReactor.state
            .map { $0.wishList }
            .bind(to: self.pageItemView.tableView.rx.items(
                cellIdentifier: HomeWishTableViewCell.registerId,
                cellType: HomeWishTableViewCell.self
            )) { row, wish, cell in
                cell.bind(wish: wish)
                cell.checkButton.rx.tap
                    .map { Reactor.Action.tapFinishButton(index: row) }
                    .bind(to: reactor.action)
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: self.disposeBag)
        
        self.pageItemReactor.state
            .map { $0.wishList }
            .distinctUntilChanged()
            .bind(to: self.pageItemView.collectionView.rx.items(
                cellIdentifier: HomeWishCollectionViewCell.registerId,
                cellType: HomeWishCollectionViewCell.self
            )) { row, wish, cell in
                cell.bind(wish: wish)
                cell.checkButton.rx.tap
                    .map { Reactor.Action.tapFinishButton(index: row) }
                    .bind(to: reactor.action)
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: self.disposeBag)
        
        self.pageItemReactor.state
            .map { $0.viewType }
            .asDriver(onErrorJustReturn: .grid)
            .distinctUntilChanged()
            .drive(self.pageItemView.rx.viewType)
            .disposed(by: self.disposeBag)
        
        self.pageItemReactor.state
            .map { $0.isEmptyMessageHidden }
            .distinctUntilChanged()
            .bind(to: self.pageItemView.emptyLabel.rx.isHidden)
            .disposed(by: self.disposeBag)
    }
    
    func setViewType(viewType: ViewType) {
        self.pageItemReactor.action.onNext(.setViewType(viewType))
    }
    
    func actionFetchData() {
        self.pageItemReactor.action.onNext(.viewWillAppear)
    }
    
    private func setupTableView() {
        self.pageItemView.tableView.rx
            .setDelegate(self)
            .disposed(by: self.disposeBag)
    }
    
    private func setupCollectionView() {
        self.pageItemView.collectionView.rx
            .setDelegate(self)
            .disposed(by: self.disposeBag)
    }
}

extension PageItemViewController: WishDetailDelegate {
    func onUpdateCategory(category: Category) {
        self.pageItemReactor.action.onNext(.viewWillAppear)
        self.delegate?.onDismiss()
    }
}

extension PageItemViewController: UITableViewDelegate, UICollectionViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.delegate?.scrollViewWillBeginDragging()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.delegate?.scrollViewDidEndDragging()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.delegate?.scrollViewDidEndDragging()
    }
}
