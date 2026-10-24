import SwiftUI

/// 안내 화면의 한 묶음: 제목 + 설명 + 단계 3개 + 스크린샷
struct GuideSection: Identifiable {
    let title: String
    let description: String
    let steps: [String]
    /// 시스템 화면 스크린샷. 시뮬레이터로 찍을 수 없는 화면(잠금화면 편집)은 비워 둔다
    var screenshot: ImageAsset?

    var id: String { title }
}

/// 설정에서 push 하는 화면 공통 틀. 시스템 내비게이션 바의 큰 제목 + 내용 (탭 바는 숨는다)
struct SettingsDetailLayout<Content: View>: View {
    let title: String
    let screenName: ScreenName
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 32)
            .frame(maxWidth: SeepLayout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.gray2)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .trackScreen(screenName)
    }
}

/// 위젯·컨트롤 안내 화면 (R-27)
struct GuideScreen: View {
    let title: String
    let screenName: ScreenName
    let sections: [GuideSection]

    var body: some View {
        SettingsDetailLayout(title: title, screenName: screenName) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 12) {
                    Text(verbatim: section.title)
                        .font(.appleSemiBold(size: 16))
                        .foregroundStyle(Color.gray5)
                    Text(verbatim: section.description)
                        .font(.appleRegular(size: 14))
                        .foregroundStyle(Color.gray4)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(section.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(verbatim: "\(index + 1)")
                                    .font(.appleBold(size: 12))
                                    .foregroundStyle(Color.onAccent)
                                    .frame(width: 20, height: 20)
                                    .background(Color.seepBlue, in: Circle())
                                Text(verbatim: step)
                                    .font(.appleRegular(size: 14))
                                    .foregroundStyle(Color.gray5)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
                    if let screenshot = section.screenshot {
                        screenshot.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(height: 420)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16).strokeBorder(Color.gray2_5, lineWidth: 1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.top, 24)
            }
        }
    }
}
