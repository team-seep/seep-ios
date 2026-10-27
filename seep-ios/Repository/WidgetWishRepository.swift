import Foundation

import GRDB

/// 위젯 Provider(소형·중형·잠금화면)가 읽는 저장소. 앱·위젯 두 타깃에 들어간다 (GH-79 R-15).
/// Provider 가 DB 를 직접 열지 않고 앱과 같은 규칙(삭제 표시 제외)으로 읽게 한다.
protocol WidgetWishRepository {
    /// 완료하지 않은 위시 전체 (카테고리 무관)
    func fetchUnfinishedWishes() -> [Wish]

    /// 카테고리의 완료하지 않은 위시 수
    func fetchUnfinishedCount(category: Category) -> Int
}

final class WidgetWishRepositoryImpl: WidgetWishRepository {
    private let database: AppDatabase?

    init(database: AppDatabase? = AppDatabase.shared) {
        self.database = database
    }

    func fetchUnfinishedWishes() -> [Wish] {
        guard let database else { return [] }
        let request = WishRecordStore.aliveWishes().filter(WishRecord.Columns.isSuccess == false)
        return (try? database.writer.read { try WishRecordStore.fetchWishes(request, in: $0) }) ?? []
    }

    func fetchUnfinishedCount(category: Category) -> Int {
        guard let database else { return 0 }
        let request = WishRecordStore.aliveWishes()
            .filter(WishRecord.Columns.category == category.rawValue && WishRecord.Columns.isSuccess == false)
        return (try? database.writer.read { try request.fetchCount($0) }) ?? 0
    }
}
