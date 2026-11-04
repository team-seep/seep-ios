import Foundation
import Observation

extension WishCalendarViewModel {
    enum Action: Equatable {
        /// ⋯ 메뉴 "캘린더에 추가" / "캘린더에 추가됨"
        case tapButton
        /// 중복 확인 알럿에서 "추가하기"
        case confirmAddAgain
        /// 수정 화면에서 돌아와 날짜·제목·메모가 바뀌었다
        case reload(Wish)
        case routeHandled
    }

    enum Route: Equatable {
        case addAgainAlert
        case permissionDeniedAlert
        case errorAlert(String)
        case toast(String)
    }

    struct Config {
        let wish: Wish
        /// 완료 목록에서 연 상세는 false (GH-28 R-1)
        let isAddable: Bool
    }

    struct State: Equatable {
        /// 홈에서 연 미완료 위시이고 날짜가 있을 때만 메뉴에 보인다 (GH-28 R-1)
        var isVisible: Bool
        /// 이 위시를 캘린더에 추가한 기록이 있는지 (GH-28 R-4)
        var isAdded: Bool
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

    /// 저장 시도 결과. 로그 `value` 로 보낸다
    enum AddResult: String {
        case saved
        case denied
        case failed
    }
}

/// 상세 ⋯ 메뉴의 "캘린더에 추가" (GH-28, GH-59 R-9)
@Observable
final class WishCalendarViewModel {
    let screenName: ScreenName = .wishDetail
    private(set) var state: State
    private(set) var route: Route?

    private var wish: Wish
    private let isAddable: Bool
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.wish = config.wish
        self.isAddable = config.isAddable
        self.dependency = dependency
        self.state = State(
            isVisible: Self.isVisible(wish: config.wish, isAddable: config.isAddable),
            isAdded: dependency.preference.calendarEventId(wishId: config.wish.id) != nil
        )
    }

    func send(_ action: Action) {
        switch action {
        case .tapButton:
            handleTapButton()
        case .confirmAddAgain:
            addToCalendar { [weak self] result in
                self?.sendClickLog(objectId: .confirmAddCalendar, extraParameters: [.value: result.rawValue])
            }
        case .reload(let wish):
            self.wish = wish
            state.isVisible = Self.isVisible(wish: wish, isAddable: isAddable)
        case .routeHandled:
            route = nil
        }
    }

    private func handleTapButton() {
        guard state.isVisible else { return }
        if state.isAdded {
            // 같은 일정이 두 번 생기지 않게 한 번 더 묻는다 (GH-28 R-5). 저장은 알럿 이후라 value 가 없다
            sendClickLog(objectId: .addCalendar, extraParameters: [.type: "again"])
            route = .addAgainAlert
        } else {
            addToCalendar { [weak self] result in
                self?.sendClickLog(objectId: .addCalendar, extraParameters: [.type: "first", .value: result.rawValue])
            }
        }
    }

    private func addToCalendar(completion: @escaping (AddResult) -> Void) {
        dependency.calendarManager.requestAccess { [weak self] isGranted in
            guard let self else { return }
            guard isGranted else {
                route = .permissionDeniedAlert
                completion(.denied)
                return
            }
            completion(saveEvent())
        }
    }

    private func saveEvent() -> AddResult {
        guard let date = wish.endDate else { return .failed }
        let draft = CalendarEventDraft(
            title: "\(wish.emoji) \(wish.title)",
            date: date,
            notes: wish.memo.isEmpty ? nil : wish.memo
        )
        switch dependency.calendarManager.saveAllDayEvent(draft) {
        case .success(let eventId):
            dependency.preference.setCalendarEventId(eventId, wishId: wish.id)
            state.isAdded = true
            route = .toast(Strings.Detail.Calendar.Toast.addedFormat(
                DisplayDate.monthDay(date)
            ))
            return .saved
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
            return .failed
        }
    }

    private static func isVisible(wish: Wish, isAddable: Bool) -> Bool {
        isAddable && wish.isSuccess == false && wish.endDate != nil
    }

    private func sendClickLog(objectId: LogObjectId, extraParameters: [ParameterName: Any]? = nil) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: objectId,
            extraParameters: extraParameters
        ))
    }
}
