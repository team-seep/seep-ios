import Foundation

/// 사진 공유 이모지 탭에서 고르는 이모지 목록. 작성 폼의 이모지 고르기와 같은 `EmojiCategory` 목록을 쓴다.
/// 공유 이미지에만 쓰고 위시의 이모지는 바꾸지 않는다 (기존 ISEmojiView 키보드 대체)
enum ShareEmojiCatalog {
    struct Section: Identifiable, Equatable {
        let id: String
        /// 탭에 그릴 대표 이모지
        let symbol: String
        let emojis: [String]
    }

    static let sections: [Section] = EmojiCategory.allCases.map { category in
        Section(id: category.rawValue, symbol: symbol(of: category), emojis: category.emojis)
    }

    private static func symbol(of category: EmojiCategory) -> String {
        switch category {
        case .smileys: return "😀"
        case .people: return "👋"
        case .animals: return "🐶"
        case .food: return "🍔"
        case .activities: return "⚽️"
        case .travel: return "✈️"
        case .objects: return "💡"
        case .symbols: return "❤️"
        case .flags: return "🏳️"
        }
    }
}
