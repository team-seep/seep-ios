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
            (emoji, caption, question) = ("😍", Strings.Widget.SmallWrite.Caption.wantToDo, Strings.Widget.SmallWrite.Question.wantToDo)
        case .wantToGet:
            (emoji, caption, question) = ("🤩", Strings.Widget.SmallWrite.Caption.wantToGet, Strings.Widget.SmallWrite.Question.wantToGet)
        case .wantToGo:
            (emoji, caption, question) = ("😆", Strings.Widget.SmallWrite.Caption.wantToGo, Strings.Widget.SmallWrite.Question.wantToGo)
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
        case .wantToDo: headline = Strings.Widget.SmallRemain.Headline.wantToDo
        case .wantToGet: headline = Strings.Widget.SmallRemain.Headline.wantToGet
        case .wantToGo: headline = Strings.Widget.SmallRemain.Headline.wantToGo
        }
        self.count = "\(count)"
        // 숫자만 크게 그려서 문장을 나눠 둔다. 단위는 개수와 상관없는 말로 둔다(복수형은 2단계 번역 때 다시 본다)
        suffix = category == .wantToGo ? Strings.Widget.SmallRemain.suffixPlaces : Strings.Widget.SmallRemain.suffixThings
        emptyCaption = count == 0 ? Strings.Widget.SmallRemain.emptyCaption : nil
        url = URL(string: "widget://home")
    }
}

/// 중형 위젯의 빈 상태 문구 (GH-87 R-3, TC-3)
enum WidgetEmptyCopy {
    static var title: String { Strings.Widget.Empty.title }
    static var bold: String { Strings.Widget.Empty.bold }
    static var action: String { Strings.Widget.Empty.action }
}
