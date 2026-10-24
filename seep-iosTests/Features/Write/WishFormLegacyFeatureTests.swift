import XCTest

@testable import seep_ios_dev

/// 레거시 `WriteReactor`·`WishEditReactor` 테스트를 SwiftUI 작성·수정 폼으로 옮긴 것 (원래 이름 유지).
/// 단계(GH-5)·목표 금액(GH-16)·링크(GH-29)·장소(GH-31)
final class WishFormLegacyFeatureTests: WishFormFeatureTestCase {
    private let link = "https://store.example.com/p/1"
    private let place = WishPlace(name: "성산일출봉", address: "제주 서귀포시 성산읍 성산리 1", latitude: 33.458, longitude: 126.942)

    private func makeSteps(count: Int, doneCount: Int = 0) -> [WishStep] {
        (0..<count).map { index in
            WishStep(id: "step-\(index)", title: "단계 \(index)", isDone: index < doneCount, order: index)
        }
    }

    // MARK: GH-5 TC13 (작성)

    func test_GH5_TC13_단계2개를추가하고_작성완료하면_위시와단계가함께저장된다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)
        viewModel.send(.addStep("항공권 예약"))
        viewModel.send(.addStep("숙소 예약"))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.count, 1)
        let steps = wishRepository.addedWishes.first?.steps ?? []
        XCTAssertEqual(steps.map(\.title), ["항공권 예약", "숙소 예약"])
        XCTAssertEqual(steps.map(\.order), [0, 1])
        XCTAssertEqual(steps.map(\.isDone), [false, false])
    }

    // MARK: GH-5 TC14

    func test_GH5_TC14_단계를추가했지만_작성완료전에닫으면_아무것도저장되지않는다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)
        viewModel.send(.addStep("항공권 예약"))
        viewModel.send(.addStep("숙소 예약"))

        // When: 입력이 있으면 버릴지 묻고, 버리면 닫힌다 (GH-70 R-18)
        viewModel.send(.tapClose)
        XCTAssertEqual(viewModel.route, .confirmDiscard)
        viewModel.send(.confirmDiscard)

        // Then
        XCTAssertTrue(wishRepository.addedWishes.isEmpty)
        XCTAssertEqual(viewModel.route, .finish(nil))
    }

    // MARK: GH-5 TC19

    func test_GH5_TC19_단계없이작성하면_단계0개로저장된다() {
        // Given
        let viewModel = makeWrite(category: .wantToDo)

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.count, 1)
        XCTAssertEqual(wishRepository.addedWishes.first?.steps, [])
    }

    // MARK: GH-5 TC1 (수정)

    func test_GH5_TC1_수정화면에서_단계를추가하고_수정완료하면_단계가함께저장된다() {
        // Given
        let viewModel = makeEdit(Wish(id: "wish-1", emoji: "🏝️", title: "제주도 한 달 살기", steps: []))
        viewModel.send(.addStep("날짜 정하기"))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.updatedWishes.map(\.id), ["wish-1"])
        let steps = wishRepository.updatedWishes.first?.steps ?? []
        XCTAssertEqual(steps.map(\.title), ["날짜 정하기"])
        XCTAssertEqual(steps.map(\.isDone), [false])
    }

    // MARK: GH-5 TC5

    func test_GH5_TC5_미완료단계를지우고_수정완료하면_완료된단계만_isDone그대로저장된다() {
        // Given
        let steps = makeSteps(count: 2, doneCount: 1)
        let viewModel = makeEdit(Wish(id: "wish-1", emoji: "🏝️", title: "제주도 한 달 살기", steps: steps))
        viewModel.send(.deleteStep(index: 1))

        // When
        viewModel.send(.tapSave)

        // Then
        let saved = wishRepository.updatedWishes.first?.steps ?? []
        XCTAssertEqual(saved.map(\.id), ["step-0"])
        XCTAssertEqual(saved.map(\.isDone), [true])
    }

    // MARK: GH-5 TC12

    func test_GH5_TC12_제목만바꿔저장하면_단계와완료상태가그대로저장된다() {
        // Given
        let steps = makeSteps(count: 3, doneCount: 2)
        let viewModel = makeEdit(Wish(id: "wish-1", emoji: "🏝️", title: "제주도 한 달 살기", steps: steps))
        viewModel.send(.inputTitle("제주도 두 달 살기"))

        // When
        viewModel.send(.tapSave)

        // Then
        let saved = wishRepository.updatedWishes.first
        XCTAssertEqual(saved?.title, "제주도 두 달 살기")
        XCTAssertEqual(saved?.steps, steps)
    }

    // MARK: GH-5 TC23

    func test_GH5_TC23_단계를바꿨지만_수정완료전에나가면_저장되지않는다() {
        // Given
        let viewModel = makeEdit(Wish(id: "wish-1", emoji: "🏝️", title: "제주도 한 달 살기", steps: makeSteps(count: 2)))
        viewModel.send(.deleteStep(index: 0))
        viewModel.send(.deleteStep(index: 0))

        // When: 바꾼 게 있으면 버릴지 묻고, 버리면 닫힌다 (GH-70 R-18)
        viewModel.send(.tapClose)
        viewModel.send(.confirmDiscard)

        // Then
        XCTAssertTrue(wishRepository.updatedWishes.isEmpty)
        XCTAssertEqual(viewModel.route, .finish(nil))
    }

    // MARK: GH-16 TC1 (작성 목표 금액)

    func test_GH16_TC1_갖고싶어요에서_목표금액769000을입력하고_작성완료하면_targetAmount가저장된다() {
        // Given
        let viewModel = makeWrite(category: .wantToGet, title: "에어팟 맥스")
        viewModel.send(.inputTargetAmount("769,000"))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.count, 1)
        XCTAssertEqual(wishRepository.addedWishes.first?.targetAmount, 769_000)
        XCTAssertEqual(wishRepository.addedWishes.first?.savings, [])
    }

    // MARK: GH-16 TC2

    func test_GH16_TC2_갖고싶어요에서입력후_다른카테고리로바꿔저장하면_targetAmount는0이다() {
        // Given
        let viewModel = makeWrite(category: .wantToGet, title: "에어팟 맥스")
        viewModel.send(.inputTargetAmount("769000"))
        viewModel.send(.selectCategory(.wantToDo))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.first?.category, .wantToDo)
        XCTAssertEqual(wishRepository.addedWishes.first?.targetAmount, 0)
    }

    func test_GH16_TC2_다른카테고리로갔다가_갖고싶어요로돌아오면_입력했던목표금액이저장된다() {
        // Given
        let viewModel = makeWrite(category: .wantToGet, title: "에어팟 맥스")
        viewModel.send(.inputTargetAmount("769000"))
        viewModel.send(.selectCategory(.wantToGo))
        viewModel.send(.selectCategory(.wantToGet))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.first?.targetAmount, 769_000)
    }

    // MARK: GH-16 TC10

    func test_GH16_TC10_목표금액이있으면_작성완료로그에_has_target_amount_true가붙는다() {
        // Given
        let viewModel = makeWrite(category: .wantToGet, title: "에어팟 맥스")
        viewModel.send(.inputTargetAmount("769000"))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(writeClickEvents.count, 1)
        XCTAssertEqual(writeClickEvents.first?.screen, .write)
        XCTAssertEqual(writeClickEvents.first?.extraParameters?[.objectType] as? LogObjectType, .button)
        XCTAssertEqual(writeClickEvents.first?.extraParameters?[.hasTargetAmount] as? Bool, true)
    }

    func test_GH16_TC10_목표금액이없으면_작성완료로그에_has_target_amount_false가붙는다() {
        // Given
        let viewModel = makeWrite(category: .wantToGet, title: "에어팟 맥스")

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(writeClickEvents.count, 1)
        XCTAssertEqual(writeClickEvents.first?.extraParameters?[.hasTargetAmount] as? Bool, false)
    }

    func test_GH16_TC10_필수값이없어작성이안되면_작성완료로그를보내지않는다() {
        // Given
        let viewModel = makeWrite(category: .wantToGet, title: "에어팟 맥스")
        viewModel.send(.inputTitle(""))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertTrue(wishRepository.addedWishes.isEmpty)
        XCTAssertTrue(writeClickEvents.isEmpty)
    }

    // MARK: GH-16 TC12 (수정 목표 금액)

    private let savings = [
        WishSaving(id: "s-2", amount: 50_000),
        WishSaving(id: "s-1", amount: 30_000)
    ]

    private func makeEditWithAmount(targetAmount: Int) -> WishFormViewModel {
        makeEdit(Wish(
            id: "wish-1",
            emoji: "🎧",
            category: .wantToGet,
            title: "에어팟 맥스",
            targetAmount: targetAmount,
            savings: savings
        ))
    }

    func test_GH16_TC12_목표금액을지우고_수정완료하면_targetAmount0으로저장되고_기록은남는다() {
        // Given
        let viewModel = makeEditWithAmount(targetAmount: 769_000)
        XCTAssertEqual(viewModel.state.targetAmount, 769_000)

        // When
        viewModel.send(.inputTargetAmount(""))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.updatedWishes.first?.targetAmount, 0)
        XCTAssertEqual(finishedWish(viewModel)?.targetAmount, 0)
        XCTAssertEqual(finishedWish(viewModel)?.savings.map(\.id), ["s-2", "s-1"])
    }

    func test_GH16_TC12_목표금액을바꾸고_수정완료하면_새목표금액과_기존기록이함께돌아간다() {
        // Given
        let viewModel = makeEditWithAmount(targetAmount: 769_000)

        // When
        viewModel.send(.inputTargetAmount("500,000"))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.updatedWishes.first?.targetAmount, 500_000)
        XCTAssertEqual(finishedWish(viewModel)?.savings.count, 2)
    }

    // MARK: GH-16 TC13

    func test_GH16_TC13_카테고리를하고싶어요로바꿔_수정완료하면_targetAmount0으로저장되고_기록은남는다() {
        // Given
        let viewModel = makeEditWithAmount(targetAmount: 769_000)

        // When
        viewModel.send(.selectCategory(.wantToDo))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.updatedWishes.first?.category, .wantToDo)
        XCTAssertEqual(wishRepository.updatedWishes.first?.targetAmount, 0)
        XCTAssertEqual(finishedWish(viewModel)?.savings.count, 2)
    }

    // MARK: GH-29 TC2 (링크)

    private func makeEditWithLink(category: seep_ios_dev.Category = .wantToGet, link: String) -> WishFormViewModel {
        makeEdit(Wish(id: "wish-1", emoji: "🎧", category: category, title: "노이즈캔슬링 헤드폰", link: link))
    }

    func test_GH29_TC2_갖고싶어요에서링크를넣고_작성완료하면_link가저장된다() {
        // Given
        let viewModel = makeWrite(category: .wantToGet, title: "노이즈캔슬링 헤드폰")
        viewModel.send(.inputLink(link))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.count, 1)
        XCTAssertEqual(wishRepository.addedWishes.first?.link, link)
    }

    func test_GH29_TC2_링크칸이비어있으면_링크없이저장된다() {
        // Given
        let viewModel = makeWrite(category: .wantToGet, title: "노이즈캔슬링 헤드폰")
        viewModel.send(.inputLink(""))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.first?.link, "")
    }

    // MARK: GH-29 TC3

    func test_GH29_TC3_링크형식이아니면_작성완료가비활성이고_눌러도저장되지않는다() {
        // Given
        let viewModel = makeWrite(category: .wantToGet, title: "노이즈캔슬링 헤드폰")

        // When
        viewModel.send(.inputLink("헤드폰 매장 어딘가"))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(viewModel.state.saveButtonState, .initial)
        XCTAssertTrue(wishRepository.addedWishes.isEmpty)
    }

    func test_GH29_TC3_링크형식이아니어도_하고싶어요로바꾸면_작성할수있고_링크는비운다() {
        // Given
        let viewModel = makeWrite(category: .wantToGet, title: "노이즈캔슬링 헤드폰")
        viewModel.send(.inputLink("헤드폰 매장 어딘가"))

        // When
        viewModel.send(.selectCategory(.wantToDo))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(viewModel.state.saveButtonState, .active)
        XCTAssertEqual(wishRepository.addedWishes.first?.link, "")
    }

    func test_GH29_TC3_수정화면에서링크형식이아니면_수정완료가비활성이고_저장되지않는다() {
        // Given
        let viewModel = makeEditWithLink(link: link)

        // When
        viewModel.send(.inputLink("헤드폰 매장 어딘가"))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(viewModel.state.saveButtonState, .more)
        XCTAssertTrue(wishRepository.updatedWishes.isEmpty)
    }

    // MARK: GH-29 TC4

    func test_GH29_TC4_앞뒤공백포함링크를저장하면_공백이제거된값이저장된다() {
        // Given
        let viewModel = makeWrite(category: .wantToGet, title: "노이즈캔슬링 헤드폰")
        viewModel.send(.inputLink("  \(link) \n"))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.first?.link, link)
    }

    // MARK: GH-29 TC6

    func test_GH29_TC6_미리보기를못불러와도_링크는저장된다() {
        // Given: 미리보기를 못 불러온다
        linkMetadataProvider.fetchPreviewResult = nil
        let viewModel = makeWrite(category: .wantToGet, title: "노이즈캔슬링 헤드폰")
        viewModel.send(.inputLink(link))
        XCTAssertEqual(viewModel.state.linkPreview, .failed(domain: "store.example.com"))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(viewModel.state.saveButtonState, .active)
        XCTAssertEqual(wishRepository.addedWishes.first?.link, link)
    }

    // MARK: GH-29 TC7

    func test_GH29_TC7_링크있는갖고싶어요위시를_하고싶어요로바꿔저장하면_link는빈문자열이다() {
        // Given
        let viewModel = makeEditWithLink(link: link)

        // When
        viewModel.send(.selectCategory(.wantToDo))
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.updatedWishes.first?.category, .wantToDo)
        XCTAssertEqual(wishRepository.updatedWishes.first?.link, "")
    }

    func test_GH29_TC7_링크를바꾸지않고수정완료하면_기존링크가그대로저장된다() {
        // Given
        let viewModel = makeEditWithLink(link: link)

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.updatedWishes.first?.link, link)
    }

    // MARK: GH-29 TC9

    func test_GH29_TC9_링크가없는기존위시레코드는_link가빈문자열이다() {
        // Given: 저장소 레코드로 바꿨다가 되돌린다 (GH-79 에서 Realm DTO → GRDB 레코드)
        let record = WishRecord(wish: Wish(title: "예전 위시"), updatedAt: Date())

        // When
        let wish = Wish(record: record, steps: [], savings: [], notifications: [])

        // Then
        XCTAssertEqual(wish.link, "")
        XCTAssertEqual(WishRecord(wish: Wish(link: link), updatedAt: Date()).link, link)
    }

    // MARK: GH-31 TC9 (장소)

    func test_GH31_TC9_가고싶어요에서장소를고르고_작성완료하면_위시와함께장소가저장된다() {
        // Given
        let viewModel = makeWrite(category: .wantToGo, title: "성산일출봉에서 새해 일출 보기")
        viewModel.send(.selectPlace(place))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.count, 1)
        XCTAssertEqual(wishRepository.addedWishes.first?.place, place)
    }

    func test_GH31_TC9_장소를고른뒤_다른카테고리로바꿔작성하면_장소는저장되지않는다() {
        // Given
        let viewModel = makeWrite(category: .wantToGo, title: "성산일출봉에서 새해 일출 보기")
        viewModel.send(.selectPlace(place))
        viewModel.send(.selectCategory(.wantToDo))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.addedWishes.first?.category, .wantToDo)
        XCTAssertNil(wishRepository.addedWishes.first?.place)
    }

    // MARK: GH-31 TC15

    func test_GH31_TC15_장소가붙은위시를_수정화면에서제목만바꿔저장하면_장소가유지된다() {
        // Given
        let viewModel = makeEdit(Wish(id: "wish-1", emoji: "🌅", category: .wantToGo, title: "일출 보기", place: place))
        viewModel.send(.inputTitle("성산일출봉에서 새해 일출 보기"))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(finishedWish(viewModel)?.title, "성산일출봉에서 새해 일출 보기")
        XCTAssertEqual(finishedWish(viewModel)?.place, place)
        XCTAssertEqual(wishRepository.updatedWishes.first?.place, place)
        XCTAssertFalse(viewModel.isPlaceVisible, "수정 폼은 장소를 고르지 않는다 (GH-31 R-10)")
    }
}
