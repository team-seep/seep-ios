import UIKit
import RxSwift
import ReactorKit

class HomeVC: BaseVC, View {
  
  private lazy var homeView = HomeView(frame: self.view.frame)
  private let homeReactor = HomeReactor(
    wishService: WishService(),
    userDefaults: UserDefaultsUtils()
  )
  private let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
  private var pageViewControllers: [UIViewController] = []
  
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  static func instance() -> UINavigationController {
    let homeVC = HomeVC(nibName: nil, bundle: nil)

    return UINavigationController(rootViewController: homeVC).then {
      $0.setNavigationBarHidden(true, animated: false)
      $0.interactivePopGestureRecognizer?.delegate = nil
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view = homeView
    self.reactor = homeReactor
    self.registerNotification()
    self.setupPageVC()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
     
    self.homeView.startEmojiAnimation()
    Observable.just(HomeReactor.Action.viewDidLoad)
      .bind(to: self.homeReactor.action)
      .disposed(by: disposeBag)
  }
  
  override func bindEvent() {
    self.homeView.successCountButton.rx.tap
      .map { self.homeReactor.currentState.category }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.goToFinish)
      .disposed(by: self.eventDisposeBag)
    
    self.homeView.writeButton.rx.tap
      .map { self.homeReactor.currentState.category }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.showWirteVC(category:))
      .disposed(by: self.eventDisposeBag)
    
    self.homeReactor.presentWritePublisher
      .asDriver(onErrorJustReturn: Category.wantToDo)
      .drive { [weak self] category in
        self?.showWirteVC(category: category)
      }
      .disposed(by: self.eventDisposeBag)
  }
  
  func bind(reactor: HomeReactor) {
    // MARK: Action
    self.homeView.categoryView.rx.tapCategory
      .map { HomeReactor.Action.tapCategory($0)}
      .do(onNext: { _ in
        FeedbackUtils.feedbackInstance.impactOccurred()
      })
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
    
    self.homeView.viewTypeButton.rx.tap
      .map { HomeReactor.Action.tapViewType }
      .do(onNext: { _ in
        FeedbackUtils.feedbackInstance.impactOccurred()
      })
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
    
    // MARK: State
    reactor.state
      .map { ($0.category, $0.successCount) }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.homeView.setSuccessCount)
      .disposed(by: self.disposeBag)
    
    reactor.state
      .map { ($0.category, $0.wishCount) }
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.homeView.setWishCount)
      .disposed(by: self.disposeBag)
    
    reactor.state
        .map { $0.category }
        .skip(1)
        .distinctUntilChanged()
        .observeOn(MainScheduler.instance)
        .asDriver(onErrorJustReturn: .wantToDo)
        .drive(onNext: { [weak self] category in
            self?.movePageView(category: category)
            self?.homeView.emojiView.bind(category: category)
        })
        .disposed(by: self.disposeBag)
    
    reactor.state
      .map { $0.viewType }
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .do(onNext: self.setViewType(viewType:))
      .bind(onNext: self.homeView.changeViewType(to:))
      .disposed(by: self.disposeBag)
    
    reactor.state
      .map { $0.writeButtonTitle }
      .distinctUntilChanged()
      .bind(to: self.homeView.writeButton.rx.title())
      .disposed(by: self.disposeBag)
  }
  
  private func setupPageVC() {
    self.pageViewControllers = [
      PageItemVC.instance(category: .wantToDo).then {
        $0.delegate = self
      },
      PageItemVC.instance(category: .wantToGet).then {
        $0.delegate = self
      },
      PageItemVC.instance(category: .wantToGo).then {
        $0.delegate = self
      }
    ]
    self.addChild(self.pageVC)
    self.pageVC.delegate = self
    self.pageVC.dataSource = self
    self.homeView.containerView.addSubview(self.pageVC.view)
    self.pageVC.view.snp.makeConstraints { make in
      make.edges.equalTo(self.homeView.containerView)
    }
    self.pageVC.setViewControllers(
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
  
  private func goToFinish(category: Category) {
    let finishedVC = FinishedVC.instance(category: category)
    
    self.navigationController?.pushViewController(finishedVC, animated: true)
  }
  
  func showWirteVC(category: Category) {
    let writeVC = WriteViewController.instance(category: category).then {
      $0.delegate = self
    }
    
    self.present(writeVC, animated: true, completion: nil)
  }
  
  private func movePageView(category: Category) {
    guard let currentViewControllerIndex = self.pageViewControllers.firstIndex(of: self.pageVC.viewControllers![0]) else { return }
    
    switch category {
    case .wantToDo:
      self.pageVC.setViewControllers(
        [self.pageViewControllers[0]],
        direction: .reverse,
        animated: true,
        completion: nil
      )
    case .wantToGet:
      self.pageVC.setViewControllers(
        [self.pageViewControllers[1]],
        direction: currentViewControllerIndex > 1 ? .reverse : .forward,
        animated: true,
        completion: nil
      )
    case .wantToGo:
      self.pageVC.setViewControllers(
        [self.pageViewControllers[2]],
        direction: .forward,
        animated: true,
        completion: nil
      )
    }
  }
  
  private func setViewType(viewType: ViewType) {
    if let viewControllers = self.pageVC.viewControllers {
      if !viewControllers.isEmpty {
        if let pageItemVC = viewControllers[0] as? PageItemVC {
          pageItemVC.setViewType(viewType: viewType)
        }
      }
    }
  }
  
  private func fetchPageVC() {
    if let viewControllers = self.pageVC.viewControllers {
      if !viewControllers.isEmpty {
        if let pageItemVC = viewControllers[0] as? PageItemVC {
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
  
  @objc private func willEnterForeground() {
    self.homeView.startEmojiAnimation()
  }
}

extension HomeVC: WriteDelegate {
  
  func onSuccessWrite(category: Category) {
    self.homeReactor.action.onNext(.viewDidLoad)
    self.homeReactor.action.onNext(.tapCategory(category))
    self.fetchPageVC()
  }
}

extension HomeVC: PageItemDelegate {
  
  func onDismiss() {
    Observable.just(HomeReactor.Action.viewDidLoad)
      .bind(to: self.homeReactor.action)
      .disposed(by: disposeBag)
  }
  
  func onFinishWish() {
    self.showFinishAlert()
    Observable.just(HomeReactor.Action.viewDidLoad)
      .bind(to: self.homeReactor.action)
      .disposed(by: disposeBag)
  }
  
  func scrollViewWillBeginDragging() {
    self.homeView.hideWriteButton()
  }
  
  func scrollViewDidEndDragging() {
    self.homeView.showWriteButton()
  }
}

extension HomeVC: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
  
  func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerBefore viewController: UIViewController
  ) -> UIViewController? {
    guard let viewControllerIndex = self.pageViewControllers.firstIndex(of: viewController) else {
      return nil
    }
    
    let previousIndex = viewControllerIndex - 1
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
    guard let viewControllerIndex = self.pageViewControllers.firstIndex(of: viewController) else {
      return nil
    }
    
    let nextIndex = viewControllerIndex + 1
    
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
      guard let viewControllerIndex = self.pageViewControllers.firstIndex(of: self.pageVC.viewControllers![0]) else {
        return
      }
      
      switch viewControllerIndex {
      case 0:
        Observable.just(HomeReactor.Action.tapCategory(.wantToDo))
          .bind(to: self.homeReactor.action)
          .disposed(by: self.disposeBag)
      case 1:
        Observable.just(HomeReactor.Action.tapCategory(.wantToGet))
          .bind(to: self.homeReactor.action)
          .disposed(by: self.disposeBag)
      case 2:
        Observable.just(HomeReactor.Action.tapCategory(.wantToGo))
          .bind(to: self.homeReactor.action)
          .disposed(by: self.disposeBag)
      default:
        break
      }
    }
  }
}
