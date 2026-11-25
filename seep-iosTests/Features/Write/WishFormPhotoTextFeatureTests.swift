import XCTest

@testable import seep_ios

/// 사진 속 글자로 채우기: 사진을 고르면 제목·금액 칩을 제안한다 (GH-144)
final class WishFormPhotoTextFeatureTests: WishFormFeatureTestCase {
    private let imageData = Data([0xFF, 0xD8, 0xFF])
    private let otherImageData = Data([0x89, 0x50, 0x4E])
    private let productLines = [
        RecognizedTextLine(text: "무료배송 · 오늘출발", height: 11),
        RecognizedTextLine(text: "접이식 캠핑 체어 L", height: 15),
        RecognizedTextLine(text: "캠핑 체어", height: 13),
        RecognizedTextLine(text: "89,000원", height: 18),
        RecognizedTextLine(text: "장바구니", height: 12)
    ]
    private let usdLines = [
        RecognizedTextLine(text: "Folding Camp Chair", height: 15),
        RecognizedTextLine(text: "$12.99", height: 18)
    ]

    private var impressions: [any LogEventType] {
        logManager.sentEvents.filter {
            $0.name == .impression && ($0.extraParameters?[.objectId] as? LogObjectId) == .photoTextSuggestion
        }
    }

    private func pickProductPhoto(_ form: WishFormViewModel, lines: [RecognizedTextLine]? = nil) {
        photoTextRecognizer.result = lines ?? productLines
        form.send(.pickPhoto(imageData))
    }

    // MARK: GH-144 TC4

    func test_GH144_TC4_갖고싶어요에서사진을고르면_인식후보가제목금액칩으로들어간다() {
        // Given
        let form = makeWrite(category: .wantToGet, title: "")

        // When
        pickProductPhoto(form)

        // Then
        XCTAssertEqual(photoTextRecognizer.recognizedImages, [imageData])
        XCTAssertEqual(form.state.photoTextTitles, ["접이식 캠핑 체어 L", "캠핑 체어"])
        XCTAssertEqual(form.state.photoTextAmountChip, PhotoTextAmount(amount: 89_000, currency: "KRW"))
        XCTAssertTrue(form.state.isPhotoTextSuggestionVisible)
    }

    func test_GH144_TC4_하고싶어요면_금액칩이없다() {
        // Given
        let form = makeWrite(category: .wantToDo, title: "")

        // When
        pickProductPhoto(form)

        // Then
        XCTAssertEqual(form.state.photoTextTitles, ["접이식 캠핑 체어 L", "캠핑 체어"])
        XCTAssertNil(form.state.photoTextAmountChip)
    }

    func test_GH144_TC4_찾은글자가없으면_칩줄이보이지않는다() {
        // Given
        let form = makeWrite(category: .wantToGet, title: "")

        // When
        pickProductPhoto(form, lines: [RecognizedTextLine(text: "장바구니", height: 12)])

        // Then
        XCTAssertFalse(form.state.isPhotoTextSuggestionVisible)
        XCTAssertTrue(impressions.isEmpty)
    }

    // MARK: GH-144 TC5

    func test_GH144_TC5_제목칩을누르면_제목을바꾸고제목칩이사라지며_토스트가나온다() {
        // Given
        let form = makeWrite(category: .wantToGet, title: "캠핑")
        pickProductPhoto(form)

        // When
        form.send(.tapPhotoTextTitle("접이식 캠핑 체어 L"))

        // Then
        XCTAssertEqual(form.state.title, "접이식 캠핑 체어 L")
        XCTAssertEqual(form.state.photoTextTitles, [])
        XCTAssertEqual(form.route, .toast("👏 사진 속 글자로 채웠어요"))
        XCTAssertEqual(form.state.saveButtonState, .active)
        // 금액 칩은 남아 있어 캡션도 보인다
        XCTAssertTrue(form.state.isPhotoTextSuggestionVisible)
    }

    // MARK: GH-144 TC6

    func test_GH144_TC6_금액칩을누르면_목표금액블록이열리고_금액통화가들어간다() {
        // Given
        let form = makeWrite(category: .wantToGet)
        pickProductPhoto(form)
        XCTAssertFalse(form.visibleBlocks.contains(.targetAmount))

        // When
        form.send(.tapPhotoTextAmount)

        // Then
        XCTAssertTrue(form.visibleBlocks.contains(.targetAmount))
        XCTAssertEqual(form.state.targetAmount, 89_000)
        XCTAssertEqual(form.state.targetAmountText, "89,000")
        XCTAssertEqual(form.state.currency, "KRW")
        XCTAssertNil(form.state.photoTextAmountChip)
        XCTAssertEqual(form.route, .toast("👏 사진 속 글자로 채웠어요"))
    }

    func test_GH144_TC6_다른통화금액칩은_통화를바꿔넣고_칩을다쓰면캡션까지사라진다() {
        // Given
        let form = makeWrite(category: .wantToGet)
        form.send(.tapChip(.targetAmount))
        form.send(.inputTargetAmount("50000"))
        pickProductPhoto(form, lines: usdLines)

        // When
        form.send(.tapPhotoTextTitle("Folding Camp Chair"))
        form.send(.tapPhotoTextAmount)

        // Then
        XCTAssertEqual(form.state.currency, "USD")
        XCTAssertEqual(form.state.targetAmount, 1_299)
        XCTAssertEqual(form.state.targetAmountText, "12.99")
        XCTAssertEqual(form.state.title, "Folding Camp Chair")
        XCTAssertFalse(form.state.isPhotoTextSuggestionVisible)
    }

    func test_GH144_TC6_저장하면_채운제목과목표금액이위시에들어간다() {
        // Given
        let form = makeWrite(category: .wantToGet, title: "")
        photoStorage.savePhotoResult = .success("new.jpg")
        pickProductPhoto(form)

        // When
        form.send(.tapPhotoTextTitle("접이식 캠핑 체어 L"))
        form.send(.tapPhotoTextAmount)
        form.send(.tapSave)

        // Then
        let added = wishRepository.addedWishes.first
        XCTAssertEqual(added?.title, "접이식 캠핑 체어 L")
        XCTAssertEqual(added?.targetAmount, 89_000)
        XCTAssertEqual(added?.currency, "KRW")
        XCTAssertEqual(added?.photoFileName, "new.jpg")
    }

    // MARK: GH-144 TC7

    func test_GH144_TC7_저금기록이있어통화를못바꾸면_다른통화금액칩은보이지않는다() {
        // Given: 저금 기록이 있는 원화 위시
        let wish = Wish(
            id: "wish-1", category: .wantToGet, title: "캠핑 의자", targetAmount: 100_000, currency: "KRW",
            savings: [WishSaving(id: "s-1", amount: 30_000)]
        )
        let form = makeEdit(wish)

        // When
        pickProductPhoto(form, lines: usdLines)

        // Then
        XCTAssertTrue(form.state.isCurrencyLocked)
        XCTAssertNotNil(form.state.photoTextAmount)
        XCTAssertNil(form.state.photoTextAmountChip)
        form.send(.tapPhotoTextAmount)
        XCTAssertEqual(form.state.targetAmount, 100_000)
    }

    func test_GH144_TC7_저금기록이있어도_같은통화금액칩은보인다() {
        // Given
        let wish = Wish(
            id: "wish-1", category: .wantToGet, title: "캠핑 의자", targetAmount: 100_000, currency: "KRW",
            savings: [WishSaving(id: "s-1", amount: 30_000)]
        )
        let form = makeEdit(wish)

        // When
        pickProductPhoto(form)
        form.send(.tapPhotoTextAmount)

        // Then
        XCTAssertEqual(form.state.targetAmount, 89_000)
        XCTAssertEqual(form.state.currency, "KRW")
    }

    // MARK: GH-144 TC8

    func test_GH144_TC8_사진을빼면_칩이사라지고_채운제목은그대로다() {
        // Given
        let form = makeWrite(category: .wantToGet, title: "")
        pickProductPhoto(form)
        form.send(.tapPhotoTextTitle("캠핑 체어"))

        // When
        form.send(.removeBlock(.photo))

        // Then
        XCTAssertFalse(form.state.isPhotoTextSuggestionVisible)
        XCTAssertEqual(form.state.photoTextTitles, [])
        XCTAssertNil(form.state.photoTextAmount)
        XCTAssertEqual(form.state.title, "캠핑 체어")
    }

    func test_GH144_TC8_사진을바꾸면_칩을지우고다시읽으며_앞사진의늦은결과는버린다() {
        // Given: 인식이 늦게 끝난다
        let form = makeWrite(category: .wantToGet, title: "")
        photoTextRecognizer.isDeferred = true
        form.send(.pickPhoto(imageData))

        // When: 첫 사진 결과가 오기 전에 사진을 바꾼다
        form.send(.pickPhoto(otherImageData))
        photoTextRecognizer.complete(at: 0, with: productLines)
        let afterStale = form.state.isPhotoTextSuggestionVisible
        photoTextRecognizer.complete(at: 1, with: usdLines)

        // Then
        XCTAssertEqual(photoTextRecognizer.recognizedImages, [imageData, otherImageData])
        XCTAssertFalse(afterStale)
        XCTAssertEqual(form.state.photoTextTitles, ["Folding Camp Chair"])
        XCTAssertEqual(form.state.photoTextAmount, PhotoTextAmount(amount: 1_299, currency: "USD"))
    }

    func test_GH144_TC8_사진을뺀뒤에온결과는_버린다() {
        // Given
        let form = makeWrite(category: .wantToGet, title: "")
        photoTextRecognizer.isDeferred = true
        form.send(.pickPhoto(imageData))

        // When
        form.send(.removeBlock(.photo))
        photoTextRecognizer.complete(at: 0, with: productLines)

        // Then
        XCTAssertFalse(form.state.isPhotoTextSuggestionVisible)
    }

    // MARK: GH-144 TC9

    func test_GH144_TC9_저장된사진이있는위시를열면_인식을부르지않는다() {
        // Given
        photoStorage.existingFileNames = ["wish-1-old.jpg"]
        let wish = Wish(id: "wish-1", category: .wantToGet, title: "캠핑 의자", photoFileName: "wish-1-old.jpg")

        // When
        let form = makeEdit(wish)
        form.send(.onAppear)

        // Then
        XCTAssertEqual(form.state.photo, .stored(fileName: "wish-1-old.jpg"))
        XCTAssertEqual(photoTextRecognizer.recognizedImages.count, 0)
        XCTAssertFalse(form.state.isPhotoTextSuggestionVisible)
    }

    // MARK: GH-144 TC10

    func test_GH144_TC10_칩줄이처음보이면_노출로그가사진마다1건전송된다() {
        // Given
        let form = makeWrite(category: .wantToGet, title: "")

        // When
        pickProductPhoto(form)
        form.send(.tapPhotoTextTitle("캠핑 체어"))
        form.send(.selectCategory(.wantToDo))
        form.send(.selectCategory(.wantToGet))

        // Then
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.screen, .write)
        XCTAssertEqual(impressions.first?.extraParameters?[.objectType] as? LogObjectType, .card)
        XCTAssertEqual(impressions.first?.extraParameters?[.titleCount] as? Int, 2)
        XCTAssertEqual(impressions.first?.extraParameters?[.hasAmount] as? Bool, true)

        // When: 사진을 바꾸면 다시 1건
        form.send(.pickPhoto(otherImageData))
        XCTAssertEqual(impressions.count, 2)
    }

    func test_GH144_TC10_하고싶어요에서금액만찾았으면_갖고싶어요로바꿀때노출로그가나간다() {
        // Given
        let form = makeWrite(category: .wantToDo, title: "")
        pickProductPhoto(form, lines: [RecognizedTextLine(text: "89,000원", height: 18)])
        XCTAssertTrue(impressions.isEmpty)

        // When
        form.send(.selectCategory(.wantToGet))

        // Then
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.extraParameters?[.titleCount] as? Int, 0)
        XCTAssertEqual(impressions.first?.extraParameters?[.hasAmount] as? Bool, true)
    }

    func test_GH144_TC10_칩을누를때마다_kind와함께클릭로그가1건씩전송된다() {
        // Given
        let wish = Wish(id: "wish-1", category: .wantToGet, title: "캠핑 의자")
        let form = makeEdit(wish)
        pickProductPhoto(form)

        // When
        form.send(.tapPhotoTextTitle("접이식 캠핑 체어 L"))
        form.send(.tapPhotoTextAmount)

        // Then
        let events = clickEvents(objectId: .fillFromPhotoText)
        XCTAssertEqual(events.map { $0.extraParameters?[.kind] as? String }, ["title", "amount"])
        XCTAssertEqual(events.map(\.screen), [.wishEdit, .wishEdit])
        XCTAssertEqual(events.first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }

    // MARK: GH-144 TC12

    func test_GH144_TC12_제목후보가18자보다길면_칩은앞18자이고_누르면그대로채운다() {
        // Given
        let long = "접이식 캠핑 체어 L 경량 알루미늄 의자 세트"
        let form = makeWrite(category: .wantToGet, title: "")
        pickProductPhoto(form, lines: [RecognizedTextLine(text: long, height: 15)])
        let chip = String(long.prefix(WishFormViewModel.titleMaxLength)).trimmingCharacters(in: .whitespaces)

        // When
        form.send(.tapPhotoTextTitle(chip))

        // Then
        XCTAssertEqual(form.state.photoTextTitles.isEmpty, true)
        XCTAssertLessThanOrEqual(chip.count, WishFormViewModel.titleMaxLength)
        XCTAssertEqual(form.state.title, chip)
        // 직접 치다 닿은 게 아니라 최대 길이 안내는 띄우지 않는다
        XCTAssertNil(form.state.titleError)
    }
}
