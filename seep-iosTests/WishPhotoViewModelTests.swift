import XCTest
import Combine

@testable import seep_ios_dev

/// 상세 "사진" 섹션 (GH-36 R-1~R-4, R-7).
final class WishPhotoViewModelTests: XCTestCase {
    private var mockRepository: MockWishRepository!
    private var mockStorage: MockWishPhotoStorage!
    private var mockLogManager: MockLogManager!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        mockStorage = MockWishPhotoStorage()
        mockLogManager = MockLogManager()
        cancellables = []
    }

    override func tearDown() {
        mockRepository = nil
        mockStorage = nil
        mockLogManager = nil
        cancellables = nil
        super.tearDown()
    }

    private func makeViewModel(photoFileName: String = "") -> WishPhotoViewModel {
        let wish = Wish(id: "wish-1", emoji: "🏝️", category: .wantToGo, title: "제주도 한 달 살기", photoFileName: photoFileName)
        return WishPhotoViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: mockRepository, photoStorage: mockStorage, logManager: mockLogManager)
        )
    }

    private func collectRoutes(_ viewModel: WishPhotoViewModel) -> () -> [WishPhotoViewModel.Route] {
        var routes: [WishPhotoViewModel.Route] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)
        return { routes }
    }

    private func collectUpdates(_ viewModel: WishPhotoViewModel) -> () -> [String] {
        var updates: [String] = []
        viewModel.output.didUpdatePhoto
            .sink { updates.append($0) }
            .store(in: &cancellables)
        return { updates }
    }

    private func clickEvents(objectId: LogObjectId) -> [ClickEvent] {
        return mockLogManager.sentEvents
            .compactMap { $0 as? ClickEvent }
            .filter { ($0.extraParameters?[.objectId] as? LogObjectId) == objectId }
    }

    // MARK: GH-36 TC1

    func test_GH36_TC1_사진없는위시상세를열면_사진섹션이빈상태다() {
        // Given
        let viewModel = makeViewModel(photoFileName: "")

        // When
        let photoURL = viewModel.output.photoURL.value

        // Then
        XCTAssertNil(photoURL)
        XCTAssertFalse(viewModel.hasPhoto)
    }

    func test_GH36_TC1_빈사진자리를탭하면_사진고르기를연다() {
        // Given
        let viewModel = makeViewModel()
        let routes = collectRoutes(viewModel)

        // When
        viewModel.input.didTapAdd.send(())

        // Then
        XCTAssertEqual(routes().count, 1)
        guard case .presentPhotoPicker = routes().first else {
            return XCTFail("사진 고르기 route 가 아니다")
        }
    }

    // MARK: GH-36 TC2

    func test_GH36_TC2_사진을고르면_저장소에쓰고_파일이름을위시에저장한뒤_사진있음상태가된다() {
        // Given
        let viewModel = makeViewModel()
        let updates = collectUpdates(viewModel)
        mockStorage.savePhotoResult = .success("wish-1-new.jpg")
        let imageData = Data([0xFF, 0xD8, 0xFF])

        // When
        viewModel.input.didPickPhoto.send(imageData)

        // Then
        XCTAssertEqual(mockStorage.savePhotoCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(mockStorage.savePhotoCalls.map(\.imageData), [imageData])
        XCTAssertEqual(mockRepository.updatePhotoCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(mockRepository.updatePhotoCalls.map(\.fileName), ["wish-1-new.jpg"])
        XCTAssertEqual(viewModel.output.photoURL.value?.lastPathComponent, "wish-1-new.jpg")
        XCTAssertTrue(viewModel.hasPhoto)
        XCTAssertEqual(updates(), ["wish-1-new.jpg"])
        XCTAssertTrue(mockStorage.deletedFileNames.isEmpty)
    }

    func test_GH36_TC2_위시저장에실패하면_방금쓴파일을지우고_에러알럿을띄운다() {
        // Given
        let viewModel = makeViewModel()
        let routes = collectRoutes(viewModel)
        let updates = collectUpdates(viewModel)
        mockStorage.savePhotoResult = .success("wish-1-new.jpg")
        mockRepository.updatePhotoResult = .failure(.writeFailed)

        // When
        viewModel.input.didPickPhoto.send(Data([0x01]))

        // Then
        XCTAssertEqual(mockStorage.deletedFileNames, ["wish-1-new.jpg"])
        XCTAssertNil(viewModel.output.photoURL.value)
        XCTAssertTrue(updates().isEmpty)
        guard case .showErrorAlert = routes().first else {
            return XCTFail("에러 알럿 route 가 아니다")
        }
    }

    func test_GH36_TC2_이미지를읽지못하면_위시를바꾸지않고_에러알럿을띄운다() {
        // Given
        let viewModel = makeViewModel()
        let routes = collectRoutes(viewModel)
        mockStorage.savePhotoResult = .failure(.invalidImage)

        // When
        viewModel.input.didPickPhoto.send(Data([0x01]))

        // Then
        XCTAssertTrue(mockRepository.updatePhotoCalls.isEmpty)
        XCTAssertNil(viewModel.output.photoURL.value)
        guard case .showErrorAlert = routes().first else {
            return XCTFail("에러 알럿 route 가 아니다")
        }
    }

    // MARK: GH-36 TC3

    func test_GH36_TC3_사진을바꾸면_새파일이름이저장되고_이전파일삭제가호출된다() {
        // Given
        mockStorage.existingFileNames = ["wish-1-old.jpg"]
        let viewModel = makeViewModel(photoFileName: "wish-1-old.jpg")
        let routes = collectRoutes(viewModel)
        let updates = collectUpdates(viewModel)
        mockStorage.savePhotoResult = .success("wish-1-new.jpg")

        // When
        viewModel.input.didTapChange.send(())
        viewModel.input.didPickPhoto.send(Data([0x01]))

        // Then
        guard case .presentPhotoPicker = routes().first else {
            return XCTFail("사진 고르기 route 가 아니다")
        }
        XCTAssertEqual(mockRepository.updatePhotoCalls.map(\.fileName), ["wish-1-new.jpg"])
        XCTAssertEqual(mockStorage.deletedFileNames, ["wish-1-old.jpg"])
        XCTAssertEqual(viewModel.output.photoURL.value?.lastPathComponent, "wish-1-new.jpg")
        XCTAssertEqual(updates(), ["wish-1-new.jpg"])
    }

    // MARK: GH-36 TC4

    func test_GH36_TC4_사진지우기를하면_파일이름이빈값으로저장되고_파일삭제가호출된다() {
        // Given
        mockStorage.existingFileNames = ["wish-1-old.jpg"]
        let viewModel = makeViewModel(photoFileName: "wish-1-old.jpg")
        let updates = collectUpdates(viewModel)
        XCTAssertTrue(viewModel.hasPhoto)

        // When
        viewModel.input.didTapDelete.send(())

        // Then
        XCTAssertEqual(mockRepository.updatePhotoCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(mockRepository.updatePhotoCalls.map(\.fileName), [""])
        XCTAssertEqual(mockStorage.deletedFileNames, ["wish-1-old.jpg"])
        XCTAssertNil(viewModel.output.photoURL.value)
        XCTAssertFalse(viewModel.hasPhoto)
        XCTAssertEqual(updates(), [""])
    }

    func test_GH36_TC4_위시저장에실패하면_파일을지우지않고_에러알럿을띄운다() {
        // Given
        mockStorage.existingFileNames = ["wish-1-old.jpg"]
        let viewModel = makeViewModel(photoFileName: "wish-1-old.jpg")
        let routes = collectRoutes(viewModel)
        mockRepository.updatePhotoResult = .failure(.writeFailed)

        // When
        viewModel.input.didTapDelete.send(())

        // Then
        XCTAssertTrue(mockStorage.deletedFileNames.isEmpty)
        XCTAssertTrue(viewModel.hasPhoto)
        guard case .showErrorAlert = routes().first else {
            return XCTFail("에러 알럿 route 가 아니다")
        }
    }

    // MARK: GH-36 TC6

    func test_GH36_TC6_파일이름은있지만파일이없으면_상세는사진없는상태로보인다() {
        // Given
        mockStorage.existingFileNames = []

        // When
        let viewModel = makeViewModel(photoFileName: "wish-1-restored.jpg")

        // Then
        XCTAssertNil(viewModel.output.photoURL.value)
        XCTAssertFalse(viewModel.hasPhoto)
    }

    // MARK: GH-36 TC9

    func test_GH36_TC9_빈사진자리를탭하면_add_photo클릭로그가1건전송된다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.input.didTapAdd.send(())

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
        viewModel.input.didTapChange.send(())

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
        viewModel.input.didTapDelete.send(())

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
        viewModel.input.didPickPhoto.send(Data([0x01]))

        // Then
        let events = mockLogManager.sentEvents
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
        viewModel.input.didPickPhoto.send(Data([0x01]))

        // Then
        XCTAssertTrue(mockLogManager.sentEvents.compactMap { $0 as? CustomEvent }.isEmpty)
    }
}
