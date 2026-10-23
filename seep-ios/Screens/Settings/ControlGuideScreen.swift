import SwiftUI

/// 제어 센터 · 단축어로 적기 (R-27, GH-49). 제어 센터·잠금화면 컨트롤·동작 버튼·단축어에서 "싶 적기" 추가하는 법
struct ControlGuideScreen: View {
    var body: some View {
        GuideScreen(
            title: Strings.ControlGuide.title,
            screenName: .controlGuide,
            sections: [
                GuideSection(
                    title: Strings.ControlGuide.Control.title,
                    description: Strings.ControlGuide.Control.description,
                    steps: [Strings.ControlGuide.Control.step1, Strings.ControlGuide.Control.step2, Strings.ControlGuide.Control.step3]
                ),
                GuideSection(
                    title: Strings.ControlGuide.Shortcut.title,
                    description: Strings.ControlGuide.Shortcut.description,
                    steps: [Strings.ControlGuide.Shortcut.step1, Strings.ControlGuide.Shortcut.step2, Strings.ControlGuide.Shortcut.step3]
                )
            ]
        )
    }
}
