import WidgetKit

/// 잠금화면 위젯 2종의 타임라인. D-n 이 날마다 바뀌도록 다음 날 0시에 갱신한다 (GH-47 R-9)
struct LockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenEntry {
        return LockScreenEntry.preview
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> Void) {
        // 위젯 갤러리 미리보기는 위시가 없어도 모양을 보여준다
        if context.isPreview {
            completion(LockScreenEntry.preview)
        } else {
            completion(generateEntry(now: Date()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> Void) {
        let now = Date()
        let entry = generateEntry(now: now)
        let timeline = Timeline(
            entries: [entry],
            policy: .after(LockScreenDdayPicker.nextRefreshDate(after: now))
        )

        completion(timeline)
    }

    private func generateEntry(now: Date) -> LockScreenEntry {
        // 앱·다른 위젯과 같은 App Group DB 를 읽는다 (GH-79 R-15)
        let wishes = WidgetWishRepositoryImpl().fetchUnfinishedWishes()

        return LockScreenEntry(
            date: now,
            wish: LockScreenDdayPicker.pick(wishes: wishes, now: now),
            remainCount: wishes.count
        )
    }
}
