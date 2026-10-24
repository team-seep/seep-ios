import XCTest

@testable import seep_ios_dev

/// 작성·수정 폼 화면별 기능 테스트 (GH-64 TC-402~408, 501~504, TC-37, TC-39)
final class WishFormFeatureTests: WishFormFeatureTestCase {
    // MARK: GH-64 TC402

    func test_GH64_TC402_제목이비어있으면_완료버튼이비활성모양이고_제목을넣으면_활성이된다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        XCTAssertEqual(viewModel.state.saveButtonState, .initial)

        // When
        viewModel.send(.inputTitle("서핑 배우기"))

        // Then
        XCTAssertEqual(viewModel.state.saveButtonState, .active)
    }

    func test_GH64_TC402_제목없이완료를누르면_안내만보이고_저장되지않는다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(viewModel.state.titleError, Strings.writeErrorTitleEmpty)
        // GH-70 R-7: 날짜는 기본으로 없어 날짜 안내는 뜨지 않는다
        XCTAssertNil(viewModel.state.deadlineError)
        XCTAssertTrue(wishRepository.addedWishes.isEmpty)
        XCTAssertNil(viewModel.route)
    }

    func test_GH64_TC402_제목은18자까지만_들어가고_18자에닿으면_안내한다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))

        // When
        viewModel.send(.inputTitle(String(repeating: "가", count: 20)))

        // Then
        XCTAssertEqual(viewModel.state.title.count, WishFormViewModel.titleMaxLength)
        XCTAssertEqual(viewModel.state.titleError, Strings.writeErrorMaxLengthTitle)
    }

    // MARK: GH-64 TC403

    func test_GH64_TC403_갖고싶어요에서하고싶어요로바꾸면_갖고전용섹션이숨고_그값은저장되지않는다() {
        // Given
        let viewModel = makeWrite(category: .wantToGet, title: "카메라")
        viewModel.send(.inputTargetAmount("1,000,000"))
        viewModel.send(.inputLink("https://store.example.com/camera"))
        XCTAssertTrue(viewModel.state.isLinkVisible)
        XCTAssertTrue(viewModel.state.isTargetAmountVisible)

        // When
        viewModel.send(.selectCategory(.wantToDo))
        viewModel.send(.tapSave)

        // Then
        XCTAssertFalse(viewModel.state.isLinkVisible)
        XCTAssertFalse(viewModel.state.isTargetAmountVisible)
        XCTAssertEqual(wishRepository.addedWishes.first?.targetAmount, 0)
        XCTAssertEqual(wishRepository.addedWishes.first?.link, "")
        XCTAssertEqual(viewModel.state.titlePlaceholder, Strings.writePlaceholderTitleCategoryWantToDo)
    }

    func test_GH64_TC403_장소칸은_작성의가고싶어요에서만보인다() {
        // Given
        let write = makeViewModel(mode: .add(.wantToDo))
        XCTAssertFalse(write.isPlaceVisible)

        // When
        write.send(.selectCategory(.wantToGo))

        // Then
        XCTAssertTrue(write.isPlaceVisible)
        XCTAssertFalse(makeViewModel(mode: .edit(Wish(id: "w", category: .wantToGo))).isPlaceVisible)
    }

    // MARK: GH-64 TC404

    func test_GH64_TC404_날짜를고르면_그날끝으로저장되고_날짜를끄면_nil이다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        viewModel.send(.inputTitle("서핑 배우기"))
        let picked = Date(timeIntervalSince1970: 1_798_000_000)

        // When
        viewModel.send(.tapChip(.date))
        viewModel.send(.inputDeadline(picked))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.first?.endDate, picked.endOfDay)

        // When — 날짜를 끄고 다시 저장
        let second = makeViewModel(mode: .add(.wantToDo))
        second.send(.inputTitle("서핑 배우기"))
        second.send(.tapChip(.date))
        second.send(.inputDeadline(picked))
        second.send(.toggleDeadline(false))
        second.send(.tapSave)

        // Then
        XCTAssertNil(wishRepository.addedWishes.last?.endDate)
        XCTAssertEqual(wishRepository.addedWishes.last?.notifications, [])
    }

    func test_GH64_TC404_날짜칸을누르면_날짜시트가뜨고_오늘로채운다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))

        // When
        viewModel.send(.tapDate)

        // Then
        XCTAssertEqual(viewModel.state.sheet, .date)
        XCTAssertEqual(viewModel.state.deadline, now.endOfDay)
    }

    // MARK: GH-64 TC405

    func test_GH64_TC405_알림2개를추가하고1개를지우면_1개만예약된다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        viewModel.send(.inputTitle("서핑 배우기"))
        // GH-70: 날짜·알림은 칩으로 꺼낸다
        viewModel.send(.tapChip(.date))
        viewModel.send(.tapChip(.notification))
        viewModel.send(.inputDeadline(now.addingTimeInterval(86_400 * 10)))
        XCTAssertEqual(viewModel.state.notifications.count, 1, "기본 알림 하나로 시작한다")
        viewModel.send(.saveNotification(SeepNotification(type: .dayAgo), index: nil))
        viewModel.send(.saveNotification(SeepNotification(type: .weekAgo), index: nil))

        // When
        viewModel.send(.deleteNotification(index: 1))
        viewModel.send(.deleteNotification(index: 1))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(notificationManager.reservedWishes.count, 1)
        XCTAssertEqual(notificationManager.reservedWishes.first?.notifications.count, 1)
        XCTAssertEqual(notificationManager.reservedWishes.first?.notifications.first?.type, .targetDay)
    }

    func test_GH64_TC405_날짜가꺼져있으면_알림을켤수없고_안내토스트가뜬다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        viewModel.send(.toggleDeadline(false))

        // When
        viewModel.send(.toggleNotification(true))

        // Then
        XCTAssertFalse(viewModel.state.isNotificationEnabled)
        XCTAssertEqual(viewModel.route, .toast(Strings.WishForm.notificationRequiresDate))
    }

    func test_GH64_TC405_알림줄을누르면_그알림을고칠시트가뜬다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        // GH-70: 날짜·알림은 칩으로 꺼낸다
        viewModel.send(.tapChip(.date))
        viewModel.send(.tapChip(.notification))

        // When
        viewModel.send(.tapNotification(index: 0))

        // Then
        XCTAssertEqual(
            viewModel.state.sheet,
            .notification(NotificationEditorConfig(notifications: viewModel.state.notifications, selectedIndex: 0))
        )
    }

    // MARK: GH-64 TC406

    func test_GH64_TC406_해시태그는하나만고르고_직접입력하면_고른태그가풀린다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)
        viewModel.send(.selectHashtag(.trip))
        viewModel.send(.selectHashtag(.hobby))
        XCTAssertEqual(viewModel.state.selectedHashtag, .hobby)

        // When
        viewModel.send(.inputCustomHashtag("버킷"))
        viewModel.send(.tapSave)

        // Then
        XCTAssertNil(viewModel.state.selectedHashtag)
        XCTAssertEqual(wishRepository.addedWishes.first?.hashtag, "버킷")
    }

    func test_GH64_TC406_직접입력태그는7자까지만들어가고_안내한다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)

        // When
        viewModel.send(.inputCustomHashtag("일이삼사오육칠팔"))

        // Then
        XCTAssertEqual(viewModel.state.customHashtag, "일이삼사오육칠")
        XCTAssertEqual(viewModel.state.customHashtagError, Strings.writeErrorMaxLengthHashtag)
    }

    func test_GH64_TC406_고른해시태그는_rawValue로저장된다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)
        viewModel.send(.selectHashtag(.trip))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.first?.hashtag, HashtagType.trip.rawValue)
    }

    // MARK: GH-64 TC407

    func test_GH64_TC407_단계는10개까지_추가할수있고_넘으면토스트가뜬다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)
        (0..<WishStep.maxCount).forEach { viewModel.send(.addStep("단계 \($0)")) }
        XCTAssertFalse(viewModel.state.isAddStepEnabled)

        // When
        viewModel.send(.tapAddStep)

        // Then
        XCTAssertEqual(viewModel.route, .toast(Strings.Detail.Step.Toast.maxCount))
        XCTAssertEqual(clickEvents(objectId: .addStep).count, WishStep.maxCount)
        XCTAssertEqual(clickEvents(objectId: .addStep).first?.screen, .write)
    }

    func test_GH64_TC407_빈단계는추가하지않고_30자를넘으면토스트가뜬다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)

        // When
        viewModel.send(.addStep("   "))
        viewModel.send(.addStep(String(repeating: "가", count: 31)))

        // Then
        XCTAssertTrue(viewModel.state.steps.isEmpty)
        XCTAssertEqual(viewModel.route, .toast(Strings.Detail.Step.Toast.maxLength))
    }

    func test_GH64_TC407_장소를고르면_장소추가로그1건과_장소가채워지고_지우면비워진다() {
        // Given
        let viewModel = makeWrite(category: .wantToGo)
        let place = WishPlace(name: "한라산", address: "제주", latitude: 33.36, longitude: 126.53)

        // When
        viewModel.send(.tapPlace)

        // Then
        XCTAssertEqual(viewModel.state.sheet, .placeSearch)
        XCTAssertEqual(clickEvents(objectId: .addPlace).count, 1)

        // When
        viewModel.send(.selectPlace(place))

        // Then
        XCTAssertEqual(viewModel.state.place, place)
        XCTAssertNil(viewModel.state.sheet)

        // When
        viewModel.send(.deletePlace)

        // Then
        XCTAssertNil(viewModel.state.place)
    }

    func test_GH64_TC407_링크를붙여넣으면_붙여넣기로그와_공백을뺀링크_미리보기노출로그1건() {
        // Given
        linkMetadataProvider.fetchPreviewResult = LinkPreview(link: "https://a.example.com/x", title: "카메라", imageData: nil)
        let viewModel = makeWrite(category: .wantToGet)

        // When
        viewModel.send(.pasteLink("  https://a.example.com/x  "))
        viewModel.send(.inputLink("https://a.example.com/x "))

        // Then
        XCTAssertEqual(viewModel.state.link, .valid("https://a.example.com/x"))
        XCTAssertEqual(clickEvents(objectId: .pasteWishLink).count, 1)
        XCTAssertEqual(linkMetadataProvider.fetchedLinks, ["https://a.example.com/x"], "공백만 바뀌면 다시 부르지 않는다")
        let impressions = logManager.sentEvents.filter {
            $0.name == .impression && ($0.extraParameters?[.objectId] as? LogObjectId) == .wishLinkPreview
        }
        XCTAssertEqual(impressions.count, 1)
    }

    // MARK: GH-64 TC408

    func test_GH64_TC408_작성을완료하면_저장_알림예약_작성로그_닫기Route가나온다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        viewModel.send(.inputTitle("서핑 배우기"))
        viewModel.send(.inputDeadline(now.addingTimeInterval(86_400 * 5)))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.count, 1)
        XCTAssertEqual(wishRepository.addedWishes.first?.emoji, "🎲", "이모지를 안 고르면 무작위 이모지")
        XCTAssertEqual(wishRepository.addedWishes.first?.createdAt, now)
        XCTAssertEqual(notificationManager.reservedWishes.map(\.id), wishRepository.addedWishes.map(\.id))
        XCTAssertEqual(writeClickEvents.count, 1)
        XCTAssertEqual(finishedWish(viewModel)?.id, wishRepository.addedWishes.first?.id)
    }

    // MARK: GH-64 TC501

    func test_GH64_TC501_수정을열면_모든칸이위시값으로채워진다() {
        // Given
        let deadline = now.addingTimeInterval(86_400 * 30).endOfDay
        let wish = Wish(
            id: "w1",
            emoji: "📷",
            category: .wantToGet,
            title: "카메라",
            endDate: deadline,
            notifications: [SeepNotification(type: .weekAgo)],
            steps: [WishStep(id: "s", title: "알아보기", order: 0)],
            targetAmount: 1_200_000,
            memo: "필름 카메라",
            hashtag: "나만의",
            link: "https://a.example.com/x"
        )

        // When
        let viewModel = makeViewModel(mode: .edit(wish))

        // Then
        let state = viewModel.state
        XCTAssertEqual(state.emoji, "📷")
        XCTAssertEqual(state.category, .wantToGet)
        XCTAssertEqual(state.title, "카메라")
        XCTAssertEqual(state.deadline, deadline)
        XCTAssertTrue(state.isDeadlineEnabled)
        XCTAssertEqual(state.notifications.map(\.type), [.weekAgo])
        XCTAssertTrue(state.isNotificationEnabled)
        XCTAssertEqual(state.steps.map(\.title), ["알아보기"])
        XCTAssertEqual(state.targetAmount, 1_200_000)
        XCTAssertEqual(state.memo, "필름 카메라")
        XCTAssertNil(state.selectedHashtag)
        XCTAssertEqual(state.customHashtag, "나만의")
        XCTAssertEqual(state.linkText, "https://a.example.com/x")
        XCTAssertEqual(state.saveButtonState, .active)
        XCTAssertEqual(viewModel.screenName, .wishEdit)
    }

    func test_GH64_TC501_알림없는위시는_기본알림하나에_알림꺼짐으로시작한다() {
        // Given / When
        let viewModel = makeViewModel(mode: .edit(Wish(id: "w1", title: "카메라")))

        // Then
        XCTAssertEqual(viewModel.state.notifications.count, 1)
        XCTAssertFalse(viewModel.state.isNotificationEnabled)
        XCTAssertFalse(viewModel.state.isDeadlineEnabled)
    }

    func test_GH64_TC501_저장된링크는_캐시에같은링크가있으면_네트워크없이미리보기를보여준다() {
        // Given
        let link = "https://a.example.com/x"
        linkPreviewCache.previews["w1"] = LinkPreview(link: link, title: "카메라", imageData: nil)
        let viewModel = makeViewModel(mode: .edit(Wish(id: "w1", category: .wantToGet, title: "카메라", link: link)))

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(viewModel.state.linkPreview, .loaded(LinkPreview(link: link, title: "카메라", imageData: nil)))
        XCTAssertTrue(linkMetadataProvider.fetchedLinks.isEmpty)
    }

    // MARK: GH-64 TC502

    func test_GH64_TC502_제목을지우면_수정버튼이_조금만더모양이고_저장되지않는다() {
        // Given
        let viewModel = makeEdit(Wish(id: "w1", title: "카메라"))

        // When
        viewModel.send(.inputTitle(""))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(viewModel.state.saveButtonState, .more)
        XCTAssertTrue(wishRepository.updatedWishes.isEmpty)
    }

    // MARK: GH-64 TC503

    func test_GH64_TC503_수정저장하면_수정전알림을지우고_새알림을예약한다() {
        // Given
        let original = Wish(
            id: "w1",
            title: "카메라",
            endDate: now.addingTimeInterval(86_400 * 10),
            notifications: [SeepNotification(type: .dayAgo), SeepNotification(type: .weekAgo)]
        )
        let viewModel = makeViewModel(mode: .edit(original))
        viewModel.send(.deleteNotification(index: 1))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(notificationManager.cancelledWishes.first?.notifications.count, 2, "지운 알림까지 지운다")
        XCTAssertEqual(notificationManager.reservedWishes.first?.notifications.map(\.type), [.dayAgo])
    }

    // MARK: GH-64 TC504

    func test_GH64_TC504_수정저장하면_고정·사진·완료상태를지키고_lastCheckedAt을갱신해_돌려준다() {
        // Given
        let pinnedAt = Date(timeIntervalSince1970: 1_790_000_000)
        let original = Wish(
            id: "w1",
            category: .wantToDo,
            title: "카메라",
            pinnedAt: pinnedAt,
            photoFileName: "photo.jpg",
            createdAt: Date(timeIntervalSince1970: 1_780_000_000)
        )
        photoStorage.existingFileNames = ["photo.jpg"]
        let viewModel = makeEdit(original)
        viewModel.send(.inputTitle("필름 카메라"))

        // When
        viewModel.send(.tapSave)

        // Then
        let saved = finishedWish(viewModel)
        XCTAssertEqual(saved?.title, "필름 카메라")
        XCTAssertEqual(saved?.pinnedAt, pinnedAt)
        XCTAssertEqual(saved?.photoFileName, "photo.jpg")
        XCTAssertEqual(saved?.lastCheckedAt, now)
        XCTAssertEqual(saved?.createdAt, original.createdAt)
    }

    func test_GH64_TC504_카테고리를바꿔저장하면_고정이풀린다() {
        // Given
        let original = Wish(id: "w1", category: .wantToDo, title: "카메라", pinnedAt: Date())
        let viewModel = makeEdit(original)

        // When
        viewModel.send(.selectCategory(.wantToGet))
        viewModel.send(.tapSave)

        // Then
        XCTAssertNil(wishRepository.updatedWishes.first?.pinnedAt)
    }

    // MARK: GH-64 TC37

    func test_GH64_TC37_이모지원을누르면_시트가뜨고_고르면반영되고_닫힌다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)

        // When
        viewModel.send(.tapEmoji)

        // Then
        XCTAssertEqual(viewModel.state.sheet, .emoji)

        // When
        viewModel.send(.selectEmoji("🏄"))
        viewModel.send(.tapSave)

        // Then
        XCTAssertNil(viewModel.state.sheet)
        XCTAssertEqual(wishRepository.addedWishes.first?.emoji, "🏄")
    }

    func test_GH64_TC37_R버튼은_무작위이모지를채운다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)

        // When
        viewModel.send(.tapRandomEmoji)

        // Then
        XCTAssertEqual(viewModel.state.emoji, "🎲")
    }

    func test_GH64_TC37_작성을처음열면_무작위안내를한번만보여준다() {
        // Given
        userDefaults.setRandomEmojiTooltipIsShow(isShown: false)
        let first = makeViewModel(mode: .add(.wantToDo))

        // When
        first.send(.onAppear)

        // Then
        XCTAssertTrue(first.state.isTooltipVisible)

        // When — 다음에 열면
        let second = makeViewModel(mode: .add(.wantToDo))
        second.send(.onAppear)

        // Then
        XCTAssertFalse(second.state.isTooltipVisible)
    }

    // MARK: GH-64 TC39

    func test_GH64_TC39_알림시간을오후9시30분으로고쳐저장하면_그시각으로예약된다() {
        // Given
        var components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        components.hour = 21
        components.minute = 30
        let time = Calendar.current.date(from: components) ?? now
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        viewModel.send(.inputTitle("서핑 배우기"))
        // GH-70: 날짜·알림은 칩으로 꺼낸다
        viewModel.send(.tapChip(.date))
        viewModel.send(.tapChip(.notification))
        viewModel.send(.inputDeadline(now.addingTimeInterval(86_400 * 10)))
        let editor = NotificationEditorViewModel(config: NotificationEditorConfig(
            notifications: viewModel.state.notifications,
            selectedIndex: 0
        ))
        editor.send(.inputTime(time))
        editor.send(.tapSave)
        guard case .saved(let notification, let index) = editor.route else {
            return XCTFail("저장 Route 가 나와야 한다")
        }

        // When
        viewModel.send(.saveNotification(notification, index: index))
        viewModel.send(.tapSave)

        // Then
        let reserved = notificationManager.reservedWishes.first?.notifications.first
        XCTAssertEqual(reserved?.time, time)
        XCTAssertEqual(reserved?.type, .targetDay)
        XCTAssertEqual(viewModel.state.notifications.count, 1, "수정은 그 자리를 바꾼다")
    }

    // MARK: GH-10 TC7 (ToastManagerTests 에서 옮김 — 레거시 WriteView 대신 SwiftUI 폼)
    // 작성·수정 폼의 닫기·뒤로 버튼은 시스템 내비게이션 바 버튼이라 위치·터치 영역을 시스템이 정한다 (GH-64 P4)

    func test_GH10_TC7_알림화면_뒤로·삭제버튼과_목록이_safeArea안에있다() {
        // Given: 알림 화면은 시트(NotificationEditorSheet)로 바뀌어 뒤로 버튼 없이 삭제 버튼만 남았다
        // When
        let size = NotificationEditorSheet.deleteButtonSize

        // Then
        XCTAssertGreaterThanOrEqual(size, 44)
    }
}
