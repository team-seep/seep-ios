import SwiftUI

/// 회고 카드 한 장 (GH-34 R-4). 이 뷰만 이미지로 그려 공유한다 (R-5)
struct YearReviewCard: View {
    let summary: YearReviewSummary

    private let inset: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Assets.Icons.icLogoBlack.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
                    .accessibilityHidden(true)
                Spacer()
                Text(verbatim: "\(summary.year)")
                    .font(.appleBold(size: 12))
                    .foregroundStyle(Color.gray4)
            }
            .padding(.top, 22)

            headline
                .lineSpacing(9)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 18)

            HStack(spacing: 8) {
                ForEach([Category.wantToDo, .wantToGet, .wantToGo]) { category in
                    YearReviewCategoryCell(category: category, count: summary.count(of: category))
                }
            }
            .padding(.top, 20)

            Rectangle()
                .fill(Color.gray2_5)
                .frame(height: 1)
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 16) {
                if let longestHeld = summary.longestHeld {
                    YearReviewLongestHeldView(wish: longestHeld.wish, days: longestHeld.days)
                }
                if let busiestMonth = summary.busiestMonth {
                    VStack(alignment: .leading, spacing: 4) {
                        YearReviewCaption(text: Strings.YearReview.BusiestMonth.title)
                        Text(verbatim: Strings.YearReview.BusiestMonth.format(busiestMonth.month, busiestMonth.count))
                            .font(.appleSemiBold(size: 16))
                            .foregroundStyle(Color.gray5)
                    }
                }
                if let noteOfYear = summary.noteOfYear {
                    YearReviewNoteView(wish: noteOfYear)
                }
            }
            .padding(.top, 18)
            .padding(.bottom, inset)
        }
        .padding(.horizontal, inset)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
    }

    /// "올해 나는 / **싶 n개를 이뤘어요!**" — 개수만 tennis-green
    private var headline: Text {
        let count = summary.totalCount
        let text = Strings.YearReview.headlineFormat(count)
        let nsText = text as NSString
        let boldRange = nsText.range(of: Strings.YearReview.headlineBoldFormat(count))
        let countRange = nsText.range(of: Strings.YearReview.countFormat(count))
        guard boldRange.location != NSNotFound, countRange.location != NSNotFound,
              NSLocationInRange(countRange.location, boldRange) else {
            return Text(verbatim: text).font(.appleLight(size: 22)).foregroundStyle(Color.gray5)
        }
        let head = nsText.substring(to: boldRange.location)
        let boldHead = nsText.substring(with: NSRange(location: boldRange.location, length: countRange.location - boldRange.location))
        let countText = nsText.substring(with: countRange)
        let boldTail = nsText.substring(with: NSRange(
            location: countRange.location + countRange.length,
            length: boldRange.location + boldRange.length - countRange.location - countRange.length
        ))
        let tail = nsText.substring(from: boldRange.location + boldRange.length)
        return Text(verbatim: head).font(.appleLight(size: 22)).foregroundStyle(Color.gray5)
            + Text(verbatim: boldHead).font(.appleBold(size: 22)).foregroundStyle(Color.gray5)
            + Text(verbatim: countText).font(.appleBold(size: 22)).foregroundStyle(Color.tennisGreen)
            + Text(verbatim: boldTail).font(.appleBold(size: 22)).foregroundStyle(Color.gray5)
            + Text(verbatim: tail).font(.appleLight(size: 22)).foregroundStyle(Color.gray5)
    }
}

/// 카테고리 한 칸: 일러스트 + 이름 + 완료 수
private struct YearReviewCategoryCell: View {
    let category: Category
    let count: Int

    var body: some View {
        VStack(spacing: 0) {
            category.illustration
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .padding(.top, 10)
                .accessibilityHidden(true)
            Text(verbatim: category.title)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
            Text(verbatim: Strings.YearReview.countFormat(count))
                .font(.appleBold(size: 16))
                .foregroundStyle(Color.gray5)
                .padding(.top, 2)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// 가장 오래 품고 이룬 싶
private struct YearReviewLongestHeldView: View {
    let wish: Wish
    let days: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            YearReviewCaption(text: Strings.YearReview.LongestHeld.title)
            HStack(spacing: 12) {
                Text(verbatim: wish.emoji)
                    .font(.system(size: 30))
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: wish.title)
                        .font(.appleSemiBold(size: 16))
                        .foregroundStyle(Color.gray5)
                        .lineLimit(1)
                    daysText
                }
            }
        }
    }

    private var daysText: Text {
        let text = Strings.YearReview.LongestHeld.daysFormat(days)
        let bold = Strings.YearReview.LongestHeld.daysBoldFormat(days)
        guard let range = text.range(of: bold) else {
            return Text(verbatim: text).font(.appleRegular(size: 14)).foregroundStyle(Color.gray4)
        }
        return Text(verbatim: String(text[..<range.lowerBound])).font(.appleRegular(size: 14)).foregroundStyle(Color.gray4)
            + Text(verbatim: bold).font(.appleBold(size: 14)).foregroundStyle(Color.gray5)
            + Text(verbatim: String(text[range.upperBound...])).font(.appleRegular(size: 14)).foregroundStyle(Color.gray4)
    }
}

/// 올해의 한 줄 (소감)
private struct YearReviewNoteView: View {
    let wish: Wish

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            YearReviewCaption(text: Strings.YearReview.NoteOfYear.title)
            Text(verbatim: Strings.Home.FinishNote.cellFormat(wish.finishNote))
                .font(.appleSemiBold(size: 14))
                .foregroundStyle(Color.gray5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            Text(verbatim: wish.title)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
                .lineLimit(1)
                .padding(.top, 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct YearReviewCaption: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.appleMedium(size: 12))
            .foregroundStyle(Color.gray4)
    }
}
