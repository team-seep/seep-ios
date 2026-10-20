import SwiftUI
import WidgetKit

struct CheckWidgetEntryView: View {
    let entry: CheckWidgetEntry

    var body: some View {
        Group {
            if entry.wishes.isEmpty {
                // 위시가 없으면 기존 medium 위젯과 같은 빈 화면 (R-10)
                EmptyView()
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.wishes, id: \.id) { wish in
                        CheckWishRowView(wish: wish)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.init(top: 12, leading: 15, bottom: 12, trailing: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground(.gray2)
    }
}

/// 줄 하나: D-day · 이모지 · 제목 · 보조 문구 · 체크 원 (R-2)
struct CheckWishRowView: View {
    let wish: Wish

    var body: some View {
        HStack(spacing: 0) {
            if #available(iOSApplicationExtension 17.0, *) {
                // 체크 원 밖은 위시 상세 링크, 체크 원은 인텐트 버튼 (R-3, R-9)
                Link(destination: detailURL) {
                    content
                }
                checkButton
            } else {
                // iOS 16 은 인텐트 버튼이 없어 줄 전체가 상세 링크다 (R-9)
                Link(destination: detailURL) {
                    HStack(spacing: 0) {
                        content
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray3)
                            .frame(width: 32, height: 40)
                    }
                }
            }
        }
        .frame(height: 40)
        .background(Color.gray1)
        .cornerRadius(10)
    }

    private var detailURL: URL {
        let deepLink = WidgetDeepLink.wish(id: wish.id, source: .checkWidget)
        return deepLink.url ?? URL(fileURLWithPath: "/")
    }

    private var content: some View {
        HStack(spacing: 7) {
            if let endDate = wish.endDate {
                DdayView(date: endDate)
            }

            Text(wish.emoji)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 0) {
                Text(wish.title)
                    .font(.custom("AppleSDGothicNeo-SemiBold", size: 13))
                    .foregroundColor(wish.isSuccess ? .gray4 : .gray5)
                    .lineLimit(1)
                    // 위젯 렌더러가 커스텀 폰트의 strikethrough 를 그리지 않아 선을 직접 얹는다 (R-4)
                    .overlay(
                        Rectangle()
                            .fill(Color.gray4)
                            .frame(height: 1)
                            .opacity(wish.isSuccess ? 1 : 0)
                    )

                Text(WidgetCheckAction.caption(wish: wish))
                    .font(.custom("AppleSDGothicNeo-Medium", size: 11))
                    .foregroundColor(.gray4)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.leading, 10)
        // 완료한 줄은 흐리게 남긴다 (R-4, 앱 셀 규칙과 같은 0.4)
        .opacity(wish.isSuccess ? 0.4 : 1)
        // 완료·취소 때 흐림과 문구가 같이 바뀌면 이전 문구가 남은 채 보간돼, 상태마다 새 뷰로 그린다
        .id("\(wish.id)-\(wish.isSuccess)")
    }

    @available(iOSApplicationExtension 17.0, *)
    private var checkButton: some View {
        Group {
            if wish.isSuccess {
                Button(intent: UncheckWishIntent(wishId: wish.id)) {
                    CheckCircleView(isChecked: true)
                }
            } else {
                Button(intent: CheckWishIntent(wishId: wish.id)) {
                    CheckCircleView(isChecked: false)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// 24pt 체크 원, 터치 영역 40×40 (R-2)
struct CheckCircleView: View {
    let isChecked: Bool

    var body: some View {
        ZStack {
            if isChecked {
                Circle()
                    .fill(Color.tennisGreen)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(.white)
            } else {
                Circle()
                    .strokeBorder(Color.gray3, lineWidth: 2)
            }
        }
        .frame(width: 24, height: 24)
        .frame(width: 40, height: 40)
        .contentShape(Rectangle())
    }
}

struct CheckWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        CheckWidgetEntryView(entry: CheckWidgetEntry.preview)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
