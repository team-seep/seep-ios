import AppIntents

/// 앱을 열어 고른 카테고리의 작성 화면을 띄운다. 컨트롤·단축어·Siri 가 같은 인텐트를 쓴다 (GH-49 R-4, R-7)
/// 컨트롤이 앱을 열려면 앱·위젯 두 타깃에 모두 들어가야 한다. `perform()` 은 앱 프로세스에서 실행된다
struct OpenWriteIntent: OpenIntent {
    static let title: LocalizedStringResource = "싶 적기"
    static let description = IntentDescription("생각났을 때 바로 위시를 적어요")

    @Parameter(title: "카테고리", default: .wantToDo)
    var target: WriteCategoryAppEnum

    /// 어디서 열었는지 (R-10). 컨트롤은 `.control` 로 만들고, 비어 있으면(단축어 앱에서 직접 만든 동작 등) 단축어로 본다.
    /// OpenIntent 는 `target` 만 필수여야 해서 옵셔널이다
    @Parameter(title: "여는 곳")
    var source: WriteSourceAppEnum?

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$target) 적기")
    }

    /// 위젯 타깃에서도 컴파일되도록 앱 코드를 직접 부르지 않고, 앱이 등록한 구현으로 링크를 넘긴다 (R-11)
    @Dependency
    private var opener: WriteDeepLinkOpening

    init() {}

    init(target: WriteCategoryAppEnum, source: WriteSourceAppEnum) {
        self.target = target
        self.source = source
    }

    var deepLink: WidgetDeepLink {
        return .add(target.category, source: (source ?? .shortcut).deepLinkSource)
    }

    func perform() async throws -> some IntentResult {
        await opener.open(deepLink)
        return .result()
    }
}

/// 인텐트를 어디서 실행했는지 (GH-49 R-10)
enum WriteSourceAppEnum: String, AppEnum {
    case control
    case shortcut

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "여는 곳"

    static let caseDisplayRepresentations: [WriteSourceAppEnum: DisplayRepresentation] = [
        .control: "컨트롤",
        .shortcut: "단축어"
    ]

    var deepLinkSource: WidgetDeepLink.Source {
        switch self {
        case .control:
            return .control
        case .shortcut:
            return .shortcut
        }
    }
}

/// 인텐트가 만든 링크를 앱에 넘긴다. 구현은 앱 타깃(`WriteDeepLinkOpener`)이 `AppDependencyManager` 에 등록한다
protocol WriteDeepLinkOpening: Sendable {
    func open(_ deepLink: WidgetDeepLink) async
}
