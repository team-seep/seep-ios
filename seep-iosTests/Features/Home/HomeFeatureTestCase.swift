import XCTest

@testable import seep_ios_dev

/// 홈 기능 테스트 공용 바탕. 목 저장소·알림·라우터를 묶어 `HomeViewModel`을 만든다
class HomeFeatureTestCase: ViewModelTestCase {
    var repository: MockWishRepository!
    var notificationManager: MockNotificationManager!
    var linkPreviewCache: MockLinkPreviewCache!
    var photoStorage: MockWishPhotoStorage!
    var preference: Preference!
    var router: AppRouter!

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
        notificationManager = MockNotificationManager()
        linkPreviewCache = MockLinkPreviewCache()
        photoStorage = MockWishPhotoStorage()
        preference = Preference(name: "test.home.feature")
        router = AppRouter(dependency: .init(
            wishRepository: MockWishRepository(),
            deepLinkStore: Preference(name: "test.home.feature.router")
        ))
    }

    override func tearDown() {
        repository = nil
        notificationManager = nil
        linkPreviewCache = nil
        photoStorage = nil
        preference = nil
        router = nil
        super.tearDown()
    }

    func makeSut(
        preference: Preference? = nil,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current,
        remoteConfigRepository: RemoteConfigRepository = StubRemoteConfigRepository(period: nil),
        dateProvider: @escaping () -> Date = Date.init,
        widgetCheckStore: WidgetCheckStore = WidgetCheckStore(userDefaults: UserDefaults(suiteName: "test.home.feature.widget")),
        withRouter: Bool = true
    ) -> HomeViewModel {
        HomeViewModel(dependency: .init(
            wishRepository: repository,
            preference: preference ?? self.preference,
            notificationManager: notificationManager,
            logManager: logManager,
            now: now,
            calendar: calendar,
            remoteConfigRepository: remoteConfigRepository,
            linkPreviewCache: linkPreviewCache,
            dateProvider: dateProvider,
            photoStorage: photoStorage,
            widgetCheckStore: widgetCheckStore,
            router: withRouter ? router : nil
        ))
    }

    /// 목록을 넣고 화면을 띄운다
    func load(_ sut: HomeViewModel, wishes: [Wish], notFinishedCount: Int? = nil) {
        repository.fetchWishesResult = wishes
        repository.fetchNotFinishCountResult = notFinishedCount ?? wishes.filter { !$0.isSuccess }.count
        sut.send(.onAppear)
    }

    func finishNoteViewModel(of sut: HomeViewModel) -> FinishNoteViewModel? {
        if case .finishNote(let viewModel) = sut.state.sheet { return viewModel }
        return nil
    }

    func celebrationViewModel(of sut: HomeViewModel) -> BadgeCelebrationViewModel? {
        if case .badgeCelebration(let viewModel) = sut.state.sheet { return viewModel }
        return nil
    }

    func listedWishIds(of sut: HomeViewModel) -> [String] {
        sut.state.items.map(\.id)
    }

    func objectId(_ event: (any LogEventType)?) -> String? {
        event?.parameters[ParameterName.objectId.rawValue] as? String
    }

    func events(objectId: String) -> [any LogEventType] {
        logManager.sentEvents.filter { self.objectId($0) == objectId }
    }
}

/// 연말 회고 기간만 돌려주는 Remote Config 대역 (GH-34 R-9)
struct StubRemoteConfigRepository: RemoteConfigRepository {
    let period: YearReviewPeriod?

    func fetchForceUpdateVersion() async -> Result<String, Error> {
        .success("")
    }

    func fetchAndActivate() async {}

    func fetchYearReviewPeriod() -> YearReviewPeriod? {
        period
    }
}
