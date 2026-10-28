// swiftlint:disable file_length - 홈 기본 동작·완료 흐름·고정·삭제와 화면별 기능 TC(TC-101~113)를 한 화면 단위로 모았다
import XCTest

@testable import seep_ios

/// 싶 탭(홈) — 완료·소감·삭제·검색 (기존 HomeViewModelTests 이전) + 화면별 기능 TC (GH-64)
final class HomeFeatureTests: HomeFeatureTestCase {
    private func date(daysFromNow days: Double) -> Date {
        Date().addingTimeInterval(days * 86400)
    }

    // MARK: - finishWish 알림 취소 테스트

    func test_finishWish_success_cancelsNotifications() {
        // Given
        let wish = Wish(id: "test-wish-1", emoji: "🎯", category: .wantToDo, title: "테스트 위시", endDate: Date(),
                        notifications: [SeepNotification(type: .dayAgo)])
        var finishedWish = wish
        finishedWish.isSuccess = true
        finishedWish.finishDate = Date()
        repository.finishWishResult = .success(finishedWish)
        let sut = makeSut()
        load(sut, wishes: [wish])

        // When
        sut.send(.tapFinish(wish))

        // Then
        XCTAssertEqual(notificationManager.cancelledWishes.count, 1)
        XCTAssertEqual(notificationManager.cancelledWishes.first?.id, wish.id)
    }

    func test_finishWish_failure_doesNotCancelNotifications() {
        // Given
        let wish = Wish(id: "test-wish-2", emoji: "🎯", category: .wantToDo, title: "테스트 위시", endDate: Date())
        repository.finishWishResult = .failure(.targetNotFound)
        let sut = makeSut()
        load(sut, wishes: [wish])

        // When
        sut.send(.tapFinish(wish))

        // Then
        XCTAssertTrue(notificationManager.cancelledWishes.isEmpty)
    }

    func test_finishWish_success_showsToast() {
        // Given
        let wish = Wish(id: "test-wish-3", category: .wantToDo, title: "테스트")
        repository.finishWishResult = .success(Wish(id: wish.id, isSuccess: true))
        let sut = makeSut()
        load(sut, wishes: [wish])

        // When: 완료하고 소감 시트를 닫는다 (토스트는 완료 흐름이 끝날 때, R-14)
        sut.send(.tapFinish(wish))
        sut.send(.sheetDismissed)

        // Then
        XCTAssertNotNil(sut.state.toast)
    }

    func test_finishWish_failure_showsErrorAlert() {
        // Given
        let wish = Wish(id: "test-wish-4", category: .wantToDo, title: "테스트")
        repository.finishWishResult = .failure(.writeFailed)
        let sut = makeSut()
        load(sut, wishes: [wish])

        // When
        sut.send(.tapFinish(wish))

        // Then
        XCTAssertNotNil(sut.state.errorMessage)
        XCTAssertNil(sut.state.sheet)
    }

    // MARK: - GH-25 완료 소감

    private func makeFinishNoteWishes() -> (wish: Wish, finished: Wish) {
        let wish = Wish(id: "finish-note-1", emoji: "🏃", title: "하프 마라톤 완주하기")
        var finished = wish
        finished.isSuccess = true
        finished.finishDate = Date()
        return (wish, finished)
    }

    // MARK: GH-25 TC1

    func test_GH25_TC1_완료체크에성공하면_토스트후_소감시트route가_해당위시로1회전달된다() {
        // Given
        let (wish, finished) = makeFinishNoteWishes()
        repository.finishWishResult = .success(finished)
        let sut = makeSut()
        load(sut, wishes: [wish])

        // When
        sut.send(.tapFinish(wish))

        // Then: 소감 시트가 그 위시로 뜨고, 토스트는 시트가 닫힌 뒤에 뜬다 (GH-64 R-14)
        XCTAssertEqual(finishNoteViewModel(of: sut)?.wish.id, wish.id)
        XCTAssertNil(sut.state.toast)
        sut.send(.sheetDismissed)
        XCTAssertEqual(sut.state.toast?.message, Strings.Home.Toast.addedToFinished)
    }

    func test_GH25_TC1_완료저장에실패하면_소감시트를띄우지않는다() {
        // Given
        let (wish, _) = makeFinishNoteWishes()
        repository.finishWishResult = .failure(.writeFailed)
        let sut = makeSut()
        load(sut, wishes: [wish])

        // When
        sut.send(.tapFinish(wish))

        // Then
        XCTAssertNil(sut.state.sheet)
    }

    // MARK: GH-25 TC6

    func test_GH25_TC6_소감이있는완료위시를_완료취소하면_소감이빈문자열이된다() {
        // Given: 소감 있는 완료 위시는 싶 탭에 없다
        var (wish, finished) = makeFinishNoteWishes()
        finished.finishNote = "끝까지 뛰었다!"
        let sut = makeSut()
        load(sut, wishes: [finished], notFinishedCount: 0)
        XCTAssertTrue(sut.state.items.isEmpty)

        // When: 상세에서 완료를 취소하고(저장소가 소감을 비운다) 싶 탭으로 돌아온다
        wish.finishNote = ""
        load(sut, wishes: [wish])

        // Then
        XCTAssertEqual(sut.state.items.first?.wish.isSuccess, false)
        XCTAssertEqual(sut.state.items.first?.wish.finishNote, "")
        XCTAssertNil(sut.state.items.first?.finishNote)
    }

    // MARK: GH-25 TC11

    func test_GH25_TC11_소감을저장하면_홈목록셀에바로반영된다() {
        // Given
        let (wish, finished) = makeFinishNoteWishes()
        repository.finishWishResult = .success(finished)
        var updatedFinished = finished
        updatedFinished.finishNote = "최고!"
        repository.updateFinishNoteResult = .success(updatedFinished)
        let sut = makeSut()
        load(sut, wishes: [wish])
        sut.send(.tapFinish(wish))
        let sheetViewModel = finishNoteViewModel(of: sut)

        // When
        sheetViewModel?.send(.inputNote("최고!"))
        sheetViewModel?.send(.tapSave)

        // Then
        XCTAssertEqual(repository.updateFinishNoteCalls.map(\.note), ["최고!"])
        XCTAssertEqual(sut.state.items.first?.finishNote, "최고!")
    }

    // MARK: GH-28 TC9

    func test_GH28_TC9_위시를삭제하면_캘린더추가기록이지워진다() {
        // Given
        let preference = Preference(name: "test-gh28")
        let wishes = [
            Wish(id: "wish-detail-delete", emoji: "🏝️", title: "상세에서 삭제", endDate: Date()),
            Wish(id: "wish-swipe-delete", emoji: "🎧", title: "스와이프 삭제", endDate: Date())
        ]
        wishes.forEach { preference.setCalendarEventId("event-\($0.id)", wishId: $0.id) }
        let sut = makeSut(preference: preference)
        load(sut, wishes: wishes)

        // When: 상세 삭제는 상세가 같은 정리 규칙(WishDeletionCleanup)을 쓴다
        WishDeletionCleanup(preference: preference, linkPreviewCache: linkPreviewCache, photoStorage: photoStorage)
            .run(wish: wishes[0])
        sut.send(.delete(wishes[1]))

        // Then
        XCTAssertNil(preference.calendarEventId(wishId: "wish-detail-delete"))
        XCTAssertNil(preference.calendarEventId(wishId: "wish-swipe-delete"))
        XCTAssertEqual(repository.deleteWishCalledIds, ["wish-swipe-delete"])
    }

    // MARK: GH-32 TC10

    func test_GH32_TC10_돋보기버튼을탭하면_검색화면으로이동한다() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.tapSearch)

        // Then
        XCTAssertEqual(router.wishPath, [.search(finishedOnly: false)])
    }

    // MARK: GH-32 TC11

    func test_GH32_TC11_돋보기버튼을탭하면_search클릭로그가1건전송된다() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.tapSearch)

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let parameters = logManager.sentEvents.first?.parameters
        XCTAssertEqual(logManager.sentEvents.first?.name, .click)
        XCTAssertEqual(parameters?[ParameterName.screen.rawValue] as? String, "home")
        XCTAssertEqual(parameters?[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(parameters?[ParameterName.objectId.rawValue] as? String, "search")
    }

    // MARK: GH-29 TC13

    func test_GH29_TC13_홈에서위시를스와이프삭제하면_그위시의링크미리보기캐시가지워진다() {
        // Given
        let wish = Wish(id: "wish-link", category: .wantToGet, title: "헤드폰", link: "https://store.example.com/p/1")
        linkPreviewCache.previews[wish.id] = LinkPreview(link: wish.link, title: "헤드폰", imageData: nil)
        let sut = makeSut()
        repository.fetchWishesResult = [wish]
        sut.send(.selectCategory(.wantToGet))

        // When
        sut.send(.delete(wish))

        // Then
        XCTAssertEqual(linkPreviewCache.removedWishIds, ["wish-link"])
        XCTAssertNil(linkPreviewCache.previews["wish-link"])
    }

    func test_GH29_TC13_상세에서위시를삭제하고돌아오면_그위시의링크미리보기캐시가지워진다() {
        // Given
        let wish = Wish(id: "wish-link", category: .wantToGet, title: "헤드폰", link: "https://store.example.com/p/1")
        linkPreviewCache.previews[wish.id] = LinkPreview(link: wish.link, title: "헤드폰", imageData: nil)

        // When: 상세 삭제가 쓰는 정리 규칙
        WishDeletionCleanup(preference: preference, linkPreviewCache: linkPreviewCache, photoStorage: photoStorage)
            .run(wish: wish)

        // Then
        XCTAssertEqual(linkPreviewCache.removedWishIds, ["wish-link"])
    }

    // MARK: GH-36 TC5

    func test_GH36_TC5_홈에서위시를삭제하면_위시삭제와함께사진파일삭제가호출된다() {
        // Given
        let wish = Wish(id: "wish-1", category: .wantToGo, title: "제주도 한 달 살기", photoFileName: "wish-1-a.jpg")
        let sut = makeSut()
        load(sut, wishes: [wish])

        // When
        sut.send(.delete(wish))

        // Then
        XCTAssertEqual(repository.deleteWishCalledIds, ["wish-1"])
        XCTAssertEqual(photoStorage.deletePhotosCalledWishIds, ["wish-1"])
    }

    func test_GH36_TC5_상세에서위시를삭제하면_사진파일삭제가호출된다() {
        // Given
        let wish = Wish(id: "wish-1", category: .wantToGo, title: "제주도 한 달 살기", photoFileName: "wish-1-a.jpg")

        // When
        WishDeletionCleanup(preference: preference, linkPreviewCache: linkPreviewCache, photoStorage: photoStorage)
            .run(wish: wish)

        // Then
        XCTAssertEqual(photoStorage.deletePhotosCalledWishIds, ["wish-1"])
    }

    // MARK: - GH-33 위시 맨 위 고정

    // MARK: GH-33 TC1

    func test_GH33_TC1_마감순에서_일정없는위시를고정하면_맨위로온다() {
        // Given
        let soon = Wish(id: "soon", title: "D-1", endDate: date(daysFromNow: 1))
        let later = Wish(id: "later", title: "D-23", endDate: date(daysFromNow: 23))
        var noDate = Wish(id: "no-date", title: "일정없음")
        XCTAssertEqual(HomeSortOrder.deadlineOrder.sorted([noDate, later, soon]).map(\.id), ["soon", "later", "no-date"])

        // When
        noDate.pinnedAt = Date()
        let sorted = HomeSortOrder.deadlineOrder.sorted([soon, later, noDate])

        // Then
        XCTAssertEqual(sorted.map(\.id), ["no-date", "soon", "later"])
    }

    func test_GH33_TC1_고정메뉴를탭하면_저장후목록을다시불러와_핀이보인다() {
        // Given
        let wish = Wish(id: "wish-1", title: "기타로 노래 한 곡 치기")
        let sut = makeSut()
        load(sut, wishes: [wish])
        var pinned = wish
        pinned.pinnedAt = Date()
        repository.fetchWishesResult = [pinned]

        // When
        sut.send(.tapPinMenu(wish))

        // Then
        XCTAssertEqual(repository.updatePinCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(repository.updatePinCalls.map(\.isPinned), [true])
        XCTAssertEqual(sut.state.items.first?.isPinned, true)
    }

    // MARK: GH-33 TC2

    func test_GH33_TC2_고정2개는_나중에고정한것부터맨위에오고_나머지는마감순이다() {
        // Given
        let pinnedA = Wish(id: "A", title: "A", endDate: date(daysFromNow: 30), pinnedAt: date(daysFromNow: -2))
        let pinnedB = Wish(id: "B", title: "B", pinnedAt: date(daysFromNow: -1))
        let soon = Wish(id: "soon", title: "D-1", endDate: date(daysFromNow: 1))
        let later = Wish(id: "later", title: "D-23", endDate: date(daysFromNow: 23))

        // When
        let sorted = HomeSortOrder.deadlineOrder.sorted([later, pinnedA, soon, pinnedB])

        // Then
        XCTAssertEqual(sorted.map(\.id), ["B", "A", "soon", "later"])
    }

    func test_GH33_TC2_최신순에서도_고정이맨위고_나머지는최신순이다() {
        // Given
        let pinnedOld = Wish(id: "pinned-old", title: "오래된 고정", pinnedAt: Date(), createdAt: date(daysFromNow: -10))
        let older = Wish(id: "older", title: "예전 위시", createdAt: date(daysFromNow: -5))
        let newer = Wish(id: "newer", title: "최근 위시", createdAt: date(daysFromNow: -1))

        // When
        let sorted = HomeSortOrder.latestOrder.sorted([older, pinnedOld, newer])

        // Then
        XCTAssertEqual(sorted.map(\.id), ["pinned-old", "newer", "older"])
    }

    // MARK: GH-33 TC3

    func test_GH33_TC3_고정3개인카테고리에서_네번째고정은_저장하지않고_토스트를띄운다() {
        // Given
        let pinnedWishes = (1...3).map { Wish(id: "pinned-\($0)", title: "고정 \($0)", pinnedAt: date(daysFromNow: -Double($0))) }
        let target = Wish(id: "target", title: "네 번째")
        let sut = makeSut()
        load(sut, wishes: pinnedWishes + [target])

        // When
        sut.send(.tapPinMenu(target))

        // Then
        XCTAssertTrue(repository.updatePinCalls.isEmpty)
        XCTAssertEqual(sut.state.toast?.message, "고정은 3개까지 할 수 있어요")
    }

    // MARK: GH-33 TC4

    func test_GH33_TC4_다른카테고리에고정3개가있어도_이카테고리에서는_고정된다() {
        // Given
        let wantToDoPinned = (1...3).map {
            Wish(id: "do-\($0)", category: .wantToDo, title: "하고 싶은 \($0)", pinnedAt: date(daysFromNow: -Double($0)))
        }
        let sut = makeSut()
        load(sut, wishes: wantToDoPinned)
        let wantToGet = Wish(id: "get-1", category: .wantToGet, title: "갖고 싶은 것")
        repository.fetchWishesResult = [wantToGet]
        sut.send(.selectCategory(.wantToGet))

        // When
        sut.send(.tapPinMenu(wantToGet))

        // Then
        XCTAssertEqual(repository.updatePinCalls.map(\.wishId), ["get-1"])
        XCTAssertEqual(repository.updatePinCalls.map(\.isPinned), [true])
    }

    // MARK: GH-33 TC5

    func test_GH33_TC5_고정을해제하면_원래정렬위치로돌아간다() {
        // Given
        let soon = Wish(id: "soon", title: "D-1", endDate: date(daysFromNow: 1))
        var target = Wish(id: "target", title: "D-23", endDate: date(daysFromNow: 23), pinnedAt: Date())
        let noDate = Wish(id: "no-date", title: "일정없음")
        XCTAssertEqual(HomeSortOrder.deadlineOrder.sorted([soon, noDate, target]).map(\.id).first, "target")

        // When
        target.pinnedAt = nil
        let sorted = HomeSortOrder.deadlineOrder.sorted([soon, noDate, target])

        // Then
        XCTAssertEqual(sorted.map(\.id), ["soon", "target", "no-date"])
    }

    func test_GH33_TC5_고정된위시의메뉴를탭하면_해제로저장하고_핀이사라진다() {
        // Given
        let pinned = Wish(id: "wish-1", title: "고정된 위시", pinnedAt: Date())
        let sut = makeSut()
        load(sut, wishes: [pinned])
        var unpinned = pinned
        unpinned.pinnedAt = nil
        repository.fetchWishesResult = [unpinned]

        // When
        sut.send(.tapPinMenu(pinned))

        // Then
        XCTAssertEqual(repository.updatePinCalls.map(\.isPinned), [false])
        XCTAssertEqual(sut.state.items.first?.isPinned, false)
    }

    // MARK: GH-33 TC7

    func test_GH33_TC7_완료된위시는_고정요청이와도_저장하지않는다() {
        // Given
        let finished = Wish(id: "finished", title: "완료된 위시", finishDate: Date(), isSuccess: true)
        let sut = makeSut()
        load(sut, wishes: [finished])

        // When
        sut.send(.tapPinMenu(finished))

        // Then
        XCTAssertTrue(repository.updatePinCalls.isEmpty)
        XCTAssertTrue(logManager.sentEvents.isEmpty)
    }

    // MARK: GH-33 TC9

    func test_GH33_TC9_고정하면_pin_wish클릭로그가_카테고리와고정후개수와함께1건전송된다() {
        // Given
        let alreadyPinned = Wish(id: "pinned", title: "이미 고정", pinnedAt: Date())
        let target = Wish(id: "target", title: "새로 고정")
        let sut = makeSut()
        load(sut, wishes: [alreadyPinned, target])

        // When
        sut.send(.tapPinMenu(target))

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.parameters[ParameterName.screen.rawValue] as? String, "home")
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(objectId(event), "pin_wish")
        XCTAssertEqual(event?.parameters[ParameterName.category.rawValue] as? String, seep_ios.Category.wantToDo.rawValue)
        XCTAssertEqual(event?.parameters[ParameterName.count.rawValue] as? Int, 2)
    }

    func test_GH33_TC9_고정해제하면_unpin_wish클릭로그가1건전송된다() {
        // Given
        let pinned = Wish(id: "pinned", title: "고정된 위시", pinnedAt: Date())
        let sut = makeSut()
        load(sut, wishes: [pinned])

        // When
        sut.send(.tapPinMenu(pinned))

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(objectId(event), "unpin_wish")
        XCTAssertEqual(event?.parameters[ParameterName.category.rawValue] as? String, seep_ios.Category.wantToDo.rawValue)
    }

    func test_GH33_TC9_3개초과로토스트가뜨면_pin_limit_toast노출로그가1건전송된다() {
        // Given
        let pinnedWishes = (1...3).map { Wish(id: "pinned-\($0)", title: "고정 \($0)", pinnedAt: Date()) }
        let target = Wish(id: "target", title: "네 번째")
        let sut = makeSut()
        load(sut, wishes: pinnedWishes + [target])

        // When
        sut.send(.tapPinMenu(target))

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
        XCTAssertEqual(event?.name, .impression)
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "banner")
        XCTAssertEqual(objectId(event), "pin_limit_toast")
        XCTAssertEqual(event?.parameters[ParameterName.category.rawValue] as? String, seep_ios.Category.wantToDo.rawValue)
    }
}

// MARK: - 화면별 기능 테스트 (GH-64 TC-6, TC-101 ~ TC-113)

final class HomeScreenFeatureTests: HomeFeatureTestCase {
    // MARK: GH-64 TC6

    func test_GH64_TC6_완료하고소감시트를닫으면_목록에서빠지고_토스트와이룬싶탭점이생긴다() {
        // Given
        let wish = Wish(id: "wish-1", title: "서핑 배우기")
        var finished = wish
        finished.isSuccess = true
        finished.finishDate = Date()
        repository.finishWishResult = .success(finished)
        let sut = makeSut()
        load(sut, wishes: [wish, Wish(id: "wish-2", title: "책 읽기")])

        // When: 완료 → 소감 시트가 떠 있는 동안은 흐리게 남는다
        sut.send(.tapFinish(wish))

        // Then
        XCTAssertEqual(listedWishIds(of: sut), ["wish-1", "wish-2"])
        XCTAssertEqual(sut.state.items.first?.wish.isSuccess, true)
        XCTAssertFalse(router.showsFinishedDot)

        // When: 저장소가 완료로 바뀐 목록을 돌려주고, 소감 시트가 닫힌다(새 배지 없음)
        repository.fetchWishesResult = [finished, Wish(id: "wish-2", title: "책 읽기")]
        sut.send(.sheetDismissed)

        // Then
        XCTAssertEqual(listedWishIds(of: sut), ["wish-2"])
        XCTAssertEqual(sut.state.toast?.message, "👏 이룬 싶에 담았어요")
        XCTAssertTrue(router.showsFinishedDot)
        XCTAssertEqual(events(objectId: "finished_tab_dot").count, 1)
        XCTAssertEqual(events(objectId: "finished_tab_dot").first?.name, .impression)
    }

    func test_GH64_TC6_이룬싶탭을열면_점이사라진다() {
        // Given
        router.showsFinishedDot = true

        // When
        router.select(.finished)

        // Then
        XCTAssertFalse(router.showsFinishedDot)
    }

    // MARK: GH-64 TC101

    func test_GH64_TC101_첫로드면_완료하지않은위시만보이고_헤드라인개수가남은수다() {
        // Given
        let wishes = (1...3).map { Wish(id: "do-\($0)", title: "진행 \($0)") }
            + (1...2).map { Wish(id: "done-\($0)", title: "완료 \($0)", isSuccess: true) }
        let sut = makeSut()

        // When
        load(sut, wishes: wishes)

        // Then
        XCTAssertEqual(listedWishIds(of: sut), ["do-1", "do-2", "do-3"])
        XCTAssertEqual(sut.state.notFinishedCount, 3)
        XCTAssertEqual(Strings.Home.TitleFormat.wantToDo(3), "하고 싶은 것들이\n3개 남았어요!")
    }

    // MARK: GH-64 TC102

    func test_GH64_TC102_카테고리를바꾸면_그카테고리목록이고_적기시트기본카테고리가저장된다() {
        // Given
        let sut = makeSut()
        load(sut, wishes: [Wish(id: "do", title: "하고")])
        repository.fetchWishesResult = [Wish(id: "get", category: .wantToGet, title: "갖고")]

        // When
        sut.send(.selectCategory(.wantToGet))

        // Then
        XCTAssertEqual(sut.state.category, .wantToGet)
        XCTAssertEqual(listedWishIds(of: sut), ["get"])
        XCTAssertEqual(router.homeCategory, .wantToGet)
    }

    func test_GH64_TC102_라우터의마지막카테고리로시작한다() {
        // Given
        router.homeCategory = .wantToGo

        // When
        let sut = makeSut()

        // Then
        XCTAssertEqual(sut.state.category, .wantToGo)
        XCTAssertTrue(sut.state.isPlaceMapVisible)
    }

    // MARK: GH-64 TC103

    func test_GH64_TC103_정렬을고르면_시트가닫히고_고정위시는맨위를유지한다() {
        // Given
        let sut = makeSut()
        load(sut, wishes: [])
        sut.send(.tapSortOrder)
        XCTAssertEqual(sut.state.sheet, .sortOrder)

        // When
        sut.send(.selectSortOrder(.latestOrder))

        // Then
        XCTAssertEqual(sut.state.sortOrder, .latestOrder)
        XCTAssertNil(sut.state.sheet)
        let pinned = Wish(id: "pinned", pinnedAt: Date(), createdAt: Date(timeIntervalSince1970: 0))
        let newest = Wish(id: "newest", createdAt: Date())
        XCTAssertEqual(HomeSortOrder.latestOrder.sorted([newest, pinned]).map(\.id), ["pinned", "newest"])
    }

    // MARK: GH-64 TC104

    func test_GH64_TC104_보기방식을바꾸면_그리드가되고_저장된다() {
        // Given
        preference.viewType = .list
        let sut = makeSut()

        // When
        sut.send(.toggleViewType)

        // Then
        XCTAssertEqual(sut.state.viewType, .grid)
        XCTAssertEqual(preference.viewType, .grid)
    }

    // MARK: GH-64 TC105

    func test_GH64_TC105_고정3개에서네번째를고정하면_한도토스트와노출로그만남는다() {
        // Given
        let pinned = (1...3).map { Wish(id: "p\($0)", pinnedAt: Date()) }
        let target = Wish(id: "target")
        let sut = makeSut()
        load(sut, wishes: pinned + [target])

        // When
        sut.send(.tapPinMenu(target))

        // Then
        XCTAssertEqual(sut.state.toast?.message, Strings.Home.Pin.limitToast)
        XCTAssertEqual(events(objectId: "pin_limit_toast").count, 1)
        XCTAssertTrue(repository.updatePinCalls.isEmpty)
    }

    // MARK: GH-64 TC106

    func test_GH64_TC106_삭제하면_저장소삭제_알림취소_목록에서빠진다() {
        // Given
        let target = Wish(id: "target", notifications: [SeepNotification(type: .dayAgo)])
        let other = Wish(id: "other")
        let sut = makeSut()
        load(sut, wishes: [target, other])
        repository.fetchNotFinishCountResult = 1

        // When
        sut.send(.delete(target))

        // Then
        XCTAssertEqual(repository.deleteWishCalledIds, ["target"])
        XCTAssertEqual(notificationManager.cancelledWishes.map(\.id), ["target"])
        XCTAssertEqual(listedWishIds(of: sut), ["other"])
        XCTAssertEqual(sut.state.notFinishedCount, 1)
    }

    // MARK: GH-64 TC108

    func test_GH64_TC108_60일넘게손대지않은위시는_카드와노출로그가나오고_여전히하고싶어요면사라진다() {
        // Given
        let today = Date()
        let sleeping = Wish(id: "sleeping", createdAt: today.addingTimeInterval(-61 * 86400))
        let sut = makeSut(dateProvider: { today })
        load(sut, wishes: [sleeping])

        // Then
        XCTAssertEqual(sut.state.sleepingWishCard?.wish.id, "sleeping")
        XCTAssertEqual(events(objectId: "sleeping_wish_card").count, 1)

        // When
        sut.send(.keepSleepingWish(sleeping))

        // Then
        XCTAssertNil(sut.state.sleepingWishCard)
        XCTAssertEqual(repository.markCheckedCalledIds, ["sleeping"])
    }

    // MARK: GH-64 TC109

    func test_GH64_TC109_회고기간이고올해이룬싶이있으면_배너가보이고_닫으면그해다시뜨지않는다() {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let now = calendar.date(from: DateComponents(year: 2026, month: 12, day: 5, hour: 12)) ?? Date()
        let finishDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 12)) ?? Date()
        repository.fetchFinishedWishesResult = [Wish(id: "a", finishDate: finishDate, isSuccess: true)]
        let period = YearReviewPeriod(isEnabled: true, start: .init(month: 12, day: 1), end: .init(month: 1, day: 31))
        let sut = makeSut(now: { now }, calendar: calendar, remoteConfigRepository: StubRemoteConfigRepository(period: period))
        load(sut, wishes: [])
        XCTAssertEqual(sut.state.yearReviewBanner, YearReviewEligibility(year: 2026, count: 1))

        // When
        sut.send(.closeYearReviewBanner)
        let reopened = makeSut(now: { now }, calendar: calendar, remoteConfigRepository: StubRemoteConfigRepository(period: period))
        load(reopened, wishes: [])

        // Then
        XCTAssertNil(sut.state.yearReviewBanner)
        XCTAssertNil(reopened.state.yearReviewBanner)
    }

    // MARK: GH-64 TC110

    func test_GH64_TC110_위젯에서완료한위시가있으면_싶탭에서알림취소_소감시트_로그를처리한다() {
        // Given
        let suiteName = "test.home.tc110"
        UserDefaults().removePersistentDomain(forName: suiteName)
        let store = WidgetCheckStore(userDefaults: UserDefaults(suiteName: suiteName))
        let wish = Wish(id: "wish-1", title: "위시", isSuccess: true)
        repository.fetchWishResult = [wish]
        store.recordFinish(wishId: "wish-1", at: Date())
        let sut = makeSut(widgetCheckStore: store)

        // When
        sut.send(.syncWidgetChanges)

        // Then
        XCTAssertEqual(notificationManager.cancelledWishes.map(\.id), ["wish-1"])
        XCTAssertEqual(finishNoteViewModel(of: sut)?.wish.id, "wish-1")
        XCTAssertEqual(logManager.sentEvents.filter { $0.screen == .checkWidget }.count, 1)
    }

    // MARK: GH-64 TC111

    func test_GH64_TC111_가고싶어요면지도버튼이보이고_누르면지도로간다_다른카테고리는숨긴다() {
        // Given
        let sut = makeSut()
        load(sut, wishes: [])
        XCTAssertFalse(sut.state.isPlaceMapVisible)

        // When
        sut.send(.selectCategory(.wantToGo))
        sut.send(.tapPlaceMap)

        // Then
        XCTAssertTrue(sut.state.isPlaceMapVisible)
        XCTAssertEqual(router.wishPath, [.placeMap])
        XCTAssertEqual(events(objectId: "place_map").count, 1)
    }

    // MARK: GH-64 TC112

    func test_GH64_TC112_진행위시가없으면_빈상태다() {
        // Given
        let sut = makeSut()

        // When
        load(sut, wishes: [Wish(id: "done", isSuccess: true)], notFinishedCount: 0)

        // Then
        XCTAssertTrue(sut.state.isEmpty)
        XCTAssertEqual(sut.state.notFinishedCount, 0)
    }

    // MARK: GH-64 TC113

    func test_GH64_TC113_상세에서수정삭제완료취소하고돌아오면_목록이새로읽힌다() {
        // Given
        let edited = Wish(id: "edited", title: "원래 제목")
        let deleted = Wish(id: "deleted", title: "지울 위시")
        let sut = makeSut()
        load(sut, wishes: [edited, deleted])
        sut.send(.tapWish(edited))
        XCTAssertEqual(router.wishPath, [.wishDetail(id: "edited", isFinished: false)])

        // When: 상세에서 제목을 바꾸고, 하나는 지우고, 완료했던 위시는 완료 취소한 뒤 돌아온다
        var editedNow = edited
        editedNow.title = "바꾼 제목"
        let restored = Wish(id: "restored", title: "완료 취소한 위시")
        load(sut, wishes: [editedNow, restored])

        // Then
        XCTAssertEqual(sut.state.items.map(\.wish.title), ["바꾼 제목", "완료 취소한 위시"])
    }
}
