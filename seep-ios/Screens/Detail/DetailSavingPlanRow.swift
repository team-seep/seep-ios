import SwiftUI

/// 모은 돈 섹션 안 "적금 계획" 줄 (GH-121 R-1, R-3~R-5, 디자인 After 1).
/// 제목 Medium 14 `gray4` + 파란 글자 버튼 / 계획 요약 SemiBold 16 / 예측(날짜만 Bold `gray5`)·기한 비교 Regular 14 `gray4`
struct DetailSavingPlanRow: View {
    let row: SavingPlanText.Row
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(Strings.Detail.SavingPlan.title)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                Spacer(minLength: 12)
                TextActionButton(
                    title: row.summary == nil ? Strings.Detail.SavingPlan.add : Strings.Detail.SavingPlan.change,
                    action: onTap
                )
            }
            .frame(height: 22)
            if let summary = row.summary {
                Text(verbatim: summary)
                    .font(.appleSemiBold(size: 16))
                    .foregroundStyle(Color.gray5)
                    .padding(.top, 8)
            }
            if let forecast = row.forecast {
                highlighted(forecast, highlight: row.forecastHighlight)
                    .padding(.top, row.summary == nil ? 6 : 2)
            }
            if let meta = row.meta {
                Text(verbatim: meta)
                    .font(.appleRegular(size: 14))
                    .foregroundStyle(Color.gray4)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func highlighted(_ text: String, highlight: String?) -> Text {
        guard let highlight, let range = text.range(of: highlight) else {
            return Text(verbatim: text).font(.appleRegular(size: 14)).foregroundStyle(Color.gray4)
        }
        return Text(verbatim: String(text[..<range.lowerBound])).font(.appleRegular(size: 14)).foregroundStyle(Color.gray4)
            + Text(verbatim: highlight).font(.appleBold(size: 14)).foregroundStyle(Color.gray5)
            + Text(verbatim: String(text[range.upperBound...])).font(.appleRegular(size: 14)).foregroundStyle(Color.gray4)
    }
}
