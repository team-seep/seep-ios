import SwiftUI

/// 앨범에 저장하는 정사각형 카드. 화면 표시와 `ImageRenderer` 저장이 같은 뷰를 쓴다.
/// 위: 마감일(SemiBold 16) · 로고 / 가운데: 이모지 / 아래: D-day 뱃지(gray5 바탕·흰 SemiBold 22·라운드 12·그림자) + 제목(UltraLight 24)
struct ShareCardView: View {
    let state: SharePhotoViewModel.State
    let side: CGFloat
    /// 사진 탭에서 고른 사진. 없으면 이모지 바탕색
    let photo: CGImage?

    var body: some View {
        ZStack {
            background

            if !state.showsPhotoBackground {
                Text(verbatim: state.emoji)
                    .font(.system(size: SharePhotoLayout.emojiFontSize(cardSide: side)))
            }

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    if let dateText = state.dateText {
                        Text(verbatim: dateText)
                            .font(.appleSemiBold(size: 16))
                            .foregroundStyle(textColor)
                    }
                    Spacer(minLength: 0)
                    logo
                }
                .padding(.top, 24)
                .padding(.leading, 19)
                .padding(.trailing, 17)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                if let ddayText = state.ddayText {
                    Text(verbatim: ddayText)
                        .font(.appleSemiBold(size: 22))
                        .foregroundStyle(Color.gray1)
                        .padding(EdgeInsets(top: 4, leading: 9, bottom: 1, trailing: 9))
                        .background(Color.gray5, in: RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.25), radius: 12, y: 10)
                        .padding(.bottom, 13)
                }
                Text(verbatim: state.title)
                    .font(.appleUltraLight(size: 24))
                    .foregroundStyle(textColor)
                    .lineLimit(2)
            }
            .padding(.horizontal, 21)
            .padding(.bottom, 21)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(width: side, height: side)
        .clipped()
    }

    @ViewBuilder
    private var background: some View {
        if state.showsPhotoBackground, let photo {
            Image(decorative: photo, scale: 1)
                .resizable()
                .scaledToFill()
                .frame(width: side, height: side)
                .clipped()
        } else if state.showsPhotoBackground {
            // 고른 사진을 아직 불러오는 중
            Color.gray3
        } else {
            Color(
                red: state.emojiBackground.red,
                green: state.emojiBackground.green,
                blue: state.emojiBackground.blue
            )
        }
    }

    private var textColor: Color {
        state.isTextBlack ? .gray5 : .gray1
    }

    private var logo: some View {
        (state.isTextBlack ? Assets.Icons.icLogoBlack : Assets.Icons.icLogoWhite).swiftUIImage
            .accessibilityHidden(true)
    }
}
