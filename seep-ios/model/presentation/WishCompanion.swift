import Foundation

/// 위시에 붙인 "함께할 사람" 한 명 (GH-122).
/// 사람은 이름이 아니라 `personId`로 가른다 — 같은 사람이면 위시가 달라도 같은 id 다(R-11).
/// 나중에 친구 계정과 연결할 때 이 id 로 그 사람이 붙은 위시를 한 번에 잡는다
struct WishCompanion: Equatable, Hashable, Identifiable {
    /// 위시 하나에 붙일 수 있는 최대 인원 (R-1)
    static let maxCount = 5
    /// 이름 하나의 최대 글자 수 (R-2)
    static let nameMaxLength = 20

    let personId: String
    var name: String

    var id: String { personId }

    init(personId: String = UUID().uuidString, name: String) {
        self.personId = personId
        self.name = name
    }

    /// 저장할 이름: 앞뒤 공백을 지우고 최대 글자 수로 자른다. 비면 nil (R-2)
    static func cleanedName(_ text: String) -> String? {
        let name = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(nameMaxLength))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    /// 같은 사람인지 볼 때 쓰는 키: 대소문자를 무시하고 공백을 하나로 줄인다 (R-2, R-11)
    static func matchKey(_ name: String) -> String {
        name.lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// 같은 사람인지: id 가 같거나, 정규화한 이름이 같다 (R-11). 두 기기가 따로 적어 id 가 다른 같은 사람도 하나로 본다
    func isSamePerson(as other: WishCompanion) -> Bool {
        personId == other.personId || Self.matchKey(name) == Self.matchKey(other.name)
    }

    /// 이름 끝 글자에 받침이 있는지. 한글이 아니면 받침 없음으로 본다 — "지은이랑" / "엄마랑" (R-9)
    static func hasFinalConsonant(_ name: String) -> Bool {
        guard let scalar = name.unicodeScalars.last, (0xAC00...0xD7A3).contains(scalar.value) else { return false }
        return (scalar.value - 0xAC00) % 28 != 0
    }
}
