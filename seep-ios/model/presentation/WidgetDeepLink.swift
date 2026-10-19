import Foundation

/// 위젯 탭 링크(`widget://…`). 위젯은 이 타입으로 URL 을 만들고, 앱은 같은 타입으로 읽는다 (GH-47 R-11, GH-48 R-9)
/// #53(GH-47)과 같은 타입이다. 늦게 머지되는 쪽이 `Source` 케이스를 합친다.
enum WidgetDeepLink: Equatable {
    /// 바로 적기 위젯 → 작성 화면. `widget://add?category=…`
    case add(Category)
    /// 위젯의 위시 줄 → 위시 상세. `widget://wish?id=…&source=…`
    case wish(id: String, source: Source?)
    /// 홈만 연다. `widget://home?source=…`
    case home(source: Source?)

    /// 어느 위젯에서 열렸는지
    enum Source: String {
        case checkWidget = "check_widget"
    }

    static let scheme = "widget"

    init?(string: String) {
        guard let components = URLComponents(string: string),
              components.scheme == Self.scheme else { return nil }
        let queryItems = components.queryItems ?? []
        let query: (String) -> String? = { name in
            queryItems.first(where: { $0.name == name })?.value
        }
        let source = query("source").flatMap(Source.init(rawValue:))

        switch components.host {
        case "add":
            guard let category = query("category").flatMap(Category.init(rawValue:)) else { return nil }
            self = .add(category)

        case "wish":
            guard let id = query("id"), !id.isEmpty else { return nil }
            self = .wish(id: id, source: source)

        case "home":
            self = .home(source: source)

        default:
            return nil
        }
    }

    var source: Source? {
        switch self {
        case .add:
            return nil
        case .wish(_, let source), .home(let source):
            return source
        }
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = Self.scheme
        var queryItems: [URLQueryItem] = []

        switch self {
        case .add(let category):
            components.host = "add"
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))

        case .wish(let id, let source):
            components.host = "wish"
            queryItems.append(URLQueryItem(name: "id", value: id))
            if let source {
                queryItems.append(URLQueryItem(name: "source", value: source.rawValue))
            }

        case .home(let source):
            components.host = "home"
            if let source {
                queryItems.append(URLQueryItem(name: "source", value: source.rawValue))
            }
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }
}
