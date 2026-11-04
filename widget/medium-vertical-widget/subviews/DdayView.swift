import SwiftUI
import WidgetKit

/// 위젯 D-day 뱃지. 앱과 같은 디자인 시스템 `DdayBadge`를 쓴다 (GH-87 R-1)
struct DdayView: View {
    let date: Date

    var body: some View {
        DdayBadge(style: DdayBadgeStyle(endDate: date), farFutureText: Strings.homeInFarFurture, noDateText: Strings.homeNoDeanline)
    }
}

struct DdayView_Previews: PreviewProvider {
    static var previews: some View {
        DdayView(date: Date())
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
