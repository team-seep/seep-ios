import Foundation

@testable import seep_ios_dev

final class MockCalendarManager: CalendarManagerProtocol {
    var requestAccessResult = true
    var saveAllDayEventResult: Result<String, Error> = .success("event-1")
    private(set) var requestAccessCallCount = 0
    private(set) var savedDrafts: [CalendarEventDraft] = []

    /// 실제 구현은 메인 스레드로 돌려주지만, 목은 동기로 바로 부른다.
    func requestAccess(completion: @escaping (Bool) -> Void) {
        requestAccessCallCount += 1
        completion(requestAccessResult)
    }

    func saveAllDayEvent(_ draft: CalendarEventDraft) -> Result<String, Error> {
        savedDrafts.append(draft)
        return saveAllDayEventResult
    }
}
