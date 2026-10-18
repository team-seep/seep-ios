import Combine
import CoreGraphics

extension HomeWishCellViewModel {
    struct Input {
        let didTapFinish = PassthroughSubject<Void, Never>()
        /// 그리드 셀이 사진 자리 크기(픽셀)를 알게 되면 썸네일을 요청한다 (GH-36 R-8)
        let loadThumbnail = PassthroughSubject<Int, Never>()
    }
    
    struct Output {
        let wish: Wish
        let viewType: ViewType
        /// 단계가 없으면 nil — 셀에서 진행도를 숨긴다
        let stepProgress: WishStepProgress?
        /// 완료됐고 소감이 있을 때만 값이 있다 — 셀에서 뱃지 줄 대신 보여준다 (GH-25 R-5)
        let finishNote: String?
        /// 사진 파일이 실제로 있을 때만 값이 있다 — 그리드 셀이 사진 레이아웃을 쓴다 (GH-36 R-6, R-7)
        let photoFileName: String?
        let thumbnail = PassthroughSubject<CGImage?, Never>()
        let didTapFinish = PassthroughSubject<Wish, Never>()
    }
    
    struct Config {
        let wish: Wish
        let viewType: ViewType
    }
    
    struct Dependency {
        let photoStorage: WishPhotoStorage
        
        init(photoStorage: WishPhotoStorage = WishPhotoStorageImpl.shared) {
            self.photoStorage = photoStorage
        }
    }
}

final class HomeWishCellViewModel {
    let input = Input()
    let output: Output
    var cancellables = Set<AnyCancellable>()
    private let dependency: Dependency
    
    init(config: Config, dependency: Dependency = Dependency()) {
        self.output = Output(
            wish: config.wish,
            viewType: config.viewType,
            stepProgress: WishStepProgress(steps: config.wish.steps),
            finishNote: Self.finishNote(wish: config.wish),
            photoFileName: Self.photoFileName(wish: config.wish, photoStorage: dependency.photoStorage)
        )
        self.dependency = dependency
        
        bind()
    }
    
    private static func finishNote(wish: Wish) -> String? {
        guard wish.isSuccess, !wish.finishNote.isEmpty else { return nil }
        return wish.finishNote
    }
    
    private static func photoFileName(wish: Wish, photoStorage: WishPhotoStorage) -> String? {
        guard photoStorage.photoURL(fileName: wish.photoFileName) != nil else { return nil }
        return wish.photoFileName
    }
    
    private func bind() {
        input.loadThumbnail
            .withUnretained(self)
            .sink { (owner: HomeWishCellViewModel, maxPixelSize: Int) in
                owner.loadThumbnail(maxPixelSize: maxPixelSize)
            }
            .store(in: &cancellables)
        
        input.didTapFinish
            .withUnretained(self)
            .filter({ (owner: HomeWishCellViewModel, _) in
                return !owner.output.wish.isSuccess
            })
            .sink(receiveValue: { (owner: HomeWishCellViewModel, _) in
                owner.output.didTapFinish.send(owner.output.wish)
            })
            .store(in: &cancellables)
    }
    
    private func loadThumbnail(maxPixelSize: Int) {
        guard let photoFileName = output.photoFileName, maxPixelSize > 0 else { return }
        
        dependency.photoStorage.loadThumbnail(fileName: photoFileName, maxPixelSize: maxPixelSize) { [weak self] image in
            self?.output.thumbnail.send(image)
        }
    }
}

extension HomeWishCellViewModel: Hashable {
    static func == (lhs: HomeWishCellViewModel, rhs: HomeWishCellViewModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(output.wish)
        hasher.combine(output.viewType)
    }
}
