import Foundation

/// 이모지 고르기 시트의 "최근 사용" 줄 (GH-64 R-40, TC-49). 최근 고른 것이 맨 앞, 중복 없이 최대 16개
struct EmojiRecentStore {
    static let maxCount = 16
    private static let key = "emojiRecents"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var recents: [String] {
        defaults.stringArray(forKey: Self.key) ?? []
    }

    func add(_ emoji: String) {
        guard !emoji.isEmpty else { return }
        var updated = recents.filter { $0 != emoji }
        updated.insert(emoji, at: 0)
        defaults.set(Array(updated.prefix(Self.maxCount)), forKey: Self.key)
    }
}
