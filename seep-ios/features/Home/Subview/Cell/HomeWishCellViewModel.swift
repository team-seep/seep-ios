import Combine

extension HomeWishCellViewModel {
    struct Input {
        let didTapFinish = PassthroughSubject<Void, Never>()
        /// 길게 눌러 뜬 메뉴에서 "맨 위에 고정" / "고정 해제"를 탭 (GH-33 R-2)
        let didTapPinMenu = PassthroughSubject<Void, Never>()
    }
    
    struct Output {
        let wish: Wish
        let viewType: ViewType
        /// 단계가 없으면 nil — 셀에서 진행도를 숨긴다
        let stepProgress: WishStepProgress?
        /// 완료됐고 소감이 있을 때만 값이 있다 — 셀에서 뱃지 줄 대신 보여준다 (GH-25 R-5)
        let finishNote: String?
        /// 셀에 핀 아이콘을 보여줄지 (GH-33 R-7)
        let isPinned: Bool
        /// 완료된 위시는 고정 메뉴를 띄우지 않는다 (GH-33 R-2)
        let canShowPinMenu: Bool
        let didTapFinish = PassthroughSubject<Wish, Never>()
        let didTapPinMenu = PassthroughSubject<Wish, Never>()
    }
    
    struct Config {
        let wish: Wish
        let viewType: ViewType
    }
    
    struct Dependency {
        init() {
            
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
            isPinned: config.wish.isPinned,
            canShowPinMenu: !config.wish.isSuccess
        )
        self.dependency = dependency
        
        bind()
    }
    
    private static func finishNote(wish: Wish) -> String? {
        guard wish.isSuccess, !wish.finishNote.isEmpty else { return nil }
        return wish.finishNote
    }
    
    private func bind() {
        input.didTapFinish
            .withUnretained(self)
            .filter({ (owner: HomeWishCellViewModel, _) in
                return !owner.output.wish.isSuccess
            })
            .sink(receiveValue: { (owner: HomeWishCellViewModel, _) in
                owner.output.didTapFinish.send(owner.output.wish)
            })
            .store(in: &cancellables)
        
        input.didTapPinMenu
            .withUnretained(self)
            .filter { (owner: HomeWishCellViewModel, _) in
                return owner.output.canShowPinMenu
            }
            .sink { (owner: HomeWishCellViewModel, _) in
                owner.output.didTapPinMenu.send(owner.output.wish)
            }
            .store(in: &cancellables)
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
