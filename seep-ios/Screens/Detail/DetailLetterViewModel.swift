import Foundation
import Observation

extension DetailLetterViewModel {
    enum Action: Equatable {
        /// 편지 없음 "＋ 쓰기" (R-2)
        case tapWrite
        /// 봉인됨 "다시 쓰기" — 확인 알럿부터 (R-4)
        case tapRewrite
        case confirmRewrite
        /// 시트에서 봉인했다
        case seal(String)
        /// ⋯ "편지 지우기" → 확인 알럿 (R-7)
        case tapDelete
        case confirmDelete
        /// 상세가 위시를 다시 읽었다 (완료·완료 취소·위젯)
        case reload(Wish)
        case routeHandled
    }

    /// 섹션 모양. 판정은 `isSuccess` 하나 — 완료 취소하면 다시 봉인된다 (R-6)
    enum Letter: Equatable {
        /// 미완료 + 편지 없음: 안내 + ＋ 쓰기
        case empty
        /// 미완료 + 편지 있음: 자물쇠 + "이루는 날 열려요" + 봉인일·글자 수. 본문은 어디에도 없다 (TC-5)
        case sealed(caption: String)
        /// 완료 + 편지 있음: 본문 보기 전용 (R-6)
        case opened(body: String, writtenAt: String)
        /// 완료 + 편지 없음: 섹션을 그리지 않는다
        case hidden
    }

    struct State: Equatable {
        var letter: Letter = .hidden
    }

    enum Route: Equatable {
        case writeSheet(FutureLetterViewModel)
        case rewriteAlert
        case deleteAlert
        case errorAlert(String)
    }

    struct Config {
        let wish: Wish
    }

    struct Dependency {
        let wishRepository: WishRepository
        let logManager: LogManagerProtocol
    }
}

/// 상세 "미래의 나에게" 섹션 (GH-61 R-2, R-4, R-6, R-7)
@Observable
final class DetailLetterViewModel {
    let screenName: ScreenName = .wishDetail
    private(set) var state = State()
    private(set) var route: Route?
    /// 저장한 위시를 상세로 돌려준다
    @ObservationIgnored var onUpdate: ((Wish) -> Void)?

    private var wish: Wish
    private let dependency: Dependency

    var hasLetter: Bool {
        wish.hasFutureLetter
    }

    init(config: Config, dependency: Dependency) {
        self.wish = config.wish
        self.dependency = dependency
        state.letter = Self.letter(for: config.wish)
    }

    func send(_ action: Action) {
        switch action {
        case .tapWrite:
            sendClickLog()
            presentSheet()
        case .tapRewrite:
            sendClickLog()
            route = .rewriteAlert
        case .confirmRewrite:
            presentSheet()
        case .seal(let letter):
            save(dependency.wishRepository.sealFutureLetter(wishId: wish.id, letter: letter))
        case .tapDelete:
            route = .deleteAlert
        case .confirmDelete:
            save(dependency.wishRepository.deleteFutureLetter(wishId: wish.id))
        case .reload(let wish):
            apply(wish: wish)
        case .routeHandled:
            route = nil
        }
    }

    private func presentSheet() {
        let sheet = FutureLetterViewModel(dependency: .init(logManager: dependency.logManager))
        sheet.onSeal = { [weak self] letter in
            self?.send(.seal(letter))
        }
        route = .writeSheet(sheet)
    }

    private func save(_ result: Result<Wish, RepositoryError>) {
        switch result {
        case .success(let savedWish):
            apply(wish: savedWish)
            onUpdate?(savedWish)
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }

    private func apply(wish: Wish) {
        self.wish = wish
        let letter = Self.letter(for: wish)
        if letter != state.letter {
            state.letter = letter
        }
    }

    private func sendClickLog() {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: .writeFutureLetter
        ))
    }

    static func letter(for wish: Wish) -> Letter {
        let sealedDate = wish.futureLetterSealedAt.map { DateUtils.toString(format: "M월 d일", date: $0) } ?? ""
        switch (wish.isSuccess, wish.hasFutureLetter) {
        case (false, false):
            return .empty
        case (false, true):
            return .sealed(caption: Strings.Detail.Letter.sealedCaptionFormat(sealedDate, wish.futureLetter.count))
        case (true, true):
            return .opened(body: wish.futureLetter, writtenAt: Strings.Detail.Letter.writtenFormat(sealedDate))
        case (true, false):
            return .hidden
        }
    }
}
