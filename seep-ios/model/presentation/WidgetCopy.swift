import Foundation

/// 예전 홈 화면 위젯 4종의 kind. 바꾸면 이미 홈 화면에 둔 위젯이 사라지므로 타입 이름 그대로 둔다 (GH-87 R-1, TC-2)
enum WidgetKind {
    static let smallWrite = "SmallWriteWidget"
    static let smallRemain = "SmallRemainWidget"
    static let mediumHorizontal = "MediumHorizontalWidget"
    static let mediumVertical = "MediumVerticalWidget"
}

/// 작게 쓰기 위젯 문구·링크 (GH-87 R-1). 탭하면 그 카테고리 작성 화면 (TC-6)
struct SmallWriteCopy: Equatable {
    let emoji: String
    let caption: String
    let question: String
    let url: URL?

    init(category: Category) {
        switch category {
        case .wantToDo:
            (emoji, caption, question) = ("😍", "지금", "뭐 하고 싶어요?")
        case .wantToGet:
            (emoji, caption, question) = ("🤩", "연말에", "뭐 갖고 싶어요?")
        case .wantToGo:
            (emoji, caption, question) = ("😆", "이번주 주말", "어디 가고 싶어요?")
        }
        url = URL(string: "widget://add?category=\(category.rawValue)")
    }
}

/// 남은 개수 위젯 문구·링크 (GH-87 R-1, R-3). 탭하면 홈 (TC-6)
struct SmallRemainCopy: Equatable {
    let headline: String
    let count: String
    let suffix: String
    /// 남은 위시가 없을 때 아래 줄 문구 (TC-3)
    let emptyCaption: String?
    let url: URL?

    init(category: Category, count: Int) {
        switch category {
        case .wantToDo: headline = "하고 싶은 것들이"
        case .wantToGet: headline = "갖고 싶은 것들이"
        case .wantToGo: headline = "가고 싶은 곳들이"
        }
        self.count = "\(count)"
        suffix = category == .wantToGo ? "곳 남았어요!" : "개 남았어요!"
        emptyCaption = count == 0 ? "새 싶을 적어봐요" : nil
        url = URL(string: "widget://home")
    }
}

/// 중형 위젯의 빈 상태 문구 (GH-87 R-3, TC-3)
enum WidgetEmptyCopy {
    static let title = "하고 싶은 것들을"
    static let bold = "적어봐요."
    static let action = "✍️ 지금 쓰러 갈까요?"
}
