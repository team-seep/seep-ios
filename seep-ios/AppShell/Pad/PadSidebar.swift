import SwiftUI

/// 아이패드 사이드바: 싶(카테고리 3개 · 개수) / 돌아보기 / 앱 + 아래 작성 CTA (GH-99 R-4)
struct PadSidebar: View {
    let viewModel: PadRootViewModel

    var body: some View {
        // 시스템 선택 표시는 사이드바가 포커스를 잃으면 회색이 되어, 고른 줄을 직접 그린다 (HIG: 선택 상태를 계속 강조)
        List {
            Section {
                ForEach([PadSidebarItem.wantToDo, .wantToGet, .wantToGo], id: \.self) { item in
                    row(item)
                }
            } header: {
                sectionTitle(Strings.Pad.Sidebar.sectionWish)
            }
            Section {
                ForEach([PadSidebarItem.finished, .badges, .placeMap], id: \.self) { item in
                    row(item)
                }
            } header: {
                sectionTitle(Strings.Pad.Sidebar.sectionLookBack)
            }
            Section {
                row(.settings)
            } header: {
                sectionTitle(Strings.Pad.Sidebar.sectionApp)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color.gray2)
        .tint(Color.seepBlue)
        .safeAreaInset(edge: .bottom) {
            writeButton
        }
    }

    private func row(_ item: PadSidebarItem) -> some View {
        // 고른 줄은 seep-blue 바탕이라 글자·아이콘을 흰색으로
        let isSelected = item == viewModel.selectedItem
        return Button {
            viewModel.send(.tapSidebar(item))
        } label: {
            rowLabel(item, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.seepBlue : Color.clear)
                .padding(.horizontal, 10)
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func rowLabel(_ item: PadSidebarItem, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.systemImage)
                .font(.system(size: 16))
                .foregroundStyle(isSelected ? Color.onAccent : Color.seepBlue)
                .frame(width: 24)
            Text(verbatim: item.title)
                .font(isSelected ? .appleBold(size: 16) : .appleMedium(size: 16))
                .foregroundStyle(isSelected ? Color.onAccent : Color.gray5)
            Spacer(minLength: 4)
            if let category = item.category, let count = viewModel.state.counts[category] {
                Text(verbatim: "\(count)")
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(isSelected ? Color.onAccent : Color.gray4)
            }
        }
        .frame(minHeight: 36)
        .contentShape(Rectangle())
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(verbatim: title)
            .font(.appleBold(size: 13))
            .foregroundStyle(Color.gray4)
    }

    /// 아이폰 탭 바의 "적기"와 같다: 카테고리를 고르면 작성 화면 (GH-64 R-6)
    private var writeButton: some View {
        Button {
            viewModel.send(.tapWrite)
        } label: {
            Text(Strings.Pad.Sidebar.write)
                .font(.appleBold(size: 16))
                .foregroundStyle(Color.gray5)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.tennisGreen, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        // 화면 아래쪽 버튼이라 위로 연다
        .seepPopover(isPresented: writePickerBinding, width: 360, arrowEdge: .bottom) {
            WriteCategorySheet(
                highlightedCategory: viewModel.highlightedCategory,
                onSelect: { viewModel.send(.selectWriteCategory($0)) }
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var writePickerBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isWritePickerPresented },
            set: { isPresented in
                if !isPresented { viewModel.send(.dismissWritePicker) }
            }
        )
    }
}

private extension PadSidebarItem {
    var title: String {
        switch self {
        case .wantToDo: return Strings.categoryWantToDo
        case .wantToGet: return Strings.categoryWantToGet
        case .wantToGo: return Strings.categoryWantToGo
        case .finished: return Strings.MainTab.finished
        case .badges: return Strings.Pad.Sidebar.badges
        case .placeMap: return Strings.PlaceMap.title
        case .settings: return Strings.MainTab.settings
        }
    }

    var systemImage: String {
        switch self {
        case .wantToDo: return "figure.run"
        case .wantToGet: return "gift"
        case .wantToGo: return "airplane"
        case .finished: return "checkmark.circle"
        case .badges: return "medal"
        case .placeMap: return "map"
        case .settings: return "gearshape"
        }
    }
}
