import Foundation
import Combine

extension WishDetailViewModel {
    struct Input {
        /// 상단 바 "수정" 탭 (R-8)
        let didTapEdit = PassthroughSubject<Void, Never>()
        /// 상단 바 ⋯ 탭. 메뉴 구성에 필요한 섹션 상태(캘린더·사진)를 같이 넘긴다 (R-9)
        let didTapMore = PassthroughSubject<MoreMenuState, Never>()
        /// 수정 저장·단계 체크·기록 등으로 위시가 바뀌었다 (R-11)
        let updateWish = PassthroughSubject<Wish, Never>()
    }

    struct Output {
        let screenName: ScreenName = .wishDetail
        let summary: CurrentValueSubject<WishDetailSummary, Never>
        let sections: CurrentValueSubject<[DetailSection], Never>
        /// 홈에서 연 상세에서만 "수정"이 보인다 (R-8)
        let isEditVisible: Bool
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case pushEdit(Wish)
        case showMoreMenu([DetailMoreMenu.Item])
    }

    struct MoreMenuState: Equatable {
        let isCalendarVisible: Bool
        let isCalendarAdded: Bool
        let hasPhoto: Bool
    }

    struct Config {
        let wish: Wish
        let mode: DetailMode
    }

    struct State {
        var wish: Wish
    }

    struct Dependency {
        let logManager: LogManagerProtocol
        let now: () -> Date
        let calendar: Calendar

        init(
            logManager: LogManagerProtocol = LogManager.shared,
            now: @escaping () -> Date = Date.init,
            calendar: Calendar = .current
        ) {
            self.logManager = logManager
            self.now = now
            self.calendar = calendar
        }
    }
}

/// 위시 상세의 문서형 머리(제목 블록·D-day·메타·메모)·섹션 구성·상단 바(수정·⋯) (GH-59).
/// 상세는 레거시 Reactor(`WishDetailReactor`)가 삭제·완료 취소·공유를 맡고 있어, 단계·모으기 섹션처럼 이번에 바뀐 부분만 Combine ViewModel 로 붙인다.
final class WishDetailViewModel {
    let input = Input()
    let output: Output
    private var state: State
    private let config: Config
    private let dependency: Dependency
    private var cancellables = Set<AnyCancellable>()

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
        self.state = State(wish: config.wish)
        self.output = Output(
            summary: .init(WishDetailSummary(wish: config.wish, now: dependency.now(), calendar: dependency.calendar)),
            sections: .init(DetailSectionBuilder.sections(for: config.wish)),
            isEditVisible: config.mode == .fromHome
        )

        bind()
    }

    private func bind() {
        input.didTapEdit
            .withUnretained(self)
            .sink { (owner: WishDetailViewModel, _) in
                owner.pushEdit()
            }
            .store(in: &cancellables)

        input.didTapMore
            .withUnretained(self)
            .sink { (owner: WishDetailViewModel, menuState: MoreMenuState) in
                owner.showMoreMenu(menuState: menuState)
            }
            .store(in: &cancellables)

        input.updateWish
            .withUnretained(self)
            .sink { (owner: WishDetailViewModel, wish: Wish) in
                owner.update(wish: wish)
            }
            .store(in: &cancellables)
    }

    private func pushEdit() {
        guard output.isEditVisible else { return }
        sendClickLog(objectId: .detailEdit)
        output.route.send(.pushEdit(state.wish))
    }

    private func showMoreMenu(menuState: MoreMenuState) {
        sendClickLog(objectId: .detailMore)
        let items = DetailMoreMenu.items(context: .init(
            mode: config.mode,
            isCalendarVisible: menuState.isCalendarVisible,
            isCalendarAdded: menuState.isCalendarAdded,
            hasPhoto: menuState.hasPhoto
        ))
        output.route.send(.showMoreMenu(items))
    }

    private func update(wish: Wish) {
        state.wish = wish
        let summary = WishDetailSummary(wish: wish, now: dependency.now(), calendar: dependency.calendar)
        if summary != output.summary.value {
            output.summary.send(summary)
        }
        let sections = DetailSectionBuilder.sections(for: wish)
        if sections != output.sections.value {
            output.sections.send(sections)
        }
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .button,
            objectId: objectId
        ))
    }
}
