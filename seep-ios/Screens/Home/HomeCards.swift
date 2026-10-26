import SwiftUI

/// 잠든 위시 카드: 캡션 · 질문 · 이모지+제목 · 구분선 · [이제 됐어요 | 여전히 하고 싶어요] (GH-30 R-6)
struct HomeSleepingWishCardView: View {
    let card: SleepingWishCard
    let onRelease: () -> Void
    let onKeep: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: card.caption)
                    .font(.appleMedium(size: 12))
                    .foregroundStyle(Color.gray4)
                    .frame(height: 17)
                Text(verbatim: card.question)
                    .font(.appleBold(size: 14))
                    .foregroundStyle(Color.gray5)
                    .frame(height: 20)
                HStack(spacing: 12) {
                    Text(verbatim: card.wish.emoji)
                        .font(.system(size: 30))
                    Text(verbatim: card.wish.title)
                        .font(.appleSemiBold(size: 16))
                        .foregroundStyle(Color.gray5)
                        .lineLimit(1)
                }
                .frame(height: 36)
                .padding(.top, 10)
            }
            .padding(.top, 16)
            .padding(.bottom, 14)
            .padding(.leading, 14)
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(Color.gray2_5)
                .frame(height: 1)

            HStack(spacing: 0) {
                Button(action: onRelease) {
                    Text(verbatim: card.releaseTitle)
                        .font(.appleMedium(size: 14))
                        .foregroundStyle(Color.gray4)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button(action: onKeep) {
                    Text(verbatim: card.keepTitle)
                        .font(.appleExtraBold(size: 14))
                        .foregroundStyle(Color.seepBlue)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// "올해 돌아보기" 배너. 카드를 누르면 회고, X는 닫기 (GH-34 R-1, R-2)
struct HomeYearReviewBannerView: View {
    let banner: YearReviewEligibility
    let onTap: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: Strings.Home.YearReview.captionFormat(String(banner.year)))
                            .font(.appleMedium(size: 12))
                            .foregroundStyle(Color.gray4)
                        titleText
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Assets.Icons.icRightArrow.swiftUIImage
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color.gray5)
                }
                .padding(.leading, 16)
                .padding(.trailing, 12)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.gray2_5)
                .frame(width: 1, height: 24)
                .padding(.trailing, 2)

            Button(action: onClose) {
                Assets.Icons.icClose.swiftUIImage
                    .renderingMode(.template)
                    .foregroundStyle(Color.gray3)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(Strings.Home.YearReview.close))
            .padding(.trailing, 4)
        }
        .frame(height: 64)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
    }

    private var titleText: Text {
        var attributed = AttributedString(Strings.Home.YearReview.titleFormat(banner.count))
        attributed.font = .appleSemiBold(size: 16)
        attributed.foregroundColor = .gray5
        if let range = attributed.range(of: Strings.Home.YearReview.countFormat(banner.count)) {
            attributed[range].font = .appleExtraBold(size: 16)
            attributed[range].foregroundColor = .seepBlue
        }
        return Text(attributed)
    }
}

/// 진행 중 위시가 없을 때 (디자인 시스템 empty-text, Medium 12, 줄 간격 1.5)
struct HomeEmptyView: View {
    var body: some View {
        Text(Strings.Home.emptyTab)
            .font(.appleMedium(size: 12))
            .foregroundStyle(Color.emptyText)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .frame(maxWidth: .infinity)
            .padding(.top, 180)
    }
}

/// "예전 위시를 불러오지 못했어요" 카드: 제목 · 안내 · 구분선 · [문의하기 | 다시 시도] (GH-96 R-9, R-12)
struct HomeMigrationNoticeCardView: View {
    let state: MigrationNoticeViewModel.State
    let onContact: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.Home.MigrationNotice.title)
                    .font(.appleBold(size: 14))
                    .foregroundStyle(Color.gray5)
                Text(verbatim: state.message)
                    .font(.appleMedium(size: 12))
                    .foregroundStyle(Color.gray4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 16)
            .padding(.bottom, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)

            if state.isContactVisible || state.isRetryVisible {
                Rectangle()
                    .fill(Color.gray2_5)
                    .frame(height: 1)

                HStack(spacing: 0) {
                    if state.isContactVisible {
                        Button(action: onContact) {
                            Text(Strings.Home.MigrationNotice.contact)
                                .font(.appleMedium(size: 14))
                                .foregroundStyle(Color.gray4)
                                .frame(maxWidth: .infinity, minHeight: 46)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    if state.isRetryVisible {
                        Button(action: onRetry) {
                            ZStack {
                                Text(Strings.Home.MigrationNotice.retry)
                                    .font(.appleExtraBold(size: 14))
                                    .foregroundStyle(Color.seepBlue)
                                    .opacity(state.isRetrying ? 0 : 1)
                                if state.isRetrying {
                                    ProgressView()
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(state.isRetrying)
                    }
                }
            }
        }
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
