import SwiftUI
import PhotosUI

/// 위시 상세 — 읽는 문서 (GH-59 D2, GH-64 TC-601~609).
/// 흰 바탕 한 장 문서: 상단 바(뒤로·수정·⋯) / 제목 블록 / 메모 / 단계 · 일지 · 모은 돈 · 링크 · 장소 · 사진 섹션.
/// 작성용 입력 컴포넌트·카드·구분선 없이 섹션 사이 40pt 여백으로 나눈다 (R-1)
struct WishDetailScreen: View {
    let wishId: String
    /// 이룬 싶 탭(완료 목록)에서 열었는지 — 수정 버튼·메뉴 항목이 달라진다
    let isFinished: Bool

    @State private var viewModel: WishDetailViewModel

    init(wishId: String, isFinished: Bool) {
        self.wishId = wishId
        self.isFinished = isFinished
        _viewModel = State(initialValue: WishDetailViewModel(config: .init(
            wishId: wishId,
            mode: isFinished ? .fromFinish : .fromHome
        )))
    }

    init(viewModel: WishDetailViewModel, wishId: String, isFinished: Bool) {
        self.wishId = wishId
        self.isFinished = isFinished
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        WishDetailContent(viewModel: viewModel)
    }
}

private struct WishDetailContent: View {
    private enum Layout {
        static let horizontalInset: CGFloat = 24
        static let sectionSpacing: CGFloat = 40
        static let bodySpacing: CGFloat = 28
    }

    let viewModel: WishDetailViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?
    @Environment(AppRouter.self) private var router: AppRouter?
    @Environment(\.isPadDetailPane) private var isPadDetailPane

    @State private var isTitleCollapsed = false
    @State private var titleBottom: CGFloat = 0
    @State private var moreMenuItems: [DetailMoreMenu.Item] = []
    @State private var isMoreMenuPresented = false
    @State private var isDeleteAlertPresented = false
    @State private var isCancelFinishAlertPresented = false
    /// 수정 중이면 문서가 제자리에서 편집 상태로 바뀐다 (GH-70 R-14)
    @State private var editingViewModel: WishFormViewModel?
    @State private var sharingWish: SharingWish?
    @State private var errorMessage: String?
    @State private var savingInput: SavingInputViewModel?
    @State private var deletingSavingId: String?
    @State private var isAddAgainAlertPresented = false
    @State private var isCalendarDeniedAlertPresented = false
    @State private var isPlaceSearchPresented = false
    @State private var isPhotoPickerPresented = false
    @State private var pickedPhoto: PhotosPickerItem?

    var body: some View {
        ZStack {
            if let editingViewModel {
                WishDocumentEditor(viewModel: editingViewModel) { savedWish in
                    withAnimation(.easeInOut(duration: 0.2)) { self.editingViewModel = nil }
                    if let savedWish {
                        viewModel.send(.editFinished(savedWish))
                    }
                }
                .transition(.opacity)
            } else {
                readingDocument
                    .transition(.opacity)
            }
        }
        .background(Color.gray1)
        .navigationBarTitleDisplayMode(.inline)
        // 편집 중에는 뒤로 버튼·밀어서 뒤로 가기를 막는다 (GH-70 R-14)
        .navigationBarBackButtonHidden(editingViewModel != nil)
        .onAppear { viewModel.send(.onAppear) }
        .trackScreen(viewModel.screenName)
        .onChange(of: viewModel.route) { _, route in handle(route) }
        .onChange(of: viewModel.steps?.route) { _, route in handleSteps(route) }
        .onChange(of: viewModel.savings?.route) { _, route in handleSavings(route) }
        .onChange(of: viewModel.calendar?.route) { _, route in handleCalendar(route) }
        .onChange(of: viewModel.link?.route) { _, route in handleLink(route) }
        .onChange(of: viewModel.place?.route) { _, route in handlePlace(route) }
        .onChange(of: viewModel.photo?.route) { _, route in handlePhoto(route) }
        .onChange(of: pickedPhoto) { _, item in loadPickedPhoto(item) }
        .modifier(DetailJournalEvents(journal: viewModel.journal, errorMessage: $errorMessage))
        .confirmationDialog("", isPresented: $isMoreMenuPresented, titleVisibility: .hidden) {
            ForEach(moreMenuItems, id: \.title) { item in
                Button(role: item.isDestructive ? .destructive : nil) {
                    viewModel.send(.selectMoreItem(item))
                } label: {
                    Text(verbatim: item.title)
                }
            }
            Button(role: .cancel) {} label: { Text(Strings.detailActionSheetCancel) }
        }
        .alert(Text(verbatim: ""), isPresented: $isDeleteAlertPresented) {
            Button(role: .cancel) {} label: { Text(Strings.commonCancel) }
            Button { viewModel.send(.confirmDelete) } label: { Text(Strings.commonOk) }
        } message: {
            Text(Strings.detailDeleteMessage)
        }
        .alert(Text(Strings.detailCancelFinishTitle), isPresented: $isCancelFinishAlertPresented) {
            Button(role: .cancel) {} label: { Text(Strings.detailCancelFinishNo) }
            Button { viewModel.send(.confirmCancelFinish) } label: { Text(Strings.detailCancelFinishOk) }
        } message: {
            Text(Strings.detailCancelFinishDescription)
        }
        .alert(Text(Strings.Detail.Saving.DeleteAlert.title), isPresented: deletingSavingBinding) {
            Button(role: .cancel) {} label: { Text(Strings.commonCancel) }
            Button {
                if let savingId = deletingSavingId {
                    viewModel.savings?.send(.confirmDelete(savingId: savingId))
                }
            } label: { Text(Strings.Detail.Saving.DeleteAlert.confirm) }
        }
        .alert(Text(Strings.Detail.Calendar.AgainAlert.title), isPresented: $isAddAgainAlertPresented) {
            Button(role: .cancel) {} label: { Text(Strings.commonCancel) }
            Button { viewModel.calendar?.send(.confirmAddAgain) } label: {
                Text(Strings.Detail.Calendar.AgainAlert.confirm)
            }
        } message: {
            Text(Strings.Detail.Calendar.AgainAlert.message)
        }
        .alert(Text(Strings.Detail.Calendar.DeniedAlert.title), isPresented: $isCalendarDeniedAlertPresented) {
            Button(role: .cancel) {} label: { Text(Strings.commonCancel) }
            Button {
                // UIApplication.openSettingsURLString 과 같은 값 (UIKit 없이 앱 설정 열기)
                if let url = URL(string: "app-settings:") { openURL(url) }
            } label: { Text(Strings.Detail.Calendar.DeniedAlert.settings) }
        } message: {
            Text(Strings.Detail.Calendar.DeniedAlert.message)
        }
        .alert(Text(verbatim: ""), isPresented: errorBinding) {
            Button {} label: { Text(Strings.commonOk) }
        } message: {
            Text(verbatim: errorMessage ?? "")
        }
        .seepSheet(item: $savingInput) { inputViewModel in
            SavingInputSheet(viewModel: inputViewModel)
        }
        .seepSheet(isPresented: $isPlaceSearchPresented, detent: .large) {
            PlaceSearchSheet { place in
                viewModel.place?.send(.selectPlace(place))
            }
        }
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $pickedPhoto, matching: .images)
        .seepFullScreenCover(item: $sharingWish) { sharing in
            SharePhotoScreen(wish: sharing.wish)
        }
    }

    /// 읽기 상태 문서. 장소·사진·모은 돈은 여기서만 고친다 (GH-70 R-16)
    private var readingDocument: some View {
        ScrollView {
            if let summary = viewModel.state.summary {
                document(summary: summary)
                    // 넓은 화면(듀오 안쪽)은 600pt 기둥 (GH-12)
                    .frame(maxWidth: SeepLayout.maxContentWidth)
                    .frame(maxWidth: .infinity)
            }
        }
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            // 큰 제목이 상단 바 아래로 지나가면 바 가운데에 제목·작은 D-day를 보인다 (R-8)
            let collapsed = titleBottom > 0 && offset >= titleBottom
            if collapsed != isTitleCollapsed { isTitleCollapsed = collapsed }
        }
        .toolbar {
            DetailToolbar(
                title: viewModel.state.summary?.title ?? "",
                dday: viewModel.state.summary?.navigationDday,
                isTitleCollapsed: isTitleCollapsed,
                isEditVisible: viewModel.isEditVisible,
                onEdit: { viewModel.send(.tapEdit) },
                onMore: { viewModel.send(.tapMore) }
            )
        }
    }

    // MARK: 문서

    private func document(summary: WishDetailSummary) -> some View {
        let sections = viewModel.state.sections
        return VStack(alignment: .leading, spacing: 0) {
            DocumentTitleBlock(summary: summary)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.frame(in: .scrollView).maxY
                } action: { maxY in
                    titleBottom = maxY
                }
            if sections.contains(.memo), let memo = summary.memo {
                DocumentBody(text: memo)
                    .padding(.top, Layout.bodySpacing)
            }
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                ForEach(sections.filter { $0 != .memo }, id: \.self) { section in
                    sectionView(section)
                }
            }
            .padding(.top, Layout.sectionSpacing)
        }
        .padding(.horizontal, Layout.horizontalInset)
        .padding(.top, 8)
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private func sectionView(_ section: DetailSection) -> some View {
        switch section {
        case .memo:
            EmptyView()
        case .chain:
            if let chain = viewModel.state.chain {
                DetailChainSection(chain: chain) { viewModel.send(.tapChainWish(id: $0)) }
            }
        case .steps:
            if let steps = viewModel.steps {
                DocumentSection(
                    title: Strings.Detail.Step.title,
                    count: steps.state.progress.map {
                        Strings.Detail.Section.stepCountFormat($0.doneCount, $0.totalCount)
                    }
                ) {
                    DetailStepsBody(steps: steps.state.steps) { steps.send(.tapStep($0)) }
                }
            }
        case .journal:
            if let journal = viewModel.journal {
                DetailJournalSection(journal: journal)
            }
        case .savings:
            if let savings = viewModel.savings, savings.state.isVisible, let progress = savings.state.progress {
                DocumentSection(
                    title: Strings.Detail.Section.savings,
                    actionTitle: Strings.Detail.Section.savingsAdd,
                    action: { savings.send(.tapAdd) }
                ) {
                    DetailSavingsBody(progress: progress, savings: savings.state.savings) {
                        savings.send(.tapDelete(savingId: $0))
                    }
                }
            }
        case .link:
            if let link = viewModel.link, link.state.isVisible {
                DocumentSection(
                    title: Strings.Detail.Link.title,
                    actionTitle: Strings.Detail.Section.linkOpen,
                    action: { link.send(.tapCard) }
                ) {
                    DetailLinkBody(preview: link.state.preview) { link.send(.tapCard) }
                        .onAppear { link.send(.load) }
                }
            }
        case .place:
            if let place = viewModel.place {
                DocumentSection(
                    title: Strings.Detail.Place.title,
                    actionTitle: place.state.place == nil ? nil : Strings.Detail.Section.placeChange,
                    action: { place.send(.tapPlace) }
                ) {
                    DetailPlaceBody(
                        place: place.state.place,
                        onAdd: { place.send(.tapPlace) },
                        onDelete: { place.send(.tapDelete) }
                    )
                }
            }
        case .letter:
            DetailLetterSection(letter: viewModel.state.letter)
        case .photo:
            if let photo = viewModel.photo {
                // 바꾸기·빈 자리는 이룬 싶 탭 상세에만 (GH-61 R-12)
                DocumentSection(
                    title: Strings.Detail.Photo.title,
                    actionTitle: photo.isEditable && photo.hasPhoto ? Strings.Detail.Photo.change : nil,
                    action: { photo.send(.tapChange) }
                ) {
                    DetailPhotoBody(
                        photoURL: photo.state.photoURL,
                        onAdd: photo.isEditable ? { photo.send(.tapAdd) } : nil
                    )
                }
            }
        }
    }

    // MARK: Route

    private func handle(_ route: WishDetailViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .edit(let wish):
            withAnimation(.easeInOut(duration: 0.2)) {
                editingViewModel = WishFormViewModel(config: .init(mode: .edit(wish)))
            }
        case .moreMenu(let items):
            moreMenuItems = items
            isMoreMenuPresented = true
        case .confirmDelete:
            isDeleteAlertPresented = true
        case .confirmCancelFinish:
            isCancelFinishAlertPresented = true
        case .sharePhoto(let wish):
            sharingWish = SharingWish(wish: wish)
        case .chainedWrite(let wish):
            router?.openChainedWrite(from: wish)
        case .wishDetail(let id, let isFinished):
            router?.push(.wishDetail(id: id, isFinished: isFinished))
        case .errorAlert(let message):
            errorMessage = message
        case .close:
            // 아이패드 상세 열은 쌓인 화면이 아니라 열을 비운다 (GH-99 R-5)
            if isPadDetailPane {
                router?.closePadDetail()
            } else {
                dismiss()
            }
        }
        viewModel.send(.routeHandled)
    }

    private func handleSteps(_ route: DetailStepsViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .errorAlert(let message):
            errorMessage = message
        }
        viewModel.steps?.send(.routeHandled)
    }

    private func handleSavings(_ route: WishSavingsViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .savingInput(let inputViewModel):
            savingInput = inputViewModel
        case .deleteAlert(let savingId):
            deletingSavingId = savingId
        case .errorAlert(let message):
            errorMessage = message
        case .toast(let message):
            toastCenter?.show(message)
        }
        viewModel.savings?.send(.routeHandled)
    }

    private func handleCalendar(_ route: WishCalendarViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .addAgainAlert:
            isAddAgainAlertPresented = true
        case .permissionDeniedAlert:
            isCalendarDeniedAlertPresented = true
        case .errorAlert(let message):
            errorMessage = message
        case .toast(let message):
            toastCenter?.show(message)
        }
        viewModel.calendar?.send(.routeHandled)
    }

    private func handleLink(_ route: DetailLinkViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .openURL(let url):
            openURL(url)
        }
        viewModel.link?.send(.routeHandled)
    }

    private func handlePlace(_ route: DetailPlaceViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .placeSearch:
            isPlaceSearchPresented = true
        case .errorAlert(let message):
            errorMessage = message
        }
        viewModel.place?.send(.routeHandled)
    }

    private func handlePhoto(_ route: WishPhotoViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .photoPicker:
            isPhotoPickerPresented = true
        case .errorAlert(let message):
            errorMessage = message
        }
        viewModel.photo?.send(.routeHandled)
    }

    /// 원본 데이터(HEIC·JPEG 등)를 넘기고, 줄이기·저장은 저장소가 메인 스레드 밖에서 한다 (GH-36 R-3)
    private func loadPickedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        pickedPhoto = nil
        Task { @MainActor in
            if let data = try? await item.loadTransferable(type: Data.self) {
                viewModel.photo?.send(.pickPhoto(data))
            } else {
                viewModel.photo?.send(.pickFailed)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private var deletingSavingBinding: Binding<Bool> {
        Binding(get: { deletingSavingId != nil }, set: { if !$0 { deletingSavingId = nil } })
    }
}

/// 공유 화면을 `seepFullScreenCover(item:)`로 띄우기 위한 감싸개
private struct SharingWish: Identifiable {
    let wish: Wish
    var id: String { wish.id }
}
