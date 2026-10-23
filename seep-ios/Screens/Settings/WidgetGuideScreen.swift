import SwiftUI

/// 위젯 추가하는 법 (R-27). 홈 화면 위젯(바로 적기·남은 싶·체크)과 잠금화면 위젯 추가 3단계
struct WidgetGuideScreen: View {
    var body: some View {
        GuideScreen(
            title: Strings.WidgetGuide.title,
            screenName: .widgetGuide,
            sections: [
                GuideSection(
                    title: Strings.WidgetGuide.Home.title,
                    description: Strings.WidgetGuide.Home.description,
                    steps: [Strings.WidgetGuide.Home.step1, Strings.WidgetGuide.Home.step2, Strings.WidgetGuide.Home.step3],
                    screenshot: Assets.Images.imgGuideWidgetHome
                ),
                GuideSection(
                    title: Strings.WidgetGuide.Lock.title,
                    description: Strings.WidgetGuide.Lock.description,
                    steps: [Strings.WidgetGuide.Lock.step1, Strings.WidgetGuide.Lock.step2, Strings.WidgetGuide.Lock.step3]
                )
            ]
        )
    }
}
