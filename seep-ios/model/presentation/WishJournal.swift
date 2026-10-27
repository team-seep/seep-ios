import Foundation

/// 이루는 동안 남기는 일지 한 줄 (GH-95). 카테고리와 상관없이 날짜별로 여러 번 남긴다
struct WishJournal: Equatable, Hashable {
    /// 한 줄 최대 글자 수 (R-4)
    static let maxLength = 100

    let id: String
    let text: String
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }

    /// 최신 일지가 먼저 오도록 정렬한다 (R-1)
    static func latestFirst(_ journals: [WishJournal]) -> [WishJournal] {
        journals.sorted { $0.createdAt > $1.createdAt }
    }
}
