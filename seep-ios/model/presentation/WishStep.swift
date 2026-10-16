import Foundation

struct WishStep: Equatable, Hashable {
    static let maxCount = 10
    static let maxTitleLength = 30

    let id: String
    var title: String
    var isDone: Bool
    let order: Int

    init(
        id: String = UUID().uuidString,
        title: String,
        isDone: Bool = false,
        order: Int
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.order = order
    }

    init(dto: WishStepDTO) {
        self.id = dto._id
        self.title = dto.title
        self.isDone = dto.isDone
        self.order = dto.order
    }
}

/// 단계 진행도. 단계가 없으면 표시하지 않으므로 nil 이 된다.
struct WishStepProgress: Equatable, Hashable {
    let doneCount: Int
    let totalCount: Int

    var ratio: Double {
        Double(doneCount) / Double(totalCount)
    }

    init?(steps: [WishStep]) {
        guard steps.isEmpty == false else { return nil }
        self.doneCount = steps.filter(\.isDone).count
        self.totalCount = steps.count
    }
}
