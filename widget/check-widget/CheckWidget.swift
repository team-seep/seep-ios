import WidgetKit
import SwiftUI

/// 홈 화면에서 앱을 열지 않고 다음 단계·위시를 체크하는 위젯 (GH-48 R-1, R-12).
/// 체크 원은 App Intent 버튼이고, 나머지 줄은 위시 상세 링크다
struct CheckWidget: Widget {
    let kind: String = "\(CheckWidget.self)"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CheckWidgetProvider()) { entry in
            CheckWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("바로 체크하기")
        .description("앱을 열지 않고 다음 단계와 위시를 체크해요")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabledIfAvailable()
    }
}
