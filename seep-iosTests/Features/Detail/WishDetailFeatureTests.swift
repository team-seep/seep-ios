import XCTest

@testable import seep_ios_dev

/// 위시 상세 상단 바(수정·⋯)·⋯ 메뉴·문서 갱신·삭제·완료 취소 (GH-59, GH-64 TC-601~606)
final class WishDetailFeatureTests: ViewModelTestCase {
    private var mockRepository: MockWishRepository!
    private var mockNotificationManager: MockNotificationManager!
    private var mockStorage: MockWishPhotoStorage!
    private var mockLinkPreviewCache: MockLinkPreviewCache!
    private var mockCalendarManager: MockCalendarManager!
    private var preference: Preference!
    private var calendar: Calendar!
    /// 2026-10-20(화) 15:00 KST
    private var now: Date!

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        mockNotificationManager = MockNotificationManager()
        mockStorage = MockWishPhotoStorage()
        mockLinkPreviewCache = MockLinkPreviewCache()
        mockCalendarManager = MockCalendarManager()
        preference = Preference(name: "test-gh64-detail-\(UUID().uuidString)")
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: 15))
    }

    override func tearDown() {
        mockRepository = nil
        mockNotificationManager = nil
        mockStorage = nil
        mockLinkPreviewCache = nil
        mockCalendarManager = nil
        preference = nil
        calendar = nil
        now = nil
        super.tearDown()
    }

    private func makeWish(endDate: Date? = nil, isSuccess: Bool = false, photoFileName: String = "") -> Wish {
        Wish(
            id: "wish-1",
            emoji: "🎧",
            category: .wantToGet,
            title: "에어팟 프로 3",
            endDate: endDate,
            memo: "연말 보너스 나오면 사기",
            isSuccess: isSuccess,
            photoFileName: photoFileName
        )
    }

    private func makeViewModel(wish: Wish, mode: DetailMode) -> WishDetailViewModel {
        mockRepository.fetchWishResult = [wish]
        let now = self.now ?? Date()
        return WishDetailViewModel(
            config: .init(wishId: wish.id, mode: mode),
            dependency: .init(
                wishRepository: mockRepository,
                notificationManager: mockNotificationManager,
                logManager: logManager,
                preference: preference,
                photoStorage: mockStorage,
                linkMetadataProvider: MockLinkMetadataProvider(),
                linkPreviewCache: mockLinkPreviewCache,
                calendarManager: mockCalendarManager,
                now: { now },
                calendar: calendar
            )
        )
    }

    private func menuItems(_ route: WishDetailViewModel.Route?) -> [DetailMoreMenu.Item]? {
        guard case .moreMenu(let items) = route else { return nil }
        return items
    }

    // MARK: GH-59 TC6

    func test_GH59_TC6_홈에서연상세에서_수정을탭하면_수정화면Route와_detail_edit로그1건() {
        // Given
        let wish = makeWish()
        let viewModel = makeViewModel(wish: wish, mode: .fromHome)

        // When
        viewModel.send(.tapEdit)

        // Then
        guard case .edit(let pushed) = viewModel.route else {
            return XCTFail("수정 화면 Route 가 없다")
        }
        XCTAssertEqual(pushed.id, wish.id)
        let events = clickEvents(objectId: .detailEdit)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        XCTAssertEqual(events.first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }

    func test_GH59_TC6_수정화면으로는_최신위시를넘긴다() {
        // Given 단계 체크 등으로 상세의 위시가 바뀌었다
        let viewModel = makeViewModel(wish: makeWish(), mode: .fromHome)
        var updated = makeWish()
        updated.title = "에어팟 프로 3 화이트"
        viewModel.send(.editFinished(updated))

        // When
        viewModel.send(.tapEdit)

        // Then
        guard case .edit(let pushed) = viewModel.route else {
            return XCTFail("수정 화면 Route 가 없다")
        }
        XCTAssertEqual(pushed.title, "에어팟 프로 3 화이트")
    }

    // MARK: GH-59 TC7

    func test_GH59_TC7_완료목록에서연상세는_수정버튼이없고_탭이와도무시한다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(isSuccess: true), mode: .fromFinish)

        // When
        viewModel.send(.tapEdit)

        // Then
        XCTAssertFalse(viewModel.isEditVisible)
        XCTAssertNil(viewModel.route)
        XCTAssertTrue(clickEvents(objectId: .detailEdit).isEmpty)
    }

    func test_GH59_TC7_홈에서연상세는_수정버튼이보인다() {
        // Given / When
        let viewModel = makeViewModel(wish: makeWish(), mode: .fromHome)

        // Then
        XCTAssertTrue(viewModel.isEditVisible)
    }

    // MARK: GH-59 TC8

    // GH-61 R-9: 사진 지우기는 수정 문서로 옮겨 홈 상세 메뉴에는 없다
    func test_GH59_TC8_홈상세_날짜사진있으면_캘린더공유삭제순이고_수정하기없음_detail_more로그1건() {
        // Given
        mockStorage.existingFileNames = ["wish-1-photo.jpg"]
        let viewModel = makeViewModel(wish: makeWish(endDate: now, photoFileName: "wish-1-photo.jpg"), mode: .fromHome)

        // When
        viewModel.send(.tapMore)

        // Then
        let items = menuItems(viewModel.route)
        XCTAssertEqual(items, [.addCalendar(isAdded: false), .share, .delete])
        XCTAssertEqual(items?.map(\.title), ["캘린더에 추가", "공유하기", "삭제하기"])
        XCTAssertFalse(items?.map(\.title).contains("수정하기") ?? true)
        XCTAssertEqual(items?.filter(\.isDestructive), [.delete])
        let events = clickEvents(objectId: .detailMore)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
    }

    func test_GH59_TC8_사진이없으면_사진지우기가없다() {
        // Given
        let items = DetailMoreMenu.items(context: .init(
            mode: .fromHome,
            isCalendarVisible: true,
            isCalendarAdded: false,
            hasPhoto: false
        ))

        // Then
        XCTAssertEqual(items, [.addCalendar(isAdded: false), .share, .delete])
    }

    // MARK: GH-59 TC9

    func test_GH59_TC9_완료상세메뉴는_완료취소하기가있고_캘린더수정하기는없다() {
        // Given
        mockStorage.existingFileNames = ["wish-1-photo.jpg"]
        let viewModel = makeViewModel(
            wish: makeWish(endDate: now, isSuccess: true, photoFileName: "wish-1-photo.jpg"),
            mode: .fromFinish
        )

        // When
        viewModel.send(.tapMore)

        // Then
        XCTAssertEqual(menuItems(viewModel.route), [.cancelFinish, .deletePhoto, .share])
    }

    func test_GH59_TC9_완료모드는_캘린더상태와상관없이_캘린더항목이없다() {
        // Given
        let items = DetailMoreMenu.items(context: .init(
            mode: .fromFinish,
            isCalendarVisible: true,
            isCalendarAdded: true,
            hasPhoto: false
        ))

        // Then
        XCTAssertEqual(items, [.cancelFinish, .share])
    }

    // MARK: GH-59 TC10

    func test_GH59_TC10_날짜없는위시는_캘린더에추가가없다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(endDate: nil), mode: .fromHome)

        // When
        viewModel.send(.tapMore)

        // Then
        XCTAssertEqual(menuItems(viewModel.route), [.share, .delete])
    }

    func test_GH59_TC10_이미추가했으면_캘린더에추가됨으로보인다() {
        // Given
        let items = DetailMoreMenu.items(context: .init(
            mode: .fromHome,
            isCalendarVisible: true,
            isCalendarAdded: true,
            hasPhoto: false
        ))

        // Then
        XCTAssertEqual(items.first, .addCalendar(isAdded: true))
        XCTAssertEqual(items.first?.title, "캘린더에 추가됨")
    }

    // MARK: GH-59 TC16

    func test_GH59_TC16_수정저장후위시가바뀌면_제목메모DDay와섹션이새값이된다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(), mode: .fromHome)
        var updated = makeWish(endDate: calendar.date(byAdding: .day, value: 3, to: now))
        updated.title = "에어팟 맥스"
        updated.memo = ""

        // When
        viewModel.send(.editFinished(updated))

        // Then
        let summary = viewModel.state.summary
        XCTAssertEqual(summary?.title, "에어팟 맥스")
        XCTAssertNil(summary?.memo)
        XCTAssertEqual(summary?.ddayLine.text, "D-3")
        XCTAssertFalse(viewModel.state.sections.contains(.memo))
    }

    // MARK: GH-59 TC19

    func test_GH59_TC19_메뉴에서캘린더에추가를고르면_add_calendar로그1건() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(endDate: now), mode: .fromHome)

        // When
        viewModel.send(.selectMoreItem(.addCalendar(isAdded: false)))

        // Then
        let events = clickEvents(objectId: .addCalendar)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        XCTAssertEqual(mockCalendarManager.savedDrafts.count, 1)
    }

    // MARK: GH-64 TC601

    func test_GH64_TC601_열면저장소에서위시를읽어_문서머리와섹션을만든다() {
        // Given / When
        let viewModel = makeViewModel(wish: makeWish(endDate: calendar.date(byAdding: .day, value: 61, to: now)), mode: .fromHome)

        // Then
        XCTAssertEqual(mockRepository.fetchWishCalledIds, ["wish-1"])
        XCTAssertEqual(viewModel.state.summary?.title, "에어팟 프로 3")
        XCTAssertEqual(viewModel.state.summary?.ddayLine.text, "D-61")
        // GH-61 R-9: 사진·편지는 값이 있을 때만
        XCTAssertEqual(viewModel.state.sections, [.memo])
        XCTAssertNotNil(viewModel.steps)
        XCTAssertNotNil(viewModel.photo)
    }

    func test_GH64_TC601_다시나타났을때다른곳에서바뀐위시를반영하고_지워졌으면닫는다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(), mode: .fromHome)
        var changed = makeWish()
        changed.title = "에어팟 4"
        mockRepository.fetchWishResult = [changed]

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(viewModel.state.summary?.title, "에어팟 4")

        // When
        mockRepository.fetchWishResult = []
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(viewModel.route, .close)
    }

    // MARK: GH-64 TC602

    func test_GH64_TC602_홈상세는수정버튼이있고_이룬싶상세는없다() {
        // Given / When
        let fromHome = makeViewModel(wish: makeWish(), mode: .fromHome)
        let fromFinish = makeViewModel(wish: makeWish(isSuccess: true), mode: .fromFinish)

        // Then
        XCTAssertTrue(fromHome.isEditVisible)
        XCTAssertFalse(fromFinish.isEditVisible)
    }

    // MARK: GH-64 TC603

    func test_GH64_TC603_메뉴항목고르기는_공유는공유화면_삭제와완료취소는확인알럿으로간다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(), mode: .fromHome)

        // When / Then
        viewModel.send(.selectMoreItem(.share))
        XCTAssertEqual(viewModel.route, .sharePhoto(makeWish()))
        viewModel.send(.selectMoreItem(.delete))
        XCTAssertEqual(viewModel.route, .confirmDelete)
        XCTAssertTrue(mockRepository.deleteWishCalledIds.isEmpty)
        viewModel.send(.selectMoreItem(.cancelFinish))
        XCTAssertEqual(viewModel.route, .confirmCancelFinish)
        XCTAssertTrue(mockRepository.cancelFinishCalledIds.isEmpty)
    }

    // MARK: GH-64 TC604

    func test_GH64_TC604_삭제를확인하면_저장소삭제_알림취소_사진링크캐시캘린더기록정리후_닫는다() {
        // Given
        preference.setCalendarEventId("event-1", wishId: "wish-1")
        let viewModel = makeViewModel(wish: makeWish(), mode: .fromHome)

        // When
        viewModel.send(.confirmDelete)

        // Then
        XCTAssertEqual(mockRepository.deleteWishCalledIds, ["wish-1"])
        XCTAssertEqual(mockNotificationManager.cancelledWishes.map(\.id), ["wish-1"])
        XCTAssertEqual(mockStorage.deletePhotosCalledWishIds, ["wish-1"])
        XCTAssertEqual(mockLinkPreviewCache.removedWishIds, ["wish-1"])
        XCTAssertNil(preference.calendarEventId(wishId: "wish-1"))
        XCTAssertEqual(viewModel.route, .close)
    }

    // MARK: GH-64 TC605

    func test_GH64_TC605_완료취소를확인하면_완료가풀리고_알림을다시예약한뒤_닫는다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(endDate: now, isSuccess: true), mode: .fromFinish)

        // When
        viewModel.send(.confirmCancelFinish)

        // Then
        XCTAssertEqual(mockRepository.cancelFinishCalledIds, ["wish-1"])
        XCTAssertEqual(mockNotificationManager.reservedWishes.map(\.id), ["wish-1"])
        XCTAssertEqual(mockNotificationManager.reservedWishes.first?.isSuccess, false)
        XCTAssertEqual(viewModel.route, .close)
    }

    func test_GH64_TC605_완료취소저장에실패하면_닫지않고_에러알럿을띄운다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(isSuccess: true), mode: .fromFinish)
        mockRepository.cancelFinishResult = .failure(.writeFailed)

        // When
        viewModel.send(.confirmCancelFinish)

        // Then
        XCTAssertTrue(mockNotificationManager.reservedWishes.isEmpty)
        guard case .errorAlert = viewModel.route else {
            return XCTFail("에러 알럿 route 가 와야 한다")
        }
    }

    // MARK: GH-64 TC606

    func test_GH64_TC606_단계를체크하면_상세위시의단계와진행도가바뀌어_수정화면으로최신값이간다() {
        // Given
        var wish = makeWish()
        wish.steps = [WishStep(id: "s-1", title: "가격 비교", isDone: false, order: 0), WishStep(id: "s-2", title: "주문", isDone: false, order: 1)]
        let viewModel = makeViewModel(wish: wish, mode: .fromHome)
        let checked = [WishStep(id: "s-1", title: "가격 비교", isDone: true, order: 0), WishStep(id: "s-2", title: "주문", isDone: false, order: 1)]
        mockRepository.toggleStepResult = .success(checked)

        // When
        viewModel.steps?.send(.tapStep(0))

        // Then
        XCTAssertEqual(viewModel.steps?.state.progress?.doneCount, 1)
        XCTAssertEqual(viewModel.steps?.state.progress?.totalCount, 2)
        XCTAssertEqual(viewModel.state.wish?.steps, checked)
        viewModel.send(.tapEdit)
        guard case .edit(let pushed) = viewModel.route else {
            return XCTFail("수정 화면 Route 가 없다")
        }
        XCTAssertEqual(pushed.steps, checked)
    }
}
