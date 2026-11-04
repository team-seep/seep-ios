import AppIntents
import SwiftUI
import WidgetKit

/// 제어 센터·잠금화면·동작 버튼에 놓는 "싶 적기" 컨트롤 (GH-49 R-1~R-3, R-8)
struct SeepWriteControl: ControlWidget {
    static let kind = "SeepWriteControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            intent: SeepWriteControlConfiguration.self
        ) { configuration in
            ControlWidgetButton(action: OpenWriteIntent(target: configuration.category, source: .control)) {
                Label {
                    Text("싶 적기")
                    Text(verbatim: configuration.category.title)
                } icon: {
                    Image(systemName: "square.and.pencil")
                }
                .controlWidgetActionHint(Text(verbatim: configuration.category.actionHint))
            }
            .tint(.tennisGreen)
        }
        .displayName("싶 적기")
        .description("생각났을 때 바로 위시를 적어요")
    }
}

/// 컨트롤 편집에서 고르는 카테고리. 기본값 하고 싶어요 (R-2)
struct SeepWriteControlConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "싶 적기"

    @Parameter(title: "카테고리", default: .wantToDo)
    var category: WriteCategoryAppEnum

    init() {}
}
