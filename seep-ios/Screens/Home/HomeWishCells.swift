import SwiftUI

/// 홈 리스트 셀. 흰 카드 높이 70·라운드 12, 이모지 36 → 제목(+핀) / D-day·해시태그·단계 진행도 → 체크.
/// 완료 흐름 중인 줄은 내용을 0.5로 흐리고 제목에 gray4 취소선 (디자인 시스템 WishListCell)
struct HomeWishRow: View {
    let item: HomeWishItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(verbatim: item.wish.emoji)
                .font(.system(size: 36))
                .opacity(contentOpacity)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    HomeWishTitle(wish: item.wish, lineLimit: 1)
                    if item.isPinned {
                        HomePinIcon()
                    }
                }
                badgeLine
            }
            .opacity(contentOpacity)
            Spacer(minLength: 0)
            HomeCheckButton(isChecked: item.wish.isSuccess, size: nil, action: onToggle)
        }
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .frame(height: HomeLayout.listRowHeight)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private var contentOpacity: Double {
        item.wish.isSuccess ? 0.5 : 1
    }

    @ViewBuilder
    private var badgeLine: some View {
        if let finishNote = item.finishNote {
            // 소감이 있으면 뱃지 줄 대신 소감 한 줄 (GH-25 R-5)
            Text(verbatim: Strings.Home.FinishNote.cellFormat(finishNote))
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
                .lineLimit(1)
        } else {
            HStack(spacing: 7) {
                HomeDdayBadge(endDate: item.wish.endDate)
                if let tag = item.tagText {
                    TagBadge(text: tag)
                }
                if let progress = item.stepProgress {
                    HomeStepProgress(progress: progress)
                        .padding(.leading, 2)
                }
            }
        }
    }
}

/// 홈 그리드 셀. 높이 = 폭 × 1.09. 사진이 있으면 위에 사진(92), 이모지는 사진 아래 모서리의 흰 원 (GH-36 R-6)
struct HomeWishTile: View {
    let item: HomeWishItem
    let thumbnail: CGImage?
    let onToggle: () -> Void
    let onNeedThumbnail: (Int) -> Void

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.gray1
                if hasPhoto {
                    photoLayout(width: proxy.size.width)
                } else {
                    defaultLayout
                }
                if item.isPinned {
                    HomePinIcon()
                        .padding(.top, hasPhoto ? HomeGridLayout.Photo.height + 8 : 24)
                        .padding(.trailing, 14)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                HomeCheckButton(isChecked: item.wish.isSuccess, size: 30, action: onToggle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 7)
                    .padding(.bottom, 7)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onAppear {
                guard item.photoFileName != nil, thumbnail == nil else { return }
                let width = proxy.size.width > 0 ? proxy.size.width : HomeGridLayout.columnWidthUnit
                onNeedThumbnail(Int((width * displayScale * HomeGridLayout.Photo.thumbnailScale).rounded(.up)))
            }
        }
        .aspectRatio(1 / HomeGridLayout.heightRatio, contentMode: .fit)
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    /// 사진 이름이 있어도 썸네일을 못 읽으면(파일 없음) 사진 없는 셀로 그린다 (GH-36 R-7)
    private var hasPhoto: Bool {
        item.photoFileName != nil && thumbnail != nil
    }

    private var contentOpacity: Double {
        item.wish.isSuccess ? 0.5 : 1
    }

    private var defaultLayout: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: item.wish.emoji)
                .font(.system(size: 36))
            HomeWishTitle(wish: item.wish, lineLimit: 2)
            Spacer(minLength: 0)
            bottomBadges
        }
        .padding(14)
        .opacity(contentOpacity)
    }

    private func photoLayout(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                if let thumbnail {
                    Image(decorative: thumbnail, scale: displayScale)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: HomeGridLayout.Photo.height)
                        .clipped()
                        .accessibilityIgnoresInvertColors()
                }
                Text(verbatim: item.wish.emoji)
                    .font(.system(size: HomeGridLayout.Photo.emojiFontSize))
                    .frame(width: HomeGridLayout.Photo.emojiCircleSize, height: HomeGridLayout.Photo.emojiCircleSize)
                    .background(Color.gray1, in: Circle())
                    .padding(.leading, 10)
                    .offset(y: HomeGridLayout.Photo.emojiCircleSize - HomeGridLayout.Photo.emojiCircleOverlap)
            }
            .frame(height: HomeGridLayout.Photo.height)
            HomeWishTitle(wish: item.wish, lineLimit: 2)
                .padding(.top, 20)
                .padding(.horizontal, 14)
            Spacer(minLength: 0)
            bottomBadges
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
        }
        .opacity(contentOpacity)
    }

    private var bottomBadges: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 9) {
                HomeDdayBadge(endDate: item.wish.endDate)
                if let progress = item.stepProgress {
                    HomeStepProgress(progress: progress)
                }
            }
            if let tag = item.tagText {
                TagBadge(text: tag)
            }
        }
        .padding(.trailing, 36)
    }
}

/// 위시 제목. 완료 흐름 중이면 gray4 취소선
struct HomeWishTitle: View {
    let wish: Wish
    let lineLimit: Int

    var body: some View {
        Text(verbatim: wish.title)
            .font(.appleSemiBold(size: 16))
            .foregroundStyle(Color.gray5)
            .strikethrough(wish.isSuccess, color: .gray4)
            .lineLimit(lineLimit)
            .multilineTextAlignment(.leading)
    }
}

/// 고정 핀 (GH-33 R-7)
struct HomePinIcon: View {
    var body: some View {
        Image(systemName: "pin.fill")
            .font(.system(size: 14))
            .foregroundStyle(Color.gray4)
            .accessibilityLabel(Text(Strings.Home.Pin.pin))
    }
}

/// D-day 뱃지(앱 문구)
struct HomeDdayBadge: View {
    let endDate: Date?

    var body: some View {
        DdayBadge(
            style: DdayBadgeStyle(endDate: endDate),
            farFutureText: Strings.homeInFarFurture,
            noDateText: Strings.homeNoDeanline
        )
    }
}

/// 단계 진행도: 32×4 바 + "n/m" (GH-5)
struct HomeStepProgress: View {
    let progress: WishStepProgress

    var body: some View {
        HStack(spacing: 4) {
            Capsule()
                .fill(Color.gray2_5)
                .frame(width: 32, height: 4)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.tennisGreen)
                        .frame(width: 32 * min(max(progress.ratio, 0), 1), height: 4)
                }
            Text(verbatim: Strings.Home.stepProgressFormat(progress.doneCount, progress.totalCount))
                .font(.appleBold(size: 11))
                .foregroundStyle(Color.gray4)
        }
    }
}

/// 체크 버튼. 터치 영역 44, 아이콘은 `ic_check_off`/`ic_check_on`
struct HomeCheckButton: View {
    let isChecked: Bool
    /// nil 이면 아이콘 원래 크기
    let size: CGFloat?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isChecked ? Strings.Home.finishedAccessibility : Strings.Home.finishAccessibility))
    }

    @ViewBuilder
    private var icon: some View {
        let image = (isChecked ? Assets.Icons.icCheckOn : Assets.Icons.icCheckOff).swiftUIImage
        if let size {
            image.resizable().foregroundStyle(Color.gray3).frame(width: size, height: size)
        } else {
            image.foregroundStyle(Color.gray3)
        }
    }
}
