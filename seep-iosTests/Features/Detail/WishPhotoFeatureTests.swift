import XCTest

@testable import seep_ios_dev

/// 상세 "사진" 섹션 (GH-36 R-1~R-4, R-7, GH-64 TC-608)
final class WishPhotoFeatureTests: ViewModelTestCase {
    private var mockRepository: MockWishRepository!
    private var mockStorage: MockWishPhotoStorage!
    private var updates: [String] = []

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        mockStorage = MockWishPhotoStorage()
        updates = []
    }

    override func tearDown() {
        mockRepository = nil
        mockStorage = nil
        super.tearDown()
    }

    private func makeViewModel(photoFileName: String = "") -> WishPhotoViewModel {
        let wish = Wish(id: "wish-1", emoji: "🏝️", category: .wantToGo, title: "제주도 한 달 살기", photoFileName: photoFileName)
        let viewModel = WishPhotoViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: mockRepository, photoStorage: mockStorage, logManager: logManager)
        )
        viewModel.onUpdate = { [unowned self] in updates.append($0) }
        return viewModel
    }

    private func isErrorAlert(_ route: WishPhotoViewModel.Route?) -> Bool {
        if case .errorAlert = route { return true }
        return false
    }

    // MARK: GH-36 TC1

    func test_GH36_TC1_사진없는위시상세를열면_사진섹션이빈상태다() {
        // Given
        let viewModel = makeViewModel(photoFileName: "")

        // When
        let photoURL = viewModel.state.photoURL

        // Then
        XCTAssertNil(photoURL)
        XCTAssertFalse(viewModel.hasPhoto)
    }

    func test_GH36_TC1_빈사진자리를탭하면_사진고르기를연다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.tapAdd)

        // Then
        XCTAssertEqual(viewModel.route, .photoPicker)
    }

    // MARK: GH-36 TC2

    func test_GH36_TC2_사진을고르면_저장소에쓰고_파일이름을위시에저장한뒤_사진있음상태가된다() {
        // Given
        let viewModel = makeViewModel()
        mockStorage.savePhotoResult = .success("wish-1-new.jpg")
        let imageData = Data([0xFF, 0xD8, 0xFF])

        // When
        viewModel.send(.pickPhoto(imageData))

        // Then
        XCTAssertEqual(mockStorage.savePhotoCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(mockStorage.savePhotoCalls.map(\.imageData), [imageData])
        XCTAssertEqual(mockRepository.updatePhotoCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(mockRepository.updatePhotoCalls.map(\.fileName), ["wish-1-new.jpg"])
        XCTAssertEqual(viewModel.state.photoURL?.lastPathComponent, "wish-1-new.jpg")
        XCTAssertTrue(viewModel.hasPhoto)
        XCTAssertEqual(updates, ["wish-1-new.jpg"])
        XCTAssertTrue(mockStorage.deletedFileNames.isEmpty)
    }

    func test_GH36_TC2_위시저장에실패하면_방금쓴파일을지우고_에러알럿을띄운다() {
        // Given
        let viewModel = makeViewModel()
        mockStorage.savePhotoResult = .success("wish-1-new.jpg")
        mockRepository.updatePhotoResult = .failure(.writeFailed)

        // When
        viewModel.send(.pickPhoto(Data([0x01])))

        // Then
        XCTAssertEqual(mockStorage.deletedFileNames, ["wish-1-new.jpg"])
        XCTAssertNil(viewModel.state.photoURL)
        XCTAssertTrue(updates.isEmpty)
        XCTAssertTrue(isErrorAlert(viewModel.route))
    }

    func test_GH36_TC2_이미지를읽지못하면_위시를바꾸지않고_에러알럿을띄운다() {
        // Given
        let viewModel = makeViewModel()
        mockStorage.savePhotoResult = .failure(.invalidImage)

        // When
        viewModel.send(.pickPhoto(Data([0x01])))

        // Then
        XCTAssertTrue(mockRepository.updatePhotoCalls.isEmpty)
        XCTAssertNil(viewModel.state.photoURL)
        XCTAssertTrue(isErrorAlert(viewModel.route))
    }

    // MARK: GH-36 TC3

    func test_GH36_TC3_사진을바꾸면_새파일이름이저장되고_이전파일삭제가호출된다() {
        // Given
        mockStorage.existingFileNames = ["wish-1-old.jpg"]
        let viewModel = makeViewModel(photoFileName: "wish-1-old.jpg")
        mockStorage.savePhotoResult = .success("wish-1-new.jpg")

        // When
        viewModel.send(.tapChange)

        // Then
        XCTAssertEqual(viewModel.route, .photoPicker)

        // When
        viewModel.send(.pickPhoto(Data([0x01])))

        // Then
        XCTAssertEqual(mockRepository.updatePhotoCalls.map(\.fileName), ["wish-1-new.jpg"])
        XCTAssertEqual(mockStorage.deletedFileNames, ["wish-1-old.jpg"])
        XCTAssertEqual(viewModel.state.photoURL?.lastPathComponent, "wish-1-new.jpg")
        XCTAssertEqual(updates, ["wish-1-new.jpg"])
    }

    // MARK: GH-36 TC4

    func test_GH36_TC4_사진지우기를하면_파일이름이빈값으로저장되고_파일삭제가호출된다() {
        // Given
        mockStorage.existingFileNames = ["wish-1-old.jpg"]
        let viewModel = makeViewModel(photoFileName: "wish-1-old.jpg")
        XCTAssertTrue(viewModel.hasPhoto)

        // When
        viewModel.send(.tapDelete)

        // Then
        XCTAssertEqual(mockRepository.updatePhotoCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(mockRepository.updatePhotoCalls.map(\.fileName), [""])
        XCTAssertEqual(mockStorage.deletedFileNames, ["wish-1-old.jpg"])
        XCTAssertNil(viewModel.state.photoURL)
        XCTAssertFalse(viewModel.hasPhoto)
        XCTAssertEqual(updates, [""])
    }

    func test_GH36_TC4_위시저장에실패하면_파일을지우지않고_에러알럿을띄운다() {
        // Given
        mockStorage.existingFileNames = ["wish-1-old.jpg"]
        let viewModel = makeViewModel(photoFileName: "wish-1-old.jpg")
        mockRepository.updatePhotoResult = .failure(.writeFailed)

        // When
        viewModel.send(.tapDelete)

        // Then
        XCTAssertTrue(mockStorage.deletedFileNames.isEmpty)
        XCTAssertTrue(viewModel.hasPhoto)
        XCTAssertTrue(isErrorAlert(viewModel.route))
    }

    // MARK: GH-36 TC6

    func test_GH36_TC6_파일이름은있지만파일이없으면_상세는사진없는상태로보인다() {
        // Given
        mockStorage.existingFileNames = []

        // When
        let viewModel = makeViewModel(photoFileName: "wish-1-restored.jpg")

        // Then
        XCTAssertNil(viewModel.state.photoURL)
        XCTAssertFalse(viewModel.hasPhoto)
    }

    // MARK: GH-36 TC9

    func test_GH36_TC9_빈사진자리를탭하면_add_photo클릭로그가1건전송된다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.tapAdd)

        // Then
        let events = clickEvents(objectId: .addPhoto)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        XCTAssertEqual(events.first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }

    func test_GH36_TC9_바꾸기를탭하면_change_photo클릭로그가1건전송된다() {
        // Given
        mockStorage.existingFileNames = ["wish-1-old.jpg"]
        let viewModel = makeViewModel(photoFileName: "wish-1-old.jpg")

        // When
        viewModel.send(.tapChange)

        // Then
        let events = clickEvents(objectId: .changePhoto)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        XCTAssertEqual(events.first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }

    func test_GH36_TC9_사진지우기를탭하면_delete_photo클릭로그가1건전송된다() {
        // Given
        mockStorage.existingFileNames = ["wish-1-old.jpg"]
        let viewModel = makeViewModel(photoFileName: "wish-1-old.jpg")

        // When
        viewModel.send(.tapDelete)

        // Then
        let events = clickEvents(objectId: .deletePhoto)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        XCTAssertEqual(events.first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }

    func test_GH36_TC9_사진저장을완료하면_save_photo이벤트가1건전송된다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.pickPhoto(Data([0x01])))

        // Then
        let events = logManager.sentEvents
            .compactMap { $0 as? CustomEvent }
            .filter { $0.name == .savePhoto }
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
    }

    func test_GH36_TC9_사진저장에실패하면_save_photo이벤트를보내지않는다() {
        // Given
        let viewModel = makeViewModel()
        mockRepository.updatePhotoResult = .failure(.writeFailed)

        // When
        viewModel.send(.pickPhoto(Data([0x01])))

        // Then
        XCTAssertTrue(logManager.sentEvents.compactMap { $0 as? CustomEvent }.isEmpty)
    }

    // MARK: GH-64 TC608

    func test_GH64_TC608_사진고르기에서읽지못하면_저장하지않고_에러알럿을띄운다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.pickFailed)

        // Then
        XCTAssertTrue(mockStorage.savePhotoCalls.isEmpty)
        XCTAssertTrue(isErrorAlert(viewModel.route))
    }

    func test_GH64_TC608_수정화면에서돌아와사진이바뀌면_새파일로보인다() {
        // Given
        mockStorage.existingFileNames = ["wish-1-a.jpg", "wish-1-b.jpg"]
        let viewModel = makeViewModel(photoFileName: "wish-1-a.jpg")

        // When
        viewModel.send(.reload(Wish(id: "wish-1", photoFileName: "wish-1-b.jpg")))

        // Then
        XCTAssertEqual(viewModel.state.photoURL?.lastPathComponent, "wish-1-b.jpg")
    }
}
