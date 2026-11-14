import Foundation

/// 작성·수정 문서에서 고른 태그 묶음 (GH-136 R-2). 순서·최대 개수·중복 규칙을 한 곳에서 지킨다.
/// 기본 태그는 `HashtagType` rawValue, 직접 입력은 글자 그대로 저장한다
struct WishTagSelection: Equatable {
    static let maxCount = 5
    /// 직접 입력 태그 하나의 최대 글자 수 (기존 해시태그 7자 제한 그대로)
    static let customMaxLength = 7

    enum AddResult: Equatable {
        case added
        /// 이미 있는 태그라 넣지 않았다
        case duplicate
        /// 최대 개수라 넣지 않았다
        case full
        /// 공백뿐이라 넣지 않았다
        case empty
    }

    private(set) var tags: [String]

    init(tags: [String] = []) {
        var normalized: [String] = []
        for tag in tags {
            let name = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !normalized.contains(name), normalized.count < Self.maxCount else { continue }
            normalized.append(name)
        }
        self.tags = normalized
    }

    var isFull: Bool { tags.count >= Self.maxCount }

    /// 고른 직접 입력 태그, 넣은 순서대로. 기본 태그 칩과 따로 칩으로 쌓는다
    var customTags: [String] {
        tags.filter { HashtagType(rawValue: $0) == nil }
    }

    func contains(_ hashtag: HashtagType) -> Bool {
        tags.contains(hashtag.rawValue)
    }

    /// 기본 태그를 켜고 끈다. 최대 개수라 켜지 못했으면 false
    @discardableResult
    mutating func toggle(_ hashtag: HashtagType) -> Bool {
        if let index = tags.firstIndex(of: hashtag.rawValue) {
            tags.remove(at: index)
            return true
        }
        guard !isFull else { return false }
        tags.append(hashtag.rawValue)
        return true
    }

    /// 직접 입력 태그를 넣는다. 기본 태그 이름과 같으면 그 기본 태그로 넣는다
    @discardableResult
    mutating func addCustom(_ text: String) -> AddResult {
        let name = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.customMaxLength))
        guard !name.isEmpty else { return .empty }
        let stored = HashtagType.preset(named: name)?.rawValue ?? name
        guard !tags.contains(stored) else { return .duplicate }
        guard !isFull else { return .full }
        tags.append(stored)
        return .added
    }

    mutating func remove(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}
