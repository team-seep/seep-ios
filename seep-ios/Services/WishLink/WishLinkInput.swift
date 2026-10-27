import Foundation

/// 링크 칸에 들어온 값을 검증한 결과 (GH-29 R-2). 작성·수정 Reactor 는 이 값만 받는다.
enum WishLinkInput: Equatable {
    /// 빈 칸 = 링크 없음
    case empty
    /// 앞뒤 공백을 지운 http/https 링크
    case valid(String)
    /// 링크 형식이 아님. 작성·수정 완료를 막는다
    case invalid

    static let maxLength = 2_000
    private static let allowedSchemes: Set<String> = ["http", "https"]

    init(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            self = .empty
            return
        }

        guard trimmed.count <= Self.maxLength,
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              Self.allowedSchemes.contains(scheme),
              let host = url.host,
              host.isEmpty == false else {
            self = .invalid
            return
        }

        self = .valid(trimmed)
    }

    var link: String? {
        guard case .valid(let link) = self else { return nil }
        return link
    }

    /// 저장할 링크. 갖고 싶어요가 아니거나 올바른 링크가 아니면 비운다 (R-1, R-2)
    func storedLink(category: Category) -> String {
        guard category == .wantToGet else { return "" }
        return link ?? ""
    }

    /// 작성·수정 완료를 막아야 하는지. 링크 칸은 갖고 싶어요에서만 보인다 (R-1)
    func blocksSave(category: Category) -> Bool {
        return category == .wantToGet && self == .invalid
    }

    /// 카드에 보여줄 도메인. `www.` 은 뺀다.
    static func domain(of link: String) -> String {
        guard let host = URL(string: link)?.host else { return link }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
