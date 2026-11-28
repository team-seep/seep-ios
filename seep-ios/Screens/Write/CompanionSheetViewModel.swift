import Foundation
import Observation

extension CompanionSheetViewModel {
    enum Action: Equatable {
        case onAppear
        case inputName(String)
        /// 입력 칸에서 완료 — 친 이름을 고른 사람으로 넣는다 (R-1, R-2)
        case submitName
        /// '전에 적은 사람' 칩 (R-3, R-11)
        case tapRecent(WishCompanion)
        /// 고른 사람 칩 — 뺀다
        case tapSelected(WishCompanion)
        /// "정했어요"
        case tapDone
        /// "혼자 할래요" — 모두 빼고 닫는다 (R-1)
        case tapAlone
        case routeHandled
    }

    struct State: Equatable {
        /// 고른 사람, 고른 순서대로
        var selected: [WishCompanion]
        var nameInput = ""
        /// 전에 적은 사람, 최근 것부터
        var recent: [WishCompanion] = []

        var isFull: Bool { selected.count >= WishCompanion.maxCount }
        /// '전에 적은 사람'에 보일 칩 — 이미 고른 사람(같은 id 나 같은 이름)은 뺀다
        var suggested: [WishCompanion] {
            recent.filter { person in !selected.contains { $0.isSamePerson(as: person) } }
        }
    }

    enum Route: Equatable {
        case toast(String)
        case dismiss
    }

    struct Config {
        /// 시트를 열 때 문서에 붙어 있던 사람
        let selected: [WishCompanion]
    }

    struct Dependency {
        let wishRepository: WishRepository
        let logManager: LogManagerProtocol

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.wishRepository = wishRepository
            self.logManager = logManager
        }
    }
}

/// "이 싶은 / 누구랑 하고 싶어요?" 시트 (GH-122 R-1 ~ R-3, R-11).
/// 이름을 적거나 전에 적은 사람을 골라 최대 5명까지 붙인다. 저장은 작성·수정 문서가 한다
@Observable
final class CompanionSheetViewModel: Identifiable {
    /// '전에 적은 사람'에 보일 최대 수
    static let recentLimit = 10

    let screenName: ScreenName = .companionBottomSheet
    private(set) var state: State
    private(set) var route: Route?
    /// "정했어요"·"혼자 할래요"를 누르면 고른 사람을 넘긴다
    @ObservationIgnored var onFinish: (([WishCompanion]) -> Void)?

    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.dependency = dependency
        state = State(selected: config.selected)
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            state.recent = Array(dependency.wishRepository.fetchRecentCompanions().prefix(Self.recentLimit))
        case .inputName(let text):
            state.nameInput = String(text.prefix(WishCompanion.nameMaxLength))
        case .submitName:
            if submitNameInput() {
                state.nameInput = ""
            }
        case .tapRecent(let person):
            add(person)
        case .tapSelected(let person):
            state.selected.removeAll { $0.personId == person.personId }
        case .tapDone:
            // 치다 만 이름도 넣는다 (태그 시트와 같다). 최대 인원이라 못 넣었으면 닫지 않고 안내를 보여 준다
            guard submitNameInput() else { return }
            state.nameInput = ""
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: screenName,
                objectType: .button,
                objectId: .companionSave,
                extraParameters: [.count: state.selected.count]
            ))
            finish(with: state.selected)
        case .tapAlone:
            state.selected = []
            state.nameInput = ""
            finish(with: [])
        case .routeHandled:
            route = nil
        }
    }

    /// 입력 칸의 이름을 넣는다. 넣었거나(이미 있어 넣을 필요가 없었거나) 비어 있으면 true — 칸을 비운다
    private func submitNameInput() -> Bool {
        guard let name = WishCompanion.cleanedName(state.nameInput) else { return true }
        let key = WishCompanion.matchKey(name)
        if state.selected.contains(where: { WishCompanion.matchKey($0.name) == key }) {
            return true
        }
        // 같은 이름을 전에 적었으면 그 사람으로 본다 (R-11)
        let known = state.recent.first { WishCompanion.matchKey($0.name) == key }
        return add(known ?? WishCompanion(name: name))
    }

    @discardableResult
    private func add(_ person: WishCompanion) -> Bool {
        guard !state.selected.contains(where: { $0.isSamePerson(as: person) }) else { return true }
        guard !state.isFull else {
            route = .toast(Strings.Companion.Sheet.maxCountFormat(WishCompanion.maxCount))
            return false
        }
        state.selected.append(person)
        // 다 차면 입력 칸이 사라진다. 보이지 않는 칸에 친 글자가 남아 "정했어요"를 막지 않게 비운다
        if state.isFull { state.nameInput = "" }
        return true
    }

    private func finish(with companions: [WishCompanion]) {
        onFinish?(companions)
        route = .dismiss
    }
}

extension CompanionSheetViewModel: Equatable {
    static func == (lhs: CompanionSheetViewModel, rhs: CompanionSheetViewModel) -> Bool {
        lhs === rhs
    }
}
