import SwiftUI

/// 메타 줄 아래 상태 줄 (GH-143 R-2, R-6). 위아래 `gray2_5` 1pt 선, 높이 44.
/// 시작 전: "아직 시작 전이에요" + "시작했어요" / 하는 중: ● "하고 있어요 · {시작일}부터 n일째" + "되돌리기" / 이룬 싶: 시작 기록 한 줄
struct DetailStartStatusLine: View {
    let status: WishStartStatus
    /// 이룬 싶 탭에서 연 상세는 버튼 없이 글자만
    let isEditable: Bool
    let onStart: () -> Void
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            leading
            Spacer(minLength: 8)
            if isEditable {
                trailing
            }
        }
        .frame(minHeight: 44)
        .overlay(alignment: .top) { divider }
        .overlay(alignment: .bottom) { divider }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.gray2_5)
            .frame(height: 1)
    }

    @ViewBuilder
    private var leading: some View {
        switch status {
        case .notStarted:
            Text(Strings.Detail.Start.notStarted)
                .font(.appleMedium(size: 14))
                .foregroundStyle(Color.gray4)
        case .doing(let sinceText, let days):
            HStack(spacing: 8) {
                InProgressDot()
                (Text(Strings.Detail.Start.doing).font(.appleBold(size: 14)).foregroundStyle(Color.gray5)
                    + Text(verbatim: " · " + sinceText).font(.appleMedium(size: 14)).foregroundStyle(Color.gray4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: Strings.Detail.Start.doingAccessibilityFormat(days)))
        case .finished(let text):
            Text(verbatim: text)
                .font(.appleMedium(size: 14))
                .foregroundStyle(Color.gray4)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    @ViewBuilder
    private var trailing: some View {
        switch status {
        case .notStarted:
            textButton(Strings.Detail.Start.start, font: .appleExtraBold(size: 14), action: onStart)
        case .doing:
            textButton(Strings.Detail.Start.undo, font: .appleMedium(size: 14), action: onUndo)
        case .finished:
            EmptyView()
        }
    }

    private func textButton(_ title: String, font: Font, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(font)
                .foregroundStyle(Color.seepBlue)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
