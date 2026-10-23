import EventKit
import Foundation

/// 캘린더에 넣을 "하루 종일" 일정 (GH-28 R-3)
struct CalendarEventDraft: Equatable {
    let title: String
    let date: Date
    let notes: String?
}

enum CalendarManagerError: LocalizedError {
    case noDefaultCalendar

    var errorDescription: String? {
        switch self {
        case .noDefaultCalendar:
            return Strings.Detail.Calendar.Error.noDefaultCalendar
        }
    }
}

protocol CalendarManagerProtocol {
    /// 캘린더 쓰기 권한을 요청한다. 이미 정해진 권한이면 팝업 없이 결과만 돌려준다. completion 은 메인 스레드에서 불린다.
    func requestAccess(completion: @escaping (Bool) -> Void)

    /// 기본 캘린더에 하루 종일 일정을 저장하고 이벤트 id 를 돌려준다.
    func saveAllDayEvent(_ draft: CalendarEventDraft) -> Result<String, Error>
}

final class CalendarManager: CalendarManagerProtocol {
    static let shared = CalendarManager()

    private let eventStore = EKEventStore()

    func requestAccess(completion: @escaping (Bool) -> Void) {
        let handler: (Bool, Error?) -> Void = { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }

        // 일정을 읽지 않으므로 쓰기 전용 권한만 요청한다 (R-2)
        eventStore.requestWriteOnlyAccessToEvents(completion: handler)
    }

    func saveAllDayEvent(_ draft: CalendarEventDraft) -> Result<String, Error> {
        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            return .failure(CalendarManagerError.noDefaultCalendar)
        }

        let event = EKEvent(eventStore: eventStore)
        let startOfDay = Calendar.current.startOfDay(for: draft.date)
        event.calendar = calendar
        event.title = draft.title
        event.isAllDay = true
        event.startDate = startOfDay
        event.endDate = startOfDay
        event.notes = draft.notes

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            // 쓰기 전용 권한에서도 저장 직후 id 는 받을 수 있다. 혹시 비어 있으면 "추가됨" 표시용 임의 값을 쓴다.
            return .success(event.eventIdentifier ?? UUID().uuidString)
        } catch {
            return .failure(error)
        }
    }
}
