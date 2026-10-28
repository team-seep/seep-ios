// GH-61 R-10: 칩 끝에 사진·미래의 나에게가 늘 있다
import XCTest

@testable import seep_ios

/// 작성·수정 문서: 블록·칩·버리기 확인 (GH-70)
final class WishDocumentFeatureTests: WishFormFeatureTestCase {
    private func addBlockEvents() -> [ClickEvent] {
        logManager.sentEvents
            .compactMap { $0 as? ClickEvent }
            .filter { ($0.extraParameters?[.objectId] as? LogObjectId) == .addBlock }
    }

    // MARK: GH-70 TC1

    func test_GH70_TC1_하고싶어요작성을열면_날짜알림이꺼져있고_블록없이_칩은날짜메모단계다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))

        // Then
        XCTAssertFalse(viewModel.state.isDeadlineEnabled)
        XCTAssertFalse(viewModel.state.isNotificationEnabled)
        XCTAssertTrue(viewModel.visibleBlocks.isEmpty)
        XCTAssertEqual(viewModel.chips, [.date, .memo, .steps, .photo, .letter])
    }

    func test_GH70_TC1_갖고싶어요는_링크·목표금액칩이_가고싶어요는_장소칩이더있다() {
        XCTAssertEqual(makeViewModel(mode: .add(.wantToGet)).chips, [.date, .memo, .steps, .link, .targetAmount, .photo, .letter])
        XCTAssertEqual(makeViewModel(mode: .add(.wantToGo)).chips, [.date, .memo, .steps, .place, .photo, .letter])
    }

    // MARK: GH-70 TC2

    func test_GH70_TC2_제목만넣고저장하면_날짜알림없이저장되고_알림예약은0건이다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        viewModel.send(.inputTitle("서핑 배우기"))

        // When
        viewModel.send(.tapSave)

        // Then
        let saved = finishedWish(viewModel)
        XCTAssertEqual(saved?.title, "서핑 배우기")
        XCTAssertNil(saved?.endDate)
        XCTAssertEqual(saved?.notifications, [])
        XCTAssertTrue(notificationManager.reservedWishes.allSatisfy { $0.notifications.isEmpty })
    }

    // MARK: GH-70 TC3

    func test_GH70_TC3_날짜칩을누르면_날짜가켜져오늘끝으로채워지고_시트가뜨며_칩이알림으로바뀐다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))

        // When
        viewModel.send(.tapChip(.date))

        // Then
        XCTAssertTrue(viewModel.state.isDeadlineEnabled)
        XCTAssertEqual(viewModel.state.deadline, now.endOfDay)
        XCTAssertEqual(viewModel.state.sheet, .date)
        XCTAssertEqual(viewModel.chips, [.memo, .steps, .notification, .photo, .letter])
    }

    // MARK: GH-70 TC4

    func test_GH70_TC4_알림칩을누르면_기본알림1개로켜지고_블록이펼쳐진다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        viewModel.send(.tapChip(.date))

        // When
        viewModel.send(.tapChip(.notification))

        // Then
        XCTAssertTrue(viewModel.state.isNotificationEnabled)
        XCTAssertEqual(viewModel.state.notifications.count, 1)
        XCTAssertEqual(viewModel.visibleBlocks, [.notification])
        XCTAssertFalse(viewModel.chips.contains(.notification))
    }

    func test_GH70_TC4_날짜를없애면_알림이꺼지고_알림블록과칩이사라지며_날짜칩이돌아온다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        viewModel.send(.tapChip(.date))
        viewModel.send(.tapChip(.notification))

        // When
        viewModel.send(.removeBlock(.date))

        // Then
        XCTAssertFalse(viewModel.state.isDeadlineEnabled)
        XCTAssertNil(viewModel.state.deadline)
        XCTAssertFalse(viewModel.state.isNotificationEnabled)
        XCTAssertTrue(viewModel.visibleBlocks.isEmpty)
        XCTAssertEqual(viewModel.chips, [.date, .memo, .steps, .photo, .letter])
    }

    // MARK: GH-70 TC5

    func test_GH70_TC5_메모·링크·목표금액칩을누르면_블록이펼쳐지고_그칸포커스요청이나온다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToGet))
        let cases: [(WishDocumentBlock, WishFormField)] = [(.memo, .memo), (.link, .link), (.targetAmount, .targetAmount)]

        for (block, field) in cases {
            // When
            viewModel.send(.tapChip(block))

            // Then
            XCTAssertTrue(viewModel.visibleBlocks.contains(block), "\(block)")
            XCTAssertEqual(viewModel.route, .focus(field))
            viewModel.send(.routeHandled)
        }
        XCTAssertEqual(viewModel.chips, [.date, .steps, .photo, .letter])
    }

    func test_GH70_TC5_지우기를누르면_값이비고_블록이닫히며_칩이돌아온다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToGet))
        viewModel.send(.tapChip(.memo))
        viewModel.send(.inputMemo("오전반"))
        viewModel.send(.tapChip(.link))
        viewModel.send(.inputLink("https://example.com"))
        viewModel.send(.tapChip(.targetAmount))
        viewModel.send(.inputTargetAmount("10000"))

        // When
        viewModel.send(.removeBlock(.memo))
        viewModel.send(.removeBlock(.link))
        viewModel.send(.removeBlock(.targetAmount))

        // Then
        XCTAssertEqual(viewModel.state.memo, "")
        XCTAssertEqual(viewModel.state.linkText, "")
        XCTAssertEqual(viewModel.state.linkPreview, .hidden)
        XCTAssertEqual(viewModel.state.targetAmount, 0)
        XCTAssertTrue(viewModel.visibleBlocks.isEmpty)
        XCTAssertEqual(viewModel.chips, [.date, .memo, .steps, .link, .targetAmount, .photo, .letter])
    }

    // MARK: GH-70 TC6

    func test_GH70_TC6_단계칩을누르면_단계블록이펼쳐지고_단계입력창이뜬다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))

        // When
        viewModel.send(.tapChip(.steps))

        // Then
        XCTAssertEqual(viewModel.visibleBlocks, [.steps])
        XCTAssertEqual(viewModel.route, .addStepAlert)
    }

    // MARK: GH-70 TC7

    func test_GH70_TC7_가고싶어요작성에서장소칩을누르면_장소검색시트가뜨고_수정에는장소칩이없다() {
        // Given
        let write = makeViewModel(mode: .add(.wantToGo))

        // When
        write.send(.tapChip(.place))

        // Then
        XCTAssertEqual(write.state.sheet, .placeSearch)
        let edit = makeViewModel(mode: .edit(Wish(id: "wish-1", emoji: "🏝️", category: .wantToGo, title: "제주")))
        XCTAssertFalse(edit.chips.contains(.place))
    }

    // MARK: GH-70 TC8

    func test_GH70_TC8_링크블록을펼친뒤_하고싶어요로바꾸면_링크블록·칩이숨고_링크는저장되지않는다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToGet))
        viewModel.send(.inputTitle("에어팟"))
        viewModel.send(.tapChip(.link))
        viewModel.send(.inputLink("https://example.com"))

        // When
        viewModel.send(.selectCategory(.wantToDo))

        // Then
        XCTAssertFalse(viewModel.visibleBlocks.contains(.link))
        XCTAssertFalse(viewModel.chips.contains(.link))
        viewModel.send(.tapSave)
        XCTAssertEqual(finishedWish(viewModel)?.link, "")
    }

    // MARK: GH-70 TC9

    func test_GH70_TC9_메모·단계·알림이있는위시를수정하면_그블록만펼쳐진다() {
        // Given
        let wish = Wish(
            id: "wish-1",
            emoji: "🏄",
            category: .wantToDo,
            title: "서핑 배우기",
            endDate: now.endOfDay,
            notifications: [SeepNotification()],
            steps: [WishStep(title: "보드 대여", order: 0)],
            memo: "오전반"
        )

        // When
        let viewModel = makeViewModel(mode: .edit(wish))

        // Then
        XCTAssertEqual(viewModel.visibleBlocks, [.memo, .steps, .notification])
        XCTAssertTrue(viewModel.isRevealed(.date))
        XCTAssertEqual(viewModel.chips, [.photo, .letter])
    }

    // MARK: GH-70 TC10

    func test_GH70_TC10_아무것도안바꾸고닫으면_바로닫힌다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))

        // When
        viewModel.send(.tapClose)

        // Then
        XCTAssertEqual(viewModel.route, .finish(nil))
    }

    func test_GH70_TC10_제목을넣고닫으면_버리기확인이나오고_버리면저장없이닫히며_로그1건() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        viewModel.send(.inputTitle("서핑 배우기"))

        // When
        viewModel.send(.tapClose)

        // Then
        XCTAssertEqual(viewModel.route, .confirmDiscard)
        viewModel.send(.routeHandled)
        viewModel.send(.confirmDiscard)
        XCTAssertEqual(viewModel.route, .finish(nil))
        XCTAssertTrue(wishRepository.addedWishes.isEmpty)
        let discards = logManager.sentEvents
            .compactMap { $0 as? ClickEvent }
            .filter { ($0.extraParameters?[.objectId] as? LogObjectId) == .discardWrite }
        XCTAssertEqual(discards.count, 1)
        XCTAssertEqual(discards.first?.screen, .write)
    }

    func test_GH70_TC10_계속쓰기를고르면_입력이남아있다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        viewModel.send(.inputTitle("서핑 배우기"))

        // When: 확인에서 계속 쓰기 — ViewModel 에는 아무것도 보내지 않는다
        viewModel.send(.tapClose)
        viewModel.send(.routeHandled)

        // Then
        XCTAssertEqual(viewModel.state.title, "서핑 배우기")
        XCTAssertNil(viewModel.route)
    }

    // MARK: GH-70 TC11

    func test_GH70_TC11_수정에서안바꾸고취소하면_바로닫히고_바꾼뒤취소하면_버리기확인이나온다() {
        // Given
        let wish = Wish(id: "wish-1", emoji: "🏄", title: "서핑 배우기", memo: "오전반")
        let untouched = makeViewModel(mode: .edit(wish))
        let changed = makeViewModel(mode: .edit(wish))

        // When
        untouched.send(.tapClose)
        changed.send(.inputMemo("오후반"))
        changed.send(.tapClose)

        // Then
        XCTAssertEqual(untouched.route, .finish(nil))
        XCTAssertEqual(changed.route, .confirmDiscard)
    }

    // MARK: GH-70 TC12

    func test_GH70_TC12_태그를누르면_해시태그시트가뜬다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))

        // When
        viewModel.send(.tapHashtag)

        // Then
        XCTAssertEqual(viewModel.state.sheet, .hashtag)
    }

    // MARK: GH-70 TC13

    func test_GH70_TC13_칩을누르면_add_block로그1건에_block이붙고_수정이면wish_edit화면이다() {
        // Given
        let write = makeViewModel(mode: .add(.wantToDo))
        let edit = makeViewModel(mode: .edit(Wish(id: "wish-1", emoji: "🏄", title: "서핑 배우기")))

        // When
        write.send(.tapChip(.memo))
        edit.send(.tapChip(.date))

        // Then
        let events = addBlockEvents()
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].screen, .write)
        XCTAssertEqual(events[0].extraParameters?[.block] as? String, "memo")
        XCTAssertEqual(events[1].screen, .wishEdit)
        XCTAssertEqual(events[1].extraParameters?[.block] as? String, "date")
    }
}
