import XCTest

@testable import seep_ios

/// 작성/수정 문서의 사진 블록 (GH-61 R-10, R-11)
final class WishFormPhotoFeatureTests: WishFormFeatureTestCase {
    private let imageData = Data([0xFF, 0xD8, 0xFF])

    private func photoWish() -> Wish {
        photoStorage.existingFileNames = ["wish-1-old.jpg"]
        return Wish(id: "wish-1", title: "제주도 한 달 살기", photoFileName: "wish-1-old.jpg")
    }

    // MARK: GH-61 TC17

    func test_GH61_TC17_사진없는위시의문서는_사진칩이있고_칩을누르면사진고르기가열린다() {
        // Given
        let form = makeEdit(Wish(id: "wish-1", title: "제주도 한 달 살기"))

        // When
        form.send(.tapChip(.photo))

        // Then
        XCTAssertTrue(form.chips.contains(.photo))
        XCTAssertEqual(form.route, .photoPicker)
        let events = clickEvents(objectId: .addBlock)
        XCTAssertEqual(events.first?.extraParameters?[.block] as? String, "photo")
    }

    // MARK: GH-61 TC18

    func test_GH61_TC18_작성에서사진을고르고저장하면_그위시id로파일을쓰고파일이름을저장한다() {
        // Given
        let form = makeWrite(category: .wantToGo)
        photoStorage.savePhotoResult = .success("new.jpg")

        // When
        form.send(.pickPhoto(imageData))
        let preview = form.photoPreview
        form.send(.tapSave)

        // Then
        XCTAssertEqual(preview, .data(imageData))
        XCTAssertEqual(form.visibleBlocks, [.photo])
        let added = wishRepository.addedWishes.first
        XCTAssertEqual(photoStorage.savePhotoCalls.map(\.wishId), [added?.id])
        XCTAssertEqual(added?.photoFileName, "new.jpg")
        XCTAssertEqual(finishedWish(form)?.photoFileName, "new.jpg")
        XCTAssertEqual(logManager.sentEvents.filter { $0.name == .savePhoto }.count, 1)
    }

    // MARK: GH-61 TC19

    func test_GH61_TC19_수정에서사진을바꾸고완료하면_새파일이름을저장하고이전파일을지운다() {
        // Given
        let form = makeEdit(photoWish())
        photoStorage.savePhotoResult = .success("wish-1-new.jpg")

        // When
        form.send(.tapPhoto)
        let route = form.route
        form.send(.pickPhoto(imageData))
        form.send(.tapSave)

        // Then
        XCTAssertEqual(route, .photoPicker)
        XCTAssertEqual(wishRepository.updatedWishes.first?.photoFileName, "wish-1-new.jpg")
        XCTAssertEqual(photoStorage.deletedFileNames, ["wish-1-old.jpg"])
    }

    func test_GH61_TC19_사진을바꾸지않고완료하면_파일을건드리지않는다() {
        // Given
        let form = makeEdit(photoWish())

        // When
        form.send(.tapSave)

        // Then
        XCTAssertTrue(form.visibleBlocks.contains(.photo))
        XCTAssertEqual(wishRepository.updatedWishes.first?.photoFileName, "wish-1-old.jpg")
        XCTAssertTrue(photoStorage.savePhotoCalls.isEmpty)
        XCTAssertTrue(photoStorage.deletedFileNames.isEmpty)
    }

    // MARK: GH-61 TC20

    func test_GH61_TC20_수정에서사진을지우고완료하면_빈파일이름을저장하고파일을지운다() {
        // Given
        let form = makeEdit(photoWish())

        // When
        form.send(.removeBlock(.photo))
        form.send(.tapSave)

        // Then
        XCTAssertEqual(wishRepository.updatedWishes.first?.photoFileName, "")
        XCTAssertEqual(photoStorage.deletedFileNames, ["wish-1-old.jpg"])
    }

    // MARK: GH-61 TC21

    func test_GH61_TC21_사진편지를바꾸고버리면_저장도파일변경도없다() {
        // Given
        let form = makeEdit(photoWish())
        form.send(.pickPhoto(imageData))
        form.send(.tapChip(.letter))
        if case .letter(let sheet) = form.state.sheet {
            sheet.send(.inputLetter("편지"))
            sheet.send(.tapSeal)
        }

        // When
        form.send(.tapClose)
        let route = form.route
        form.send(.routeHandled)
        form.send(.confirmDiscard)

        // Then
        XCTAssertEqual(route, .confirmDiscard)
        XCTAssertTrue(wishRepository.updatedWishes.isEmpty)
        XCTAssertTrue(photoStorage.savePhotoCalls.isEmpty)
        XCTAssertTrue(photoStorage.deletedFileNames.isEmpty)
    }

    // MARK: GH-61 TC23

    func test_GH61_TC23_위시저장이실패하면_방금쓴사진파일을지우고에러를보여준다() {
        // Given
        let form = makeWrite(category: .wantToDo)
        photoStorage.savePhotoResult = .success("new.jpg")
        wishRepository.addWishResult = .failure(.writeFailed)

        // When
        form.send(.pickPhoto(imageData))
        form.send(.tapSave)

        // Then
        XCTAssertEqual(photoStorage.deletedFileNames, ["new.jpg"])
        guard case .toast = form.route else { return XCTFail("에러 토스트가 없다") }
    }

    func test_GH61_TC23_사진파일쓰기가실패하면_위시를저장하지않는다() {
        // Given
        let form = makeWrite(category: .wantToDo)
        photoStorage.savePhotoResult = .failure(.writeFailed)

        // When
        form.send(.pickPhoto(imageData))
        form.send(.tapSave)

        // Then
        XCTAssertTrue(wishRepository.addedWishes.isEmpty)
        XCTAssertEqual(form.route, .toast(WishPhotoStorageError.writeFailed.localizedDescription))
    }
}
