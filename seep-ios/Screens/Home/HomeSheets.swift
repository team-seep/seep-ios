import SwiftUI

/// 정렬 시트: 완료일 가까운순 / 최근 생성순 / 내가 정한 순서 (높이 56 세 줄, 사이 gray2 선).
/// 고른 정렬은 seep-blue ExtraBold, 아래에 "내가 정한 순서" 안내 캡션 (GH-73 R-1)
struct SortOrderSheet: View {
    let selected: HomeSortOrder
    let onSelect: (HomeSortOrder) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(HomeSortOrder.allCases.enumerated()), id: \.element) { index, sortOrder in
                if index > 0 {
                    Rectangle()
                        .fill(Color.gray2)
                        .frame(height: 1)
                }
                row(sortOrder)
            }
            Text(Strings.Home.Filter.sortCaption)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
                .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private func row(_ sortOrder: HomeSortOrder) -> some View {
        let isSelected = sortOrder == selected
        return Button {
            onSelect(sortOrder)
        } label: {
            Text(verbatim: sortOrder.title)
                .font(isSelected ? .appleExtraBold(size: 16) : .appleSemiBold(size: 16))
                .foregroundStyle(isSelected ? Color.seepBlue : Color.gray5)
                .frame(maxWidth: .infinity, minHeight: 56)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// 완료 소감 시트: "{이모지} {제목} · 이뤘어요!" · "기대했던 것과 비교하면 / **어땠어요?**" · 기대 비교 세 칸 ·
/// "한 줄 소감 (선택)" 입력 칸(글자 수) · 이어서 적기 · 저장할게요 · 다음에 할게요 (GH-25, GH-139 R-2).
/// 편지가 열리면 편지 아래에 기대 비교 질문과 세 칸을 둔다 (GH-139 R-4)
struct FinishNoteSheet: View {
    @Bindable var viewModel: FinishNoteViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let letter = viewModel.state.openedLetter {
                openedLetter(letter)
                Text(Strings.Home.FinishNote.letterFeelingQuestion)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24)
                feelingButtons
                    .padding(.top, 12)
                Text(Strings.Home.FinishNote.letterQuestion)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray5)
                    .padding(.top, 24)
            } else {
                Text(verbatim: finishedCaption)
                    .font(.appleMedium(size: 13))
                    .foregroundStyle(Color.gray4)
                    .lineLimit(1)
                    .padding(.top, 24)
                HeadlineText(
                    text: Strings.Home.FinishNote.feelingTitle,
                    boldPart: Strings.Home.FinishNote.feelingTitleBold
                )
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
                feelingButtons
                    .padding(.top, 20)
                Text(Strings.Home.FinishNote.noteLabel)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray5)
                    .padding(.top, 24)
            }

            HStack(spacing: 8) {
                TextField(
                    "",
                    text: Binding(
                        get: { viewModel.state.noteText },
                        set: { viewModel.send(.inputNote($0)) }
                    ),
                    prompt: Text(Strings.Home.FinishNote.placeholder).foregroundStyle(Color.gray3)
                )
                .font(.appleRegular(size: 16))
                .foregroundStyle(Color.gray5)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { viewModel.send(.submitNote) }
                .accessibilityLabel(Text(Strings.Home.FinishNote.field))
                Text(verbatim: viewModel.state.countText)
                    .font(.appleMedium(size: 12))
                    .foregroundStyle(Color.gray4)
                    .fixedSize()
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
            .padding(.top, 10)

            chainRow
                .padding(.top, 20)

            SeepCTA(title: Strings.Home.FinishNote.save, isEnabled: viewModel.state.isSaveEnabled, fillsWidth: true) {
                viewModel.send(.tapSave)
            }
            .padding(.top, 22)

            Button {
                viewModel.send(.tapSkip)
            } label: {
                Text(Strings.Home.FinishNote.skip)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .onAppear { viewModel.send(.onAppear) }
        .onChange(of: viewModel.route) { _, route in
            if route == .dismiss { dismiss() }
        }
        .alert(
            errorMessage ?? "",
            isPresented: Binding(get: { errorMessage != nil }, set: { _ in }),
            actions: {
                Button(Strings.Home.ErrorAlert.confirm, role: .cancel) {}
            }
        )
    }

    private var errorMessage: String? {
        if case .errorAlert(let message) = viewModel.route { return message }
        return nil
    }

    /// "{이모지} {제목} · 이뤘어요!"
    private var finishedCaption: String {
        Strings.Home.FinishNote.finishedCaptionFormat(
            "\(viewModel.wish.emoji) \(viewModel.wish.title)".trimmingCharacters(in: .whitespaces)
        )
    }
}

/// 새 배지 축하 시트: "위시를 n개나 이뤘어요! / **새 배지를 받았어요**" · 배지 카드들 · 좋아요 · 배지 모아보기 (GH-35)
struct BadgeCelebrationSheet: View {
    let viewModel: BadgeCelebrationViewModel
    @Environment(\.dismiss) private var dismiss

    /// 카드가 이보다 높아지면 카드 영역만 스크롤한다 (카드 약 3장 반)
    private let maxCardsHeight: CGFloat = 400

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeadlineText(
                text: Strings.Badge.Celebration.titleFormat(viewModel.finishedCount),
                boldPart: Strings.Badge.Celebration.titleBold
            )
            .padding(.top, 24)

            ViewThatFits(in: .vertical) {
                cards
                ScrollView { cards }
                    .frame(maxHeight: maxCardsHeight)
            }
            .padding(.top, 20)

            SeepCTA(title: Strings.Badge.Celebration.confirm, fillsWidth: true) {
                viewModel.send(.tapConfirm)
            }
            .padding(.top, 24)

            Button {
                viewModel.send(.tapViewBadges)
            } label: {
                Text(Strings.Badge.Celebration.viewBadges)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .onAppear { viewModel.send(.onAppear) }
        .onChange(of: viewModel.route) { _, route in
            if route == .dismiss { dismiss() }
        }
    }

    private var cards: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.badges, id: \.type) { badge in
                HStack(spacing: 16) {
                    HomeBadgeMedal(type: badge.type, diameter: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: badge.type.name)
                            .font(.appleSemiBold(size: 16))
                            .foregroundStyle(Color.gray5)
                        Text(verbatim: Strings.Badge.Celebration.cardDescriptionFormat(
                            badge.type.conditionText,
                            badge.earnedDateText ?? ""
                        ))
                        .font(.appleMedium(size: 12))
                        .foregroundStyle(Color.gray4)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// 얻은 배지 메달: 흰 원 + tennis-green 3pt 링 + 숫자 / 카테고리 일러스트 / "D-day" (GH-35 R-1)
struct HomeBadgeMedal: View {
    let type: BadgeType
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray1)
            Circle()
                .strokeBorder(Color.tennisGreen, lineWidth: 3)
            switch type.medal {
            case .number(let number):
                Text(verbatim: "\(number)")
                    .font(.appleBold(size: 22))
                    .foregroundStyle(Color.gray5)
            case .category(let category):
                category.illustration
                    .resizable()
                    .scaledToFit()
                    .frame(width: (diameter * 36 / 56).rounded(), height: (diameter * 36 / 56).rounded())
            case .dday:
                Text(Strings.Badge.dday)
                    .font(.appleExtraBold(size: 14))
                    .foregroundStyle(Color.gray5)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}

/// 완료 순간 열린 편지 (GH-61 R-5): "{n}일 전의 내가 / **편지를 보냈어요**" + 편지 카드 + "이루고 나니 어때요?"
private extension FinishNoteSheet {
    /// "다음엔 뭐 하고 싶어요? / ＋ 이어서 적기" (GH-84 R-1)
    var chainRow: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray2_5)
                .frame(height: 1)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Home.FinishNote.chainTitle)
                        .font(.appleBold(size: 15))
                        .foregroundStyle(Color.gray5)
                    Text(Strings.Home.FinishNote.chainDescription)
                        .font(.appleRegular(size: 13))
                        .foregroundStyle(Color.gray4)
                }
                Spacer(minLength: 0)
                TextActionButton(title: Strings.Home.FinishNote.chainAction) {
                    viewModel.send(.tapChainNext)
                }
            }
            .padding(.top, 16)
        }
    }

    func openedLetter(_ letter: FinishNoteViewModel.OpenedLetter) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HeadlineText(text: letter.headline, boldPart: Strings.Home.FinishNote.letterTitleBold)
                .padding(.top, 24)
            VStack(alignment: .leading, spacing: 10) {
                Text(verbatim: letter.caption)
                    .font(.appleRegular(size: 12))
                    .foregroundStyle(Color.gray4)
                ScrollView {
                    Text(verbatim: letter.body)
                        .font(.appleRegular(size: 15))
                        .foregroundStyle(Color.gray5)
                        .lineSpacing(6)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 180)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .background(Color.gray2, in: RoundedRectangle(cornerRadius: 16))
            .padding(.top, 20)
        }
    }

    /// 기대 비교 세 칸: 고른 칸 = seep-blue 바탕 흰 ExtraBold + 그림자(카테고리 탭 선택과 같은 역할), 나머지 = gray2 바탕 gray4 (GH-139 R-2)
    var feelingButtons: some View {
        HStack(spacing: 8) {
            ForEach(FinishFeeling.allCases, id: \.self) { feeling in
                feelingButton(feeling)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.state.selectedFeeling)
        .sensoryFeedback(.selection, trigger: viewModel.state.selectedFeeling)
    }

    func feelingButton(_ feeling: FinishFeeling) -> some View {
        let isSelected = viewModel.state.selectedFeeling == feeling
        return Button {
            viewModel.send(.selectFeeling(feeling))
        } label: {
            Text(verbatim: feeling.buttonTitle)
                .font(isSelected ? .appleExtraBold(size: 14) : .appleMedium(size: 14))
                .foregroundStyle(isSelected ? Color.onAccent : Color.gray4)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 6)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.seepBlue : Color.gray2)
                        .shadow(color: .black.opacity(isSelected ? 0.15 : 0), radius: 1.5, y: 2)
                }
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: feeling.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
