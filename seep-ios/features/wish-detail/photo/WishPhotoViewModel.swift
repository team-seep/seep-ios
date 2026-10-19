import Foundation
import Combine

extension WishPhotoViewModel {
    struct Input {
        /// 빈 사진 자리 탭 (사진 고르기 열기)
        let didTapAdd = PassthroughSubject<Void, Never>()
        /// "바꾸기" 탭
        let didTapChange = PassthroughSubject<Void, Never>()
        /// 사진 고르기에서 고른 이미지 원본 데이터
        let didPickPhoto = PassthroughSubject<Data, Never>()
        /// 더보기 메뉴의 "사진 지우기" 탭
        let didTapDelete = PassthroughSubject<Void, Never>()
    }

    struct Output {
        let screenName: ScreenName = .wishDetail
        /// 보여줄 사진 파일. nil 이면 빈 상태("＋ 사진 붙이기") (R-2, R-7)
        let photoURL: CurrentValueSubject<URL?, Never>
        /// 사진 파일 이름이 바뀔 때마다 보낸다(빈 값 = 지움). 상세 Reactor 의 위시에 반영해 홈 그리드까지 전달한다.
        let didUpdatePhoto = PassthroughSubject<String, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case presentPhotoPicker
        case showErrorAlert(Error)
    }

    struct Config {
        let wish: Wish
    }

    struct State {
        let wishId: String
        var fileName: String
    }

    struct Dependency {
        let wishRepository: WishRepository
        let photoStorage: WishPhotoStorage
        let logManager: LogManagerProtocol

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            photoStorage: WishPhotoStorage = WishPhotoStorageImpl.shared,
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.wishRepository = wishRepository
            self.photoStorage = photoStorage
            self.logManager = logManager
        }
    }
}

/// 위시 상세의 "사진" 섹션 (GH-36). 상세 화면은 레거시 Reactor 라 GH-16 모으기 섹션처럼 이 섹션만 Combine ViewModel 로 붙인다.
final class WishPhotoViewModel {
    let input = Input()
    let output: Output
    private var state: State
    private let dependency: Dependency
    private var cancellables = Set<AnyCancellable>()

    /// 더보기 메뉴에 "사진 지우기"를 넣을지 (R-4). 파일이 없으면 사진이 없는 것으로 본다 (R-7).
    var hasPhoto: Bool {
        return output.photoURL.value != nil
    }

    init(config: Config, dependency: Dependency = Dependency()) {
        self.dependency = dependency
        self.state = State(wishId: config.wish.id, fileName: config.wish.photoFileName)
        self.output = Output(photoURL: .init(dependency.photoStorage.photoURL(fileName: config.wish.photoFileName)))

        bind()
    }

    private func bind() {
        input.didTapAdd
            .withUnretained(self)
            .sink { (owner: WishPhotoViewModel, _) in
                owner.sendClickLog(objectId: .addPhoto)
                owner.output.route.send(.presentPhotoPicker)
            }
            .store(in: &cancellables)

        input.didTapChange
            .withUnretained(self)
            .sink { (owner: WishPhotoViewModel, _) in
                owner.sendClickLog(objectId: .changePhoto)
                owner.output.route.send(.presentPhotoPicker)
            }
            .store(in: &cancellables)

        input.didPickPhoto
            .withUnretained(self)
            .sink { (owner: WishPhotoViewModel, imageData: Data) in
                owner.savePhoto(imageData: imageData)
            }
            .store(in: &cancellables)

        input.didTapDelete
            .withUnretained(self)
            .sink { (owner: WishPhotoViewModel, _) in
                owner.sendClickLog(objectId: .deletePhoto)
                owner.deletePhoto()
            }
            .store(in: &cancellables)
    }

    private func savePhoto(imageData: Data) {
        dependency.photoStorage.savePhoto(imageData: imageData, wishId: state.wishId) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let fileName):
                self.applySavedPhoto(fileName: fileName)
            case .failure(let error):
                self.output.route.send(.showErrorAlert(error))
            }
        }
    }

    private func applySavedPhoto(fileName: String) {
        switch dependency.wishRepository.updatePhoto(wishId: state.wishId, fileName: fileName) {
        case .success:
            let previousFileName = state.fileName
            if !previousFileName.isEmpty, previousFileName != fileName {
                dependency.photoStorage.deletePhoto(fileName: previousFileName)
            }
            apply(fileName: fileName)
            dependency.logManager.sendEvent(event: CustomEvent(screen: output.screenName, name: .savePhoto))
        case .failure(let error):
            // 위시에 붙이지 못한 파일은 남기지 않는다 (R-3)
            dependency.photoStorage.deletePhoto(fileName: fileName)
            output.route.send(.showErrorAlert(error))
        }
    }

    private func deletePhoto() {
        let previousFileName = state.fileName
        guard !previousFileName.isEmpty else { return }

        switch dependency.wishRepository.updatePhoto(wishId: state.wishId, fileName: "") {
        case .success:
            dependency.photoStorage.deletePhoto(fileName: previousFileName)
            apply(fileName: "")
        case .failure(let error):
            output.route.send(.showErrorAlert(error))
        }
    }

    private func apply(fileName: String) {
        state.fileName = fileName
        output.photoURL.send(dependency.photoStorage.photoURL(fileName: fileName))
        output.didUpdatePhoto.send(fileName)
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .button,
            objectId: objectId
        ))
    }
}
