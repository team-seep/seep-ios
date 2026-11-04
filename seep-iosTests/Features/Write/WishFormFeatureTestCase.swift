import XCTest

@testable import seep_ios

/// 작성·수정 폼 테스트 공용 바탕 (GH-64 P2)
class WishFormFeatureTestCase: ViewModelTestCase {
    var wishRepository: MockWishRepository!
    var notificationManager: MockNotificationManager!
    var linkMetadataProvider: MockLinkMetadataProvider!
    var linkPreviewCache: MockLinkPreviewCache!
    var photoStorage: MockWishPhotoStorage!
    var userDefaults: UserDefaultsUtils!
    var now = Date(timeIntervalSince1970: 1_792_540_800) // 2026-10-20

    override func setUp() {
        super.setUp()
        wishRepository = MockWishRepository()
        notificationManager = MockNotificationManager()
        linkMetadataProvider = MockLinkMetadataProvider()
        linkPreviewCache = MockLinkPreviewCache()
        photoStorage = MockWishPhotoStorage()
        userDefaults = UserDefaultsUtils(name: "test-gh64-wish-form")
    }

    override func tearDown() {
        wishRepository = nil
        notificationManager = nil
        linkMetadataProvider = nil
        linkPreviewCache = nil
        photoStorage = nil
        userDefaults = nil
        super.tearDown()
    }

    func makeViewModel(mode: WishFormMode) -> WishFormViewModel {
        WishFormViewModel(
            config: .init(mode: mode),
            dependency: .init(
                wishRepository: wishRepository,
                notificationManager: notificationManager,
                logManager: logManager,
                userDefaults: userDefaults,
                linkMetadataProvider: linkMetadataProvider,
                linkPreviewCache: linkPreviewCache,
                photoStorage: photoStorage,
                linkPreviewDelay: nil,
                randomEmoji: { "🎲" },
                now: { [unowned self] in self.now }
            )
        )
    }

    /// 작성 폼 + 필수값(제목) 입력, 날짜 끄기 (레거시 테스트의 공통 준비와 같다)
    func makeWrite(category: seep_ios.Category, title: String = "제주도 한 달 살기") -> WishFormViewModel {
        let viewModel = makeViewModel(mode: .add(category))
        viewModel.send(.inputTitle(title))
        viewModel.send(.toggleDeadline(false))
        return viewModel
    }

    /// 수정 폼 + 날짜 끄기
    func makeEdit(_ wish: Wish) -> WishFormViewModel {
        let viewModel = makeViewModel(mode: .edit(wish))
        viewModel.send(.toggleDeadline(false))
        return viewModel
    }

    /// 저장한 위시 (route .finish)
    func finishedWish(_ viewModel: WishFormViewModel) -> Wish? {
        guard case .finish(let wish) = viewModel.route else { return nil }
        return wish
    }

    var writeClickEvents: [ClickEvent] {
        logManager.sentEvents
            .compactMap { $0 as? ClickEvent }
            .filter { ($0.extraParameters?[.objectId] as? LogObjectId) == .write }
    }
}
