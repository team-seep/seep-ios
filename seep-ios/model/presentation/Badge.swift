import Foundation

/// 싶 업적 배지 8종 (GH-35 R-1). rawValue 는 UserDefaults 축하함 기록과 로그 `badge_id` 에 그대로 쓴다
enum BadgeType: String, CaseIterable {
    case finish1 = "finish_1"
    case finish5 = "finish_5"
    case finish10 = "finish_10"
    case finish30 = "finish_30"
    case firstWantToDo = "first_want_to_do"
    case firstWantToGet = "first_want_to_get"
    case firstWantToGo = "first_want_to_go"
    case onTime = "on_time"

    enum Medal: Equatable {
        case number(Int)
        case category(Category)
        case dday
    }

    /// 개수 배지의 목표 완료 수. 개수 배지가 아니면 nil
    var goalCount: Int? {
        switch self {
        case .finish1: return 1
        case .finish5: return 5
        case .finish10: return 10
        case .finish30: return 30
        case .firstWantToDo, .firstWantToGet, .firstWantToGo, .onTime: return nil
        }
    }

    /// 카테고리 배지의 카테고리. 카테고리 배지가 아니면 nil
    var category: Category? {
        switch self {
        case .firstWantToDo: return .wantToDo
        case .firstWantToGet: return .wantToGet
        case .firstWantToGo: return .wantToGo
        case .finish1, .finish5, .finish10, .finish30, .onTime: return nil
        }
    }

    var medal: Medal {
        if let goalCount {
            return .number(goalCount)
        } else if let category {
            return .category(category)
        } else {
            return .dday
        }
    }

    var name: String {
        switch self {
        case .finish1: return Strings.Badge.Name.finish1
        case .finish5: return Strings.Badge.Name.finish5
        case .finish10: return Strings.Badge.Name.finish10
        case .finish30: return Strings.Badge.Name.finish30
        case .firstWantToDo: return Strings.Badge.Name.firstWantToDo
        case .firstWantToGet: return Strings.Badge.Name.firstWantToGet
        case .firstWantToGo: return Strings.Badge.Name.firstWantToGo
        case .onTime: return Strings.Badge.Name.onTime
        }
    }

    var conditionText: String {
        switch self {
        case .finish1, .finish5, .finish10, .finish30:
            return Strings.Badge.Condition.finishFormat(goalCount ?? 0)
        case .firstWantToDo: return Strings.Badge.Condition.firstWantToDo
        case .firstWantToGet: return Strings.Badge.Condition.firstWantToGet
        case .firstWantToGo: return Strings.Badge.Condition.firstWantToGo
        case .onTime: return Strings.Badge.Condition.onTime
        }
    }
}

/// 배지 하나의 계산 결과
struct Badge: Equatable {
    let type: BadgeType
    /// 얻은 날. 잠긴 배지면 nil
    let earnedDate: Date?
    /// 지금까지 완료한 위시 수. 개수 배지의 진행도("5 / 10")에 쓴다
    let finishedCount: Int

    var isEarned: Bool {
        return earnedDate != nil
    }

    /// 잠긴 배지 칸의 보조 문구: 개수 배지는 진행도, 나머지는 조건 문구 (R-5)
    var lockedDescription: String {
        if let goalCount = type.goalCount {
            return Strings.Badge.progressFormat(min(finishedCount, goalCount), goalCount)
        }
        return type.conditionText
    }

    var earnedDateText: String? {
        guard let earnedDate else { return nil }
        return DateUtils.toString(format: "yyyy.MM.dd", date: earnedDate)
    }
}
