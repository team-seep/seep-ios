import SwiftUI

/// 안내 화면의 한 묶음: 제목 + 설명 + 단계 3개 + 스크린샷 자리
struct GuideSection: Identifiable {
    let title: String
    let description: String
    let steps: [String]

    var id: String { title }
}

/// 설정에서 push 하는 화면 공통 틀. 뒤로 버튼 + 큰 제목 + 내용 (탭 바는 숨는다)
struct SettingsDetailLayout<Content: View>: View {
    let title: String
    let screenName: ScreenName
    @ViewBuilder let content: () -> Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.gray5)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(Strings.Settings.back))
            .padding(.leading, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: title)
                        .font(.appleBold(size: 22))
                        .foregroundStyle(Color.gray5)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 8)
                    content()
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
                .frame(maxWidth: WideScreenLayout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.gray2)
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
                                    .foregroundStyle(Color.gray1)
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
                    // 실제 스크린샷 이미지는 정해지면 에셋으로 넣는다
                    Text(Strings.WidgetGuide.screenshotPlaceholder)
                        .font(.appleMedium(size: 12))
                        .foregroundStyle(Color.gray4)
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .background(Color.gray2_5.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityHidden(true)
                }
                .padding(.top, 24)
            }
        }
    }
}
