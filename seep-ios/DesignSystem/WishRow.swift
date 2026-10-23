import SwiftUI

/// 위시 줄·타일이 그리는 값. 도메인 `Wish`를 모르게 해 위젯 타깃에서도 쓴다
struct WishRowModel: Equatable, Identifiable {
    let id: String
    let emoji: String
    let title: String
    let dday: DdayBadgeStyle
    var tag: String?
    var isFinished: Bool = false
    /// 뱃지 줄 대신 보여줄 보조 문구(이룬 싶 탭의 "19일 이룸 · 소감" 등). 있으면 뱃지를 숨긴다
    var subtitle: String?
}

/// 위시 리스트 셀. 흰 카드 높이 70·라운드 12·안쪽 14, 이모지 → 제목 + 뱃지 → 체크 원 30 (디자인 시스템 WishListCell).
/// 완료한 줄은 체크 원을 뺀 내용을 0.4로 흐리고 제목에 gray4 취소선
struct WishRow: View {
    let model: WishRowModel
    let farFutureText: String
    let noDateText: String
    /// 완료 줄을 흐리게 할지. 이룬 싶 탭처럼 완료가 기본인 곳은 false
    var dimsFinished: Bool = true
    var onToggle: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Text(verbatim: model.emoji)
                    .font(.system(size: 30))
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: model.title)
                        .font(.appleSemiBold(size: 16))
                        .foregroundStyle(Color.gray5)
                        .strikethrough(model.isFinished && dimsFinished, color: .gray4)
                        .lineLimit(1)
                    if let subtitle = model.subtitle {
                        Text(verbatim: subtitle)
                            .font(.appleRegular(size: 14))
                            .foregroundStyle(Color.gray4)
                            .lineLimit(1)
                    } else {
                        HStack(spacing: 7) {
                            DdayBadge(style: model.dday, farFutureText: farFutureText, noDateText: noDateText)
                            if let tag = model.tag {
                                TagBadge(text: tag)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .opacity(model.isFinished && dimsFinished ? 0.4 : 1)

            Button(action: onToggle) {
                CheckCircle(isChecked: model.isFinished)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(model.isFinished ? .isSelected : [])
        }
        .padding(.leading, 14)
        .padding(.trailing, 7)
        .frame(minHeight: 70)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// 위시 그리드 셀. 높이 = 폭 × 1.09, 이모지 위 / 제목 / 아래 뱃지 + 오른쪽 아래 체크 (디자인 시스템 WishGridCell)
struct WishTile: View {
    let model: WishRowModel
    let farFutureText: String
    let noDateText: String
    var onToggle: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: model.emoji)
                .font(.system(size: 40))
            Spacer(minLength: 8)
            Text(verbatim: model.title)
                .font(.appleSemiBold(size: 16))
                .foregroundStyle(Color.gray5)
                .strikethrough(model.isFinished, color: .gray4)
                .lineLimit(2)
            Spacer(minLength: 8)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    DdayBadge(style: model.dday, farFutureText: farFutureText, noDateText: noDateText)
                    if let tag = model.tag {
                        TagBadge(text: tag)
                    }
                }
                Spacer(minLength: 0)
                Button(action: onToggle) {
                    CheckCircle(isChecked: model.isFinished)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .opacity(model.isFinished ? 0.4 : 1)
        .aspectRatio(1 / 1.09, contentMode: .fit)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
    }
}
