import Foundation

/// 위젯·컨트롤 링크(`widget://…`). 위젯·컨트롤은 이 타입으로 URL 을 만들고, 앱은 같은 타입으로 읽는다 (GH-47 R-11, GH-48 R-9, GH-49 R-6)
enum WidgetDeepLink: Equatable {
    /// 바로 적기 위젯·싶 적기 컨트롤·단축어 → 작성 화면. `widget://add?category=…&source=…`
    case add(Category, source: Source? = nil)
    /// 잠금화면 D-day 위젯·체크 위젯의 위시 줄 → 위시 상세. `widget://wish?id=…&source=…`
    case wish(id: String, source: Source?)
    /// 홈만 연다. `widget://home?source=…`
    case home(source: Source?)

    /// 어디서 열렸는지. 앱이 클릭 로그로 남긴다
    enum Source: String {
        case lockscreenDday = "lockscreen_dday"
        case lockscreenRemain = "lockscreen_remain"
        case checkWidget = "check_widget"
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
        case .add(_, let source), .wish(_, let source), .home(let source):
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
