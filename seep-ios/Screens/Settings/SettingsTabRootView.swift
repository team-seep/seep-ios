import AuthenticationServices
import SwiftUI

/// 마이 탭 루트 (GH-64 R-24 ~ R-29, GH-93에서 "설정" → "마이", 맨 위 계정 카드).
/// 시스템 내비게이션 바 큰 제목 "설정" 아래 그룹 목록(gray2 바탕 위 흰 카드·라운드 12·줄 최소 52, 그룹 제목 14 gray4)
struct SettingsTabRootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.authorizationController) private var authorizationController

    @State private var viewModel = SettingsViewModel()
    @State private var accountViewModel = AccountViewModel()
    @State private var isAccountPresented = false
    @State private var appLockSheet: AppLockSheetViewModel?
    @State private var isViewTypeDialogPresented = false
    @State private var isAppearanceDialogPresented = false
    @State private var isStartCategoryDialogPresented = false
    @State private var isLanguageDialogPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if accountViewModel.state.isAvailable {
                    AccountCard(viewModel: accountViewModel)
                }
                ForEach(viewModel.state.groups) { group in
                    Text(verbatim: group.title)
                        .font(.appleMedium(size: 14))
                        .foregroundStyle(Color.gray4)
                        .padding(.top, 18)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 2)
                    VStack(spacing: 0) {
                        ForEach(Array(group.rows.enumerated()), id: \.element.id) { index, row in
                            if index > 0 {
                                Rectangle()
                                    .fill(Color.tagBg)
                                    .frame(height: 1)
                                    .padding(.leading, 14)
                            }
                            rowView(row)
                        }
                    }
                    .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
                }

                Text(accountViewModel.state.account == nil ? Strings.Settings.footer : Strings.Settings.footerMember)
                    .font(.appleMedium(size: 12))
                    .foregroundStyle(Color.gray4)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: SeepLayout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Color.gray2)
        .navigationTitle(Strings.Settings.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.send(.onAppear)
            accountViewModel.send(.onAppear)
        }
        .onChange(of: scenePhase) { _, phase in
            // 아이폰 설정에서 알림 권한을 바꾸고 돌아오면 다시 읽는다 (R-25)
            if phase == .active { viewModel.send(.onAppear) }
        }
        .trackScreen(viewModel.screenName)
        .onChange(of: viewModel.route) { _, route in
            handle(route)
        }
        .onChange(of: accountViewModel.route) { _, route in
            handle(route)
        }
        .navigationDestination(isPresented: $isAccountPresented) {
            AccountScreen(viewModel: accountViewModel)
                .seepPushedScreen()
        }
        .confirmationDialog(
            Strings.Account.AfterDelete.title,
            isPresented: afterDeleteBinding,
            titleVisibility: .visible
        ) {
            // 계정은 이미 지워졌으니 취소 없이 둘 중 하나를 고른다 (R-29)
            Button(Strings.Account.keepLocal) { accountViewModel.send(.selectAfterDelete(.keep)) }
            Button(Strings.Account.AfterDelete.erase, role: .destructive) { accountViewModel.send(.selectAfterDelete(.erase)) }
        } message: {
            Text(Strings.Account.AfterDelete.message)
        }
        .confirmationDialog(
            Strings.Account.OtherAccount.title,
            isPresented: otherAccountBinding,
            titleVisibility: .visible
        ) {
            Button(Strings.Account.OtherAccount.replace, role: .destructive) { accountViewModel.send(.selectOtherAccount(replace: true)) }
            Button(Strings.Account.cancel, role: .cancel) { accountViewModel.send(.selectOtherAccount(replace: false)) }
        } message: {
            Text(Strings.Account.OtherAccount.message)
        }
        .seepSheet(item: $appLockSheet, onDismiss: { viewModel.send(.appLockSheetDismissed) }) { sheetViewModel in
            AppLockSheet(viewModel: sheetViewModel, onDismiss: { _ in })
        }
        .confirmationDialog(
            Strings.Settings.ViewType.title,
            isPresented: $isViewTypeDialogPresented,
            titleVisibility: .visible
        ) {
            Button(Strings.Settings.ViewType.list) { viewModel.send(.selectViewType(.list)) }
            Button(Strings.Settings.ViewType.grid) { viewModel.send(.selectViewType(.grid)) }
            Button(Strings.Settings.ViewType.cancel, role: .cancel) {}
        }
        .confirmationDialog(
            Strings.Settings.StartCategory.title,
            isPresented: $isStartCategoryDialogPresented,
            titleVisibility: .visible
        ) {
            Button(Strings.Settings.StartCategory.last) { viewModel.send(.selectStartCategory(nil)) }
            ForEach([Category.wantToDo, .wantToGet, .wantToGo], id: \.self) { category in
                Button(category.title) { viewModel.send(.selectStartCategory(category)) }
            }
            Button(Strings.Settings.ViewType.cancel, role: .cancel) {}
        } message: {
            Text(Strings.Settings.StartCategory.description)
        }
        .confirmationDialog(
            Strings.Settings.Appearance.title,
            isPresented: $isAppearanceDialogPresented,
            titleVisibility: .visible
        ) {
            ForEach(AppAppearance.allCases, id: \.self) { appearance in
                Button(Self.title(of: appearance)) { viewModel.send(.selectAppearance(appearance)) }
            }
            Button(Strings.Settings.ViewType.cancel, role: .cancel) {}
        } message: {
            Text(DeviceKind.current == .pad ? Strings.Settings.Appearance.footerPad : Strings.Settings.Appearance.footer)
        }
        .confirmationDialog(
            Strings.Settings.Language.title,
            isPresented: $isLanguageDialogPresented,
            titleVisibility: .visible
        ) {
            Button(Strings.Settings.Language.system) { viewModel.send(.selectLanguage(nil)) }
            // 언어 이름은 그 언어로 쓴다("English", "日本語")
            ForEach(viewModel.state.languageOptions, id: \.self) { code in
                Button(AppLanguage.displayName(of: code)) { viewModel.send(.selectLanguage(code)) }
            }
            Button(Strings.Settings.ViewType.cancel, role: .cancel) {}
        } message: {
            Text(Strings.Settings.Language.footer)
        }
    }

    static func title(of appearance: AppAppearance) -> String {
        switch appearance {
        case .system: return Strings.Settings.Appearance.system
        case .light: return Strings.Settings.Appearance.light
        case .dark: return Strings.Settings.Appearance.dark
        }
    }

    // MARK: Rows

    @ViewBuilder
    private func rowView(_ row: SettingsRow) -> some View {
        switch row {
        case .appLock(let title, let description, let isOn):
            SettingsRowView(title: title, description: description) {
                Toggle(isOn: appLockToggleBinding(isOn: isOn)) {
                    EmptyView()
                }
                .labelsHidden()
                .tint(Color.tennisGreen)
            }

        case .notification(let status):
            button(
                title: Strings.Settings.Notification.title,
                description: DeviceKind.current == .pad ? Strings.Settings.Notification.descriptionPad : Strings.Settings.Notification.description,
                value: notificationValue(status),
                action: .tapNotification
            )

        case .viewType(let viewType):
            button(
                title: Strings.Settings.ViewType.title,
                value: viewType == .grid ? Strings.Settings.ViewType.grid : Strings.Settings.ViewType.list,
                action: .tapViewType
            )

        case .appearance(let appearance):
            button(
                title: Strings.Settings.Appearance.title,
                value: Self.title(of: appearance),
                action: .tapAppearance
            )

        case .startCategory(let category):
            button(
                title: Strings.Settings.StartCategory.title,
                value: category?.title ?? Strings.Settings.StartCategory.lastShort,
                action: .tapStartCategory
            )

        case .language(let name):
            button(
                title: Strings.Settings.Language.title,
                value: name,
                action: .tapLanguage
            )

        case .widgetGuide:
            button(title: Strings.Settings.widgetGuide, action: .tapWidgetGuide)
        case .controlGuide:
            button(title: Strings.Settings.controlGuide, action: .tapControlGuide)
        case .rateApp:
            button(title: Strings.Settings.rateApp, action: .tapRateApp)
        case .contact:
            button(title: Strings.Settings.contact, action: .tapContact)
        case .license:
            button(title: Strings.Settings.license, action: .tapLicense)

        case .version(let version):
            SettingsRowView(title: Strings.Settings.version) {
                Text(verbatim: version)
                    .font(.appleRegular(size: 14))
                    .foregroundStyle(Color.gray4)
            }
        }
    }

    private func button(
        title: String,
        description: String? = nil,
        value: String? = nil,
        action: SettingsViewModel.Action
    ) -> some View {
        Button {
            viewModel.send(action)
        } label: {
            SettingsRowView(title: title, description: description) {
                HStack(spacing: 6) {
                    if let value {
                        Text(verbatim: value)
                            .font(.appleRegular(size: 14))
                            .foregroundStyle(Color.gray4)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.gray3)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// 스위치는 잠금 시트를 띄울 뿐, 값은 인증에 성공해야 바뀐다 (실패·취소면 원래대로)
    private func appLockToggleBinding(isOn: Bool) -> Binding<Bool> {
        Binding(
            get: { isOn },
            set: { _ in viewModel.send(.tapAppLock) }
        )
    }

    private func notificationValue(_ status: NotificationAuthorization?) -> String? {
        switch status {
        case .authorized: return Strings.Settings.Notification.on
        case .denied, .notDetermined: return Strings.Settings.Notification.off
        case nil: return nil
        }
    }

    // MARK: Route

    private func handle(_ route: SettingsViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .appLockSheet:
            appLockSheet = AppLockSheetViewModel()
        case .viewTypeDialog:
            isViewTypeDialogPresented = true
        case .appearanceDialog:
            isAppearanceDialogPresented = true
        case .startCategoryDialog:
            isStartCategoryDialogPresented = true
        case .languageDialog:
            isLanguageDialogPresented = true
        case .openURL(let url):
            let isContact = url.scheme == "mailto"
            openURL(url) { accepted in
                if !accepted && isContact {
                    viewModel.send(.contactUnavailable)
                }
            }
        case .push(let destination):
            router.push(destination)
        case .toast(let message):
            toastCenter.show(message)
        }
        viewModel.send(.routeHandled)
    }
}

// MARK: - Account (GH-93)

extension SettingsTabRootView {
    private var afterDeleteBinding: Binding<Bool> {
        Binding(
            get: { accountViewModel.state.dialog == .afterDelete },
            set: { _ in }
        )
    }

    private var otherAccountBinding: Binding<Bool> {
        Binding(
            get: { accountViewModel.state.dialog == .otherAccount },
            set: { _ in }
        )
    }

    private func handle(_ route: AccountViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .requestAppleAuthorization(let nonce):
            let controller = authorizationController
            Task { @MainActor in
                switch await AppleAuthorization.perform(nonce: nonce, with: controller) {
                case .authorized(let credential):
                    accountViewModel.send(.appleAuthorized(credential))
                case .failed(let isCanceled):
                    accountViewModel.send(.appleAuthorizationFailed(isCanceled: isCanceled))
                }
            }
        case .pushAccount:
            isAccountPresented = true
        case .popAccount:
            isAccountPresented = false
        case .toast(let message):
            toastCenter.show(message)
        }
        accountViewModel.send(.routeHandled)
    }
}

extension AppLockSheetViewModel: Identifiable {
    var id: ObjectIdentifier { ObjectIdentifier(self) }
}

/// 설정 줄: 제목 16 Medium + 선택 설명 12 gray4 + 오른쪽 내용 (줄 최소 52)
struct SettingsRowView<Trailing: View>: View {
    let title: String
    var description: String?
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: title)
                    .font(.appleMedium(size: 16))
                    .foregroundStyle(Color.gray5)
                if let description {
                    Text(verbatim: description)
                        .font(.appleRegular(size: 12))
                        .foregroundStyle(Color.gray4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 8)
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
