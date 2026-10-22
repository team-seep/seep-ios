import XCTest

@testable import seep_ios_dev

/// 작성·수정 폼의 단계(GH-5)·링크(GH-29)·장소(GH-31) 섹션.
/// 레거시 `WishStepsViewModel`·`WishLinkViewModel`·`WishPlaceViewModel`의 작성·수정 케이스를 폼 ViewModel 로 옮겼다
final class WishFormSectionFeatureTests: WishFormFeatureTestCase {
    private let link = "https://store.example.com/p/1"
    private lazy var preview = LinkPreview(link: link, title: "무선 노이즈캔슬링 헤드폰", imageData: Data([0x1]))
    private let place = WishPlace(name: "성산일출봉", address: "제주 서귀포시 성산읍 성산리 1", latitude: 33.458, longitude: 126.942)

    private func makeSteps(count: Int, doneCount: Int = 0) -> [WishStep] {
        (0..<count).map { index in
            WishStep(id: "step-\(index)", title: "단계 \(index)", isDone: index < doneCount, order: index)
        }
    }

    private func makeEdit(steps: [WishStep]) -> WishFormViewModel {
        makeEdit(Wish(id: "wish-1", emoji: "🏝️", title: "제주도 한 달 살기", steps: steps))
    }

    /// 보낸 순서대로 토스트를 모은다. route 는 값 하나라 보낼 때마다 읽고 비운다
    private func sendCollectingToasts(_ viewModel: WishFormViewModel, _ actions: [WishFormViewModel.Action]) -> [String] {
        var toasts: [String] = []
        for action in actions {
            viewModel.send(action)
            if case .toast(let message) = viewModel.route { toasts.append(message) }
            viewModel.send(.routeHandled)
        }
        return toasts
    }

    private func events(objectId: LogObjectId) -> [any LogEventType] {
        logManager.sentEvents.filter { ($0.extraParameters?[.objectId] as? LogObjectId) == objectId }
    }

    // MARK: GH-5 단계 — 수정

    func test_GH5_TC1_수정화면에서_단계0개인위시에_단계를추가하면_미완료단계1개가된다() {
        // Given
        let viewModel = makeEdit(steps: [])

        // When
        viewModel.send(.addStep("  날짜 정하기 "))

        // Then
        XCTAssertEqual(viewModel.state.steps.map(\.title), ["날짜 정하기"])
        XCTAssertEqual(viewModel.state.steps.map(\.isDone), [false])
        XCTAssertEqual(viewModel.state.steps.map(\.order), [0])
        XCTAssertTrue(wishRepository.toggleStepCalls.isEmpty)
        XCTAssertTrue(wishRepository.updatedWishes.isEmpty)
    }

    func test_GH5_TC3_수정화면에서_단계10개면_추가하지않고_추가버튼이비활성이다() {
        // Given
        let viewModel = makeEdit(steps: makeSteps(count: 10))

        // When
        let toasts = sendCollectingToasts(viewModel, [.tapAddStep, .addStep("열한 번째 단계")])

        // Then
        XCTAssertEqual(viewModel.state.steps.count, 10)
        XCTAssertFalse(viewModel.state.isAddStepEnabled)
        XCTAssertEqual(toasts, [Strings.Detail.Step.Toast.maxCount, Strings.Detail.Step.Toast.maxCount])
    }

    func test_GH5_TC3_수정화면에서_단계9개면_추가버튼이활성이고_입력창을띄운다() {
        // Given
        let viewModel = makeEdit(steps: makeSteps(count: 9))

        // When
        viewModel.send(.tapAddStep)

        // Then
        XCTAssertTrue(viewModel.state.isAddStepEnabled)
        XCTAssertEqual(viewModel.route, .addStepAlert)
    }

    func test_GH5_TC4_수정화면에서_공백만입력하면_추가되지않는다() {
        // Given
        let viewModel = makeEdit(steps: [])

        // When
        viewModel.send(.addStep("   \n "))

        // Then
        XCTAssertTrue(viewModel.state.steps.isEmpty)
        XCTAssertTrue(events(objectId: .addStep).isEmpty)
    }

    func test_GH5_TC4_수정화면에서_30자를넘기면_추가되지않고_토스트가뜬다() {
        // Given
        let viewModel = makeEdit(steps: [])

        // When
        let toasts = sendCollectingToasts(viewModel, [.addStep(String(repeating: "가", count: 31))])

        // Then
        XCTAssertTrue(viewModel.state.steps.isEmpty)
        XCTAssertEqual(toasts, [Strings.Detail.Step.Toast.maxLength])
    }

    func test_GH5_TC4_수정화면에서_정확히30자는_추가된다() {
        // Given
        let viewModel = makeEdit(steps: [])
        let title = String(repeating: "가", count: 30)

        // When
        viewModel.send(.addStep(title))

        // Then
        XCTAssertEqual(viewModel.state.steps.map(\.title), [title])
    }

    func test_GH5_TC5_수정화면에서_미완료단계를삭제하면_완료된단계만_isDone그대로남는다() {
        // Given
        let steps = makeSteps(count: 2, doneCount: 1) // step-0 완료, step-1 미완료
        let viewModel = makeEdit(steps: steps)

        // When
        viewModel.send(.deleteStep(index: 1))

        // Then
        XCTAssertEqual(viewModel.state.steps.map(\.id), ["step-0"])
        XCTAssertEqual(viewModel.state.steps.map(\.isDone), [true])
        XCTAssertEqual(viewModel.state.steps.map(\.order), [0])
        XCTAssertEqual(WishStepProgress(steps: viewModel.state.steps), WishStepProgress(steps: [steps[0]]))
    }

    func test_GH5_TC9_수정화면에서_단계를추가하면_wish_edit화면_add_step로그가1건전송된다() {
        // Given
        let viewModel = makeEdit(steps: [])

        // When
        viewModel.send(.addStep("날짜 정하기"))

        // Then
        let clickEvents = events(objectId: .addStep)
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.name, .click)
        XCTAssertEqual(clickEvents.first?.parameters["screen"] as? String, "wish_edit")
        XCTAssertEqual(clickEvents.first?.parameters["object_type"] as? String, "button")
        XCTAssertEqual(clickEvents.first?.parameters["object_id"] as? String, "add_step")
    }

    // MARK: GH-5 단계 — 작성

    func test_GH5_TC15_작성화면에서_단계를추가삭제하면_저장소를부르지않고_Output만바뀐다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)

        // When
        viewModel.send(.addStep("항공권 예약"))
        viewModel.send(.addStep("숙소 예약"))
        viewModel.send(.deleteStep(index: 0))

        // Then
        XCTAssertTrue(wishRepository.toggleStepCalls.isEmpty)
        XCTAssertTrue(wishRepository.addedWishes.isEmpty)
        XCTAssertEqual(viewModel.state.steps.map(\.title), ["숙소 예약"])
        XCTAssertEqual(viewModel.state.steps.map(\.isDone), [false])
    }

    func test_GH5_TC16_작성화면에서_3개중가운데를삭제하면_남은단계의순서가0과1로다시매겨진다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)
        ["날짜 정하기", "항공권 예약", "숙소 예약"].forEach { viewModel.send(.addStep($0)) }

        // When
        viewModel.send(.deleteStep(index: 1))

        // Then
        XCTAssertEqual(viewModel.state.steps.map(\.title), ["날짜 정하기", "숙소 예약"])
        XCTAssertEqual(viewModel.state.steps.map(\.order), [0, 1])
    }

    func test_GH5_TC17_작성화면에서_10개를넘거나_공백이나30자초과면_추가되지않는다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)

        // When
        let toasts = sendCollectingToasts(
            viewModel,
            [.addStep("   "), .addStep(String(repeating: "가", count: 31))] + (0..<11).map { .addStep("단계 \($0)") }
        )

        // Then
        XCTAssertEqual(viewModel.state.steps.count, 10)
        XCTAssertFalse(viewModel.state.isAddStepEnabled)
        XCTAssertEqual(toasts, [Strings.Detail.Step.Toast.maxLength, Strings.Detail.Step.Toast.maxCount])
    }

    func test_GH5_TC20_작성화면에서_단계를추가하면_write화면_add_step로그가1건전송된다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)

        // When
        viewModel.send(.addStep("항공권 예약"))

        // Then
        let clickEvents = events(objectId: .addStep)
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.name, .click)
        XCTAssertEqual(clickEvents.first?.parameters["screen"] as? String, "write")
        XCTAssertEqual(clickEvents.first?.parameters["object_type"] as? String, "button")
        XCTAssertEqual(clickEvents.first?.parameters["object_id"] as? String, "add_step")
    }

    // MARK: GH-29 링크

    func test_GH29_TC1_갖고싶어요작성화면이면_링크칸이보이고_하고싶어요로바꾸면_사라진다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToGet))
        XCTAssertTrue(viewModel.state.isLinkVisible)

        // When
        viewModel.send(.selectCategory(.wantToDo))

        // Then
        XCTAssertFalse(viewModel.state.isLinkVisible)
    }

    func test_GH29_TC1_하고싶어요작성화면이면_링크칸이없고_갖고싶어요로바꾸면_보인다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToDo))
        XCTAssertFalse(viewModel.state.isLinkVisible)

        // When
        viewModel.send(.selectCategory(.wantToGet))

        // Then
        XCTAssertTrue(viewModel.state.isLinkVisible)
    }

    func test_GH29_TC3_링크형식이아닌글을입력하면_형식안내가뜨고_invalid가Reactor로넘어간다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToGet))

        // When
        viewModel.send(.inputLink("헤드폰 매장 어딘가"))

        // Then
        XCTAssertEqual(viewModel.state.linkError, Strings.Write.Link.errorInvalid)
        XCTAssertEqual(viewModel.state.link, .invalid)
        XCTAssertEqual(viewModel.state.linkPreview, .hidden)
        XCTAssertTrue(linkMetadataProvider.fetchedLinks.isEmpty)
    }

    func test_GH29_TC3_형식오류뒤에올바른링크로고치면_안내가사라진다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToGet))
        viewModel.send(.inputLink("store.example.com"))

        // When
        viewModel.send(.inputLink(link))

        // Then
        XCTAssertNil(viewModel.state.linkError)
        XCTAssertEqual(viewModel.state.link, .valid(link))
    }

    func test_GH29_TC3_http와https외의주소나_2000자를넘는링크는_invalid다() {
        // Given
        let longLink = "https://store.example.com/" + String(repeating: "a", count: WishLinkInput.maxLength)

        // When
        let inputs = [
            WishLinkInput(text: "ftp://store.example.com/p/1"),
            WishLinkInput(text: "javascript:alert(1)"),
            WishLinkInput(text: "https://"),
            WishLinkInput(text: longLink)
        ]

        // Then
        XCTAssertEqual(inputs, [.invalid, .invalid, .invalid, .invalid])
        XCTAssertEqual(WishLinkInput(text: "   "), .empty)
    }

    func test_GH29_TC4_앞뒤공백이있는링크를입력하면_공백을지운값이넘어간다() {
        // Given
        let viewModel = makeViewModel(mode: .add(.wantToGet))

        // When
        viewModel.send(.inputLink("  \(link)\n"))

        // Then
        XCTAssertEqual(viewModel.state.link, .valid(link))
        XCTAssertEqual(linkMetadataProvider.fetchedLinks, [link])
    }

    func test_GH29_TC5_제공자가제목이미지를돌려주면_불러오는중다음에_제목과도메인카드가뜬다() {
        // Given
        linkMetadataProvider.isDeferred = true
        let viewModel = makeViewModel(mode: .add(.wantToGet))
        var states: [WishFormLinkPreview] = [viewModel.state.linkPreview]

        // When
        viewModel.send(.inputLink(link))
        states.append(viewModel.state.linkPreview)
        linkMetadataProvider.complete(at: 0, with: preview)
        states.append(viewModel.state.linkPreview)

        // Then
        XCTAssertEqual(states, [.hidden, .loading(domain: "store.example.com"), .loaded(preview)])
        XCTAssertEqual(preview.domain, "store.example.com")
    }

    func test_GH29_TC5_응답이오기전에링크가바뀌면_이전응답은버린다() {
        // Given
        linkMetadataProvider.isDeferred = true
        let viewModel = makeViewModel(mode: .add(.wantToGet))
        viewModel.send(.inputLink(link))
        viewModel.send(.inputLink("https://www.shop.example.com/p/2"))

        // When
        linkMetadataProvider.complete(at: 0, with: preview)

        // Then
        XCTAssertEqual(viewModel.state.linkPreview, .loading(domain: "shop.example.com"))
    }

    func test_GH29_TC6_제공자가실패하면_도메인만있는카드가뜨고_링크는그대로넘어간다() {
        // Given
        linkMetadataProvider.fetchPreviewResult = nil
        let viewModel = makeViewModel(mode: .add(.wantToGet))

        // When
        viewModel.send(.inputLink(link))

        // Then
        XCTAssertEqual(viewModel.state.linkPreview, .failed(domain: "store.example.com"))
        XCTAssertEqual(viewModel.state.link, .valid(link))
        XCTAssertNil(viewModel.state.linkError)
    }

    func test_GH29_TC11_작성중미리보기카드가처음뜨면_impression로그가1건만전송된다() {
        // Given
        linkMetadataProvider.fetchPreviewResult = preview
        let viewModel = makeViewModel(mode: .add(.wantToGet))

        // When
        viewModel.send(.inputLink(link))
        viewModel.send(.inputLink(""))
        viewModel.send(.inputLink("https://store.example.com/p/2"))

        // Then
        let impressions = events(objectId: .wishLinkPreview)
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.name, .impression)
        XCTAssertEqual(impressions.first?.screen, .write)
        XCTAssertEqual(impressions.first?.extraParameters?[.objectType] as? LogObjectType, .card)
    }

    func test_GH29_TC11_수정화면에서실패카드가뜨면_wish_edit화면으로impression이전송된다() {
        // Given
        linkMetadataProvider.fetchPreviewResult = nil
        let wish = Wish(id: "wish-1", category: .wantToGet, title: "헤드폰", link: link)
        let viewModel = makeViewModel(mode: .edit(wish))

        // When
        viewModel.send(.onAppear)

        // Then
        let impressions = events(objectId: .wishLinkPreview)
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.screen, .wishEdit)
    }

    func test_GH29_TC12_붙여넣기를누르면_칸에링크가들어가고_paste_wish_link클릭로그가1건전송된다() {
        // Given
        linkMetadataProvider.fetchPreviewResult = preview
        let viewModel = makeViewModel(mode: .add(.wantToGet))

        // When
        viewModel.send(.pasteLink(" \(link) "))

        // Then
        XCTAssertEqual(viewModel.state.linkText, link)
        XCTAssertEqual(viewModel.state.link, .valid(link))
        let clickEvents = events(objectId: .pasteWishLink)
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.name, .click)
        XCTAssertEqual(clickEvents.first?.screen, .write)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }

    // MARK: GH-31 장소

    func test_GH31_TC1_수정화면에서카테고리를바꾸면_섹션은숨고_장소값은남는다() {
        // Given
        let wish = Wish(id: "wish-1", emoji: "🌅", category: .wantToGo, title: "성산일출봉에서 새해 일출 보기", place: place)
        let viewModel = makeEdit(wish)

        // When
        viewModel.send(.selectCategory(.wantToDo))

        // Then
        XCTAssertFalse(viewModel.isPlaceVisible)
        XCTAssertEqual(viewModel.state.place, place)
        XCTAssertTrue(wishRepository.updatePlaceCalls.isEmpty)
    }

    func test_GH31_TC9_작성화면에서는_장소를골라도_Repository에저장하지않는다() {
        // Given
        let viewModel = makeWrite(category: .wantToGo)

        // When
        viewModel.send(.selectPlace(place))

        // Then
        XCTAssertTrue(wishRepository.updatePlaceCalls.isEmpty)
        XCTAssertTrue(wishRepository.addedWishes.isEmpty)
        XCTAssertEqual(viewModel.state.place, place)
    }

    func test_GH31_TC9_작성화면에서카테고리를바꾸면_섹션이접히고펴진다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)
        XCTAssertFalse(viewModel.isPlaceVisible)

        // When
        viewModel.send(.selectCategory(.wantToGo))

        // Then
        XCTAssertTrue(viewModel.isPlaceVisible)
    }

    func test_GH31_TC11_작성화면에서장소섹션을탭하면_write의add_place클릭로그가1건전송된다() {
        // Given
        let viewModel = makeWrite(category: .wantToGo)

        // When
        viewModel.send(.tapPlace)

        // Then
        let clickEvents = logManager.sentEvents.compactMap { $0 as? ClickEvent }
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.screen, .write)
        XCTAssertEqual(clickEvents.first?.parameters["object_id"] as? String, "add_place")
    }
}
