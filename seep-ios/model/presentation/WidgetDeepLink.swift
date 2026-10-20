import Foundation

/// 위젯·컨트롤 링크(`widget://…`). 위젯·컨트롤은 이 타입으로 URL 을 만들고, 앱은 같은 타입으로 읽는다 (GH-49 R-6)
/// #53(GH-47)·#54(GH-48)와 같은 타입이다. 늦게 머지되는 쪽이 케이스·`Source` 케이스를 합친다.
enum WidgetDeepLink: Equatable {
    /// 바로 적기 위젯·싶 적기 컨트롤·단축어 → 작성 화면. `widget://add?category=…&source=…`
    case add(Category, source: Source? = nil)

    /// 어디서 열렸는지. 앱이 클릭 로그로 남긴다
    enum Source: String {
        /// 싶 적기 컨트롤(제어 센터·잠금화면·동작 버튼) (GH-49)
        case control
        /// 단축어·Siri·Spotlight (GH-49)
        case shortcut
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
            self = .add(category, source: source)

        default:
            return nil
        }
    }

    var source: Source? {
        switch self {
        case .add(_, let source):
            return source
        }
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = Self.scheme
        var queryItems: [URLQueryItem] = []

        switch self {
        case .add(let category, let source):
            components.host = "add"
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
            if let source {
                queryItems.append(URLQueryItem(name: "source", value: source.rawValue))
            }
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }
}
