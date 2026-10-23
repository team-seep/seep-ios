import Foundation
import Observation

extension WishPhotoViewModel {
    enum Action: Equatable {
        /// 빈 자리 "＋ 사진 붙이기" 탭 (사진 고르기 열기)
        case tapAdd
        /// 섹션 "바꾸기" 탭
        case tapChange
        /// 사진 고르기에서 고른 이미지 원본 데이터
        case pickPhoto(Data)
        /// 고른 사진을 읽지 못했다
        case pickFailed
        /// ⋯ 메뉴 "사진 지우기"
        case tapDelete
        /// 수정 화면에서 돌아왔다
        case reload(Wish)
        case routeHandled
    }

    enum Route: Equatable {
        case photoPicker
        case errorAlert(String)
    }

    struct Config {
        let wish: Wish
    }

    struct State: Equatable {
        /// 보여줄 사진 파일. nil 이면 빈 상태("＋ 사진 붙이기") (GH-36 R-2, R-7)
        var photoURL: URL?
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

/// 상세 "사진" 섹션 (GH-36, GH-59 R-6)
@Observable
final class WishPhotoViewModel {
    let screenName: ScreenName = .wishDetail
    private(set) var state: State
    private(set) var route: Route?
    /// 저장한 사진 파일 이름(빈 값 = 지움). 상세가 위시에 반영한다
    var onUpdate: ((String) -> Void)?

    private let wishId: String
    private var fileName: String
    private let dependency: Dependency

    /// ⋯ 메뉴에 "사진 지우기"를 넣을지 (R-4). 파일이 없으면 사진이 없는 것으로 본다 (GH-36 R-7)
    var hasPhoto: Bool {
        state.photoURL != nil
    }

    init(config: Config, dependency: Dependency = Dependency()) {
        self.wishId = config.wish.id
        self.fileName = config.wish.photoFileName
        self.dependency = dependency
        self.state = State(photoURL: dependency.photoStorage.photoURL(fileName: config.wish.photoFileName))
    }

    func send(_ action: Action) {
        switch action {
        case .tapAdd:
            sendClickLog(objectId: .addPhoto)
            route = .photoPicker
        case .tapChange:
            sendClickLog(objectId: .changePhoto)
            route = .photoPicker
        case .pickPhoto(let data):
            savePhoto(imageData: data)
        case .pickFailed:
            route = .errorAlert(WishPhotoStorageError.invalidImage.localizedDescription)
        case .tapDelete:
            sendClickLog(objectId: .deletePhoto)
            deletePhoto()
        case .reload(let wish):
            fileName = wish.photoFileName
            state.photoURL = dependency.photoStorage.photoURL(fileName: wish.photoFileName)
        case .routeHandled:
            route = nil
        }
    }

    private func savePhoto(imageData: Data) {
        dependency.photoStorage.savePhoto(imageData: imageData, wishId: wishId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let savedFileName):
                applySavedPhoto(fileName: savedFileName)
            case .failure(let error):
                route = .errorAlert(error.localizedDescription)
            }
        }
    }

    private func applySavedPhoto(fileName savedFileName: String) {
        switch dependency.wishRepository.updatePhoto(wishId: wishId, fileName: savedFileName) {
        case .success:
            let previousFileName = fileName
            if !previousFileName.isEmpty, previousFileName != savedFileName {
                dependency.photoStorage.deletePhoto(fileName: previousFileName)
            }
            apply(fileName: savedFileName)
            dependency.logManager.sendEvent(event: CustomEvent(screen: screenName, name: .savePhoto))
        case .failure(let error):
            // 위시에 붙이지 못한 파일은 남기지 않는다 (GH-36 R-3)
            dependency.photoStorage.deletePhoto(fileName: savedFileName)
            route = .errorAlert(error.localizedDescription)
        }
    }

    private func deletePhoto() {
        let previousFileName = fileName
        guard !previousFileName.isEmpty else { return }
        switch dependency.wishRepository.updatePhoto(wishId: wishId, fileName: "") {
        case .success:
            dependency.photoStorage.deletePhoto(fileName: previousFileName)
            apply(fileName: "")
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }

    private func apply(fileName newFileName: String) {
        fileName = newFileName
        state.photoURL = dependency.photoStorage.photoURL(fileName: newFileName)
        onUpdate?(newFileName)
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: objectId
        ))
    }
}
