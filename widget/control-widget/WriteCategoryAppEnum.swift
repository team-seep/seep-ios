import AppIntents

/// 싶 적기 컨트롤·단축어에서 고르는 카테고리. `Category` 와 1:1 (GH-49 R-2)
/// App Intents 메타데이터는 빌드 때 상수 문자열로 뽑히므로 SwiftGen 대신 문자열을 직접 쓴다(위젯 타깃에도 SwiftGen 이 없다)
enum WriteCategoryAppEnum: String, AppEnum {
    case wantToDo
    case wantToGet
    case wantToGo

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "카테고리"

    static let caseDisplayRepresentations: [WriteCategoryAppEnum: DisplayRepresentation] = [
        .wantToDo: "하고 싶어요",
        .wantToGet: "갖고 싶어요",
        .wantToGo: "가고 싶어요"
    ]

    init(category: Category) {
        switch category {
        case .wantToDo:
            self = .wantToDo
        case .wantToGet:
            self = .wantToGet
        case .wantToGo:
            self = .wantToGo
        }
    }

    var category: Category {
        switch self {
        case .wantToDo:
            return .wantToDo
        case .wantToGet:
            return .wantToGet
        case .wantToGo:
            return .wantToGo
        }
    }

    /// 컨트롤의 값 라벨 (R-3)
    var title: String {
        switch self {
        case .wantToDo:
            return "하고 싶어요"
        case .wantToGet:
            return "갖고 싶어요"
        case .wantToGo:
            return "가고 싶어요"
        }
    }

    /// 동작 버튼에 보이는 문구 (R-3)
    var actionHint: String {
        switch self {
        case .wantToDo:
            return "하고 싶은 것 적기"
        case .wantToGet:
            return "갖고 싶은 것 적기"
        case .wantToGo:
            return "가고 싶은 곳 적기"
        }
    }
}
