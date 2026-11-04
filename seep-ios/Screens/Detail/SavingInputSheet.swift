import SwiftUI

/// "모은 돈 기록" 시트 (GH-16 R-4): 헤드라인 + 금액 칸(gray2·라운드 12·높이 52, 단위 "원") + 빠른 금액 + 미리보기 + 기록하기 CTA
struct SavingInputSheet: View {
    @State var viewModel: SavingInputViewModel
    @State private var text = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeadlineText(text: Strings.Detail.Saving.Sheet.title, boldPart: Strings.Detail.Saving.Sheet.titleBold)
                .padding(.top, 24)
            amountField
                .padding(.top, 20)
            quickButtons
                .padding(.top, 12)
            preview
                .padding(.top, 16)
            SeepCTA(
                title: Strings.Detail.Saving.Sheet.save,
                isEnabled: viewModel.state.isSaveEnabled,
                fillsWidth: true
            ) {
                viewModel.send(.tapSave)
            }
            .padding(.top, 28)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .onAppear { isFocused = true }
        .onChange(of: text) { _, newText in
            viewModel.send(.inputAmountText(newText))
        }
        .onChange(of: viewModel.state.amountText) { _, formatted in
            if formatted != text { text = formatted }
        }
        .onChange(of: viewModel.route) { _, route in
            if route == .dismiss { dismiss() }
        }
    }

    private var amountField: some View {
        HStack(spacing: 4) {
            TextField(Strings.Write.TargetAmount.placeholder, text: $text)
                .font(.appleRegular(size: 16))
                .foregroundStyle(Color.gray5)
                .keyboardType(AmountFormatter.fractionDigits(viewModel.currency) > 0 ? .decimalPad : .numberPad)
                .focused($isFocused)
                .accessibilityLabel(Text(Strings.Detail.Saving.Sheet.amount))
            Text(verbatim: AmountFormatter.unit(currency: viewModel.currency))
                .font(.appleRegular(size: 16))
                .foregroundStyle(Color.gray5)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
    }

    private var quickButtons: some View {
        HStack(spacing: 8) {
            ForEach(Array(viewModel.quickAmounts.enumerated()), id: \.offset) { index, amount in
                quickButton(quickTitle(index: index, amount: amount), .plus(amount))
            }
            quickButton(Strings.Detail.Saving.Sheet.remainingAll, .remainingAll)
        }
    }

    /// 원화는 지금 문구(+1만·+5만·+10만), 그 밖은 "+$10"처럼 통화 표기 (GH-103)
    private func quickTitle(index: Int, amount: Int) -> String {
        if viewModel.currency == AmountFormatter.krw {
            return [Strings.Detail.Saving.Sheet.plus10k, Strings.Detail.Saving.Sheet.plus50k, Strings.Detail.Saving.Sheet.plus100k][index]
        }
        return "+" + AmountFormatter.money(amount, currency: viewModel.currency)
    }

    private func quickButton(_ title: String, _ amount: SavingInputViewModel.QuickAmount) -> some View {
        Button {
            viewModel.send(.tapQuickAmount(amount))
        } label: {
            Text(verbatim: title)
                .font(.appleMedium(size: 14))
                .foregroundStyle(Color.gray5)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color.gray1, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.gray2_5, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var preview: some View {
        if let preview = viewModel.state.preview {
            let amountText = Strings.Detail.Saving.Sheet.previewAmountFormat(
                AmountFormatter.money(preview.savedAmount, currency: preview.currency),
                AmountFormatter.money(preview.targetAmount, currency: preview.currency)
            )
            let text = Strings.Detail.Saving.Sheet.previewFormat(amountText, preview.percent)
            if let range = text.range(of: amountText) {
                (Text(verbatim: String(text[..<range.lowerBound])).foregroundStyle(Color.gray4)
                 + Text(verbatim: amountText).font(.appleBold(size: 14)).foregroundStyle(Color.gray5)
                 + Text(verbatim: String(text[range.upperBound...])).foregroundStyle(Color.gray4))
                    .font(.appleRegular(size: 14))
            } else {
                Text(verbatim: text)
                    .font(.appleRegular(size: 14))
                    .foregroundStyle(Color.gray4)
            }
        }
    }
}
