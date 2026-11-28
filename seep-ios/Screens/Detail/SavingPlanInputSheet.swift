import SwiftUI

/// 적금 계획 시트 (GH-121 R-2, 디자인 After 2): 헤드라인 → 얼마나 자주(매주/매달 알약 탭 + 요일·날짜 칩) →
/// 한 번에 얼마씩(금액 칸) → 미리보기·알림 안내 → `tennis-green` CTA → `gray4` 글자 버튼(다음에 할게요 / 계획 지우기)
struct SavingPlanInputSheet: View {
    @State var viewModel: SavingPlanInputViewModel
    @State private var text = ""
    @FocusState private var isAmountFocused: Bool
    @Environment(\.dismiss) private var dismiss

    /// 요일 칩은 월요일부터 (`Calendar` weekday: 2=월 … 7=토, 1=일)
    private static let weekdayOrder = [2, 3, 4, 5, 6, 7, 1]
    private let chipColumns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        // 내용 높이에 맞춘 시트(`fitContent`)라 ScrollView 로 감싸지 않는다. 매달을 고르면 날짜 칩만큼 시트가 커진다
        VStack(alignment: .leading, spacing: 0) {
            HeadlineText(text: Strings.Detail.SavingPlan.Sheet.title, boldPart: Strings.Detail.SavingPlan.Sheet.titleBold)
                .padding(.top, 24)
            label(Strings.Detail.SavingPlan.Sheet.cycleLabel)
                .padding(.top, 24)
            cycleTabs
                .padding(.top, 10)
            dayChips
                .padding(.top, 12)
            if viewModel.state.showsMonthEndNotice {
                Text(Strings.Detail.SavingPlan.Sheet.monthEndNotice)
                    .font(.appleRegular(size: 12))
                    .foregroundStyle(Color.gray4)
                    .padding(.top, 8)
            }
            label(Strings.Detail.SavingPlan.Sheet.amountLabel)
                .padding(.top, 24)
            amountField
                .padding(.top, 10)
            preview
                .padding(.top, 12)
            SeepCTA(
                title: Strings.Detail.SavingPlan.Sheet.save,
                isEnabled: viewModel.state.isSaveEnabled,
                fillsWidth: true
            ) {
                viewModel.send(.tapSave)
            }
            .padding(.top, 28)
            secondaryButton
                .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        // 매달(날짜 칩 31개)이면 키보드가 CTA 를 가린다. 빈 곳을 누르면 키보드를 내린다.
        // 바탕 층에만 달아 금액 칸·버튼을 누를 때는 끼어들지 않는다
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isAmountFocused = false }
        }
        .onAppear { text = viewModel.state.amountText }
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

    private func label(_ title: String) -> some View {
        Text(verbatim: title)
            .font(.appleMedium(size: 14))
            .foregroundStyle(Color.gray5)
    }

    /// 매주/매달 알약 탭. 작성 화면 카테고리 선택과 같은 `category-track` 트랙 위 `seep-blue` 알약
    private var cycleTabs: some View {
        HStack(spacing: 4) {
            ForEach(SavingPlan.Cycle.allCases, id: \.self) { cycle in
                let isSelected = viewModel.state.cycle == cycle
                Button {
                    isAmountFocused = false
                    viewModel.send(.selectCycle(cycle))
                } label: {
                    Text(verbatim: cycle == .weekly ? Strings.Detail.SavingPlan.Sheet.weekly : Strings.Detail.SavingPlan.Sheet.monthly)
                        .font(isSelected ? .appleExtraBold(size: 14) : .appleMedium(size: 14))
                        .foregroundStyle(isSelected ? Color.onAccent : Color.categoryTextOff)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.seepBlue)
                                    .shadow(color: .black.opacity(0.15), radius: 1.5, y: 2)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 9)
        .frame(height: 48)
        .background(Color.categoryTrack, in: Capsule())
        .animation(.easeInOut(duration: 0.2), value: viewModel.state.cycle)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.state.cycle)
    }

    /// 매주 = 요일 칩 7개, 매달 = 날짜 칩 1~31. 비선택 `gray2` 바탕/`gray4`, 선택 `seep-blue` + 흰 ExtraBold 14
    private var dayChips: some View {
        LazyVGrid(columns: chipColumns, spacing: 6) {
            switch viewModel.state.cycle {
            case .weekly:
                ForEach(Self.weekdayOrder, id: \.self) { day in
                    chip(
                        title: SavingPlanText.shortWeekdayName(day, calendar: viewModel.calendar),
                        accessibilityLabel: SavingPlanText.weekdayName(day, calendar: viewModel.calendar),
                        isSelected: viewModel.state.weekday == day
                    ) {
                        viewModel.send(.selectDay(day))
                    }
                }
            case .monthly:
                ForEach(Array(SavingPlan.dayRange(.monthly)), id: \.self) { day in
                    chip(title: "\(day)", accessibilityLabel: nil, isSelected: viewModel.state.monthDay == day) {
                        viewModel.send(.selectDay(day))
                    }
                }
            }
        }
        // 요일(1~7)과 날짜(1~31) 칩이 같은 id 를 써서, 주기를 바꾸면 예전 칩이 남지 않게 격자를 새로 만든다
        .id(viewModel.state.cycle)
    }

    private func chip(title: String, accessibilityLabel: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            isAmountFocused = false
            action()
        } label: {
            Text(verbatim: title)
                .font(isSelected ? .appleExtraBold(size: 14) : .appleMedium(size: 14))
                .foregroundStyle(isSelected ? Color.onAccent : Color.gray4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? Color.seepBlue : Color.gray2, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: accessibilityLabel ?? title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var amountField: some View {
        HStack(spacing: 4) {
            TextField(Strings.Write.TargetAmount.placeholder, text: $text)
                .font(.appleRegular(size: 16))
                .foregroundStyle(Color.gray5)
                .keyboardType(AmountFormatter.fractionDigits(viewModel.currency) > 0 ? .decimalPad : .numberPad)
                .focused($isAmountFocused)
                .accessibilityLabel(Text(Strings.Detail.SavingPlan.Sheet.amountLabel))
            Text(verbatim: AmountFormatter.unit(currency: viewModel.currency))
                .font(.appleRegular(size: 16))
                .foregroundStyle(Color.gray5)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
    }

    /// "7번 넣으면 **12월 18일 (금)**에 다 모여요" + "넣는 날 오전 11시에 알려드릴게요"
    private var preview: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let preview = viewModel.state.preview {
                if let range = preview.text.range(of: preview.highlight) {
                    (Text(verbatim: String(preview.text[..<range.lowerBound]))
                     + Text(verbatim: preview.highlight).font(.appleBold(size: 14)).foregroundStyle(Color.seepBlue)
                     + Text(verbatim: String(preview.text[range.upperBound...])))
                        .font(.appleRegular(size: 14))
                        .foregroundStyle(Color.gray4)
                } else {
                    Text(verbatim: preview.text)
                        .font(.appleRegular(size: 14))
                        .foregroundStyle(Color.gray4)
                }
            }
            Text(Strings.Detail.SavingPlan.Sheet.notice)
                .font(.appleRegular(size: 14))
                .foregroundStyle(Color.gray4)
        }
        .lineSpacing(2)
    }

    private var secondaryButton: some View {
        Button {
            viewModel.send(viewModel.isDeletable ? .tapDelete : .tapLater)
        } label: {
            Text(viewModel.isDeletable ? Strings.Detail.SavingPlan.Sheet.delete : Strings.Detail.SavingPlan.Sheet.later)
                .font(.appleMedium(size: 14))
                .foregroundStyle(Color.gray4)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
