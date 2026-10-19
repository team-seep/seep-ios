import Foundation
import Combine

extension WishCalendarViewModel {
    struct Input {
        /// "캘린더에 추가" / "캘린더에 추가됨" 탭
        let didTapButton = PassthroughSubject<Void, Never>()
        /// 중복 확인 알럿에서 "추가하기"
        let confirmAddAgain = PassthroughSubject<Void, Never>()
        /// 수정 화면에서 돌아와 위시가 바뀌면 날짜·제목·메모를 갈아끼운다.
        let reloadWish = PassthroughSubject<Wish, Never>()
    }

    struct Output {
        let screenName: ScreenName = .wishDetail
        /// 홈에서 연 미완료 위시이고 날짜가 있을 때만 보인다 (R-1)
        let isVisible: CurrentValueSubject<Bool, Never>
        /// 이 위시를 캘린더에 추가한 기록이 있는지 (R-4)
        let isAdded: CurrentValueSubject<Bool, Never>
        let toast = PassthroughSubject<String, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case showAddAgainAlert
        case showPermissionDeniedAlert
        case showErrorAlert(Error)
    }

    struct Config {
        let wish: Wish
        /// 완료 목록에서 연 상세는 false (R-1)
        let isAddable: Bool
    }

    struct State {
        var wish: Wish
        let isAddable: Bool
    }

    struct Dependency {
        let calendarManager: CalendarManagerProtocol
        let preference: Preference
        let logManager: LogManagerProtocol

        init(
            calendarManager: CalendarManagerProtocol = CalendarManager.shared,
            preference: Preference = .shared,
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.calendarManager = calendarManager
            self.preference = preference
            self.logManager = logManager
        }
    }

    /// 저장 시도 결과. 로그 `value` 로 보낸다.
    enum AddResult: String {
        case saved
        case denied
        case failed
    }
}

/// 위시 상세의 "캘린더에 추가" 버튼 (GH-28). 상세는 레거시 Reactor 라 단계·모으기 섹션처럼 이 버튼만 Combine ViewModel 로 붙인다.
final class WishCalendarViewModel {
    let input = Input()
    let output: Output
    private var state: State
    private let dependency: Dependency
    private var cancellables = Set<AnyCancellable>()

    init(config: Config, dependency: Dependency = Dependency()) {
        self.dependency = dependency
        self.state = State(wish: config.wish, isAddable: config.isAddable)
        self.output = Output(
            isVisible: .init(Self.isVisible(wish: config.wish, isAddable: config.isAddable)),
            isAdded: .init(dependency.preference.calendarEventId(wishId: config.wish.id) != nil)
        )

        bind()
    }

    private func bind() {
        input.didTapButton
            .withUnretained(self)
            .sink { (owner: WishCalendarViewModel, _) in
                owner.handleTapButton()
            }
            .store(in: &cancellables)

        input.confirmAddAgain
            .withUnretained(self)
            .sink { (owner: WishCalendarViewModel, _) in
                owner.addToCalendar { result in
                    owner.sendClickLog(objectId: .confirmAddCalendar, extraParameters: [.value: result.rawValue])
                }
            }
            .store(in: &cancellables)

        input.reloadWish
            .withUnretained(self)
            .sink { (owner: WishCalendarViewModel, wish: Wish) in
                owner.state.wish = wish
                owner.output.isVisible.send(Self.isVisible(wish: wish, isAddable: owner.state.isAddable))
            }
            .store(in: &cancellables)
    }

    private func handleTapButton() {
        guard output.isVisible.value else { return }

        if output.isAdded.value {
            // 같은 일정이 두 번 생기지 않게 한 번 더 묻는다 (R-5). 저장은 알럿 이후라 value 가 없다.
            sendClickLog(objectId: .addCalendar, extraParameters: [.type: "again"])
            output.route.send(.showAddAgainAlert)
        } else {
            addToCalendar { [weak self] result in
                self?.sendClickLog(
                    objectId: .addCalendar,
                    extraParameters: [.type: "first", .value: result.rawValue]
                )
            }
        }
    }

    private func addToCalendar(completion: @escaping (AddResult) -> Void) {
        dependency.calendarManager.requestAccess { [weak self] isGranted in
            guard let self else { return }
            guard isGranted else {
                output.route.send(.showPermissionDeniedAlert)
                completion(.denied)
                return
            }

            completion(saveEvent())
        }
    }

    private func saveEvent() -> AddResult {
        let wish = state.wish
        guard let date = wish.endDate else { return .failed }

        let draft = CalendarEventDraft(
            title: "\(wish.emoji) \(wish.title)",
            date: date,
            notes: wish.memo.isEmpty ? nil : wish.memo
        )

        switch dependency.calendarManager.saveAllDayEvent(draft) {
        case .success(let eventId):
            dependency.preference.setCalendarEventId(eventId, wishId: wish.id)
            output.isAdded.send(true)
            output.toast.send(Strings.Detail.Calendar.Toast.addedFormat(
                DateUtils.toString(format: "M월 d일", date: date)
            ))
            return .saved
        case .failure(let error):
            output.route.send(.showErrorAlert(error))
            return .failed
        }
    }

    private static func isVisible(wish: Wish, isAddable: Bool) -> Bool {
        return isAddable && wish.isSuccess == false && wish.endDate != nil
    }

    private func sendClickLog(objectId: LogObjectId, extraParameters: [ParameterName: Any]? = nil) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .button,
            objectId: objectId,
            extraParameters: extraParameters
        ))
    }
}
