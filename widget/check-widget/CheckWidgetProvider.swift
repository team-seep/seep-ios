import WidgetKit

struct CheckWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CheckWidgetEntry {
        return CheckWidgetEntry.preview
    }

    func getSnapshot(in context: Context, completion: @escaping (CheckWidgetEntry) -> Void) {
        completion(context.isPreview ? CheckWidgetEntry.preview : generateEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CheckWidgetEntry>) -> Void) {
        let now = Date()
        // 위젯에서 완료한 줄은 그날 자정까지만 남기므로 자정에 다시 그린다 (R-4)
        let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: now.startOfDay) ?? now
        completion(Timeline(entries: [generateEntry(now: now)], policy: .after(nextMidnight)))
    }

    private func generateEntry(now: Date = Date()) -> CheckWidgetEntry {
        let repository = WidgetCheckRepositoryImpl(now: { now })
        return CheckWidgetEntry(date: now, wishes: repository.fetchCheckWidgetWishes(limit: CheckWidgetEntry.maxCount))
    }
}
