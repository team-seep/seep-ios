import WidgetKit
import SwiftUI

/// 홈 화면에서 앱을 열지 않고 다음 단계·위시를 체크하는 위젯 (GH-48 R-1, R-12).
/// 체크 버튼(App Intent)은 iOS 17+ 에서만 보이고, iOS 16 은 줄을 누르면 위시 상세로 연다
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
