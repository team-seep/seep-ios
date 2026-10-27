import SwiftUI

/// 알림 추가·수정 시트 (GH-64 R-41). 레거시 알림 화면(제목·휴지통·알림 날짜 라디오·알림 시간·✔️ 저장)을
/// 시트로 옮기고, 시간 입력은 키보드 대신 휠 `DatePicker`로 고른다
struct NotificationEditorSheet: View {
    @State private var viewModel: NotificationEditorViewModel
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?
    let onSave: (SeepNotification, Int?) -> Void
    let onDelete: (Int) -> Void

    init(
        config: NotificationEditorConfig,
        onSave: @escaping (SeepNotification, Int?) -> Void,
        onDelete: @escaping (Int) -> Void
    ) {
        _viewModel = State(initialValue: NotificationEditorViewModel(config: config))
        self.onSave = onSave
        self.onDelete = onDelete
    }

    /// 삭제 버튼 탭 영역. 시트 안이라 safe area 를 벗어나지 않는다 (GH-10 TC-7)
    static let deleteButtonSize: CGFloat = 44

    var body: some View {
        // 중간 높이에서도 저장 버튼까지 닿도록 스크롤로 감싼다
        ScrollView {
            content
        }
        .scrollBounceBehavior(.basedOnSize)
        .onChange(of: viewModel.route) { _, route in
            handle(route)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Text(Strings.notificationDate)
                .font(.appleRegular(size: 14))
                .foregroundStyle(Color.gray4)
                .padding(.top, 20)
            VStack(spacing: 0) {
                ForEach(NotificationEditorViewModel.types, id: \.self) { type in
                    typeRow(type)
                }
            }
            .padding(.top, 8)
            Rectangle()
                .fill(Color.gray2)
                .frame(height: 1)
                .padding(.top, 12)
            Text(Strings.notificationTime)
                .font(.appleRegular(size: 14))
                .foregroundStyle(Color.gray4)
                .padding(.top, 20)
            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.state.notification.time },
                    set: { viewModel.send(.inputTime($0)) }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .clipped()
            SeepCTA(title: Strings.notificationAdd, fillsWidth: true) {
                viewModel.send(.tapSave)
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var header: some View {
        ZStack {
            Text(viewModel.state.isEditing ? Strings.notificationEditTitle : Strings.notificationAddTitle)
                .font(.appleRegular(size: 16))
                .foregroundStyle(Color.gray5)
            if viewModel.state.isDeletable {
                HStack {
                    Spacer()
                    Button {
                        viewModel.send(.tapDelete)
                    } label: {
                        Assets.Icons.icTrash.swiftUIImage
                            .foregroundStyle(Color.gray5)
                            .frame(width: Self.deleteButtonSize, height: Self.deleteButtonSize)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(Strings.NotificationEditor.delete))
                }
            }
        }
        .frame(height: 44)
    }

    private func typeRow(_ type: SeepNotification.NotificationType) -> some View {
        let isSelected = viewModel.state.notification.type == type
        return Button {
            viewModel.send(.selectType(type))
        } label: {
            HStack {
                Text(verbatim: type.toString)
                    .font(.appleRegular(size: 16))
                    .foregroundStyle(Color.gray5)
                Spacer()
                (isSelected ? Assets.Icons.icRadioOn : Assets.Icons.icRadioOff).swiftUIImage
                    .foregroundStyle(Color.gray3)
            }
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func handle(_ route: NotificationEditorViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .saved(let notification, let index):
            onSave(notification, index)
        case .deleted(let index):
            onDelete(index)
        case .toast(let message):
            toastCenter?.show(message)
        }
        viewModel.send(.routeHandled)
    }
}
