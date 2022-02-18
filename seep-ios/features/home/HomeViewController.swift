import UIKit

import RxSwift
import ReactorKit

final class HomeViewController: BaseVC, View, HomeCoordinator {
    private let homeView = HomeView()
    private let homeReactor = HomeReactor(
        wishService: WishService(),
        userDefaults: UserDefaultsUtils(),
        remoteConfigService: RemoteConfigService()
    )
    private weak var coordinator: HomeCoordinator?
    
    private let pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal,
        options: nil
    )
    private let pageViewControllers: [PageItemViewController] = [
        PageItemViewController.instance(category: .wantToDo),
        PageItemViewController.instance(category: .wantToGet),
        PageItemViewController.instance(category: .wantToGo)
    ]
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    static func instance() -> UINavigationController {
        let homeVC = HomeViewController(nibName: nil, bundle: nil)
        
        return UINavigationController(rootViewController: homeVC).then {
            $0.setNavigationBarHidden(true, animated: false)
            $0.interactivePopGestureRecognizer?.delegate = nil
        }
    }
    
    override func loadView() {
        self.view = self.homeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = homeReactor
        self.coordinator = self
        self.registerNotification()
        self.setupPageViewController()
        self.homeView.categoryView.moveActiveButton(category: .wantToDo)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.homeView.startEmojiAnimation()
        Observable.just(HomeReactor.Action.viewWillAppear)
            .bind(to: self.homeReactor.action)
            .disposed(by: self.disposeBag)
    }
    
    override func bindEvent() {
        self.homeReactor.presentWritePublisher
            .asDriver(onErrorJustReturn: Category.wantToDo)
            .drive(onNext: { [weak self] category in
                self?.coordinator?.presentWrite(category: category)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.homeReactor.showNoticePublisher
            .asDriver(onErrorJustReturn: "")
            .filter { !$0.isEmpty }
            .drive(onNext: { [weak self] url in
                if UserDefaultsUtils().getNoticeDisableToday() != DateUtils.todayString() {
                    self?.showNoticeAlert(url: url)
                }
            })
            .disposed(by: self.eventDisposeBag)
        
        self.homeReactor.pushFinishPublisher
            .asDriver(onErrorJustReturn: .wantToDo)
            .drive(onNext: { [weak self] category in
                self?.coordinator?.pushFinish(category: category)
            })
            .disposed(by: self.eventDisposeBag)
    }
    
    func bind(reactor: HomeReactor) {
        // MARK: Action
        self.homeView.successCountButton.rx.tap
            .map { Reactor.Action.tapSuccessCountButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.homeView.categoryView.rx.tapCategory
            .map { Reactor.Action.tapCategory($0)}
            .do(onNext: { _ in
                FeedbackUtils.feedbackInstance.impactOccurred()
            })
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.homeView.viewTypeButton.rx.tap
            .map { Reactor.Action.tapViewTypeButton }
            .do(onNext: { _ in
                FeedbackUtils.feedbackInstance.impactOccurred()
            })
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.homeView.writeButton.rx.tap
            .map { Reactor.Action.tapWriteButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // MARK: State
        reactor.state
            .map { ($0.category, $0.wishCount) }
            .asDriver(onErrorJustReturn: (.wantToDo, 0))
            .drive(self.homeView.rx.wishCount)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { ($0.category, $0.successCount) }
            .asDriver(onErrorJustReturn: (.wantToDo, 0))
            .drive(self.homeView.rx.successCount)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.category }
            .skip(1)
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .wantToDo)
            .do(onNext: { [weak self] category in
                self?.movePageView(category: category)
            })
            .drive(self.homeView.rx.category)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.viewType }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .grid)
            .do(onNext: { [weak self] viewType in
                self?.setViewType(viewType: viewType)
            })
            .drive(self.homeView.rx.viewType)
            .disposed(by: self.disposeBag)
    }
    
    private func setupPageViewController() {
        for viewController in self.pageViewControllers {
            viewController.delegate = self
        }
        self.addChild(self.pageViewController)
        self.pageViewController.delegate = self
        self.pageViewController.dataSource = self
        self.homeView.containerView.addSubview(self.pageViewController.view)
        self.pageViewController.view.snp.makeConstraints { make in
            make.edges.equalTo(self.homeView.containerView)
        }
        self.pageViewController.setViewControllers(
            [self.pageViewControllers[0]],
            direction: .forward,
            animated: false,
            completion: nil
        )
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func movePageView(category: Category) {
        guard let currentPageViewController = self.pageViewController.viewControllers?[0] as? PageItemViewController,
              let currentIndex = self.pageViewControllers.firstIndex(of: currentPageViewController) else {
            return
        }
        
        switch category {
        case .wantToDo:
            self.pageViewController.setViewControllers(
                [self.pageViewControllers[0]],
                direction: .reverse,
                animated: true,
                completion: nil
            )
        case .wantToGet:
            self.pageViewController.setViewControllers(
                [self.pageViewControllers[1]],
                direction: currentIndex > 1 ? .reverse : .forward,
                animated: true,
                completion: nil
            )
        case .wantToGo:
            self.pageViewController.setViewControllers(
                [self.pageViewControllers[2]],
                direction: .forward,
                animated: true,
                completion: nil
            )
        }
    }
    
    private func setViewType(viewType: ViewType) {
        if let viewControllers = self.pageViewController.viewControllers {
            if !viewControllers.isEmpty {
                if let pageItemVC = viewControllers[0] as? PageItemViewController {
                    pageItemVC.setViewType(viewType: viewType)
                }
            }
        }
    }
    
    private func fetchPageVC() {
        if let viewControllers = self.pageViewController.viewControllers {
            if !viewControllers.isEmpty {
                if let pageItemVC = viewControllers[0] as? PageItemViewController {
                    pageItemVC.actionFetchData()
                }
            }
        }
    }
    
    private func showFinishAlert() {
        AlertUtils.show(
            viewController: self,
            title: "home_finish_alert_title".localized,
            message: "home_finish_alert_description".localized
        )
    }
    
    private func showNoticeAlert(url: String) {
        let doNotShowAction = UIAlertAction(title: "오늘 하루 보지 않지", style: .default) { _ in
            UserDefaultsUtils().setNoticeDisableToday()
        }
        let showMoreAction = UIAlertAction(title: "자세히 보기", style: .default) { _ in
            guard let url = URL(string: url) else { return }
            
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
        AlertUtils.show(
            viewController: self,
            title: "업데이트 공지",
            message: "2.0.0 업데이트로 인한 데이터 초기화 오류에 대해 안내해드리겠습니다.",
            actions: [doNotShowAction, showMoreAction]
        )
    }
    
    @objc private func willEnterForeground() {
        self.homeView.startEmojiAnimation()
    }
}

extension HomeViewController: WriteDelegate {
    func onSuccessWrite(category: Category) {
        self.homeReactor.action.onNext(.viewWillAppear)
        self.homeReactor.action.onNext(.tapCategory(category))
        self.fetchPageVC()
    }
}

extension HomeViewController: PageItemDelegate {
    func onDismiss() {
        self.homeReactor.action.onNext(.viewWillAppear)
    }
    
    func onFinishWish() {
        self.showFinishAlert()
        self.homeReactor.action.onNext(.viewWillAppear)
    }
    
    func scrollViewWillBeginDragging() {
        self.homeView.hideWriteButton()
    }
    
    func scrollViewDidEndDragging() {
        self.homeView.showWriteButton()
    }
}

extension HomeViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let pageItemViewController = viewController as? PageItemViewController,
              let index = self.pageViewControllers.firstIndex(of: pageItemViewController) else {
            return nil
        }
        let previousIndex = index - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard self.pageViewControllers.count > previousIndex else {
            return nil
        }
        
        return self.pageViewControllers[previousIndex]
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let pageItemViewController = viewController as? PageItemViewController,
              let index = self.pageViewControllers.firstIndex(of: pageItemViewController) else {
            return nil
        }
        let nextIndex = index + 1
        
        guard nextIndex < self.pageViewControllers.count else {
            return nil
        }
        
        guard self.pageViewControllers.count > nextIndex else {
            return nil
        }
        
        return self.pageViewControllers[nextIndex]
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if completed {
            guard let currentViewController = self.pageViewController.viewControllers?[0] as? PageItemViewController,
                  let currentIndex = self.pageViewControllers.firstIndex(of: currentViewController) else {
                return
            }
            
            switch currentIndex {
            case 0:
                self.homeView.categoryView.moveActiveButton(category: .wantToDo)
                Observable.just(HomeReactor.Action.tapCategory(.wantToDo))
                    .bind(to: self.homeReactor.action)
                    .disposed(by: self.disposeBag)
            case 1:
                self.homeView.categoryView.moveActiveButton(category: .wantToGet)
                Observable.just(HomeReactor.Action.tapCategory(.wantToGet))
                    .bind(to: self.homeReactor.action)
                    .disposed(by: self.disposeBag)
            case 2:
                self.homeView.categoryView.moveActiveButton(category: .wantToGo)
                Observable.just(HomeReactor.Action.tapCategory(.wantToGo))
                    .bind(to: self.homeReactor.action)
                    .disposed(by: self.disposeBag)
            default:
                break
            }
        }
    }
}
